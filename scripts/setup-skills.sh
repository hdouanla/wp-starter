#!/usr/bin/env bash
# Rafraîchit .claude/skills/ depuis https://github.com/WordPress/agent-skills (dossier skills/).
# Les skills sont versionnés dans ce dépôt ; ce script sert à les mettre à niveau.
#
# Usage : scripts/setup-skills.sh [--ref trunk]

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/.claude/skills"
REF="trunk"
[[ "${1:-}" == "--ref" ]] && REF="$2"

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
echo "▸ Vérifier le diff, puis commiter : git add .claude/skills && git commit -m \"chore(skills): agent-skills@$COMMIT\""
