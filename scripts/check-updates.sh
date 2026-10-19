#!/usr/bin/env bash
# Interroge WordPress.org (et les updaters des fournisseurs) et compare au lock.
# N'installe rien.
#
# Usage : scripts/check-updates.sh [--json]
#   --json   sortie JSON (aussi écrite dans reports/check-updates-<date>.json)

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

JSON=0
[[ "${1:-}" == "--json" ]] && JSON=1

if (( JSON )); then
  out="$REPORTS_DIR/check-updates-$(today).json"
  wpc eval-file "$SCRIPTS_DIR/php/check-updates.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json" --json | tee "$out"
  info "Rapport : $out" >&2
else
  title "wp-starter · vérification des mises à jour ($(today))"
  wpc eval-file "$SCRIPTS_DIR/php/check-updates.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json"
fi
