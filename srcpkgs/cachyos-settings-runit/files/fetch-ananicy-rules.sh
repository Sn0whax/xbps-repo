#!/bin/sh
# fetch-ananicy-rules.sh — pull CachyOS's ananicy-cpp rule DB into /etc/ananicy.d/
# The runit ananicy-cpp service does almost nothing without these rules.
# Source: https://github.com/CachyOS/ananicy-rules  (GPL-3.0)
# Run as root:  sudo sh fetch-ananicy-rules.sh
set -eu

REPO="https://github.com/CachyOS/ananicy-rules.git"
DEST="/etc/ananicy.d"
TMP="$(mktemp -d)"
say() { printf '\033[1;36m::\033[0m %s\n' "$1"; }
trap 'rm -rf "$TMP"' EXIT

command -v git >/dev/null 2>&1 || { echo "git required: install it first."; exit 1; }

say "Cloning CachyOS ananicy-rules (shallow)..."
git clone --depth=1 "$REPO" "$TMP/rules" >/dev/null 2>&1

say "Installing rules -> $DEST/"
install -d "$DEST"
# The repo ships: ananicy.conf, 00-types.types, 00-cgroups.cgroups, and the
# 00-default/ rules tree. ananicy-cpp reads *.rules/*.types/*.cgroups here.
cp -a "$TMP/rules/ananicy.conf"        "$DEST/" 2>/dev/null || true
cp -a "$TMP/rules/00-types.types"      "$DEST/" 2>/dev/null || true
cp -a "$TMP/rules/00-cgroups.cgroups"  "$DEST/" 2>/dev/null || true
cp -a "$TMP/rules/00-default"          "$DEST/" 2>/dev/null || true

count=$(find "$DEST" -name '*.rules' 2>/dev/null | wc -l)
say "Installed rule files. *.rules count: $count"
say "Restart the daemon:  sudo sv restart ananicy-cpp   (or reload with: ananicy-cpp reload)"
