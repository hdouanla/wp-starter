---
description: Ajoute une extension au starter (config/plugins.json + installation + lock + CHANGELOG)
argument-hint: <slug-wordpress.org | chemin/vers/zip> [--no-activate]
---

Ajoute une extension au starter. Argument : `$ARGUMENTS`.

1. Détermine la source :
   - un slug → extension WordPress.org (`source: wporg`). Confirme que le slug existe : `wp plugin search <slug> --per-page=5 --fields=name,slug,version`.
   - un chemin `.zip` → extension premium/hors dépôt (`source: zip`). Le zip doit être déposé dans `premium/` (ne le déplace pas toi-même si c'est hors du dépôt : demande).
2. Installe : `wp plugin install <slug|zip>` puis `wp plugin activate <slug>` sauf `--no-activate`. Relève la version installée.
3. Ajoute l'entrée dans `config/plugins.json` en respectant le format des entrées existantes (slug, name, version, source, update_check, activate ; `zip_glob` et `vendor_url` pour un zip). Place-la à une position logique (dépendances avant dépendants ; renseigne `requires` si pertinent).
4. Lance `scripts/verify.sh --quick`.
5. Ajoute une ligne « Ajout : <Nom> <version> » sous la date du jour dans `CHANGELOG.md` (crée la section du jour si elle n'existe pas, juste sous l'en-tête).
6. Propose le commit `feat(plugins): ajoute <slug> <version>` et rappelle de régénérer le blueprint.

Pour retirer une extension : même logique à l'envers (`wp plugin deactivate` + `wp plugin delete`, retrait de l'entrée, CHANGELOG « Retrait : … »).
