#!/bin/bash
# Fork: offers the main branch that sync-upstream advanced, then rebuilds and reinstalls BetterWispr.
set -euo pipefail
cd "$(dirname "$0")/.."
git fetch --quiet origin main
news="$(git log --oneline --no-merges HEAD..origin/main)"
if [[ -z "$news" && "${1:-}" != --reinstall ]]; then
    echo "Форк актуален: BetterWispr $(tr -d '[:space:]' < VERSION) с орбом. Пересобрать без обновления: $0 --reinstall"
    exit 0
fi
if [[ -n "$news" ]]; then
    echo "Новое в форке:"
    echo "$news"
    read -r -p "Обновить и переустановить BetterWispr? [y/N] " answer
    [[ "$answer" == [yY]* ]] || exit 0
    git merge --no-edit origin/main
fi
# The fork's self-signed certificate keeps macOS permissions across rebuilds (ad-hoc loses them each time).
# Not the Apple Development identity: Gatekeeper moved builds signed with it to the Trash as malware.
kc=~/.config/betterwispr-signing/signing.keychain-db
if [[ -z "${CODESIGN_IDENTITY:-}" && -f "$kc" ]]; then
    security unlock-keychain -p "$(security find-generic-password -a betterwispr -s betterwispr-signing-p12 -w)" "$kc"
    CODESIGN_IDENTITY="BetterWisprRU Code Signing"
fi
app="$(CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}" ./scripts/build-app.sh release | tail -1)"
pkill -x BetterWispr 2>/dev/null || true
sleep 1
rm -rf /Applications/BetterWispr.app
ditto "$app" /Applications/BetterWispr.app
open /Applications/BetterWispr.app
echo "Установлено: /Applications/BetterWispr.app ($(tr -d '[:space:]' < VERSION))"
