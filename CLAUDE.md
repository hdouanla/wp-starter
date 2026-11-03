# wp-starter — instructions pour Claude Code

Package de démarrage WordPress de RepOtz pour LocalWP. Ce dépôt **n'est pas** un site WordPress : c'est la source de vérité (configuration, scripts, procédures) qui pilote le site LocalWP `wp-starter`, lequel est ensuite figé en **blueprint** LocalWP pour créer les sites clients.

Langue de travail : français (registre québécois), termes techniques en anglais acceptés. Réponses courtes, orientées décision.

## Où tu es

```
~/Local Sites/wp-starter/
├── app/public/        ← le WordPress starter (géré par LocalWP ; jamais commité ici)
└── starter/           ← CE DÉPÔT (git clone https://github.com/hdouanla/wp-starter.git)
    ├── CLAUDE.md
    ├── config/        plugins.json (lock des extensions) · stack.json (cœur, thème, env) · settings.json (réglages) · snippets/
    ├── scripts/       install.sh · check-updates.sh · update.sh · verify.sh · snapshot.sh · new-site.sh · setup-skills.sh · php/
    ├── premium/       zips Elementor Pro, Novamira (ignorés par Git)
    ├── reports/       sauvegardes SQL et rapports (ignorés par Git)
    ├── .claude/       commands/ (procédures ci-dessous) · skills/ (WordPress/agent-skills) · settings.json (permissions)
    └── CHANGELOG.md
```

Les scripts localisent le WordPress automatiquement (`../app/public`, ou `WP_PATH` dans `.env`). Lance-les toujours depuis la racine du dépôt : `scripts/<nom>.sh`. Ils supposent le « Open site shell » de LocalWP (`wp` et `php` dans le PATH) et redonnent eux-mêmes la priorité au PHP de LocalWP si le `~/.zshrc` en remet un autre devant (Herd, Homebrew). Pour une commande `wp` lancée directement, vérifie d'abord `php -v` : voir « Dépannage » dans le README.

## Procédures (slash commands)

| Commande      | Quand                                                           |
|---------------|-----------------------------------------------------------------|
| `/status`     | Savoir où on en est. Ne modifie rien.                           |
| `/update`     | Mettre à jour depuis WordPress.org, vérifier, synchroniser le lock, journaliser. |
| `/verify`     | Diagnostiquer et proposer les corrections.                     |
| `/install`    | Première installation sur un site LocalWP vierge.              |
| `/add-plugin` | Ajouter (ou retirer) une extension du starter.                 |
| `/release`    | Figer une version : tag Git + checklist blueprint.             |
| `/new-site`   | Personnaliser un site client créé depuis le blueprint.         |

Hors de ces procédures, préfère les scripts aux commandes WP-CLI à la main : ils tiennent le lock et le CHANGELOG à jour.

## Règles

1. **Le lock fait foi.** `config/plugins.json` et `config/stack.json` décrivent ce qui est installé. Toute modification d'une version sur le site passe par `update.sh` (ou `snapshot.sh` après une action manuelle), jamais par une édition manuelle des JSON.
2. **Toujours vérifier après avoir modifié.** `scripts/verify.sh` après toute installation ou mise à jour. Une erreur bloque ; on ne commit pas un starter cassé.
3. **Jamais de secrets dans le dépôt.** Mots de passe générés : affichés une fois, jamais écrits dans un fichier. `.env` et `premium/*.zip` sont ignorés — ne les lis que si nécessaire, ne les modifie pas.
4. **Pas de contenu dans le starter.** Aucune page, aucun article, aucun menu : ils varient d'un site à l'autre. Le starter livre une base propre et des réglages.
5. **Extensions premium** (`source: zip`) : la mise à jour vient soit d'un zip plus récent déposé dans `premium/`, soit de l'updater du fournisseur si la licence est active. Si ni l'un ni l'autre, on le signale et on continue — ça ne bloque pas le reste.
6. **Commits** : Conventional Commits en français — `chore(update): …`, `feat(plugins): …`, `fix(settings): …`, `chore(release): …`, `docs: …`. Un commit par intention. Ne pousse pas sans qu'on te le demande.
7. **CHANGELOG** : une section par jour (`## AAAA-MM-JJ`), transformée en `## version — date` par `/release`. `update.sh` y écrit automatiquement ; complète à la main pour le reste (ajouts, retraits, réglages).
8. **Le blueprint se régénère à la main** dans LocalWP (« Save as Blueprint »). Rappelle-le à la fin de `/update` et de `/release`. Tu ne peux pas le faire toi-même.
9. **Destructif = interdit sans accord explicite** : `wp db reset`, suppression d'extensions non listées dans `remove_if_present`, `rm -rf`, `git push --force`.
10. **Skills WordPress** (`.claude/skills/`) : utilise `wp-wpcli-and-ops` pour tout ce qui touche WP-CLI, `wp-project-triage` si tu dois comprendre un site, `wp-performance` pour des réglages de performance. Ils viennent de WordPress/agent-skills ; `scripts/setup-skills.sh` les met à niveau.

## Conventions du lock (`config/plugins.json`)

```json
{ "slug": "…", "name": "…", "version": "…", "source": "wporg|zip",
  "update_check": "wporg|license|manual", "activate": true,
  "vendor_url": "…", "requires": ["…"] }
```
L'ordre des entrées est l'ordre d'installation (dépendances d'abord). `remove_if_present` liste ce qu'on supprime d'une installation WordPress par défaut.

## Réglages figés (`config/settings.json`)

Langue `fr_CA`, fuseau `America/Toronto`, permaliens `/%postname%/`, commentaires et pingbacks fermés, Disable Comments activé partout, `blog_public = 0` (le starter n'est jamais indexé — à passer à 1 sur un site client à la mise en ligne), contenu d'exemple supprimé, thèmes par défaut supprimés sauf `twentytwentyfive` (filet de sécurité), Elementor sans couleurs/polices par défaut, upload SVG autorisé. Hors de `settings.json` : barre d'outils masquée sur le site pour les comptes existants (`show_admin_bar_front`, par compte), et `WP_AUTO_UPDATE_CORE = false` dans le `wp-config.php` du starter (posé par `install.sh`, retiré par `new-site.sh` : un site client doit garder ses mises à jour automatiques). Modifier ces réglages = modifier `settings.json` **puis** `wp eval-file scripts/php/apply-settings.php config/settings.json`, puis une ligne dans le CHANGELOG.

## Contexte métier

Sites clients RepOtz : vitrines PME au Québec, Elementor Pro, souvent bilingues FR/EN (Polylang), SEO avec Yoast, JSON-LD via HFCM (gabarit dans `config/snippets/`), intégration de maquettes HTML via Novamira + Claude Code. Le starter doit rester générique : ce qui est propre à un client ne rentre pas ici.
