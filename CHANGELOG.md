# Changelog — wp-starter

Une section par jour (`## AAAA-MM-JJ`), renommée « version — date » à la clôture (`/release`). Les lignes de versions sont écrites par `scripts/update.sh` ; les ajouts, retraits et réglages à la main.

<!-- nouvelles entrées sous cette ligne (ne pas déplacer : update.sh insère ici) -->

## 2026-11-02

- Zips premium : plus besoin de les renommer, l'extension et sa version sont lues dans le zip (`zip_glob` retiré du lock)
- Réglage : barre d'outils masquée sur le site pour les comptes existants (`install.sh`, `new-site.sh`, contrôle dans `verify.sh`)
- Réglage : Disable Comments activé partout par défaut (`settings.json`, contrôle dans `verify.sh`)
- Skills : version signalée par `check-updates.sh`, mise à niveau relue à `/release`, présence contrôlée par `verify.sh`
- `new-site.sh` retire le `.env` et le `.git` de la copie `starter/` héritée du blueprint

## 2026.11 — 2026-11-02

- Elementor Pro 4.3.2 → 4.3.3
- Yoast SEO 28.7 → 28.8
- Polylang 3.8.11 → 3.9.1
- Disable Comments 2.9.0 → 2.9.1
- WPvivid Backup Plugin 0.9.136 → 0.9.139
- Novamira 1.12.9 → 1.12.14
- WordPress 7.1.3 → 7.1.4
- Réglage : mises à jour automatiques du cœur coupées sur le starter (`WP_AUTO_UPDATE_CORE`), rétablies par `new-site.sh` sur les sites clients
- `verify.sh` et `check-updates.sh` signalent l'écart de version du cœur avec le lock
- Correctif : `verify.sh` ne signale plus à tort `elementor` comme extension hors lock
- Correctif : `update.sh` n'écrit plus deux sections du même jour dans le CHANGELOG
- Scripts : priorité au PHP de LocalWP quand le `~/.zshrc` remet un autre PHP devant (Herd, Homebrew), arrêt si PHP pollue la sortie standard
- Correctif : `install.sh --dry-run` et `check-updates.sh --json` ne plantent plus sur `wp eval-file`
- Correctif : `check-updates.sh` n'affiche plus « Tout est à jour » quand des éléments manquent
- Dépôt déplacé vers `hdouanla/wp-starter`
- Documentation : parcours d'installation précisé (zips, licences, résultat attendu de `verify.sh`), nom du blueprint à jour

## 2026.10 — 2026-10-18

Version initiale du package, alignée sur le site LocalWP `wp-starter` existant.

- WordPress 7.1.3 (fr_CA), PHP 8.2.29, MySQL 8.4.0, nginx 1.26.1
- Thème : Hello Elementor 3.5.1
- Extensions : Elementor 4.3.5 · Elementor Pro 4.3.2 · Yoast SEO 28.7 · Header Footer Code Manager 1.1.46 · Polylang 3.8.11 · Connect Polylang for Elementor 2.5.5 · Classic Editor 1.7.0 · Disable Comments 2.9.0 · WPvivid Backup 0.9.136 · Novamira 1.12.9
- Réglages figés dans `config/settings.json` (fr_CA, America/Toronto, permaliens, commentaires fermés, non indexé, contenu d'exemple supprimé, Elementor sans couleurs/polices par défaut)
- Compte `repotzadmin`, mot de passe généré
- Procédures Claude Code : `/status`, `/update`, `/verify`, `/install`, `/add-plugin`, `/release`, `/new-site`
- Skills `.claude/skills/` : WordPress/agent-skills@55cd0f7
