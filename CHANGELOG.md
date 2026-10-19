# Changelog — wp-starter

Une section par jour (`## AAAA-MM-JJ`), renommée « version — date » à la clôture (`/release`). Les lignes de versions sont écrites par `scripts/update.sh` ; les ajouts, retraits et réglages à la main.

<!-- nouvelles entrées sous cette ligne (ne pas déplacer : update.sh insère ici) -->

## 2026.10 — 2026-10-18

Version initiale du package, alignée sur le site LocalWP `wp-starter` existant.

- WordPress 7.1.3 (fr_CA), PHP 8.2.29, MySQL 8.4.0, nginx 1.26.1
- Thème : Hello Elementor 3.5.1
- Extensions : Elementor 4.3.5 · Elementor Pro 4.3.2 · Yoast SEO 28.7 · Header Footer Code Manager 1.1.46 · Polylang 3.8.11 · Connect Polylang for Elementor 2.5.5 · Classic Editor 1.7.0 · Disable Comments 2.9.0 · WPvivid Backup 0.9.136 · Novamira 1.12.9
- Réglages figés dans `config/settings.json` (fr_CA, America/Toronto, permaliens, commentaires fermés, non indexé, contenu d'exemple supprimé, Elementor sans couleurs/polices par défaut)
- Compte `repotzadmin`, mot de passe généré
- Procédures Claude Code : `/status`, `/update`, `/verify`, `/install`, `/add-plugin`, `/release`, `/new-site`
- Skills `.claude/skills/` : WordPress/agent-skills@55cd0f7
