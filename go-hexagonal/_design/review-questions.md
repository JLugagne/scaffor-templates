# Template go-hexagonal — Questionnaire de review

Coche tes reponses, je les lirai au prochain tour.

---

## Q1. Syntaxe `in:` en liste YAML pour le composant `composition`

Le composant `composition` doit matcher `init.go` ET `wire_*.go`.
La review propose une liste YAML (`in: [pattern1, pattern2]`).

- [ ] A. Liste YAML confirmee — go-arch-lint v3 supporte `in:` avec une liste, j'ai teste
- [ ] B. Pas sur — utilise le fallback deux composants separes (`composition_init` + `composition_wire`)
- [x] C. Teste les deux dans le script de validation, garde celle qui marche

---

## Q2. `excludeFiles` pour les `*_test.go`

Les tests importent des mocks et fixtures qui peuvent violer les regles arch.
La review suggere d'essayer sans d'abord.

- [ ] A. Pas de `excludeFiles` — on lint aussi les tests, on corrige si ca casse
- [x] B. Ajouter `excludeFiles: ["^.*_test\\.go$"]` d'entree de jeu
- [ ] C. Ajouter un composant `tests` separe avec des permissions larges

---

## Q3. Resolution des deps : fichier ou package ?

`cmd/main.go` importe le package `internal/{context}` qui contient `init.go` + `wire_*.go` (composant `composition`).
Si go-arch-lint resout au niveau package, ca matche `composition` et `cmd -> composition` suffit.
Si c'est au niveau fichier, le lien est ambigu.

- [ ] A. C'est au niveau fichier — go-arch-lint associe chaque `.go` a un composant independamment
- [x] B. C'est au niveau package — tous les fichiers d'un meme package Go sont dans le meme composant
- [ ] C. Je ne sais pas — il faut tester empiriquement avec le script

---

## Q4. `inbound` doit-il dependre de `app` ?

Les templates actuels ont `commands/init.go` et `queries/init.go` qui importent `app` pour le DI
(`Service` struct prend `*app.App`). Ma passe precedente avait ajoute `app` a `inbound.canUse`.
La review propose `inbound: canUse: [domain, public_pkg]` sans `app`.

- [ ] A. Oubli dans la review — garder `app` dans `inbound.canUse`
- [ ] B. Changement intentionnel — restructurer les templates pour que `inbound` ne depende plus de `app` (passer par les interfaces usecase uniquement)
- [x] C. Autre approche (preciser) : il ne faut PAS que inbound import app, inbound n'a accés que à domain et /pkg/<context> ! aucun layer n'a accés à app il faut garder de decoupling au maximum sinon l'architecture ne sert plus à rien

---

## Q5. `outbound` doit-il dependre de `public_pkg` ?

Les publisher adapters importent `pkg/{context}/events/v1/` pour serialiser les events.
Ma passe precedente avait ajoute `public_pkg` a `outbound.canUse`.
La review propose `outbound: canUse: [domain]` sans `public_pkg`.

- [ ] A. Oubli dans la review — garder `public_pkg` dans `outbound.canUse`
- [ ] B. Changement intentionnel — les publishers ne doivent pas importer `pkg/`, restructurer le serialization path
- [x] C. Autre approche (preciser) : uniquement les publishers peuvent avoir accés à /pkg/<context>/events 

---

## Q6. Script de test automatise

La review propose un `scripts/test-template-archlint.sh` qui bootstrap + add_entity x2 + go-arch-lint check.

- [x] A. Oui, creer le script dans le repo et le lancer manuellement
- [ ] B. Oui, creer le script ET l'ajouter en CI GitHub Actions
- [ ] C. Pas maintenant — valider manuellement d'abord, script plus tard

---

## Q7. `workdir: .` vs `workdir: internal`

La review propose de passer de `workdir: internal` a `workdir: .` pour couvrir `cmd/` et `pkg/`.

- [x] A. Passer a `workdir: .` — la couverture de `cmd/` et `pkg/` vaut le changement
- [ ] B. Rester a `workdir: internal` — ca marchait, le gain ne justifie pas le risque
- [ ] C. Passer a `workdir: .` seulement si le script de test passe du premier coup

---

## Notes libres

(Ecris ici tout ce qui ne rentre pas dans les QCM)

```
___________________________________________________________________________

___________________________________________________________________________

___________________________________________________________________________
```
