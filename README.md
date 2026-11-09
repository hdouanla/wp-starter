# wp-starter

Package de démarrage WordPress de **RepOtz** pour [LocalWP](https://localwp.com) (macOS).

Un site LocalWP `wp-starter` sert de modèle vivant ; ce dépôt le décrit (extensions épinglées, réglages, scripts, procédures Claude Code) ; LocalWP le fige en **blueprint** à partir duquel chaque site client est créé en un clic.

```
                 scripts/install.sh                Save as Blueprint              New site from blueprint
Site LocalWP vierge ───────────────▶ site wp-starter ──────────────────▶ blueprint ──────────────────────▶ site client
                                                                                                              │
                                                                                              scripts/new-site.sh
```

## Contenu du starter

| Composant | Détail |
|-----------|--------|
| WordPress | version épinglée dans `config/stack.json`, langue `fr_CA`, fuseau `America/Toronto` |
| Thème | Hello Elementor (+ Twenty Twenty-Five conservé comme filet de sécurité) |
| Extensions | Elementor, Elementor Pro*, Yoast SEO, Header Footer Code Manager, Polylang, Connect Polylang for Elementor, Classic Editor, Disable Comments, Site Offline, WPS Hide Login, WPvivid Backup, Novamira** — versions dans `config/plugins.json` |
| Réglages | permaliens `/%postname%/`, commentaires fermés, non indexé (`blog_public = 0`), contenu d'exemple supprimé, Elementor sans couleurs/polices par défaut, upload SVG — détail dans `config/settings.json`. Mises à jour automatiques du cœur coupées sur le starter seulement |
| Compte | `repotzadmin`, mot de passe généré et affiché une seule fois. Barre d'outils masquée sur le site (« Show Toolbar when viewing site » décoché) pour les comptes existants à l'installation |
| Contenu | aucun (pages, menus et langues Polylang se font par site) |

\* Payant, licence requise ; zip téléchargé depuis le compte Elementor : [my.elementor.com](https://my.elementor.com/subscriptions/).
\*\* Gratuit, mais distribué uniquement sur le site officiel [novamira.ai](https://novamira.ai/) (pas sur WordPress.org).
Les deux sont des zips à déposer dans `premium/`.

## Prérequis

- macOS, LocalWP installé, Git.
- [Claude Code](https://claude.com/claude-code) pour les procédures `/install`, `/verify` et `/new-site` (optionnel : les scripts fonctionnent seuls).
- Les zips Elementor Pro et Novamira, et la licence Elementor Pro.

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
6. **Vérifier** : `scripts/verify.sh`, toujours depuis le shell du site et la racine du dépôt. Résultat attendu : `Aucune erreur`. Un avertissement « installé X, lock Y » signale seulement une version différente de celle du lock, souvent parce qu'un zip ou WordPress est plus récent. Il ne bloque rien : voir « Mises à jour » avant de lancer les commandes qu'il suggère.
7. **Figer** : LocalWP → site `wp-starter` → menu ⋯ → *Save as Blueprint* → nom `wp-starter 2026.11.3`, soit la dernière version du `CHANGELOG.md`. Un seul blueprint à conserver à la fois.

## 2. Créer un site client

1. LocalWP → *Create a new site* → *Create from a Blueprint* → choisir le blueprint `wp-starter` → nom du site. LocalWP copie les fichiers et la base et remplace l'URL.
2. *Open site shell* du **nouveau** site, puis :
   ```bash
   bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --name "Nom du client" --email contact@client.com
   ```
   Nouveau mot de passe admin, nom du site, courriel, caches purgés, sessions héritées invalidées, mises à jour automatiques du cœur rétablies, `.env` et `.git` retirés de la copie `starter/` du site (skills et scripts conservés). Le script copie d'abord les skills dans `app/public/.claude/skills/` (Claude Code, lancé depuis `app/public`, ne les trouve pas plus haut hors d'un dépôt Git) et crée `<site>/CLAUDE.md` s'il n'existe pas ; cette étape passe avant les commandes WordPress, pour qu'une erreur WP-CLI ne l'empêche pas. Pour un site déjà créé sans ces outils : `bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --claude-only --path ~/Local\ Sites/<site>/app/public` (fichiers seulement, ne touche pas à WordPress). Le script refuse de s'exécuter sur le starter lui-même.
3. Suite habituelle : langues Polylang, JSON-LD (`config/snippets/hfcm-jsonld-organisation.html` complété puis collé dans HFCM), intégration des maquettes via Novamira. `blog_public` reste à 0 jusqu'à la mise en ligne.

## Mises à jour

Les mises à jour du starter sont assurées par RepOtz, qui vérifie les versions avant de les publier dans ce dépôt. **Ne pas mettre à jour le site `wp-starter` soi-même**, ni par le bouton de wp-admin, ni par `scripts/update.sh` ou `/update` : wp-admin peut annoncer des mises à jour, c'est normal. Les modifications locales font diverger votre copie du dépôt et peuvent bloquer le prochain `git pull`.

Pour passer à une nouvelle version du starter :

1. `git pull` dans `starter/`.
2. Reprendre le §1 sur un site LocalWP vierge, puis remplacer l'ancien blueprint. `install.sh` ne change pas les extensions déjà installées : relancé sur le même site, il ne les met pas à niveau.

Les sites déjà créés ne changent pas : le blueprint ne sert qu'aux prochains. Les sites clients ne sont pas concernés par cette règle : ils gardent leurs mises à jour automatiques du cœur.

## Contribuer

Une mise à jour ou une correction à proposer ? Les PR sont les bienvenues : voir « Proposer un changement » dans [`MAINTENANCE.md`](MAINTENANCE.md), qui décrit aussi le cycle de maintenance complet.

## Scripts

| Script | Rôle |
|--------|------|
| `scripts/install.sh [--dry-run] [--skip-admin]` | Installation complète et idempotente sur un site vierge. |
| `scripts/verify.sh [--quick]` | Contrôles : extensions, thème, réglages, checksums du cœur, écart du cœur avec le lock, mises à jour automatiques coupées, HTTP 200 sans erreur fatale. Code 1 si erreur. |
| `scripts/new-site.sh --name … [--email] [--locale] [--path]` | Personnalise un site créé depuis le blueprint. `--claude-only` : pose seulement les skills et le `CLAUDE.md` du site. |

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
