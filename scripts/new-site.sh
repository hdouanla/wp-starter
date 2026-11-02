#!/usr/bin/env bash
# Personnalise un site client fraîchement créé dans LocalWP à partir du blueprint wp-starter :
# nouveau mot de passe admin, nom du site, courriel, caches purgés.
#
# À lancer depuis « Open site shell » du NOUVEAU site (LocalWP se place dans app/public) :
#   bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --name "Nom du client" [--email x@y.com] [--locale en_CA]
# Ou en précisant le site :
#   scripts/new-site.sh --path ~/Local\ Sites/client-x/app/public --name "Client X"
#
# Refuse de s'exécuter sur le site starter lui-même (sauf --force).

NAME=""; EMAIL=""; LOCALE=""; TARGET="$PWD"; FORCE=0
while (( $# )); do
  case "$1" in
    --name) NAME="$2"; shift ;;
    --email) EMAIL="$2"; shift ;;
    --locale) LOCALE="$2"; shift ;;
    --path) TARGET="$2"; shift ;;
    --force) FORCE=1 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
  shift
done
[[ -z "$NAME" ]] && { echo "Usage : new-site.sh --name \"Nom du client\" [--email ...] [--locale ...] [--path ...]" >&2; exit 1; }

export WP_PATH="$TARGET"
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STARTER_WP="$(cd "$STARTER_ROOT/../app/public" 2>/dev/null && pwd || true)"
if [[ -n "$STARTER_WP" && "$WP_PATH" == "$STARTER_WP" && $FORCE -eq 0 ]]; then
  die "Ce WordPress est le site starter ($WP_PATH). Lancer depuis le shell du nouveau site, ou --force."
fi

title "wp-starter · nouveau site « $NAME »"
info "WordPress : $WP_PATH ($(wpc option get home))"

# --- Identité ---------------------------------------------------------------
wpc option update blogname "$NAME" >/dev/null
ok "Nom du site : $NAME"
ADMIN_LOGIN="$(json_get "$CONFIG_DIR/settings.json" '$d["admin"]["user_login"]')"
EMAIL="${EMAIL:-${ADMIN_EMAIL:-admin@repotz.com}}"
wpc option update admin_email "$EMAIL" >/dev/null
wpc option delete new_admin_email >/dev/null 2>&1 || true
ok "Courriel admin : $EMAIL"

# --- Compte admin : nouveau mot de passe --------------------------------------
PASS="$(gen_password)"
if wpc user get "$ADMIN_LOGIN" --field=ID >/dev/null 2>&1; then
  wpc user update "$ADMIN_LOGIN" --user_pass="$PASS" --user_email="$EMAIL" >/dev/null
  ok "$ADMIN_LOGIN : mot de passe régénéré"
else
  wpc user create "$ADMIN_LOGIN" "$EMAIL" --role=administrator --user_pass="$PASS" >/dev/null
  ok "$ADMIN_LOGIN créé"
fi
# Invalider les sessions héritées du blueprint
wpc user session destroy "$ADMIN_LOGIN" --all >/dev/null 2>&1 || true

# --- Langue (optionnel) -----------------------------------------------------
if [[ -n "$LOCALE" ]]; then
  wpc language core install "$LOCALE" --activate >/dev/null 2>&1 && ok "Langue : $LOCALE" || warn "Langue $LOCALE : installation échouée"
fi

# --- Mises à jour automatiques ----------------------------------------------
# Coupées sur le starter seulement : un site client doit recevoir ses correctifs de sécurité.
if wpc config has WP_AUTO_UPDATE_CORE 2>/dev/null; then
  wpc config delete WP_AUTO_UPDATE_CORE >/dev/null
fi
ok "Mises à jour automatiques du cœur : actives"

# --- Caches et transients ---------------------------------------------------
wpc transient delete --all >/dev/null 2>&1 || true
wpc cache flush >/dev/null 2>&1 || true
wpc elementor flush-css >/dev/null 2>&1 && ok "CSS Elementor régénéré" || true
wpc rewrite flush >/dev/null 2>&1 || true
ok "Transients et caches purgés"

# --- Rappel : indexation ----------------------------------------------------
warn "blog_public = $(wpc option get blog_public) — laisser à 0 en développement ; passer à 1 à la mise en ligne."

echo
echo "   ${C_BOLD}Site :${C_RESET} $(wpc option get home)/wp-admin/"
echo "   ${C_BOLD}Identifiant :${C_RESET} $ADMIN_LOGIN"
echo "   ${C_BOLD}Mot de passe :${C_RESET} $PASS"
echo "   (affiché une seule fois)"
