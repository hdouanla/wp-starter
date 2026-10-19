# wp-starter

Package de démarrage WordPress de **RepOtz** pour [LocalWP](https://localwp.com) (macOS).

Un site LocalWP `wp-starter` sert de modèle vivant ; ce dépôt le décrit et le pilote (extensions épinglées, réglages, scripts, procédures Claude Code) ; LocalWP le fige en **blueprint** à partir duquel chaque site client est créé en un clic.

```
                 scripts/install.sh                Save as Blueprint              New site from blueprint
Site LocalWP vierge ───────────────▶ site wp-starter ──────────────────▶ blueprint ──────────────────────▶ site client
                                        ▲      │                                                              │
                      /update (Claude)  │      │ scripts/update.sh                            scripts/new-site.sh
                      WordPress.org ────┘      ▼
                                        config/*.json + CHANGELOG (Git)
```

## Contenu du starter

| Composant | Détail |
|-----------|--------|
| WordPress | version épinglée dans `config/stack.json`, langue `fr_CA`, fuseau `America/Toronto` |
| Thème | Hello Elementor (+ Twenty Twenty-Five conservé comme filet de sécurité) |
| Extensions | Elementor, Elementor Pro*, Yoast SEO, Header Footer Code Manager, Polylang, Connect Polylang for Elementor, Classic Editor, Disable Comments, WPvivid Backup, Novamira* — versions dans `config/plugins.json` |
| Réglages | permaliens `/%postname%/`, commentaires fermés, non indexé (`blog_public = 0`), contenu d'exemple supprimé, Elementor sans couleurs/polices par défaut, upload SVG — détail dans `config/settings.json` |
| Compte | `repotzadmin`, mot de passe généré et affiché une seule fois |
| Contenu | aucun (pages, menus et langues Polylang se font par site) |

\* zip à déposer dans `premium/` (voir `premium/README.md`).

## Prérequis

- macOS, LocalWP installé, Git.
- [Claude Code](https://claude.com/claude-code) pour les procédures `/status`, `/update`, etc. (optionnel : les scripts fonctionnent seuls).
- Les zips Elementor Pro et Novamira, et leurs licences.

## 1. Installation initiale (une seule fois)

1. **Créer le site dans LocalWP** : *Create a new site* → *Custom* → nom `wp-starter`, environnement **Custom** : PHP 8.2.x, nginx, MySQL 8. Identifiants WordPress temporaires (ils seront remplacés). Ne pas cocher « Advanced → multisite ».
2. **Cloner ce dépôt à côté de `app/`** :
   ```bash
   cd ~/Local\ Sites/wp-starter
   git clone https://github.com/repotz/wp-starter starter
   cd starter
   cp .env.example .env        # puis renseigner ADMIN_EMAIL
   ```
3. **Déposer les zips premium** dans `starter/premium/` (`elementor-pro-<version>.zip`, `novamira-<version>.zip`).
4. **Ouvrir le shell du site** : dans LocalWP, site `wp-starter` → *Open site shell* (le Terminal s'ouvre dans `app/public` avec `wp` et `php` disponibles), puis :
   ```bash
   cd ../../starter
   scripts/install.sh
   ```
   Noter le mot de passe affiché. Avec Claude Code : `claude` puis `/install` fait la même chose avec un dry-run préalable.
5. **Dans wp-admin** : activer les licences (Elementor → Licence ; Novamira → réglages). Vérifier Elementor → Réglages → Général.
6. **Vérifier** : `scripts/verify.sh`.
7. **Figer** : LocalWP → site `wp-starter` → menu ⋯ → *Save as Blueprint* → nom `wp-starter 2026.10` (voir §4 pour la convention).

## 2. Créer un site client

1. LocalWP → *Create a new site* → *Create from a Blueprint* → choisir le blueprint `wp-starter` → nom du site. LocalWP copie les fichiers et la base et remplace l'URL.
2. *Open site shell* du **nouveau** site, puis :
   ```bash
   bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --name "Nom du client" --email contact@client.com
   ```
   Nouveau mot de passe admin, nom du site, courriel, caches purgés, sessions héritées invalidées. Le script refuse de s'exécuter sur le starter lui-même.
3. Suite habituelle : langues Polylang, JSON-LD (`config/snippets/hfcm-jsonld-organisation.html` complété puis collé dans HFCM), intégration des maquettes via Novamira. `blog_public` reste à 0 jusqu'à la mise en ligne.

## 3. Maintenance (mensuelle ou avant un nouveau projet)

Avec Claude Code, depuis `starter/` (via *Open site shell* du site `wp-starter`, puis `cd ../../starter && claude`) :

```
/status     → ce qui est disponible sur WordPress.org, sans rien toucher
/update     → sauvegarde SQL, mises à jour, verify.sh, lock + CHANGELOG, proposition de commit
/release    → vérification finale, tag Git, checklist « Save as Blueprint »
```

Sans Claude Code, les mêmes étapes :

```bash
scripts/check-updates.sh          # tableau lock / installé / disponible
scripts/update.sh                 # ou --plugin elementor, --core, --theme
git add -A && git commit -m "chore(update): …" && git push
```

Puis, dans LocalWP : *Save as Blueprint* sur `wp-starter`, et suppression de l'ancien blueprint (menu principal → *Blueprints*).

### Extensions premium

`update.sh` les met à jour de deux façons : un zip plus récent déposé dans `premium/` (installé par-dessus), ou l'updater du fournisseur quand la licence est active sur le starter (comme une extension WordPress.org). Sinon, `check-updates.sh` affiche « vérifier chez le fournisseur » avec l'URL — télécharger le zip, le déposer, relancer `update.sh --plugin <slug>`.

### Ajouter / retirer une extension

`/add-plugin <slug>` (ou `<chemin.zip>`), ou à la main : `wp plugin install … --activate`, entrée dans `config/plugins.json`, ligne dans `CHANGELOG.md`, `scripts/verify.sh`, commit, blueprint.

### Modifier un réglage

Éditer `config/settings.json`, appliquer avec `wp eval-file scripts/php/apply-settings.php config/settings.json`, ligne dans `CHANGELOG.md`, commit, blueprint.

### Mettre à niveau les skills WordPress de Claude Code

```bash
scripts/setup-skills.sh     # remplace .claude/skills/ par la version trunk de WordPress/agent-skills
```

## 4. Versions et blueprints

- Tag Git `vAAAA.MM` (ex. `v2026.10`), `.2`, `.3` si plusieurs versions dans le mois. Créé par `/release`.
- Blueprint LocalWP nommé pareil : `wp-starter 2026.10`. Un seul blueprint conservé à la fois ; les fichiers vivent dans `~/Library/Application Support/Local/blueprints/` et peuvent être sauvegardés ailleurs si besoin.
- `CHANGELOG.md` relie les deux : chaque version liste les changements de versions d'extensions, les ajouts/retraits et les réglages.

## 5. Scripts

| Script | Rôle |
|--------|------|
| `scripts/install.sh [--dry-run] [--skip-admin]` | Installation complète et idempotente sur un site vierge. |
| `scripts/check-updates.sh [--json]` | Interroge WordPress.org et les updaters tiers ; compare au lock. Ne modifie rien. |
| `scripts/update.sh [--plugin s] [--core] [--theme]` | Sauvegarde SQL → mises à jour → `verify.sh` → lock → CHANGELOG. |
| `scripts/verify.sh [--quick]` | Contrôles : extensions, thème, réglages, checksums du cœur, HTTP 200 sans erreur fatale. Code 1 si erreur. |
| `scripts/snapshot.sh` | Réaligne le lock sur ce qui est installé (après une action manuelle dans wp-admin). |
| `scripts/new-site.sh --name … [--email] [--locale] [--path]` | Personnalise un site créé depuis le blueprint. |
| `scripts/setup-skills.sh [--ref trunk]` | Met à niveau `.claude/skills/`. |
| `scripts/php/*.php` | Logique exécutée dans WordPress via `wp eval-file` (réglages, vérification des mises à jour, snapshot). |

Tous les scripts localisent le WordPress automatiquement : `../app/public` par rapport au dépôt, ou `WP_PATH` dans `.env`, ou le répertoire courant pour `new-site.sh`.

## Dépannage

- **« Commande requise introuvable : wp »** → lancer depuis *Open site shell* de LocalWP, pas depuis un Terminal ordinaire.
- **« WordPress introuvable »** → le dépôt n'est pas dans `~/Local Sites/wp-starter/starter/` : définir `WP_PATH` dans `.env`.
- **`verify.sh` : HTTP injoignable** → démarrer le site dans LocalWP (bouton *Start site*).
- **Mise à jour ratée** → `update.sh` a exporté la base dans `reports/db-before-update-*.sql` : `wp db import <fichier>`, puis `scripts/install.sh` réinstalle les versions du lock.
- **Elementor Pro / Novamira « inconnu »** dans `check-updates.sh` → licence non active sur le starter : l'activer dans wp-admin, ou gérer par zip.
