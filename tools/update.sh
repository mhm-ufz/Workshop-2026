#!/usr/bin/env bash
# Update this workshop folder to the latest version on GitHub (Linux and macOS).
# Run it with:  pixi run update
#
# Downloads the main branch ZIP and runs its setup.sh --update on this folder,
# which keeps test_domain/ and the QGIS profile settings. A Git clone is
# updated with git pull --ff-only instead.

# setup.sh overwrites this file while it runs, so bash must read it in full first.
{
set -euo pipefail

URL="${WORKSHOP_ZIP_URL:-https://github.com/mhm-ufz/Workshop-2026/archive/refs/heads/main.zip}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -d "$ROOT/.git" ]; then
  printf '\033[1;34m==>\033[0m %s\n' "Git clone found, pulling the latest changes ..."
  git -C "$ROOT" pull --ff-only
  bash "$ROOT/setup.sh" --update --install-dir "$ROOT"
  exit
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/mhm-workshop-update.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

printf '\033[1;34m==>\033[0m %s\n' "Downloading $URL ..."
if command -v curl >/dev/null 2>&1; then
  curl -fsSL -o "$TMP/workshop.zip" "$URL"
else
  wget -qO "$TMP/workshop.zip" "$URL"
fi
if command -v unzip >/dev/null 2>&1; then
  unzip -q "$TMP/workshop.zip" -d "$TMP/src"
else
  python -I -m zipfile -e "$TMP/workshop.zip" "$TMP/src"
fi

SRC="$(echo "$TMP"/src/*/)"   # the ZIP holds a single top folder
if [ ! -f "$SRC/setup.sh" ] || [ ! -f "$SRC/pixi.toml" ]; then
  printf '\033[1;31mError:\033[0m %s\n' "The downloaded ZIP has no workshop files. Please contact the workshop team." >&2
  exit 1
fi

bash "$SRC/setup.sh" --update --install-dir "$ROOT"
exit
}
