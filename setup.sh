#!/usr/bin/env bash
# Setup script for the mHM QGIS workshop environment (Ubuntu/Linux and macOS).
#
# Usage:
#   bash setup.sh [--install-dir DIR] [--update] [--launcher] [--start]
#
#   --install-dir DIR  folder to install into (default: current directory, ".").
#                      Its path must not contain
#                      "Nextcloud", and it must be new, empty or a previous install.
#                      It may be this folder. Otherwise pixi.toml, the lock file,
#                      tools/ and test_domain/ are copied there and this folder
#                      is left unchanged.
#   --update           refresh an existing installation from this checkout;
#                      keep its test_domain/ and QGIS profile settings
#   --launcher         additionally create a launcher
#                      (Linux: app menu entry, macOS: app in ~/Applications)
#   --start            start QGIS after setup
#
# The environment goes to DIR/.pixi, the QGIS profile with the mHM plugin to
# DIR/qgis-profiles, and the pixi tool to ~/.pixi. Start QGIS later with:
#   cd DIR && pixi run qgis
# The system Python and any system QGIS are not touched.
# Pixi GUI is also installed if possible; a failure only produces a warning.
# Works with the bash 3.2 that ships with macOS.

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Lock file with the package versions to install. pixi only reads pixi.lock,
# so the setup copies this file there. Change it to switch to another one.
LOCK_FILE="pixi.lock"
INSTALL_DIR="."
UPDATE=false
CREATE_LAUNCHER=false
START=false

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWarning:\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --install-dir)
      case "${2:-}" in
        ""|-*) fail "--install-dir needs a folder, e.g. --install-dir ~/mhm-workshop" ;;
      esac
      INSTALL_DIR="$2"; shift ;;
    --install-dir=*)      INSTALL_DIR="${1#*=}" ;;
    --update)             UPDATE=true ;;
    --launcher|--desktop) CREATE_LAUNCHER=true ;;
    --start)              START=true ;;
    -h|--help)            sed -n '2,/^$/p' "$0"; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

# --- installation folder ------------------------------------------------------
[ -n "$INSTALL_DIR" ] \
  || fail "--install-dir needs a folder, e.g. --install-dir ~/mhm-workshop"
case "$INSTALL_DIR" in
  "~")   INSTALL_DIR="$HOME" ;;
  "~/"*) INSTALL_DIR="$HOME/${INSTALL_DIR#\~/}" ;;
