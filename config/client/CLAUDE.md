Site vitrine RepOtz géré dans LocalWP, créé depuis le blueprint wp-starter. Ce fichier donne le contexte commun ; s'il existe, `app/public/CLAUDE.md` décrit le mandat et a priorité sur ce fichier.

Langue de travail : français (registre québécois), termes techniques en anglais acceptés.

## Où tu es

```
<site>/
├── CLAUDE.md          ← ce fichier
├── .claude/skills/    skills WordPress (WordPress/agent-skills), hors du dossier public
├── app/public/        le WordPress du site ; lance Claude Code ici
└── starter/           copie du starter à la création du site : référence seulement, sans Git
```

## Stack

Thème Hello Elementor, Elementor Pro, Yoast SEO, Polylang (souvent FR/EN), Header Footer Code Manager, Classic Editor, Disable Comments, WPvivid, Novamira. Gabarit JSON-LD à compléter puis à coller dans HFCM : `starter/config/snippets/hfcm-jsonld-organisation.html`.

Utilise `wp-wpcli-and-ops` pour WP-CLI, `wp-project-triage` pour comprendre le site et `wp-performance` pour la performance. Lance `wp` depuis le « Open site shell » de LocalWP : un autre terminal peut utiliser un autre PHP (`php -v` pour vérifier).

## Règles

1. **Sauvegarde avant de toucher à la base** : `wp db export` avant une opération risquée, et demande un accord explicite pour toute opération destructive (`wp db reset`, `rm -rf`, suppression de contenu ou d'extensions).
2. **Rien de propre à ce client dans `starter/`** : cette copie n'est pas le dépôt du starter et ne se met pas à jour.
3. **Jamais de secrets dans un fichier** : ni mot de passe ni licence.
4. **Mise en ligne** : `blog_public` reste à 0 en développement et passe à 1 seulement à la mise en ligne. Ne déploie que le contenu de `app/public/`.
