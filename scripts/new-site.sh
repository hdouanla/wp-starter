#!/usr/bin/env bash
# Personnalise un site client fraîchement créé dans LocalWP à partir du blueprint wp-starter :
# nouveau mot de passe admin, nom du site, courriel, caches purgés.
#
# À lancer depuis « Open site shell » du NOUVEAU site (LocalWP se place dans app/public) :
#   bash ~/Local\ Sites/wp-starter/starter/scripts/new-site.sh --name "Nom du client" [--email x@y.com] [--locale en_CA]
# Ou en précisant le site :
#   scripts/new-site.sh --path ~/Local\ Sites/client-x/app/public --name "Client X"
#
# Réparer seulement les outils Claude Code d'un site existant (sans toucher à WordPress) :
#   scripts/new-site.sh --claude-only [--path …/app/public]
#
# Refuse de s'exécuter sur le site starter lui-même (sauf --force).

NAME=""; EMAIL=""; LOCALE=""; TARGET="$PWD"; FORCE=0; CLAUDE_ONLY=0
while (( $# )); do
  case "$1" in
    --name) NAME="$2"; shift ;;
    --email) EMAIL="$2"; shift ;;
    --locale) LOCALE="$2"; shift ;;
    --path) TARGET="$2"; shift ;;
    --force) FORCE=1 ;;
    --claude-only) CLAUDE_ONLY=1 ;;
    *) echo "Option inconnue : $1" >&2; exit 1 ;;
  esac
  shift
done
[[ -z "$NAME" && $CLAUDE_ONLY -eq 0 ]] && { echo "Usage : new-site.sh --name \"Nom du client\" [--email ...] [--locale ...] [--path ...]" >&2; exit 1; }

export WP_PATH="$TARGET"
(( CLAUDE_ONLY )) && export WPS_FILES_ONLY=1
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

STARTER_WP="$(cd "$STARTER_ROOT/../app/public" 2>/dev/null && pwd || true)"
if [[ -n "$STARTER_WP" && "$WP_PATH" == "$STARTER_WP" && $FORCE -eq 0 ]]; then
  die "Ce WordPress est le site starter ($WP_PATH). Lancer depuis le shell du nouveau site, ou --force."
fi

# --- Outils Claude Code du site -----------------------------------------------
# Avant toute commande WordPress : une erreur wp-cli plus bas (set -e) ne doit pas empêcher la copie.
# Skills dans app/public/.claude/skills : c'est là qu'on lance Claude Code, et il ne remonte pas
# les .claude/ parents hors d'un dépôt Git. CLAUDE.md commun à la racine du site : Claude Code
# lit les CLAUDE.md de tous les dossiers parents ; app/public/CLAUDE.md reste libre pour le mandat.
# Rien n'est écrasé ; un échec n'arrête pas le script.
SITE_DIR="$(dirname "$(dirname "$WP_PATH")")"
install_claude_tools() {
  local src="$STARTER_ROOT/.claude/skills" dst="$WP_PATH/.claude/skills" label="${NAME:-$(basename "$SITE_DIR")}"
  if [[ "$WP_PATH" != */app/public || "$(basename "$SITE_DIR")" == "wp-starter" ]]; then
    warn "Outils Claude Code : $WP_PATH n'est pas le app/public d'un site client, rien copié"
    return 0
  fi
  local rc=0
  copy_skills_to "$WP_PATH" || rc=$?
  case "$rc" in
    0) ok "Skills Claude Code copiés dans app/public/.claude/skills (agent-skills@$(cat "$dst/.agent-skills-commit" 2>/dev/null || echo '?'))" ;;
    2) warn "Skills absents de $src : rien à copier" ;;
    *) warn "Skills Claude Code : copie échouée vers $dst" ;;
  esac
  # Ancien emplacement (racine du site) : non chargé depuis app/public, on le signale.
  [[ -d "$SITE_DIR/.claude/skills" ]] && info "$SITE_DIR/.claude/skills existe aussi (ancien emplacement) : peut être supprimé"

  if [[ -e "$SITE_DIR/CLAUDE.md" ]]; then
    info "CLAUDE.md du site déjà présent : conservé"
  elif [[ ! -f "$CONFIG_DIR/client/CLAUDE.md" ]]; then
    warn "Gabarit $CONFIG_DIR/client/CLAUDE.md absent : CLAUDE.md du site non créé"
  elif { printf '# %s\n\n' "$label"; cat "$CONFIG_DIR/client/CLAUDE.md"; } > "$SITE_DIR/CLAUDE.md"; then
    ok "CLAUDE.md créé à la racine du site"
  else
    warn "CLAUDE.md du site : écriture échouée"
  fi
}

if (( CLAUDE_ONLY )); then
  title "wp-starter · outils Claude Code"
  install_claude_tools
  exit 0
fi

title "wp-starter · nouveau site « $NAME »"
install_claude_tools
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
wpc user meta update "$ADMIN_LOGIN" show_admin_bar_front false >/dev/null
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

# --- Copie du dépôt starter héritée du blueprint ------------------------------
# Le blueprint embarque starter/ : on garde les skills et les scripts, mais pas le .env
# (licences, WP_PATH du starter) ni le .git (un push partirait vers le dépôt du starter).
# Jamais sur le vrai dépôt : ni le dépôt qui exécute ce script, ni le site wp-starter, ni un lien.
SITE_STARTER="$SITE_DIR/starter"
if [[ -d "$SITE_STARTER" && ! -L "$SITE_STARTER" && "$(basename "$SITE_DIR")" != "wp-starter" \
      && "$(cd "$SITE_STARTER" && pwd -P)" != "$(cd "$STARTER_ROOT" && pwd -P)" ]]; then
  [[ -f "$SITE_STARTER/.env" ]] && rm -f "$SITE_STARTER/.env" && ok "starter/.env hérité du blueprint retiré"
  if [[ -d "$SITE_STARTER/.git" ]]; then
    if grep -q 'wp-starter' "$SITE_STARTER/.git/config" 2>/dev/null; then
      if rm -rf "$SITE_STARTER/.git"; then
        ok "starter/.git hérité du blueprint retiré"
      else
        warn "starter/.git : suppression échouée"
      fi
    else
      warn "starter/.git conservé : ce n'est pas une copie du dépôt wp-starter"
    fi
  fi
fi

# --- Rappel : indexation ----------------------------------------------------
warn "blog_public = $(wpc option get blog_public) — laisser à 0 en développement ; passer à 1 à la mise en ligne."

echo
echo "   ${C_BOLD}Site :${C_RESET} $(wpc option get home)/wp-admin/"
echo "   ${C_BOLD}Identifiant :${C_RESET} $ADMIN_LOGIN"
echo "   ${C_BOLD}Mot de passe :${C_RESET} $PASS"
echo "   (affiché une seule fois)"
