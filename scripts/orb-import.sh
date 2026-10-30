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

# Voice-driven membrane (Voice Membrane preset): the editor's audio mapping barely bends the band,
# so the voice level rides in particleDensity (read only by Particle Ribbons) and drives the band's swing and ripple.
patch() {
    local description="$1" expression="$2"
    local before; before="$(shasum < "$export_file")"
    perl -0pi -e "$expression" "$export_file"
    [[ "$(shasum < "$export_file")" != "$before" ]] || { echo "Не лёг патч голоса: $description. Экспорт изменился — поправьте scripts/orb-import.sh." >&2; exit 1; }
}
patch 'размах полосы' 's/(float amplitude_4 = 0\.2 \+ \(_e24 \* 0\.018\))(;)/$1 + u.particleDensity * 0.3$2/'
patch 'речевая рябь' 's/(\n    float mainY_2 = [^\n]*;\n)/$1    mainY_2 += rimEnvelope * u.particleDensity * 0.07 * metal::sin((q_9.x * 11.0) - (t_12 * 7.0));\n/'
patch 'громкость в particleDensity' 's/(\n    func level\(_ value: Float\) -> Float \{[^\n]*\}\n)/$1    values[32] = level(bands.all)\n/'

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
