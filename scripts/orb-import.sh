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

# Voice-driven waves (Prismatic Field geometry; Violet Field and Siri Wave are its palettes): the editor's audio mapping never changes the wave
# height, so the voice level rides in particleDensity (read only by Particle Ribbons) and opens the waves from the centre line.
patch() {
    local description="$1" expression="$2"
    local before; before="$(shasum < "$export_file")"
    perl -0pi -e "$expression" "$export_file"
    [[ "$(shasum < "$export_file")" != "$before" ]] || { echo "Не лёг патч: $description. Экспорт изменился — поправьте scripts/orb-import.sh." >&2; exit 1; }
}
patch 'Prismatic Field: высота волн от голоса' 's/float amplitude_2 = 0\.26 \+ \(_e13 \* 0\.27\);/float amplitude_2 = (0.26 + (_e13 * 0.27)) * (0.3 + 1.2 * u.particleDensity);/'
patch 'громкость в particleDensity' 's/(\n    func level\(_ value: Float\) -> Float \{[^\n]*\}\n)/$1    values[32] = level(bands.all)\n/'
# Styles and colours chosen in Settings → Orb replace the baked seeds; the voice level is read per frame
# instead of through a SwiftUI update per frame (Sources/LiquidOrb/LiquidOrbHooks.swift).
patch 'подмена параметров стиля' 's/(\nprivate func orbUniformSeed\(for state: LiquidOrbState\) -> \[Float\] \{\n)    switch state \{\n/$1    if let seeds = LiquidOrbSeeds.current { return state == .idle ? seeds.idle : seeds.thinking }\n    return switch state {\n/'
patch 'громкость читается при отрисовке' 's/\n        applyOrbAudio\(&uniforms, audio\)\n/\n        applyOrbAudio(&uniforms, LiquidOrbAudioSource.current?() ?? audio)\n/'

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