esac
case "$INSTALL_DIR" in
  /*) ;;
  *)  INSTALL_DIR="$PWD/$INSTALL_DIR" ;;   # relative to the folder the script is called from
esac

not_in_nextcloud() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *nextcloud*) fail "The installation folder must not be inside Nextcloud (got: $1). Choose a local folder, e.g. ~/mhm-workshop" ;;
  esac
}
not_in_nextcloud "$INSTALL_DIR"
[ ! -e "$INSTALL_DIR" ] || [ -d "$INSTALL_DIR" ] || fail "$INSTALL_DIR is a file, not a folder"
if $UPDATE && ! grep -qs '^name = "mhm-workshop"' "$INSTALL_DIR/pixi.toml"; then
  fail "No workshop installation found in $INSTALL_DIR. Run setup without --update first, or choose the existing installation with --install-dir."
fi
# never write into a folder with other content, unless it is a previous installation
if [ -d "$INSTALL_DIR" ] && [ -n "$(ls -A "$INSTALL_DIR")" ] \
   && ! grep -qs '^name = "mhm-workshop"' "$INSTALL_DIR/pixi.toml"; then
  fail "$INSTALL_DIR is not empty and holds no previous workshop installation. Choose a new or empty folder."
fi

cd "$PROJECT_DIR"
[ -f pixi.toml ] || fail "pixi.toml not found in $PROJECT_DIR"

# --- 0. detect platform -------------------------------------------------------
OS="$(uname -s)"
ARCH="$(uname -m)"
case "$OS/$ARCH" in
  Linux/x86_64)              PLATFORM=linux-64 ;;
  Linux/aarch64)             PLATFORM=linux-aarch64 ;;
  Darwin/arm64)              PLATFORM=osx-arm64 ;;
  Darwin/x86_64)
    # An Apple Silicon Mac running this terminal under Rosetta reports x86_64
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
      warn "This terminal runs under Rosetta. Using the native Apple Silicon environment."
      PLATFORM=osx-arm64
    else
      PLATFORM=osx-64
    fi ;;
  *) fail "Unsupported system: $OS/$ARCH" ;;
esac
info "Platform: $PLATFORM"

grep -q "\"$PLATFORM\"" pixi.toml \
  || fail "Platform $PLATFORM is not listed under 'platforms' in pixi.toml. Please contact the workshop team."

# --- 1. pixi ------------------------------------------------------------------
if ! command -v pixi >/dev/null 2>&1; then
  if [ -x "$HOME/.pixi/bin/pixi" ]; then
    export PATH="$HOME/.pixi/bin:$PATH"
  else
    info "Installing pixi into ~/.pixi ..."
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL https://pixi.sh/install.sh | sh
    elif command -v wget >/dev/null 2>&1; then
      wget -qO- https://pixi.sh/install.sh | sh
    else
      fail "Neither curl nor wget found. On Ubuntu: sudo apt install curl"
    fi
    export PATH="$HOME/.pixi/bin:$PATH"
  fi
fi
info "Using $(pixi --version)"

# --- optional Pixi GUI (failure must not stop workshop setup) ------------------
info "Installing Pixi GUI ..."
if pixi global install pixi-gui \
    --channel https://prefix.dev/pixi-gui --channel https://prefix.dev/conda-forge; then
  info "Pixi GUI installed. Start it with: pixi-gui"
else
  warn "Pixi GUI could not be installed. Check the errors above (older Linux systems may have an incompatible glibc). Continuing with workshop setup; use pixi run qgis to start QGIS."
fi

# --- 2. environment -----------------------------------------------------------
mkdir -p "$INSTALL_DIR"
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"
INSTALL_REAL="$(cd "$INSTALL_DIR" && pwd -P)"
not_in_nextcloud "$INSTALL_REAL"     # also when reached through a symbolic link
if [ "$INSTALL_REAL" != "$(pwd -P)" ]; then
  info "Copying the environment files to $INSTALL_DIR ..."
  cp pixi.toml "$INSTALL_DIR/"
  for folder in tools test_domain; do
    if $UPDATE && [ "$folder" = test_domain ] && [ -d "$INSTALL_DIR/test_domain" ]; then
      continue
    fi
    if [ -d "$folder" ]; then
      mkdir -p "$INSTALL_DIR/$folder"
      cp -R "$folder/." "$INSTALL_DIR/$folder/"
    fi
  done
fi
LOCK_SOURCE="$PROJECT_DIR/$LOCK_FILE"
PLUGIN_ZIP="$INSTALL_DIR/tools/mhm_qgis.zip"
# From here on, everything happens in the installation folder
cd "$INSTALL_DIR"

if $UPDATE; then
  info "Updating the workshop environment in $INSTALL_DIR/.pixi ..."
else
  info "Installing the workshop environment into $INSTALL_DIR/.pixi (this can take a few minutes) ..."
fi
if [ -f "$LOCK_SOURCE" ]; then
  info "Using the package versions from $LOCK_FILE"
  [ "$LOCK_SOURCE" -ef pixi.lock ] || cp "$LOCK_SOURCE" pixi.lock
else
  warn "$LOCK_FILE not found, resolving the newest versions"
fi

if [ -f "$LOCK_SOURCE" ] && ! $UPDATE; then
  # Fresh installs use the supplied versions; updates may refresh a stale lock.
  pixi install --locked \
    || fail "Installing the environment failed. Please send the output above to the workshop team."
else
  pixi install \
    || fail "Installing the environment failed. Please send the output above to the workshop team."
fi

# --- 3. mHM QGIS plugin -------------------------------------------------------
PROFILE_DIR="qgis-profiles/profiles/workshop"
PLUGINS_DIR="$PROFILE_DIR/python/plugins"
if [ -f "$PLUGIN_ZIP" ]; then
  info "Installing the mHM plugin into $INSTALL_DIR/$PLUGINS_DIR ..."
  mkdir -p "$PLUGINS_DIR"
  rm -rf "$PLUGINS_DIR/mhm_qgis"     # replace any older version
  if command -v unzip >/dev/null 2>&1; then
    unzip -q -o "$PLUGIN_ZIP" -d "$PLUGINS_DIR"
  else
    # unzip is missing on some minimal systems, use Python from the environment
    pixi run python -m zipfile -e "$PLUGIN_ZIP" "$PLUGINS_DIR"
  fi
  [ -f "$PLUGINS_DIR/mhm_qgis/metadata.txt" ] \
    || fail "Plugin not found after unpacking $PLUGIN_ZIP"

  # enable the plugin in the workshop profile
  # QSettings uses the organization domain on macOS, and its name elsewhere.
  if [ "$OS" = Darwin ]; then
    INI="$PROFILE_DIR/qgis.org/QGIS4.ini"
  else
    INI="$PROFILE_DIR/QGIS/QGIS4.ini"
  fi
  mkdir -p "$(dirname "$INI")"
  touch "$INI"
  if grep -q '^mhm_qgis=' "$INI"; then
    sed 's/^mhm_qgis=.*/mhm_qgis=true/' "$INI" > "$INI.tmp" && mv "$INI.tmp" "$INI"
  elif grep -q '^\[PythonPlugins\]' "$INI"; then
    awk '{ print } /^\[PythonPlugins\]$/ { print "mhm_qgis=true" }' "$INI" > "$INI.tmp" && mv "$INI.tmp" "$INI"
  else
    printf '\n[PythonPlugins]\nmhm_qgis=true\n' >> "$INI"
  fi
