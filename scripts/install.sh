#!/usr/bin/env bash
# Installation complète du starter sur un WordPress vierge (site LocalWP fraîchement créé).
# Idempotent : relançable sans casser ce qui est déjà en place.
#
# Usage : scripts/install.sh [--skip-admin] [--dry-run]
#   --skip-admin  ne crée pas / ne réinitialise pas le compte repotzadmin
#   --dry-run     affiche ce qui serait fait pour les réglages, sans installer

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SKIP_ADMIN=0; DRY_RUN=0
for a in "$@"; do
  case "$a" in
    --skip-admin) SKIP_ADMIN=1 ;;
    --dry-run) DRY_RUN=1 ;;
    *) die "Option inconnue : $a" ;;
  esac
done

title "wp-starter · installation"
info "WordPress : $WP_PATH"
wpc core is-installed || die "WordPress n'est pas installé dans $WP_PATH (créer le site dans LocalWP d'abord)."
info "Version : $(wpc core version)"

# --- 1. Langue ---------------------------------------------------------------
title "Langue"
LOCALE="$(json_get "$CONFIG_DIR/settings.json" '$d["language"]["locale"]')"
if [[ "$(wpc language core list --status=active --field=language)" == "$LOCALE" ]]; then
  ok "$LOCALE déjà active"
else
  (( DRY_RUN )) || wpc language core install "$LOCALE" --activate
  ok "$LOCALE installée et activée"
fi

# --- 2. Thème ----------------------------------------------------------------
title "Thème"
THEME_SLUG="$(json_get "$CONFIG_DIR/stack.json" '$d["theme"]["slug"]')"
THEME_VER="$(json_get "$CONFIG_DIR/stack.json" '$d["theme"]["version"]')"
if wpc theme is-installed "$THEME_SLUG"; then
  ok "$THEME_SLUG déjà installé ($(wpc theme get "$THEME_SLUG" --field=version))"
else
  (( DRY_RUN )) || wpc theme install "$THEME_SLUG" --version="$THEME_VER"
  ok "$THEME_SLUG $THEME_VER installé"
fi
(( DRY_RUN )) || wpc theme activate "$THEME_SLUG" >/dev/null
ok "$THEME_SLUG actif"

# --- 3. Extensions -----------------------------------------------------------
title "Extensions"
# Suppression des extensions indésirables fournies par défaut
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if wpc plugin is-installed "$slug" 2>/dev/null; then
    (( DRY_RUN )) || wpc plugin delete "$slug" >/dev/null
    ok "supprimé : $slug"
  fi
done < <(php -r '$d=json_decode(file_get_contents($argv[1]),true); foreach(($d["remove_if_present"]??[]) as $s) echo $s,"\n";' "$CONFIG_DIR/plugins.json")

MISSING_PREMIUM=()
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  name="$(plugin_field "$slug" name)"
  version="$(plugin_field "$slug" version)"
  source="$(plugin_field "$slug" source)"
  activate="$(plugin_field "$slug" activate)"

  if wpc plugin is-installed "$slug"; then
    ok "$name déjà installé ($(wpc plugin get "$slug" --field=version))"
  else
    case "$source" in
      wporg)
        (( DRY_RUN )) || wpc plugin install "$slug" --version="$version" >/dev/null
        ok "$name $version installé depuis WordPress.org"
        ;;
      zip)
        zip="$(premium_zip_for "$slug")"
        if [[ -z "$zip" ]]; then
          warn "$name : aucun zip de cette extension dans premium/ — ignoré"
          MISSING_PREMIUM+=("$name")
          continue
        fi
        (( DRY_RUN )) || wpc plugin install "$zip" >/dev/null
        ok "$name installé depuis $(basename "$zip")"
        ;;
      *) warn "$name : source inconnue « $source »" ; continue ;;
    esac
  fi

  if [[ "$activate" == "1" ]] && ! (( DRY_RUN )); then
    wpc plugin activate "$slug" >/dev/null 2>&1 && ok "$name actif" || warn "$name : activation échouée (dépendance manquante ?)"
  fi
