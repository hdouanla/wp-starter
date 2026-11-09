#!/usr/bin/env bash
# Vérifie l'état du site starter : extensions du lock présentes et actives, thème, réglages clés,
# intégrité du cœur, réponse HTTP sans erreur fatale. Code de retour 1 si un contrôle bloquant échoue.
#
# Usage : scripts/verify.sh [--quick]   (--quick saute la vérification des checksums du cœur)

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

QUICK=0; [[ "${1:-}" == "--quick" ]] && QUICK=1
ERRORS=0; WARNINGS=0
check_ok()   { ok "$*"; }
check_fail() { fail "$*"; ERRORS=$((ERRORS+1)); }
check_warn() { warn "$*"; WARNINGS=$((WARNINGS+1)); }

title "wp-starter · vérification ($(today))"

# --- 1. WordPress charge sans erreur fatale ---------------------------------
if out="$(wpc eval 'echo "ok";' 2>&1)" && [[ "$out" == "ok" ]]; then
  check_ok "WordPress charge (cœur $(wpc core version), PHP $(php -r 'echo PHP_VERSION;'))"
else
  check_fail "WordPress ne charge pas : $out"
fi

# --- 2. Intégrité du cœur ---------------------------------------------------
if (( QUICK )); then
  info "checksums du cœur : ignorés (--quick)"
elif wpc core verify-checksums --quiet 2>/dev/null; then
  check_ok "checksums du cœur conformes"
else
  check_warn "checksums du cœur : écarts détectés (voir : wp core verify-checksums)"
fi

CORE_LOCK="$(json_get "$CONFIG_DIR/stack.json" '$d["wordpress"]["version"]')"
CORE_VER="$(wpc core version)"
if [[ "$CORE_VER" == "$CORE_LOCK" ]]; then
  check_ok "cœur $CORE_VER conforme au lock"
else
  check_warn "cœur : installé $CORE_VER, lock $CORE_LOCK (lancer scripts/snapshot.sh ou update.sh)"
fi
# Le starter ne change de version que par update.sh (voir install.sh).
if [[ "$(wpc config get WP_AUTO_UPDATE_CORE 2>/dev/null || true)" == "" ]] && wpc config has WP_AUTO_UPDATE_CORE 2>/dev/null; then
  check_ok "mises à jour automatiques du cœur coupées"
else
  check_warn "mises à jour automatiques du cœur actives (wp config set WP_AUTO_UPDATE_CORE false --raw)"
fi

# --- 3. Thème ---------------------------------------------------------------
THEME_SLUG="$(json_get "$CONFIG_DIR/stack.json" '$d["theme"]["slug"]')"
ACTIVE_THEME="$(wpc theme list --status=active --field=name)"
if [[ "$ACTIVE_THEME" == "$THEME_SLUG" ]]; then
  check_ok "thème actif : $THEME_SLUG $(wpc theme get "$THEME_SLUG" --field=version)"
else
  check_fail "thème actif : $ACTIVE_THEME (attendu : $THEME_SLUG)"
fi

# --- 4. Extensions du lock --------------------------------------------------
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  name="$(plugin_field "$slug" name)"
  want_active="$(plugin_field "$slug" activate)"
  lock_ver="$(plugin_field "$slug" version)"
  if ! wpc plugin is-installed "$slug"; then
    if [[ "$(plugin_field "$slug" source)" == "zip" ]]; then
      check_warn "$name : non installé (zip absent de premium/ ?)"
    else
      check_fail "$name : non installé"
    fi
    continue
  fi
  status="$(wpc plugin get "$slug" --field=status)"
  ver="$(wpc plugin get "$slug" --field=version)"
  if [[ "$want_active" == "1" && "$status" != "active" ]]; then
    check_fail "$name $ver : $status (devrait être actif)"
  elif [[ "$ver" != "$lock_ver" ]]; then
    check_warn "$name : installé $ver, lock $lock_ver (lancer scripts/snapshot.sh ou update.sh)"
  else
    check_ok "$name $ver ($status)"
  fi
  # Cohérence zip premium ↔ lock
  if [[ "$(plugin_field "$slug" source)" == "zip" ]]; then
    zip="$(premium_zip_for "$slug")"
    if [[ -n "$zip" ]]; then
      zip_ver="$(zip_plugin_version "$zip" "$slug")"
      [[ "$zip_ver" == "$lock_ver" ]] || check_warn "$name : zip $(basename "$zip") en version $zip_ver, lock $lock_ver"
    fi
  fi
done < <(plugin_slugs)

# Extensions hors lock
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if ! grep -qx "$slug" <<<"$(plugin_slugs)"; then
    check_warn "extension hors lock : $slug (ajouter à config/plugins.json ou supprimer)"
  fi
done < <(wpc plugin list --field=name)

