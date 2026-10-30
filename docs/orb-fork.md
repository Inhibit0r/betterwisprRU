# Форк с орбом

Этот форк — BetterWispr из [opennookorg/betterwispr](https://github.com/opennookorg/betterwispr)
с одним отличием: в капсуле диктовки вместо полосок уровня рисуется Liquid Orb
из редактора [lersent001/orb](https://github.com/lersent001/orb) (MIT, лицензия в
`Sources/LiquidOrb/LICENSE`).

## Где что лежит

Правки форка собраны так, чтобы релизы upstream вливались без конфликтов:

| Файл | Что делает |
|------|------------|
| `Sources/LiquidOrb/LiquidOrb.swift` | Экспорт орба «как есть» (SwiftUI + Metal-шейдер строкой). Не редактировать руками — менять через импорт. |
| `Sources/BetterWispr/Features/Recording/OrbWaveform.swift` | Переходник: уровень голоса → орб, размер, сглаживание, состояния. Сюда — все свои доработки анимации. |
| `Sources/BetterWispr/Features/Recording/CapsuleView.swift` | Одна строка: `OrbWaveform(...)` вместо `Waveform(...)` в `CapsuleWaveform`. |
| `Package.swift` | Модуль `LiquidOrb` (Swift 5, экспорт не рассчитан на строгую конкурентность) и зависимость от него. |
| `Resources/Info.plist` | `SUFeedURL` указывает на релизы форка: иначе Sparkle заменит сборку с орбом на оригинал. |
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

1. Открыть редактор, настроить орб (ссылка текущего орба — ниже).
2. Copy Code → вкладка SwiftUI → Copy Code.
3. `scripts/orb-import.sh` (берёт экспорт из буфера обмена; можно передать путь к файлу).
   Скрипт чинит известную ошибку экспорта (`discard_fragment()` без `metal::`
   не компилируется на macOS 26), накладывает «голосовую» мембрану и проверяет шейдер;
   при ошибке оставляет прежний орб.

### Голосовая мембрана

В экспорте редактора голос почти не двигает центральную полосу Voice Membrane
(+6% размаха). Импорт накладывает три правки: громкость пишется в `particleDensity`
(uniform 32, его читают только Particle Ribbons), в шейдере она добавляет размах
полосы (`× 0.3`) и речевую рябь (`× 0.07`, частота 11, скорость 7). Коэффициенты —
в `scripts/orb-import.sh`; после правки перезапустить импорт с файлом экспорта.
Правки завязаны на имена из сгенерированного Metal (`amplitude_4`, `mainY_2`):
если редактор их сменит, импорт остановится с сообщением, какой патч не лёг.
Для другого стиля орба голос идёт только штатным маппингом редактора.
4. `scripts/orb-update.sh --reinstall`, затем закоммитить и запушить `orb`.

Размер, реакция на голос и состояния — в `OrbWaveform.swift`: `diameter`,
коэффициенты `LevelSmoothing`, сопоставление `Waveform.Mode` → `LiquidOrbState`
(запись — `thinking` с громкостью, ожидание микрофона — `idle`).

Текущий орб (Voice Membrane):
<https://lersent001.github.io/orb/#effect=orb-glass-liquid&style=voiceWave&glass=1&state=thinking&activation=0.22&transition=0.65&preview=orb&text=Thinking...&speed=1.3&idleSpeed=0.266&radius=0.7&contourDeform=0.1&idleContourDeform=0.03&zoom=0.36&idleZoom=0.3312&warp=2.6&idleWarp=1.1960000000000002&ridgeAmt=0.46&idleRidgeAmt=0.1932&sharp=2.2&idleSharp=2.2&bandDensity=2&idleBandDensity=2&metalDepth=0.25&idleMetalDepth=0.25&metalRoughness=0.22&idleMetalRoughness=0.22&chromaticShift=0.42&idleChromaticShift=0.42&metalScale=0.77&metalStretch=0.23&idleMetalStretch=0.23&metalAngle=65&metalOffset=0&metalPhase=0&metalEvolution=1&idleMetalEvolution=1&particleDensity=0.72&ribbonCount=5&ribbonWidth=0.42&idleRibbonWidth=0.42&ribbonTwist=1.25&idleRibbonTwist=1.25&ribbonFold=0.55&idleRibbonFold=0.55&ribbonBreath=0.3&idleRibbonBreath=0.3&particleSize=1.2&particleBloom=0.7&shade=0.08&idleShade=0.08&exposure=1.35&idleExposure=0.8370000000000001&sheen=0.22&gloss=0.36&glassOpacity=0.48&shellMidAlpha=0.18&shellEdgeAlpha=0.2&edgeSoftness=0.005&edgeGlow=0&idleEdgeGlow=0&colorA=%2309030E&idleColorA=%2308050B&colorB=%23CE2CCB&idleColorB=%236A2F69&colorC=%23FF5C71&idleColorC=%238C4652&colorD=%237B53FF&idleColorD=%2355467F&highlightColor=%23FFD9F0&idleHighlightColor=%23B58AA5&shellInner=%23FFFFFF&shellMid=%23E48BFF&shellEdge=%23FF7890&sheenColor=%23FFF1FA&specColor=%23E7D9FF&canvasColor=%23020105&glowColor=%23CE2CCB&idleGlowColor=%236C3E72>

## Ограничения

- Сборка подписывается ad-hoc. Подпись сертификатом Apple Development (30.10.2026) Gatekeeper
  после онлайн-проверки отправил в Корзину как «вредоносное ПО»; ad-hoc запускается. Цена:
  после каждой пересборки macOS снимает разрешение Accessibility — включить BetterWispr заново в
  «Системные настройки → Конфиденциальность и безопасность → Универсальный доступ».
  Другую подпись можно задать через `CODESIGN_IDENTITY`.
- Шейдер компилируется при первом показе орба (~150 мс на Apple Silicon), дальше берётся из кэша Metal.
- `VoiceLevels` даёт один общий уровень, поэтому все полосы орба (low/mid/high) получают его.
- При распознавании капсула по-прежнему показывает штатный индикатор, орб — только во время записи и у notetaker.
