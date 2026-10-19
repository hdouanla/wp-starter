---
description: Installation initiale du starter sur un site LocalWP vierge (langue, thème, extensions, réglages, compte admin)
---

Procédure d'installation initiale. À n'utiliser que sur un site WordPress vierge créé dans LocalWP, ou pour compléter une installation partielle (le script est idempotent).

1. Vérifie les prérequis et signale ce qui manque :
   - `.env` existe (sinon proposer `cp .env.example .env` et demander `ADMIN_EMAIL`).
   - `premium/` contient un zip pour chaque extension `source: zip` de `config/plugins.json` (`ls premium/`). S'il en manque, préviens : l'installation continuera sans elles, et il faudra relancer après dépôt des zips.
   - `wp core is-installed` réussit sur le site cible.
2. Lance `scripts/install.sh --dry-run` et résume ce qui sera fait.
3. Après accord, lance `scripts/install.sh`. Le mot de passe admin est affiché une seule fois : rappelle à l'utilisateur de le conserver, et ne le recopie pas dans un fichier.
4. Lance `scripts/verify.sh`.
5. Liste les étapes manuelles restantes dans wp-admin : activation des licences Elementor Pro et Novamira ; langues Polylang si besoin ; vérification visuelle d'Elementor (Réglages → Général). Puis : LocalWP → « Save as Blueprint ».
