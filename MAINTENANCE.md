# Maintenance de wp-starter

La maintenance du starter est assurée par l'éditeur (RepOtz) et son équipe, c'est-à-dire les personnes qui ont le droit d'écriture sur le dépôt. Ce document est public : tout le monde peut le lire et proposer des changements par PR (voir « Proposer un changement »). Pour simplement installer le starter ou créer un site client, voir le `README.md`.

Le rôle de l'équipe : garder le site `wp-starter` à jour, faire suivre le lock (`config/*.json`) et le `CHANGELOG.md`, examiner les PR, puis figer une version que les utilisateurs récupèrent.

## Proposer un changement

1. Forker le dépôt et créer une branche.
2. Faire le changement sur votre propre site `wp-starter`, avec les procédures ci-dessous : `scripts/update.sh` ou `/update` pour une mise à jour, jamais une édition à la main des versions dans `config/*.json`.
3. Lancer `scripts/verify.sh` : il doit afficher `Aucune erreur`.
4. Ouvrir une PR, avec un commit par intention en Conventional Commits en français (`chore(update): …`, `fix(settings): …`, `docs: …`) et une ligne dans le `CHANGELOG.md`.

Ne jamais inclure de zip premium, de `.env`, de mot de passe ni de contenu propre à un client. La fusion, le tag de version et le blueprint restent à la charge de l'équipe.

```
WordPress.org ──▶ /update ou scripts/update.sh ──▶ site wp-starter ──▶ Save as Blueprint
                                  │
                                  ▼
                     config/*.json + CHANGELOG (Git)
```

## Mettre à jour (mensuel ou avant un nouveau projet)

**Toujours mettre à jour par `scripts/update.sh` ou `/update`, jamais par le bouton de wp-admin.** Le script sauvegarde la base, vérifie le site et écrit les nouvelles versions dans le lock, ce qui permet au dépôt, au blueprint et au site de rester alignés.

Sur le starter, les mises à jour automatiques du cœur sont coupées (`WP_AUTO_UPDATE_CORE` dans `wp-config.php`) pour que sa version ne change pas sans passer par le lock. Il faut donc faire ce cycle régulièrement. `new-site.sh` retire cette constante : les sites clients gardent leurs mises à jour automatiques.

Avec Claude Code, depuis `starter/` (via *Open site shell* du site `wp-starter`, puis `cd ~/Local\ Sites/wp-starter/starter && claude`) :

```
/status     → ce qui est disponible sur WordPress.org, sans rien toucher
/update     → sauvegarde SQL, mises à jour, verify.sh, lock + CHANGELOG, proposition de commit
/release    → vérification finale, tag Git, checklist « Save as Blueprint »
```