else
  warn "$PLUGIN_ZIP not found, skipping plugin installation"
fi

# --- 4. clean stale bytecode in the QGIS profile ------------------------------
if [ -d qgis-profiles ]; then
  find qgis-profiles -name __pycache__ -type d -prune -exec rm -rf {} +
fi

# --- 5. checks ----------------------------------------------------------------
QGIS_BIN="$(pixi run which qgis 2>/dev/null | tail -n 1 || true)"
case "$QGIS_BIN" in
  "$INSTALL_DIR"/.pixi/*|"$INSTALL_REAL"/.pixi/*) info "QGIS found in environment: $QGIS_BIN" ;;
  *) fail "QGIS from the environment not found (got: '${QGIS_BIN:-nothing}')" ;;
esac

# --- 6. optional launcher -----------------------------------------------------
if $CREATE_LAUNCHER; then
  PIXI_BIN="$(command -v pixi)"
  APP_NAME="QGIS mHM Workshop"

  if [ "$OS" = "Linux" ]; then
    APPS_DIR="$HOME/.local/share/applications"
    mkdir -p "$APPS_DIR"
    ICON="$(find "$INSTALL_DIR/.pixi/envs/default/share/icons" -name 'qgis*.svg' 2>/dev/null | head -n 1 || true)"
    cat > "$APPS_DIR/mhm-workshop-qgis.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=QGIS with the mHM plugin from the workshop environment
Exec=bash -c 'cd "$INSTALL_DIR" && "$PIXI_BIN" run qgis'
Icon=${ICON:-qgis}
Terminal=false
Categories=Education;Science;Geography;
EOF
    command -v update-desktop-database >/dev/null 2>&1 \
      && update-desktop-database "$APPS_DIR" >/dev/null 2>&1 || true
    info "Launcher created: '$APP_NAME' in the application menu"

  else
    APP_PATH="$HOME/Applications/$APP_NAME.app"
    mkdir -p "$HOME/Applications"
    rm -rf "$APP_PATH"
    # A small AppleScript app that starts QGIS in the background via pixi
    osacompile -o "$APP_PATH" \
      -e "do shell script \"cd '$INSTALL_DIR' && '$PIXI_BIN' run qgis > /dev/null 2>&1 &\"" \
      || fail "Could not create the macOS launcher"
    info "Launcher created: ~/Applications/$APP_NAME.app"
  fi
fi

if $UPDATE; then
  info "Update complete. Start QGIS with:  cd \"$INSTALL_DIR\" && pixi run qgis"
else
  info "Setup complete. Start QGIS with:  cd \"$INSTALL_DIR\" && pixi run qgis"
fi

if $START; then
  exec pixi run qgis
fi
