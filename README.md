# scaffor-templates

Personal [scaffor](https://github.com/JLugagne/scaffor) templates I use across my projects. Versioned here so I can pin specific versions and track how my conventions evolve over time.

This is **not** a community template catalog. Templates are added only when I actively use them in real projects.

---

## What is scaffor?

[scaffor](https://github.com/JLugagne/scaffor) is a deterministic scaffolding tool designed for LLM agents. It generates files from YAML manifests with structured post-generation hints that guide agents through multi-step workflows.

Unlike traditional scaffolding tools (Yeoman, Plop, Cookiecutter), scaffor treats the agent as a first-class consumer: same inputs produce same files every time, with machine-readable next-action hints after every command.

---

## Prerequisites

Install scaffor:

```bash
go install github.com/JLugagne/scaffor/cmd/scaffor@latest
```

Requires Go 1.25+. See the [scaffor README](https://github.com/JLugagne/scaffor#quick-start) for other installation methods.

---

## Using these templates

### Option 1: via global config (recommended)

Clone this repo once, then reference it from scaffor's global config:

```bash
git clone https://github.com/JLugagne/scaffor-templates ~/work/scaffor-templates
```

```yaml
# ~/.config/scaffor/config.yml
template_sources:
  - path: ~/work/scaffor-templates
    description: Personal templates
```

From any project:

```bash
scaffor list
scaffor execute <template> <command> --set Key=Value
```

### Option 2: via explicit path

```bash
git clone https://github.com/JLugagne/scaffor-templates /tmp/templates
scaffor --templates-dir /tmp/templates/<template> execute <command> --set Key=Value
```

### Option 3: via MCP server

scaffor ships an MCP server that exposes these templates to Claude Code, Cursor, or any MCP client. Configure once:

```json
{
  "mcpServers": {
    "scaffor": {
      "command": "scaffor",
      "args": ["mcp"]
    }
  }
}
```

Agents can then discover and invoke templates natively without shell parsing.

---

## Templates

### [mct/](mct/) — claude-mercato market profiles

Scaffolds profiles, agents, and skills for the [mct](https://github.com/JLugagne/claude-mercato) market format.

Commands:
- `add_profile` — create a new profile (category/subcategory) with README
- `add_agent` — add an agent definition to an existing profile
- `add_skill` — add a skill definition with its supporting files

Used in production at [JLugagne/claude-skills](https://github.com/JLugagne/claude-skills).

---

## Versioning

Templates are versioned independently via git tags following the pattern `<template>/v<major>.<minor>.<patch>`.

Breaking changes in a template are documented in its `CHANGELOG.md` (when present). To pin a specific version, clone at a specific tag:

```bash
git clone --branch mct/v1.0.0 https://github.com/JLugagne/scaffor-templates ~/work/scaffor-templates-mct-v1
```

---

## Inclusion policy

Templates are added here when **all** of the following are true:

- I use the template personally in at least one active project
- The template generates artifacts I create often enough to justify automation
- The conventions it enforces are stable enough that a deterministic template is worth more than ad-hoc generation

Templates are removed if I stop using them. This keeps the repo honest about what is actively maintained.

If you want templates for technologies I do not use, fork this repo and build your own. The `scaffor` tool is fully language-agnostic and its manifest format is documented at [github.com/JLugagne/scaffor](https://github.com/JLugagne/scaffor).

---

## Contributing

This is a personal repo maintained for my own usage. PRs are welcome but may not be merged if they add templates I will not use myself. Feel free to fork for your own purposes.

For scaffor itself (the tool), contributions and issues go to [JLugagne/scaffor](https://github.com/JLugagne/scaffor).

---

## License

MIT