Sans Claude Code, les mêmes étapes (le `git push` ne concerne que l'équipe ; sinon, ouvrir une PR) :

```bash
scripts/check-updates.sh          # tableau lock / installé / disponible
scripts/update.sh                 # ou --plugin elementor, --core, --theme
git add -A && git commit -m "chore(update): …" && git push
```

Puis, dans LocalWP : *Save as Blueprint* sur `wp-starter`, et suppression de l'ancien blueprint (menu principal → *Blueprints*). Les sites déjà créés ne changent pas : le blueprint ne sert qu'aux prochains.

Sur un autre poste ou une autre copie du dépôt : `git pull` pour récupérer le lock à jour.

### Écart « installé X, lock Y » sans mise à jour disponible

C'est le signe qu'une mise à jour a été faite hors de `update.sh`, par exemple dans wp-admin. `/update` n'a alors rien à appliquer et s'arrête. Pour réaligner le lock :

```bash
scripts/snapshot.sh               # écrit les versions installées dans config/*.json
scripts/verify.sh                 # contrôle complet
```

Ajouter ensuite la ligne au `CHANGELOG.md` (`snapshot.sh` ne l'écrit pas), commiter, puis *Save as Blueprint*.

## Extensions hors WordPress.org (Elementor Pro, Novamira)

Deux extensions ne viennent pas du dépôt WordPress.org et sont déclarées `source: zip` dans `config/plugins.json`. Le dossier `premium/` les accueille toutes les deux, même si une seule est payante.

| | Elementor Pro | Novamira |
|---|---|---|
| Nature | Payant, licence par site | Gratuit (volet Pro optionnel) |
| Où télécharger | [my.elementor.com](https://my.elementor.com/subscriptions/) | [novamira.ai](https://novamira.ai/) uniquement |
| Dans `premium/` | Le zip téléchargé, nom libre | Le zip téléchargé, nom libre |
| `update_check` | `license` | `manual` |
| Mise à jour automatique | Oui, si la licence est activée sur le starter : `update.sh` passe par l'updater Elementor comme pour une extension WordPress.org | Seulement si l'extension embarque son propre updater et le signale à WordPress ; sinon non |
| Mise à jour par zip | Déposer le nouveau zip → `update.sh --plugin elementor-pro` | Déposer le nouveau zip → `update.sh --plugin novamira` |
| Ce qu'affiche `check-updates.sh` sans licence / sans updater | « vérifier chez le fournisseur » + URL | « vérifier chez le fournisseur » + URL |

Logique de `update.sh` pour ces deux-là : s'il trouve dans `premium/` un zip dont la version (lue dans le zip) est plus élevée que la version installée, il l'installe par-dessus (`wp plugin install --force`) ; sinon il tente `wp plugin update <slug>`, qui ne fait quelque chose que si un updater a signalé une nouvelle version. Dans tous les cas, l'absence de mise à jour pour ces extensions ne bloque pas les autres.

Cycle manuel type pour Novamira : `/status` l'affiche « vérifier chez le fournisseur » → aller sur novamira.ai, télécharger la dernière version → déposer le zip dans `premium/` (supprimer l'ancien zip) → `scripts/update.sh --plugin novamira` ou `/update novamira` → le lock et le CHANGELOG sont mis à jour → commit → *Save as Blueprint*.

## Ajouter ou retirer une extension

`/add-plugin <slug>` (ou `<chemin.zip>`), ou à la main : `wp plugin install … --activate`, entrée dans `config/plugins.json`, ligne dans `CHANGELOG.md`, `scripts/verify.sh`, commit, blueprint.

## Modifier un réglage

Éditer `config/settings.json`, appliquer avec `wp eval-file scripts/php/apply-settings.php config/settings.json`, ligne dans `CHANGELOG.md`, commit, blueprint.

## Mettre à niveau les skills WordPress de Claude Code

```bash
scripts/setup-skills.sh          # remplace .claude/skills/ par la version trunk de WordPress/agent-skills
scripts/setup-skills.sh --local  # sans téléchargement : recopie seulement dans app/public/.claude/skills
```

Les skills sont versionnés dans ce dépôt, et `install.sh` comme `setup-skills.sh` les recopient dans `app/public/.claude/skills/` du starter : le blueprint les embarque là où Claude Code les charge, et un site créé depuis le blueprint les a dès sa création. `verify.sh` signale une copie absente ou différente du dépôt. `check-updates.sh` signale quand `trunk` a avancé ; la mise à niveau se fait à `/release`, après relecture du diff.

## Versions et blueprints

- Tag Git `vAAAA.MM` (ex. `v2026.11`), `.2`, `.3` si plusieurs versions dans le mois. Créé par `/release`.
- Blueprint LocalWP nommé pareil : `wp-starter 2026.11`. Un seul blueprint conservé à la fois ; les fichiers vivent dans `~/Library/Application Support/Local/blueprints/` et peuvent être sauvegardés ailleurs si besoin.
- `CHANGELOG.md` relie les deux : chaque version liste les changements de versions d'extensions, les ajouts/retraits et les réglages.

## Scripts de maintenance

| Script | Rôle |
|--------|------|
| `scripts/check-updates.sh [--json]` | Interroge WordPress.org et les updaters tiers ; compare au lock. Ne modifie rien. |
| `scripts/update.sh [--plugin s] [--core] [--theme]` | Sauvegarde SQL → mises à jour → `verify.sh` → lock → CHANGELOG. |
| `scripts/snapshot.sh` | Réaligne le lock sur ce qui est installé (après une action manuelle dans wp-admin). |
| `scripts/setup-skills.sh [--ref trunk] [--local]` | Met à niveau `.claude/skills/` et le recopie dans `app/public/.claude/skills/`. `--local` : recopie seulement. |
| `scripts/php/*.php` | Logique exécutée dans WordPress via `wp eval-file` (réglages, vérification des mises à jour, snapshot). |

`install.sh`, `verify.sh` et `new-site.sh` sont décrits dans le `README.md`.

## Dépannage

- **Mise à jour ratée** → `update.sh` a exporté la base dans `reports/db-before-update-*.sql` : `wp db import <fichier>`, puis `scripts/install.sh` réinstalle les versions du lock.
- **Elementor Pro « vérifier chez le fournisseur »** dans `check-updates.sh` → licence non activée sur le starter : l'activer dans wp-admin (Elementor → Licence), ou gérer par zip.
- **Novamira « vérifier chez le fournisseur »** → normal si son updater ne signale rien : l'extension n'est pas sur WordPress.org. Télécharger la nouvelle version sur novamira.ai et passer par `premium/`.

Pour les problèmes de shell, de PHP ou de chemin, voir « Dépannage » dans le `README.md`.
