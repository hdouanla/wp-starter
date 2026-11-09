#!/usr/bin/env bash
# Rafraîchit .claude/skills/ depuis https://github.com/WordPress/agent-skills (dossier skills/),
# puis recopie les skills dans app/public/.claude/skills du starter (embarqués par le blueprint).
# Les skills sont versionnés dans ce dépôt ; ce script sert à les mettre à niveau.
#
# Usage : scripts/setup-skills.sh [--ref trunk] [--local]
#   --local   ne télécharge rien : recopie seulement .claude/skills/ dans app/public/.claude/skills

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/.claude/skills"
REF="trunk"; LOCAL=0
while (( $# )); do
  case "$1" in
    --ref) REF="$2"; shift ;;
    --local) LOCAL=1 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
  shift
done

if (( ! LOCAL )); then
  command -v git >/dev/null || { echo "git requis" >&2; exit 1; }

  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  echo "▸ Clonage de WordPress/agent-skills ($REF)…"
  git clone --quiet --depth 1 --branch "$REF" https://github.com/WordPress/agent-skills "$TMP/agent-skills"
  COMMIT="$(git -C "$TMP/agent-skills" rev-parse --short HEAD)"

  # Remplacer le contenu, sans toucher aux skills maison (dossiers préfixés « repotz- »)
  mkdir -p "$DEST"
  find "$DEST" -mindepth 1 -maxdepth 1 -type d ! -name 'repotz-*' -exec rm -rf {} +
  cp -R "$TMP/agent-skills/skills/." "$DEST/"
  cp "$TMP/agent-skills/LICENSE" "$DEST/LICENSE-agent-skills"
  echo "$COMMIT" > "$DEST/.agent-skills-commit"

  echo "✓ .claude/skills mis à niveau (WordPress/agent-skills@$COMMIT)"
  for d in "$DEST"/*/; do echo "   $(basename "$d")"; done
fi

# Copie dans le WordPress du starter. Sous-shell : sans WordPress à côté, lib.sh s'arrête,
# et la mise à niveau du dépôt reste valable. Fichiers seulement : ni wp ni php requis.
if (
  export WPS_FILES_ONLY=1
  # shellcheck disable=SC1091
  source "$ROOT/scripts/lib.sh"
  copy_skills_to "$WP_PATH" mirror
  ok "Skills copiés dans $WP_PATH/.claude/skills (agent-skills@$(cat "$WP_PATH/.claude/skills/.agent-skills-commit" 2>/dev/null || echo '?'))"
); then
  :
else
  echo "! Skills non copiés dans app/public/.claude/skills du starter (voir ci-dessus)" >&2
  (( LOCAL )) && exit 1
fi

if (( ! LOCAL )); then
  echo "▸ Vérifier le diff, puis commiter : git add .claude/skills && git commit -m \"chore(skills): agent-skills@$COMMIT\""
fi
