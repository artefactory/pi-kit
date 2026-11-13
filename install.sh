#!/bin/sh
# Artefactory pi kickstarter. Idempotent: safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/artefactory/pi-kit/main/install.sh | sh
#   or: ./install.sh [--dry-run]
#
# 1. Installs pi if missing (npm global)
# 2. Installs the pi packages listed in packages.txt + this kit itself
# 3. Merges defaults.json into ~/.pi/agent/settings.json (existing keys win)
set -eu

KIT_REPO="artefactory/pi-kit"
KIT_SOURCE="git:git@github.com:${KIT_REPO}"
KIT_RAW="https://raw.githubusercontent.com/${KIT_REPO}/main"
PI_PKG="@earendil-works/pi-coding-agent"
SETTINGS_DIR="${HOME}/.pi/agent"
SETTINGS="${SETTINGS_DIR}/settings.json"

dry_run=false
[ "${1:-}" = "--dry-run" ] && dry_run=true

log() { printf '\033[1;34m[pi-kit]\033[0m %s\n' "$*" >&2; }
run() { if [ "$dry_run" = true ]; then log "(dry-run) $*"; else "$@"; fi; }
need() { command -v "$1" >/dev/null 2>&1 || { log "missing required tool: $1"; exit 1; }; }

# Resolve kit files: local checkout if run from the repo, else fetch from GitHub.
script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd || true)"
if [ -n "$script_dir" ] && [ -f "${script_dir}/packages.txt" ]; then
  kit_dir="$script_dir"
else
  kit_dir="$(mktemp -d)"
  need curl
  for f in packages.txt defaults.json; do
    curl -fsSL "${KIT_RAW}/${f}" -o "${kit_dir}/${f}"
  done
fi

need git
need jq

# SSH access to GitHub is required for private packages.
if ! ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
  log "GitHub SSH access is not configured (ssh -T git@github.com failed)."
  log "Private packages need it: https://docs.github.com/en/authentication/connecting-to-github-with-ssh"
  exit 1
fi

# 1. pi
if command -v pi >/dev/null 2>&1; then
  log "pi already installed ($(pi --version))"
else
  need npm
  log "installing pi"
  run npm install -g "$PI_PKG"
fi

# 2. packages
mkdir -p "$SETTINGS_DIR"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
installed="$(jq -r '.packages[]? | if type=="object" then .source else . end' "$SETTINGS")"
grep -v '^[[:space:]]*#' "${kit_dir}/packages.txt" | grep -v '^[[:space:]]*$' | while IFS= read -r src; do
  if printf '%s\n' "$installed" | grep -qxF "$src"; then
    log "already configured: $src"
  else
    log "installing $src"
    run pi install "$src"
  fi
done
if printf '%s\n' "$installed" | grep -qxF "$KIT_SOURCE"; then
  log "already configured: $KIT_SOURCE"
else
  log "installing $KIT_SOURCE"
  run pi install "$KIT_SOURCE"
fi

# 3. settings: defaults.json * existing -> existing keys win, missing keys are added.
if [ "$dry_run" = true ]; then
  log "(dry-run) would merge defaults into $SETTINGS:"
  jq -s '.[0] * .[1]' "${kit_dir}/defaults.json" "$SETTINGS" >&2
else
  tmp="$(mktemp)"
  jq -s '.[0] * .[1]' "${kit_dir}/defaults.json" "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  log "settings merged into $SETTINGS"
fi

log "done. Run \`pi\` to start, \`pi update --extensions\` to update packages."
