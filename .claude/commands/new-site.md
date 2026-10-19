---
description: Personnalise un site client créé depuis le blueprint (nom, courriel, nouveau mot de passe admin, caches)
argument-hint: "Nom du client" [--email ...] [--locale en_CA] [--path /chemin/app/public]
---

Personnalisation d'un nouveau site créé dans LocalWP à partir du blueprint wp-starter. Arguments : `$ARGUMENTS`.

1. Identifie le WordPress cible. Si `--path` n'est pas fourni, il faut être lancé depuis le « Open site shell » du **nouveau** site (le répertoire courant est alors son `app/public`). Confirme avec `wp option get home` que ce n'est **pas** le site starter avant d'aller plus loin.
2. Lance `scripts/new-site.sh --name "<nom>" [--email …] [--locale …] [--path …]`.
3. Le mot de passe admin est affiché une seule fois : rappelle de le conserver ; ne l'écris nulle part.
4. Rappelle les suites typiques : configurer les langues Polylang (FR/EN) si le site est bilingue ; coller le JSON-LD de `config/snippets/hfcm-jsonld-organisation.html` dans HFCM après l'avoir complété ; `blog_public` à passer à 1 seulement à la mise en ligne.

Ne modifie rien dans ce dépôt : ce qui concerne le site client vit dans le site client.
