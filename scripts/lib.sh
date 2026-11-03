#!/usr/bin/env bash
# Bibliothèque commune des scripts wp-starter. À sourcer, pas à exécuter.
# Conçu pour le « Open site shell » de LocalWP (macOS) : `wp` et `php` sont dans le PATH.

set -euo pipefail

# ----------------------------------------------------------------------------
# Chemins
# ----------------------------------------------------------------------------
STARTER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$STARTER_ROOT/config"
SCRIPTS_DIR="$STARTER_ROOT/scripts"
PREMIUM_DIR="$STARTER_ROOT/premium"
REPORTS_DIR="$STARTER_ROOT/reports"
mkdir -p "$REPORTS_DIR"

# Un WP_PATH déjà exporté par l'appelant (ex. new-site.sh) a priorité sur .env
PRESET_WP_PATH="${WP_PATH:-}"

# .env (optionnel)
if [[ -f "$STARTER_ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  set -a; source "$STARTER_ROOT/.env"; set +a
fi
ENV_WP_PATH="${WP_PATH:-}"

# Chemin du WordPress, dans l'ordre :
#   1. WP_PATH exporté par l'appelant (absolu ou relatif au répertoire courant)
#   2. WP_PATH du .env (relatif à la racine du dépôt)
#   3. ../app/public (dépôt cloné dans ~/Local Sites/wp-starter/starter/)
resolve_wp_path() {
  local candidate base
  for spec in "preset" "env" "default"; do
    case "$spec" in
      preset)  candidate="$PRESET_WP_PATH"; base="$PWD" ;;
      env)     candidate="$ENV_WP_PATH";    base="$STARTER_ROOT" ;;
      default) candidate="../app/public";   base="$STARTER_ROOT" ;;
    esac
    [[ -z "$candidate" ]] && continue
    [[ "$candidate" = /* ]] || candidate="$base/$candidate"
    if [[ -f "$candidate/wp-load.php" ]]; then
      (cd "$candidate" && pwd)
      return 0
    fi
  done
  return 1
}

WP_PATH="$(resolve_wp_path)" || {
  STARTER_PARENT="$(dirname "$STARTER_ROOT")"
  if [[ "$(basename "$STARTER_PARENT")" == "app" && -f "$STARTER_PARENT/public/wp-load.php" ]]; then
    {
      echo "✗ WordPress introuvable : le dépôt est dans app/, il doit être à côté. Pour le déplacer :"
      printf '  cd %q && mv app/%q starter && cd starter\n' "$(dirname "$STARTER_PARENT")" "$(basename "$STARTER_ROOT")"
    } >&2
  else
    {
      echo "✗ WordPress introuvable dans $STARTER_PARENT/app/public."
      echo "  Cloner le dépôt à côté de app/, ou définir WP_PATH dans .env (chemin absolu, ou relatif à la racine du dépôt)."
    } >&2
  fi
  exit 1
}
export WP_PATH

# ----------------------------------------------------------------------------
# Sortie
# ----------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_BLUE=""
fi
info()  { echo "${C_BLUE}▸${C_RESET} $*"; }
ok()    { echo "${C_GREEN}✓${C_RESET} $*"; }
warn()  { echo "${C_YELLOW}!${C_RESET} $*"; }
fail()  { echo "${C_RED}✗${C_RESET} $*" >&2; }
title() { echo; echo "${C_BOLD}== $* ==${C_RESET}"; }
die()   { fail "$@"; exit 1; }

# ----------------------------------------------------------------------------
# Outils
# ----------------------------------------------------------------------------
require_cmd() {
  local c
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || die "Commande requise introuvable : $c (lancer depuis « Open site shell » de LocalWP)."
  done
}

# « Open site shell » met le PHP de LocalWP dans le PATH, puis lance le shell de
# l'utilisateur : son ~/.zshrc peut remettre un autre PHP devant (Herd, Homebrew…).
# On redonne la priorité au PHP de LocalWP s'il est présent dans le PATH.
prefer_localwp_php() {
  local dir IFS=:
  for dir in $PATH; do
    case "$dir" in
      */Local/lightning-services/php-*/bin/*) PATH="$dir:$PATH"; export PATH; return 0 ;;
    esac
  done
}

# Tout message PHP écrit sur la sortie standard corromprait les valeurs lues par
# les scripts (locale, slugs, versions) : on s'arrête avant de toucher au site.
require_clean_php() {
  [[ "$(php -r 'echo "ok";' 2>/dev/null)" == "ok" ]] \
    || die "PHP affiche des messages parasites ($(command -v php)). Lancer depuis « Open site shell » de LocalWP et vérifier : php -v."
}

prefer_localwp_php
require_cmd wp php
require_clean_php

# Wrapper WP-CLI : toujours sur le bon site, sans couleurs ni interactions.
wpc() { wp --path="$WP_PATH" --no-color "$@"; }

# ----------------------------------------------------------------------------
# JSON (via PHP, pour éviter une dépendance à jq)
# ----------------------------------------------------------------------------
# json_get <fichier> <expression PHP sur $d>   ex. json_get plugins.json '$d["plugins"][0]["slug"]'
json_get() {
  local file="$1" expr="$2"
  php -r '$d = json_decode(file_get_contents($argv[1]), true); $v = eval("return " . $argv[2] . ";"); echo is_scalar($v) || $v === null ? (string)$v : json_encode($v, JSON_UNESCAPED_SLASHES|JSON_UNESCAPED_UNICODE);' "$file" "$expr"
}

# Liste des slugs de plugins, un par ligne, optionnellement filtrée par source (wporg|zip)
plugin_slugs() {
  local source="${1:-}"
  php -r '$d = json_decode(file_get_contents($argv[1]), true); foreach ($d["plugins"] as $p) { if ($argv[2] === "" || $p["source"] === $argv[2]) echo $p["slug"], "\n"; }' "$CONFIG_DIR/plugins.json" "$source"
}

# Champ d'un plugin : plugin_field <slug> <champ>
plugin_field() {
  php -r '$d = json_decode(file_get_contents($argv[1]), true); foreach ($d["plugins"] as $p) { if ($p["slug"] === $argv[2]) { $v = $p[$argv[3]] ?? ""; echo is_array($v) ? implode(",", $v) : (is_bool($v) ? ($v ? "1" : "0") : $v); break; } }' "$CONFIG_DIR/plugins.json" "$1" "$2"
}

# version_gt <a> <b> : vrai si a est plus récent que b
version_gt() {
  php -r 'exit(version_compare($argv[1], $argv[2], ">") ? 0 : 1);' "$1" "$2"
}

# Version de l'extension <slug> dans un zip, lue dans l'en-tête de son fichier
# principal (chaîne vide si ce zip ne contient pas cette extension).
zip_plugin_version() {
  local zip="$1" slug="$2" entry version=""
  while IFS= read -r entry; do
    version="$(unzip -p "$zip" "$entry" 2>/dev/null | awk '
      /Plugin Name:/ { found = 1 }
      /^[ \t\/*#@]*Version:/ && !v { v = $0; sub(/^[^:]*:[ \t]*/, "", v); sub(/[ \t\r]*$/, "", v) }
      END { if (found && v) print v }' || true)"
    [[ -n "$version" ]] && break
  done < <(unzip -Z1 "$zip" 2>/dev/null | grep -E "^$slug/[^/]+\.php$" || true)
  echo "$version"
}

# Zip le plus récent de l'extension <slug> dans premium/ (chaîne vide si absent).
# Le nom du fichier n'a aucune importance : seul le contenu du zip compte.
premium_zip_for() {
  local slug="$1" zip version best="" best_version=""
  for zip in "$PREMIUM_DIR"/*.zip; do
    [[ -f "$zip" ]] || continue
    version="$(zip_plugin_version "$zip" "$slug")"
    [[ -n "$version" ]] || continue
    if [[ -z "$best" ]] || version_gt "$version" "$best_version"; then
      best="$zip"; best_version="$version"
    fi
  done
  echo "$best"
}

# Génération d'un mot de passe fort (24 caractères)
gen_password() {
  php -r '$a = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%^*_+="; $o = ""; for ($i = 0; $i < 24; $i++) { $o .= $a[random_int(0, strlen($a) - 1)]; } echo $o;'
}

today() { date +%Y-%m-%d; }
