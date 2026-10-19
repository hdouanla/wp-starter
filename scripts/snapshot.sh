#!/usr/bin/env bash
# Synchronise config/plugins.json et config/stack.json avec les versions réellement installées.
# À lancer après une mise à jour faite à la main dans wp-admin, pour que le lock reste vrai.
#
# Usage : scripts/snapshot.sh

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

title "wp-starter · snapshot des versions ($(today))"
wpc eval-file "$SCRIPTS_DIR/php/snapshot.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json"
ok "config/plugins.json et config/stack.json synchronisés"
info "Penser à ajouter une entrée dans CHANGELOG.md et à commiter."
