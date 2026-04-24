#!/bin/bash
set -euo pipefail

ORIGIN=$(pwd)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

echo "==> Bootstrapping project..."
mkdir bookery && cd bookery

cp -a $ORIGIN/.scaffor-templates .

scaffor execute go-hexagonal bootstrap \
    --set AppName=bookery \
    --set ModulePath=test.local/bookery \
    --set Context=catalog

echo "==> Adding entity Book..."
scaffor execute go-hexagonal add_entity \
    --set Context=catalog \
    --set ModulePath=test.local/bookery \
    --set Entity=Book \
    --set Adapter=pg

echo "==> Adding entity Order..."
scaffor execute go-hexagonal add_entity \
    --set Context=catalog \
    --set ModulePath=test.local/bookery \
    --set Entity=Order \
    --set Adapter=pg

echo "==> Running go mod tidy..."
go mod tidy

# NOTE: go build is expected to fail on freshly scaffolded code because
# mocks are empty stubs and App struct fields are not yet populated.
# The test validates arch-lint rules only — compilation correctness is
# the agent's responsibility after filling in entity-specific details.

echo "==> Running go-arch-lint check..."
go-arch-lint check

echo ""
echo "PASS: template arch-lint config is clean on a fresh project with 2 entities"