# --- 5. Réglages clés -------------------------------------------------------
expect_option() {
  local key="$1" want="$2" got
  got="$(wpc option get "$key" 2>/dev/null || echo '')"
  if [[ "$got" == "$want" ]]; then check_ok "$key = $want"; else check_fail "$key = « $got » (attendu « $want »)"; fi
}
expect_option permalink_structure "$(json_get "$CONFIG_DIR/settings.json" '$d["options"]["permalink_structure"]')"
expect_option timezone_string "$(json_get "$CONFIG_DIR/settings.json" '$d["options"]["timezone_string"]')"
expect_option blog_public "$(json_get "$CONFIG_DIR/settings.json" '$d["options"]["blog_public"]')"
expect_option default_comment_status "$(json_get "$CONFIG_DIR/settings.json" '$d["options"]["default_comment_status"]')"
if [[ "$(wpc option pluck disable_comments_options remove_everywhere 2>/dev/null || true)" == "1" ]]; then
  check_ok "Disable Comments activé partout"
else
  check_fail "Disable Comments n'est pas activé partout (wp eval-file scripts/php/apply-settings.php config/settings.json)"
fi
LOCALE_WANT="$(json_get "$CONFIG_DIR/settings.json" '$d["language"]["locale"]')"
LOCALE_GOT="$(wpc language core list --status=active --field=language)"
[[ "$LOCALE_GOT" == "$LOCALE_WANT" ]] && check_ok "langue $LOCALE_GOT" || check_fail "langue $LOCALE_GOT (attendu $LOCALE_WANT)"
ADMIN_LOGIN="$(json_get "$CONFIG_DIR/settings.json" '$d["admin"]["user_login"]')"
if wpc user get "$ADMIN_LOGIN" --field=ID >/dev/null 2>&1; then
  check_ok "compte $ADMIN_LOGIN présent"
  if [[ "$(wpc user meta get "$ADMIN_LOGIN" show_admin_bar_front 2>/dev/null || true)" == "false" ]]; then
    check_ok "barre d'outils masquée sur le site pour $ADMIN_LOGIN"
  else
    check_warn "barre d'outils affichée sur le site pour $ADMIN_LOGIN (wp user meta update $ADMIN_LOGIN show_admin_bar_front false)"
  fi
else
  check_warn "compte $ADMIN_LOGIN absent"
fi

# --- 6. Réponse HTTP --------------------------------------------------------
SITE_URL="${SITE_URL:-$(wpc option get home)}"
if command -v curl >/dev/null 2>&1; then
  # Page de connexion : l'adresse réelle (WPS Hide Login remplace /wp-login.php, qui répond alors 404).
  LOGIN_URL="$(wpc eval 'echo wp_login_url();' 2>/dev/null || true)"
  LOGIN_PATH="${LOGIN_URL#"$(wpc option get siteurl)"}"
  [[ "$LOGIN_PATH" == /* ]] || LOGIN_PATH="/wp-login.php"
  for path in "/" "$LOGIN_PATH"; do
    code="$(curl -sk -o /dev/null -w '%{http_code}' --max-time 20 "${SITE_URL}${path}" 2>/dev/null || true)"
    [[ -z "$code" ]] && code=000
    body="$(curl -sk --max-time 20 "${SITE_URL}${path}" 2>/dev/null || true)"
    if [[ "$code" == "200" ]] && ! grep -qi "fatal error\|There has been a critical error" <<<"$body"; then
      check_ok "HTTP $code ${SITE_URL}${path}"
    elif [[ "$code" == "000" ]]; then
      check_warn "HTTP injoignable ${SITE_URL}${path} (site arrêté dans LocalWP ?)"
    else
      check_fail "HTTP $code ${SITE_URL}${path}"
    fi
  done
fi

# --- 7. Skills Claude Code --------------------------------------------------
if compgen -G "$STARTER_ROOT/.claude/skills/*/SKILL.md" >/dev/null; then
  check_ok "skills Claude Code présents (agent-skills@$(cat "$STARTER_ROOT/.claude/skills/.agent-skills-commit" 2>/dev/null || echo '?'))"
else
  check_warn "skills Claude Code absents de .claude/skills/ (git checkout -- .claude/skills, ou scripts/setup-skills.sh)"
fi
# Copie dans app/public : c'est elle que le blueprint embarque et que Claude Code charge sur un site.
if ! compgen -G "$WP_PATH/.claude/skills/*/SKILL.md" >/dev/null; then
  check_warn "skills Claude Code absents de app/public/.claude/skills (scripts/setup-skills.sh --local)"
elif ! diff -rq -x .DS_Store "$STARTER_ROOT/.claude/skills" "$WP_PATH/.claude/skills" >/dev/null 2>&1; then
  check_warn "skills de app/public/.claude/skills différents de ceux du dépôt (scripts/setup-skills.sh --local)"
else
  check_ok "skills Claude Code copiés dans app/public/.claude/skills"
fi

# --- Bilan ------------------------------------------------------------------
echo
if (( ERRORS )); then
  fail "$ERRORS erreur(s), $WARNINGS avertissement(s)."
  exit 1
fi
ok "Aucune erreur, $WARNINGS avertissement(s)."
