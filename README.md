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
| Extensions | Elementor, Elementor Pro*, Yoast SEO, Header Footer Code Manager, Polylang, Connect Polylang for Elementor, Classic Editor, Disable Comments, WPvivid Backup, Novamira** — versions dans `config/plugins.json` |
| Réglages | permaliens `/%postname%/`, commentaires fermés, non indexé (`blog_public = 0`), contenu d'exemple supprimé, Elementor sans couleurs/polices par défaut, upload SVG — détail dans `config/settings.json`. Mises à jour automatiques du cœur coupées sur le starter seulement (§3) |
| Compte | `repotzadmin`, mot de passe généré et affiché une seule fois. Barre d'outils masquée sur le site (« Show Toolbar when viewing site » décoché) pour les comptes existants à l'installation |
| Contenu | aucun (pages, menus et langues Polylang se font par site) |

\* Payant, licence requise ; zip téléchargé depuis le compte Elementor.
\*\* Gratuit, mais distribué uniquement sur le site officiel [novamira.ai](https://novamira.ai/) (pas sur WordPress.org).
Les deux sont des zips à déposer dans `premium/` — voir `premium/README.md` et §3 « Extensions hors WordPress.org ».

## Prérequis

- macOS, LocalWP installé, Git.
- [Claude Code](https://claude.com/claude-code) pour les procédures `/status`, `/update`, etc. (optionnel : les scripts fonctionnent seuls).
- Les zips Elementor Pro et Novamira, et leurs licences.

## 1. Installation initiale (une seule fois)

1. **Créer le site dans LocalWP** : *Create a new site* → *Custom* → nom `wp-starter`, environnement **Custom** : PHP 8.2.x, nginx, MySQL 8. Identifiants WordPress temporaires (ils seront remplacés). Ne pas cocher « Advanced → multisite ».
2. **Cloner ce dépôt à côté de `app/`, pas dedans** (`wp-starter/starter`, et non `wp-starter/app/starter`) :
   ```bash
   cd ~/Local\ Sites/wp-starter
   git clone https://github.com/hdouanla/wp-starter.git starter
   cd starter
   cp .env.example .env        # puis renseigner ADMIN_EMAIL
   ```
3. **Déposer les zips premium** dans `starter/premium/` tels que téléchargés : pas besoin de les renommer, les scripts lisent l'extension et sa version dans le zip. Ils sont ignorés par Git : garder une copie ailleurs, car supprimer `starter/` ou le site les efface. Sans zip, l'installation continue sans l'extension ; relancer `scripts/install.sh` après le dépôt.
4. **Ouvrir le shell du site** : dans LocalWP, site `wp-starter` → *Open site shell* (le Terminal s'ouvre dans `app/public` avec `wp` et `php` disponibles), puis :
   ```bash
   cd ~/Local\ Sites/wp-starter/starter
   scripts/install.sh
   ```
   Si des erreurs PHP s'affichent (Herd, Homebrew), voir « Dépannage ». Noter le mot de passe affiché. Avec Claude Code : `claude` puis `/install` fait la même chose avec un dry-run préalable.
5. **Dans wp-admin** : activer la licence Elementor Pro (Elementor → Licence). Novamira n'a pas de licence à activer en version gratuite. Vérifier Elementor → Réglages → Général.
6. **Vérifier** : `scripts/verify.sh`, toujours depuis le shell du site et la racine du dépôt. Résultat attendu : `Aucune erreur`. Si un zip est plus récent que le lock (« installé X, lock Y »), lancer `scripts/snapshot.sh`, puis commiter.
7. **Mettre à jour** : wp-admin peut déjà annoncer des mises à jour, car l'installation pose les versions du lock et d'autres sont sorties depuis. C'est normal : suivre le §3, pas le bouton de wp-admin.
8. **Figer** : LocalWP → site `wp-starter` → menu ⋯ → *Save as Blueprint* → nom `wp-starter 2026.11`, soit la dernière version du `CHANGELOG.md` (voir §4 pour la convention).

## 2. Créer un site client

1. LocalWP → *Create a new site* → *Create from a Blueprint* → choisir le blueprint `wp-starter` → nom du site. LocalWP copie les fichiers et la base et remplace l'URL.
2. *Open site shell* du **nouveau** site, puis :
   ```bash
   bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --name "Nom du client" --email contact@client.com
   ```
   Nouveau mot de passe admin, nom du site, courriel, caches purgés, sessions héritées invalidées, mises à jour automatiques du cœur rétablies. Le script refuse de s'exécuter sur le starter lui-même.
3. Suite habituelle : langues Polylang, JSON-LD (`config/snippets/hfcm-jsonld-organisation.html` complété puis collé dans HFCM), intégration des maquettes via Novamira. `blog_public` reste à 0 jusqu'à la mise en ligne.

## 3. Maintenance (mensuelle ou avant un nouveau projet)

Cette section s'adresse à la personne qui maintient le starter (droit d'écriture sur le dépôt). Pour simplement créer un site client, le §2 suffit.

**Toujours mettre à jour par `scripts/update.sh` ou `/update`, jamais par le bouton de wp-admin.** Le script sauvegarde la base, vérifie le site et écrit les nouvelles versions dans le lock, ce qui permet au dépôt, au blueprint et au site de rester alignés. Si une mise à jour a été faite dans wp-admin : `scripts/snapshot.sh`, ligne dans `CHANGELOG.md`, commit.

Sur le starter, les mises à jour automatiques du cœur sont coupées (`WP_AUTO_UPDATE_CORE` dans `wp-config.php`) pour que sa version ne change pas sans passer par le lock. Il faut donc faire ce cycle régulièrement. `new-site.sh` retire cette constante : les sites clients gardent leurs mises à jour automatiques.

Avec Claude Code, depuis `starter/` (via *Open site shell* du site `wp-starter`, puis `cd ~/Local\ Sites/wp-starter/starter && claude`) :

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

Puis, dans LocalWP : *Save as Blueprint* sur `wp-starter`, et suppression de l'ancien blueprint (menu principal → *Blueprints*). Les sites déjà créés ne changent pas : le blueprint ne sert qu'aux prochains.

Sur un autre poste ou une autre copie du dépôt : `git pull` pour récupérer le lock à jour.

### Extensions hors WordPress.org (Elementor Pro, Novamira)

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

### Ajouter / retirer une extension

`/add-plugin <slug>` (ou `<chemin.zip>`), ou à la main : `wp plugin install … --activate`, entrée dans `config/plugins.json`, ligne dans `CHANGELOG.md`, `scripts/verify.sh`, commit, blueprint.

### Modifier un réglage

Éditer `config/settings.json`, appliquer avec `wp eval-file scripts/php/apply-settings.php config/settings.json`, ligne dans `CHANGELOG.md`, commit, blueprint.

### Mettre à niveau les skills WordPress de Claude Code

```bash
scripts/setup-skills.sh     # remplace .claude/skills/ par la version trunk de WordPress/agent-skills
```

## 4. Versions et blueprints

- Tag Git `vAAAA.MM` (ex. `v2026.11`), `.2`, `.3` si plusieurs versions dans le mois. Créé par `/release`.
- Blueprint LocalWP nommé pareil : `wp-starter 2026.11`. Un seul blueprint conservé à la fois ; les fichiers vivent dans `~/Library/Application Support/Local/blueprints/` et peuvent être sauvegardés ailleurs si besoin.
- `CHANGELOG.md` relie les deux : chaque version liste les changements de versions d'extensions, les ajouts/retraits et les réglages.

## 5. Scripts

| Script | Rôle |
|--------|------|
| `scripts/install.sh [--dry-run] [--skip-admin]` | Installation complète et idempotente sur un site vierge. |
| `scripts/check-updates.sh [--json]` | Interroge WordPress.org et les updaters tiers ; compare au lock. Ne modifie rien. |
| `scripts/update.sh [--plugin s] [--core] [--theme]` | Sauvegarde SQL → mises à jour → `verify.sh` → lock → CHANGELOG. |
| `scripts/verify.sh [--quick]` | Contrôles : extensions, thème, réglages, checksums du cœur, écart du cœur avec le lock, mises à jour automatiques coupées, HTTP 200 sans erreur fatale. Code 1 si erreur. |
| `scripts/snapshot.sh` | Réaligne le lock sur ce qui est installé (après une action manuelle dans wp-admin). |
| `scripts/new-site.sh --name … [--email] [--locale] [--path]` | Personnalise un site créé depuis le blueprint. |
| `scripts/setup-skills.sh [--ref trunk]` | Met à niveau `.claude/skills/`. |
| `scripts/php/*.php` | Logique exécutée dans WordPress via `wp eval-file` (réglages, vérification des mises à jour, snapshot). |

Tous les scripts localisent le WordPress automatiquement : `../app/public` par rapport au dépôt, ou `WP_PATH` dans `.env`, ou le répertoire courant pour `new-site.sh`.

## Dépannage

- **« Commande requise introuvable : wp »** → lancer depuis *Open site shell* de LocalWP, pas depuis un Terminal ordinaire.
- **`Failed loading … opcache.so`, `Xdebug requires Zend Engine API`, `Module "imagick" is already loaded`** → un autre PHP (Herd, Homebrew…) passe devant celui de LocalWP, parce que le `~/.zshrc` modifie le `PATH` à l'ouverture du shell. Les scripts du dépôt redonnent eux-mêmes la priorité au PHP de LocalWP ; pour une commande `wp` lancée à la main, il faut le faire dans le shell :
  ```bash
  export PATH="$HOME/Library/Application Support/Local/lightning-services/php-8.2.29+0/bin/darwin-arm64/bin:$PATH"
  php -v    # doit afficher la version de PHP du site
  ```
  Adapter `php-8.2.29+0` à la version du site. Ne pas retirer Herd du `~/.zshrc` si d'autres projets l'utilisent.
- **« PHP affiche des messages parasites »** → le PHP trouvé n'est pas celui de LocalWP : relancer depuis *Open site shell*.
- **« WordPress introuvable »** → le dépôt n'est pas dans `~/Local Sites/wp-starter/starter/`. S'il a été cloné dans `app/` : `cd ~/Local\ Sites/wp-starter && mv app/starter starter && cd starter`. Pour un autre emplacement voulu, définir `WP_PATH` dans `.env`.
- **`verify.sh` : HTTP injoignable** → démarrer le site dans LocalWP (bouton *Start site*).
- **Avertissement « mises à jour automatiques du cœur actives »** → `wp config set WP_AUTO_UPDATE_CORE false --raw` sur le starter. Ne pas le faire sur un site client.
- **Mise à jour ratée** → `update.sh` a exporté la base dans `reports/db-before-update-*.sql` : `wp db import <fichier>`, puis `scripts/install.sh` réinstalle les versions du lock.
- **Elementor Pro « vérifier chez le fournisseur »** dans `check-updates.sh` → licence non activée sur le starter : l'activer dans wp-admin (Elementor → Licence), ou gérer par zip.
- **Novamira « vérifier chez le fournisseur »** → normal si son updater ne signale rien : l'extension n'est pas sur WordPress.org. Télécharger la nouvelle version sur novamira.ai et passer par `premium/` (§3).
