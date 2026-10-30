#!/bin/bash
# Fork: prints the idle/thinking uniform seeds of an orb editor SwiftUI export as a Swift tuple for OrbStyleSeeds.swift.
# Usage: scripts/orb-seeds.sh <export.swift>   (Copy Code → SwiftUI in https://lersent001.github.io/orb)
set -euo pipefail
[[ $# == 1 && -f "$1" ]] || { echo 'Usage: scripts/orb-seeds.sh <export.swift>' >&2; exit 2; }
seed() { awk -v name="orb$1UniformSeed" '$0 ~ "private let " name { on = 1; next } on && /^\]/ { exit } on { print }' "$2" | tr -d ' \n' | sed 's/,$//'; }
idle="$(seed Idle "$1")"; thinking="$(seed Thinking "$1")"
[[ -n "$idle" && -n "$thinking" ]] || { echo 'В файле нет orbIdleUniformSeed/orbThinkingUniformSeed.' >&2; exit 1; }
printf '(\n        idle: [%s],\n        thinking: [%s]\n    )\n' "$idle" "$thinking"
