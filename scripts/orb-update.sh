#!/bin/bash
# Fork: offers the orb branch that sync-upstream advanced, then rebuilds and reinstalls BetterWispr.
set -euo pipefail
cd "$(dirname "$0")/.."
git fetch --quiet origin orb
news="$(git log --oneline --no-merges HEAD..origin/orb)"
if [[ -z "$news" && "${1:-}" != --reinstall ]]; then
    echo "Форк актуален: BetterWispr $(tr -d '[:space:]' < VERSION) с орбом. Пересобрать без обновления: $0 --reinstall"
    exit 0
fi
if [[ -n "$news" ]]; then
    echo "Новое в форке:"
    echo "$news"
    read -r -p "Обновить и переустановить BetterWispr? [y/N] " answer
    [[ "$answer" == [yY]* ]] || exit 0
    git merge --no-edit origin/orb
fi
app="$(./scripts/build-app.sh release | tail -1)"
pkill -x BetterWispr 2>/dev/null || true
sleep 1
rm -rf /Applications/BetterWispr.app
ditto "$app" /Applications/BetterWispr.app
open /Applications/BetterWispr.app
echo "Установлено: /Applications/BetterWispr.app ($(tr -d '[:space:]' < VERSION))"
