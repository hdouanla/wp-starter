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
  echo "✗ WordPress introuvable. Définir WP_PATH dans .env (ex. WP_PATH=../app/public)." >&2
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
require_cmd wp php

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

# Zip premium le plus récent pour un slug (chaîne vide si absent)
premium_zip_for() {
  local glob
  glob="$(plugin_field "$1" zip_glob)"
  [[ -z "$glob" ]] && return 0
  # shellcheck disable=SC2086
  ls -1 "$PREMIUM_DIR"/$glob 2>/dev/null | sort -V | tail -n 1 || true
}

# Génération d'un mot de passe fort (24 caractères)
gen_password() {
  php -r '$a = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#%^*_+="; $o = ""; for ($i = 0; $i < 24; $i++) { $o .= $a[random_int(0, strlen($a) - 1)]; } echo $o;'
}

today() { date +%Y-%m-%d; }
