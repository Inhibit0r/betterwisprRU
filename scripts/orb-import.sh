#!/bin/bash
# Fork: installs a SwiftUI export from https://lersent001.github.io/orb (Copy Code → SwiftUI) as the capsule orb.
# Without an argument the export is read from the clipboard.
set -euo pipefail
cd "$(dirname "$0")/.."
target=Sources/LiquidOrb/LiquidOrb.swift
export_file="$(mktemp)"
trap 'rm -f "$export_file"' EXIT
if [[ $# -gt 0 ]]; then cp "$1" "$export_file"; else pbpaste > "$export_file"; fi
grep -q 'public struct LiquidOrbView' "$export_file" || { echo 'Это не SwiftUI-экспорт орба: нет LiquidOrbView.' >&2; exit 1; }
# The editor's Metal export calls discard_fragment() unqualified; current Metal compilers reject it.
sed -i '' -E 's/([^:])discard_fragment\(\)/\1metal::discard_fragment()/' "$export_file"
cp "$target" "$target.bak"
cp "$export_file" "$target"
if swift test --disable-keychain --filter liquidOrbShaderCompiles 2>&1 | tail -3; then
    rm "$target.bak"
    echo "Орб обновлён. Установить: scripts/orb-update.sh --reinstall"
else
    mv "$target.bak" "$target"
    echo 'Шейдер нового экспорта не компилируется, оставлен прежний орб.' >&2
    exit 1
fi
