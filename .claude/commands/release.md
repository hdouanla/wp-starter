---
description: Clôture une version du starter — vérification finale, tag Git et checklist de régénération du blueprint
argument-hint: [version, ex. 2026.10]
---

Clôture d'une version du starter. Version demandée : `$ARGUMENTS` (par défaut : `AAAA.MM` du jour ; suffixe `.2`, `.3` si une version existe déjà ce mois-ci — vérifier avec `git tag`).

1. `git status` doit être propre (tout commité). Sinon, arrête-toi et liste ce qui traîne.
2. Lance `scripts/verify.sh` (complet). Aucune erreur tolérée ; les avertissements sont listés dans le résumé.
3. Lance `scripts/check-updates.sh` : si une mise à jour est encore disponible, demande s'il faut la prendre avant de clôturer (`/update`) ou clôturer quand même.
4. Skills : si `check-updates.sh` signale une version plus récente de `agent-skills`, lance `scripts/setup-skills.sh`, puis relis le diff de `.claude/skills/` : ce sont des instructions que Claude suivra sur les sites. Résume ce qui change et signale tout ce qui semble suspect (commandes destructives, téléchargements, envoi de données). Avec l'accord de l'utilisateur, ajoute une ligne au `CHANGELOG.md` et commite `chore(skills): agent-skills@<commit>` ; sinon, annule avec `git restore --source=HEAD --staged --worktree -- .claude/skills` puis `git clean -fd -- .claude/skills` et `scripts/setup-skills.sh --local` (remet `app/public/.claude/skills` au niveau du dépôt).
5. Dans `CHANGELOG.md`, renomme la section « ## <date> » du jour en « ## <version> — <date> » si ce n'est pas déjà fait, ou crée-la avec une ligne « Version figée, aucun changement de version » le cas échéant.
6. Commit `chore(release): <version>` puis `git tag -a v<version> -m "wp-starter <version>"`. Ne pousse pas : indique les commandes `git push && git push --tags`.
7. Affiche la checklist LocalWP, à faire à la main :
   - Ouvrir LocalWP → site **wp-starter** → s'assurer qu'il est démarré et que wp-admin s'ouvre.
   - Menu du site (⋯ ou clic droit) → **Save as Blueprint** → nom : `wp-starter <version>`.
   - Dans **Blueprints** (menu principal), supprimer le blueprint précédent pour n'en garder qu'un.
   - Optionnel : créer un site de test depuis le nouveau blueprint et lancer `scripts/new-site.sh --name "Test"` pour valider, puis supprimer le site de test.