done < <(plugin_slugs)

# Traductions des extensions et du thème
(( DRY_RUN )) || { wpc language plugin install --all "$LOCALE" >/dev/null 2>&1 || true; wpc language theme install --all "$LOCALE" >/dev/null 2>&1 || true; }
ok "traductions $LOCALE installées (quand disponibles)"

# --- 4. Réglages -------------------------------------------------------------
title "Réglages"
if (( DRY_RUN )); then
  wpc eval-file "$SCRIPTS_DIR/php/apply-settings.php" "$CONFIG_DIR/settings.json" dry-run
else
  wpc eval-file "$SCRIPTS_DIR/php/apply-settings.php" "$CONFIG_DIR/settings.json"
fi

# Le starter ne change de version que par update.sh, pour rester aligné sur le lock.
# new-site.sh retire cette constante : les sites clients gardent leurs mises à jour automatiques.
(( DRY_RUN )) || wpc config set WP_AUTO_UPDATE_CORE false --raw --type=constant >/dev/null
ok "Mises à jour automatiques du cœur coupées sur le starter"

# --- 5. Compte administrateur ------------------------------------------------
if (( SKIP_ADMIN )); then
  info "Compte admin : ignoré (--skip-admin)"
else
  title "Compte administrateur"
  ADMIN_LOGIN="$(json_get "$CONFIG_DIR/settings.json" '$d["admin"]["user_login"]')"
  ADMIN_NAME="$(json_get "$CONFIG_DIR/settings.json" '$d["admin"]["display_name"]')"
  ADMIN_EMAIL="${ADMIN_EMAIL:-admin@repotz.com}"
  PASS="$(gen_password)"
  if (( DRY_RUN )); then
    info "créerait/réinitialiserait $ADMIN_LOGIN <$ADMIN_EMAIL>"
  elif wpc user get "$ADMIN_LOGIN" --field=ID >/dev/null 2>&1; then
    wpc user update "$ADMIN_LOGIN" --user_pass="$PASS" --user_email="$ADMIN_EMAIL" --role=administrator --display_name="$ADMIN_NAME" >/dev/null
    ok "$ADMIN_LOGIN existant : mot de passe réinitialisé"
  else
    wpc user create "$ADMIN_LOGIN" "$ADMIN_EMAIL" --role=administrator --user_pass="$PASS" --display_name="$ADMIN_NAME" >/dev/null
    ok "$ADMIN_LOGIN créé"
  fi
  (( DRY_RUN )) || {
    echo
    echo "   ${C_BOLD}Identifiant :${C_RESET} $ADMIN_LOGIN"
    echo "   ${C_BOLD}Mot de passe :${C_RESET} $PASS"
    echo "   (affiché une seule fois — le noter dans le gestionnaire de mots de passe)"
  }
fi

# Barre d'outils masquée sur le site pour tous les comptes existants (réglage propre à chaque compte).
if ! (( DRY_RUN )); then
  while IFS= read -r user_id; do
    [[ -n "$user_id" ]] && wpc user meta update "$user_id" show_admin_bar_front false >/dev/null
  done < <(wpc user list --field=ID)
fi
ok "Barre d'outils masquée sur le site pour les comptes existants"

# --- 6. Bilan ----------------------------------------------------------------
title "Bilan"
wpc plugin list --fields=name,status,version
echo
if (( ${#MISSING_PREMIUM[@]} )); then
  warn "Extensions premium non installées : ${MISSING_PREMIUM[*]+"${MISSING_PREMIUM[*]}"}"
  warn "Déposer les zips dans premium/ puis relancer scripts/install.sh"
fi
info "Étapes manuelles restantes : activer la licence Elementor Pro dans wp-admin,"
info "configurer les langues Polylang si le site est bilingue, puis LocalWP → Save as Blueprint."
