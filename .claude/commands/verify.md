---
description: Vérification complète du site starter (extensions, thème, réglages, intégrité du cœur, réponse HTTP)
---

Exécute `scripts/verify.sh` (complet, avec checksums du cœur).

Pour chaque erreur ou avertissement, donne la cause probable et la commande qui corrige, en te limitant à ce que les scripts du dépôt ou WP-CLI permettent :
- extension manquante → `scripts/install.sh`
- extension inactive → `wp plugin activate <slug>` (vérifier d'abord les dépendances `requires` dans `config/plugins.json`)
- lock ≠ installé → `scripts/snapshot.sh` si la version installée est voulue, sinon `scripts/update.sh --plugin <slug>`
- réglage non conforme → `wp eval-file scripts/php/apply-settings.php config/settings.json`
- extension hors lock → demander si on l'ajoute à `config/plugins.json` ou si on la supprime

Applique les corrections seulement après accord explicite. Relance `scripts/verify.sh --quick` ensuite.
