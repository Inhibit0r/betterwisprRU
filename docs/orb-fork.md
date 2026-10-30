# Форк с орбом

Этот форк — BetterWispr из [opennookorg/betterwispr](https://github.com/opennookorg/betterwispr)
с двумя отличиями: в капсуле диктовки вместо полосок уровня рисуется Liquid Orb из редактора
[lersent001/orb](https://github.com/lersent001/orb) (MIT, лицензия в `Sources/LiquidOrb/LICENSE`),
а место появления капсулы выбирается в настройках.

## Где что лежит

Правки форка собраны так, чтобы релизы upstream вливались без конфликтов:

| Файл | Что делает |
|------|------------|
| `Sources/LiquidOrb/LiquidOrb.swift` | Экспорт орба «как есть» (SwiftUI + Metal-шейдер строкой). Не редактировать руками — менять через импорт. |
| `Sources/BetterWispr/Features/Recording/OrbWaveform.swift` | Переходник: уровень голоса → орб, размер, сглаживание, состояния. Сюда — все свои доработки анимации. |
| `Sources/BetterWispr/Features/Recording/CapsuleView.swift` | `OrbWaveform(...)` вместо `Waveform(...)` в `CapsuleWaveform`; размер и скругление пилюли диктовки из `OrbWaveform`; орб вместо спиннера при распознавании; подпись VoiceOver «Transcribing». |
| `Sources/BetterWispr/App/CapsulePlacement.swift` | Место появления капсулы и строка «Capsule position» в настройках; значение в UserDefaults (`fork.capsulePlacement`), схема AppSettings не меняется. |
| `Sources/BetterWispr/App/CapsuleController.swift` | Одна строка: позиция панели из `CapsulePlacement`. |
| `Sources/BetterWispr/Features/Settings/SettingsView.swift` | Две строки: `CapsulePlacementRow()` под «Floating recording capsule». |
| `Package.swift` | Модуль `LiquidOrb` (Swift 5, экспорт не рассчитан на строгую конкурентность) и зависимость от него. |
| `Resources/Info.plist` | `SUFeedURL` указывает на релизы форка: иначе Sparkle заменит сборку с орбом на оригинал. |
| `Tests/BetterWisprCoreTests/CapsulePlacementTests.swift` | Позиции капсулы: штатная по центру, углы, «над курсором» не двигается, пока капсула видна. |
| `Tests/BetterWisprCoreTests/LiquidOrbShaderTests.swift` | Компилирует шейдер орба: сломанный экспорт роняет приложение при первой диктовке, тест ловит это раньше. |
| `.github/workflows/sync-upstream.yml` | Ежедневно вливает новый релиз upstream в ветку `orb`. |
| `scripts/orb-update.sh` | Локально: показывает новое в форке, спрашивает, пересобирает и ставит в `/Applications`. |
| `scripts/orb-import.sh` | Ставит новый экспорт орба из редактора. |

Ветка `orb` — основная ветка форка. `main` форка не используется.

## Как приходят обновления BetterWispr

1. GitHub Action `sync-upstream` раз в сутки (04:23 UTC) берёт последний тег
   upstream `vX.Y.Z`, вливает его в `orb`, проверяет, что хук орба на месте и
   приложение собирается (`macos-26`), и только тогда пушит. Force push не используется.
2. Конфликт или поломка сборки → ветка `orb` не меняется, в форке открывается
   issue `sync orb vX.Y.Z: conflict|build`. Следующий удачный прогон закрывает его.
3. Локально: `scripts/orb-update.sh` — покажет новые коммиты, спросит `[y/N]`,
   соберёт release и переставит `/Applications/BetterWispr.app`.

Ручной запуск синхронизации: `gh workflow run sync-upstream -R Inhibit0r/betterwispr`
(можно `-f tag=v0.1.6`).

### Если пришёл issue о конфликте

```bash
git fetch upstream --tags
git checkout orb && git merge vX.Y.Z   # решить конфликты, сохранив строку OrbWaveform
swift build && swift test
git push origin orb
```

Обычно конфликт бывает только в тех строках, что перечислены в таблице выше.

## Как поменять орб

1. Открыть редактор по ссылке текущего орба (ниже) и настроить. Если менять ссылку в уже
   открытой вкладке, обновить страницу: редактор читает параметры только при загрузке.
2. Copy Code → вкладка SwiftUI → Copy Code.
3. `scripts/orb-import.sh` (берёт экспорт из буфера обмена; можно передать путь к файлу).
   Скрипт чинит известную ошибку экспорта (`discard_fragment()` без `metal::`
   не компилируется на macOS 26), накладывает голосовые волны и проверяет шейдер;
   при ошибке оставляет прежний орб.
4. `scripts/orb-update.sh --reinstall`, затем закоммитить и запушить `orb`.

### Голосовые волны

Текущий стиль — Prismatic Field (`spectrum`): три симметричные волны вокруг светлой
центральной линии. В экспорте редактора голос меняет только скорость и частоту волн,
не их высоту. Импорт пишет громкость в `particleDensity` (uniform 32, его читают только
Particle Ribbons), а в шейдере умножает высоту волн на `0.3 + 1.2 × громкость`: в тишине
остаётся линия, при речи волны плавно расходятся от центра вверх и вниз. Коэффициенты —
в `scripts/orb-import.sh`, после правки перезапустить импорт с файлом экспорта.
Правка завязана на имя `amplitude_2` из сгенерированного Metal: если редактор его сменит,
импорт остановится с сообщением, какой патч не лёг. Для других стилей голос идёт только
штатным маппингом редактора.

### Размер и поведение

`OrbWaveform.swift`: `diameter` (72 pt; пилюля диктовки растёт под орб — `pillHeight`,
`pillExtraWidth`), скорость сглаживания `LevelSmoothing` (подъём 0.3, спад 0.1 за кадр),
состояния (запись — `thinking` с громкостью, ожидание микрофона и распознавание — `idle`).
У notetaker орб компактный (40 pt), его пилюля не меняется. С Reduce Motion или без Metal —
штатные полоски и размеры.

### Место появления

Settings → App → «Capsule position»: снизу по центру (как в upstream), снизу слева,
снизу справа, над указателем мыши. «Над указателем» выбирается в момент появления капсулы
и не следует за мышью, пока капсула видна. Чтобы капсула не висела в покое, выключить
«Floating recording capsule» — тогда она появляется только на время диктовки и созвона.

Текущий орб (Prismatic Field):
<https://lersent001.github.io/orb/#effect=orb-glass-liquid&style=spectrum&glass=1&state=thinking&activation=0.22&transition=0.65&preview=scene&text=Thinking...&speed=1.8&idleSpeed=0.48600000000000004&radius=0.72&contourDeform=0.03&idleContourDeform=0.009&zoom=0.46&idleZoom=0.4232&warp=4.4&idleWarp=1.9360000000000002&ridgeAmt=0.72&idleRidgeAmt=0.2736&sharp=2.2&idleSharp=2.2&bandDensity=2&idleBandDensity=2&metalDepth=0.25&idleMetalDepth=0.25&metalRoughness=0.22&idleMetalRoughness=0.22&chromaticShift=0.42&idleChromaticShift=0.42&metalScale=0.77&metalStretch=0.23&idleMetalStretch=0.23&metalAngle=65&metalOffset=0&metalPhase=0&metalEvolution=1&idleMetalEvolution=1&particleDensity=0.72&ribbonCount=5&ribbonWidth=0.42&idleRibbonWidth=0.42&ribbonTwist=1.25&idleRibbonTwist=1.25&ribbonFold=0.55&idleRibbonFold=0.55&ribbonBreath=0.3&idleRibbonBreath=0.3&particleSize=1.2&particleBloom=0.7&shade=0.06&idleShade=0.06&exposure=1.5&idleExposure=0.9299999999999999&sheen=0.26&gloss=0.24&glassOpacity=0.4&shellMidAlpha=0.18&shellEdgeAlpha=0.18&edgeSoftness=0.005&edgeGlow=0&idleEdgeGlow=0&colorA=%23FFFFFF&idleColorA=%23B4BBC2&colorB=%231677FF&idleColorB=%23285D8F&colorC=%23F249A0&idleColorC=%2391506F&colorD=%2335E6B2&idleColorD=%233F8873&highlightColor=%23FFFFFF&idleHighlightColor=%23D8DDE1&shellInner=%23FFFFFF&shellMid=%2366E8FF&shellEdge=%23D26CFF&sheenColor=%23EAF4FF&specColor=%23DCEAFF&canvasColor=%2303040A&glowColor=%231677FF&idleGlowColor=%23386789>

## Ограничения

- Сборка подписывается ad-hoc. Подпись сертификатом Apple Development (30.10.2026) Gatekeeper
  после онлайн-проверки отправил в Корзину как «вредоносное ПО»; ad-hoc запускается. Цена:
  после каждой пересборки macOS снимает разрешение Accessibility — включить BetterWispr заново в
  «Системные настройки → Конфиденциальность и безопасность → Универсальный доступ».
  Другую подпись можно задать через `CODESIGN_IDENTITY`.
- Шейдер компилируется при первом показе орба (~150 мс на Apple Silicon), дальше берётся из кэша Metal.
- `VoiceLevels` даёт один общий уровень, поэтому все полосы орба (low/mid/high) получают его.
- «Над указателем» — это курсор мыши, не текстовая каретка.
