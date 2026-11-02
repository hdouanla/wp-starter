#!/usr/bin/env bash
# Applique les mises à jour (cœur, thème, extensions), vérifie le site, synchronise le lock
# et ajoute une entrée au CHANGELOG. Sauvegarde la base avant d'agir.
#
# Usage :
#   scripts/update.sh                 tout ce qui a une mise à jour disponible
#   scripts/update.sh --plugin elementor [--plugin wordpress-seo ...]
#   scripts/update.sh --core | --theme
#   scripts/update.sh --no-verify     saute verify.sh (déconseillé)
#   scripts/update.sh --no-changelog  ne touche pas au CHANGELOG
#
# Extensions `source: zip` : si un zip plus récent est dans premium/, il est installé par-dessus
# (wp plugin install --force) ; sinon, la mise à jour passe par l'updater du fournisseur
# (licence active requise), comme pour une extension WordPress.org.

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

DO_CORE=0; DO_THEME=0; DO_PLUGINS=0; ALL=1; VERIFY=1; CHANGELOG=1
PLUGINS=()
while (( $# )); do
  case "$1" in
    --core) DO_CORE=1; ALL=0 ;;
    --theme) DO_THEME=1; ALL=0 ;;
    --plugin) DO_PLUGINS=1; ALL=0; PLUGINS+=("$2"); shift ;;
    --no-verify) VERIFY=0 ;;
    --no-changelog) CHANGELOG=0 ;;
    *) die "Option inconnue : $1" ;;
  esac
  shift
done
if (( ALL )); then
  DO_CORE=1; DO_THEME=1; DO_PLUGINS=1
  while IFS= read -r s; do [[ -n "$s" ]] && PLUGINS+=("$s"); done < <(plugin_slugs)
fi

title "wp-starter · mise à jour ($(today))"

# --- 0. Sauvegarde ----------------------------------------------------------
BACKUP="$REPORTS_DIR/db-before-update-$(date +%Y%m%d-%H%M%S).sql"
wpc db export "$BACKUP" --quiet
ok "Base sauvegardée : $BACKUP"

BEFORE="$(wpc plugin list --fields=name,version --format=csv)"
BEFORE_CORE="$(wpc core version)"
UPDATED=()

# --- 1. Cœur ---------------------------------------------------------------
if (( DO_CORE )); then
  title "Cœur WordPress"
  if wpc core check-update --format=csv | tail -n +2 | grep -q .; then
    wpc core update
    wpc core update-db >/dev/null
    wpc language core update >/dev/null 2>&1 || true
    UPDATED+=("WordPress $BEFORE_CORE → $(wpc core version)")
    ok "WordPress → $(wpc core version)"
  else
    ok "WordPress $BEFORE_CORE à jour"
  fi
fi

# --- 2. Thème --------------------------------------------------------------
if (( DO_THEME )); then
  title "Thème"
  THEME_SLUG="$(json_get "$CONFIG_DIR/stack.json" '$d["theme"]["slug"]')"
  before="$(wpc theme get "$THEME_SLUG" --field=version)"
  if wpc theme update "$THEME_SLUG" 2>&1 | grep -q "Updated 1 of"; then
    UPDATED+=("$THEME_SLUG $before → $(wpc theme get "$THEME_SLUG" --field=version)")
    ok "$THEME_SLUG → $(wpc theme get "$THEME_SLUG" --field=version)"
  else
    ok "$THEME_SLUG $before à jour"
  fi
fi

# --- 3. Extensions ---------------------------------------------------------
if (( DO_PLUGINS )); then
  title "Extensions"
  for slug in ${PLUGINS[@]+"${PLUGINS[@]}"}; do
    name="$(plugin_field "$slug" name)"
    [[ -z "$name" ]] && { warn "$slug absent de config/plugins.json — ignoré"; continue; }
    source="$(plugin_field "$slug" source)"
    if ! wpc plugin is-installed "$slug"; then
      warn "$name non installé — lancer scripts/install.sh"; continue
    fi
    before="$(wpc plugin get "$slug" --field=version)"

    if [[ "$source" == "zip" ]]; then
      zip="$(premium_zip_for "$slug")"
      zipver="$(basename "${zip:-}" .zip | sed -E 's/^[a-z0-9-]+-([0-9][0-9.]*)$/\1/')"
      if [[ -n "$zip" && -n "$zipver" ]] && php -r 'exit(version_compare($argv[1], $argv[2], ">") ? 0 : 1);' "$zipver" "$before"; then
        wpc plugin install "$zip" --force >/dev/null
        wpc plugin activate "$slug" >/dev/null 2>&1 || true
        UPDATED+=("$name $before → $(wpc plugin get "$slug" --field=version) (zip)")
        ok "$name → $(wpc plugin get "$slug" --field=version) depuis $(basename "$zip")"
        continue
      fi
    fi

    out="$(wpc plugin update "$slug" 2>&1 || true)"
    if grep -q "Updated 1 of" <<<"$out"; then
      UPDATED+=("$name $before → $(wpc plugin get "$slug" --field=version)")
      ok "$name → $(wpc plugin get "$slug" --field=version)"
    elif grep -qi "no update\|already updated\|up to date" <<<"$out" || [[ "$(wpc plugin get "$slug" --field=version)" == "$before" ]]; then
      if [[ "$source" == "zip" ]]; then
        ok "$name $before — aucune mise à jour signalée (licence active ? sinon déposer un nouveau zip dans premium/)"
      else
        ok "$name $before à jour"
      fi
    else
      warn "$name : $out"
    fi
  done
fi

# --- 4. Vérification -------------------------------------------------------
if (( VERIFY )); then
  if ! "$SCRIPTS_DIR/verify.sh"; then
    fail "La vérification a échoué. Base d'avant mise à jour : $BACKUP"
    fail "Restauration : wp db import \"$BACKUP\" puis réinstaller les versions du lock (scripts/install.sh)."
    exit 1
  fi
fi

# --- 5. Lock + CHANGELOG ---------------------------------------------------
title "Synchronisation du lock"
CHANGES="$(wpc eval-file "$SCRIPTS_DIR/php/snapshot.php" "$CONFIG_DIR/plugins.json" "$CONFIG_DIR/stack.json")"
echo "$CHANGES"

if (( CHANGELOG )) && [[ "$CHANGES" != "Aucun changement de version." ]]; then
  tmp="$(mktemp)"
  if [[ "$(sed -n 7p "$STARTER_ROOT/CHANGELOG.md")" == "## $(today)" ]]; then
    # Section du jour déjà présente : on y ajoute les lignes (une section par jour).
    { head -n 8 "$STARTER_ROOT/CHANGELOG.md"; echo "$CHANGES" | sed 's/^/- /'; tail -n +9 "$STARTER_ROOT/CHANGELOG.md"; } > "$tmp"
  else
    { head -n 6 "$STARTER_ROOT/CHANGELOG.md"; printf '## %s\n\n' "$(today)"; echo "$CHANGES" | sed 's/^/- /'; echo; tail -n +7 "$STARTER_ROOT/CHANGELOG.md"; } > "$tmp"
  fi
  mv "$tmp" "$STARTER_ROOT/CHANGELOG.md"
  ok "CHANGELOG.md mis à jour"
fi

title "Terminé"
if (( ${#UPDATED[@]} )); then
  printf '  • %s\n' ${UPDATED[@]+"${UPDATED[@]}"}
  echo
  info "Prochaine étape : commit, puis LocalWP → Save as Blueprint (remplacer l'ancien)."
else
  ok "Rien à mettre à jour."
fi
