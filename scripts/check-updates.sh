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
  wpc eval-file "$SCRIPTS_DIR/php/check-updates.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json" json | tee "$out"
  info "Rapport : $out" >&2
else
  title "wp-starter · vérification des mises à jour ($(today))"
  wpc eval-file "$SCRIPTS_DIR/php/check-updates.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json"

  # Skills Claude Code : commit versionné ici / trunk de WordPress/agent-skills. Sans réseau, on le signale et on continue.
  skills_have="$(cat "$STARTER_ROOT/.claude/skills/.agent-skills-commit" 2>/dev/null || true)"
  skills_trunk="$(GIT_TERMINAL_PROMPT=0 git ls-remote https://github.com/WordPress/agent-skills refs/heads/trunk 2>/dev/null | cut -c1-40 || true)"
  if [[ -z "$skills_trunk" ]]; then
    warn "Skills : trunk de WordPress/agent-skills injoignable (installé : ${skills_have:-inconnu})"
  elif [[ -n "$skills_have" && "$skills_trunk" == "$skills_have"* ]]; then
    ok "Skills : à jour (agent-skills@$skills_have)"
  else
    warn "Skills : agent-skills@${skills_have:-inconnu} → ${skills_trunk:0:7} disponible (scripts/setup-skills.sh, à faire au prochain /release)"
  fi
fi
