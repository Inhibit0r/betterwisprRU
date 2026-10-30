# Форк с орбом

Этот форк — BetterWispr из [opennookorg/betterwispr](https://github.com/opennookorg/betterwispr)
с двумя отличиями: в капсуле диктовки вместо полосок уровня рисуется Liquid Orb из редактора
[lersent001/orb](https://github.com/lersent001/orb) (MIT, лицензия в `Sources/LiquidOrb/LICENSE`),
а место появления капсулы выбирается в настройках.

## Где что лежит

Правки форка собраны так, чтобы релизы upstream вливались без конфликтов:

| Файл | Что делает |
|------|------------|
| `Sources/LiquidOrb/LiquidOrb.swift` | Экспорт орба (SwiftUI + Metal-шейдер строкой) с правками импорта. Не редактировать руками — менять через импорт. |
| `Sources/LiquidOrb/LiquidOrbHooks.swift` | Точки подмены в экспорте: параметры стиля (стиль и цвета без нового экспорта) и источник громкости, который орб читает на каждом кадре. |
| `Sources/BetterWispr/Features/Recording/OrbStyleSeeds.swift` | Параметры стилей из выгрузок редактора (генерирует `scripts/orb-seeds.sh`). |
| `Sources/BetterWispr/Features/Recording/OrbAppearance.swift` | Стили и кастомизация орба: размер, чувствительность, скорость, стекло, цвета волн; UserDefaults `fork.orb.*`. |
| `Sources/BetterWispr/Features/Customize/CustomizeView.swift` | Вкладка «Customize»: превью капсулы, выбор визуализации (штатные полоски или орб), настройки орба, положение капсулы. |
| `Sources/BetterWispr/Features/Dashboard/DashboardView.swift` | Страница `customize` в группе App: отдельный `case` вне общего списка, иконка, маршрут на `CustomizeView`. |
| `Sources/BetterWispr/Features/Recording/OrbWaveform.swift` | Переходник: уровень голоса → орб, размер, сглаживание, состояния. Сюда — все свои доработки анимации. |
| `Sources/BetterWispr/Features/Recording/CapsuleView.swift` | `OrbWaveform(...)` вместо `Waveform(...)` в `CapsuleWaveform`; отступы вокруг `dictationPill` в `surface` и скругление из `OrbWaveform` (строку `.frame` пилюли не трогаем — её меняет upstream); орб вместо спиннера при распознавании; подпись VoiceOver «Transcribing». |
| `Sources/BetterWispr/App/CapsulePlacement.swift` | Место появления капсулы (по умолчанию — над указателем) и строка «Capsule position»; значение в UserDefaults (`fork.capsulePlacement`), схема AppSettings не меняется. |
| `Sources/BetterWispr/App/CapsuleController.swift` | Одна строка: позиция панели из `CapsulePlacement`. |
| `Package.swift` | Модуль `LiquidOrb` (Swift 5, экспорт не рассчитан на строгую конкурентность) и зависимость от него. |
| `Resources/Info.plist` | `SUFeedURL` указывает на релизы форка: иначе Sparkle заменит сборку с орбом на оригинал. |
| `Tests/BetterWisprCoreTests/OrbAppearanceTests.swift` | Параметры каждого стиля полные и с верным номером стиля; скорость, стекло и цвета попадают в нужные ячейки. |
| `Tests/BetterWisprCoreTests/CapsulePlacementTests.swift` | Позиции капсулы: штатная по центру, углы, «над указателем» фиксируется в начале диктовки, даже когда капсула видна постоянно, и не едет за мышью. |
| `Tests/BetterWisprCoreTests/LiquidOrbShaderTests.swift` | Компилирует шейдер орба: сломанный экспорт роняет приложение при первой диктовке, тест ловит это раньше. |
| `.github/workflows/sync-upstream.yml` | Ежедневно вливает новый релиз upstream в ветку `orb`. |
| `scripts/orb-update.sh` | Локально: показывает новое в форке, спрашивает, пересобирает и ставит в `/Applications`. |
| `scripts/orb-import.sh` | Ставит новый экспорт орба из редактора. |
| `scripts/orb-seeds.sh` | Печатает параметры стиля из выгрузки — для `OrbStyleSeeds.swift`. |

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

Стили в настройках — Prismatic Field, Violet Field (геометрия Prismatic Field с фиолетовой палитрой
первого орба) и Siri Wave. В экспорте редактора голос меняет у них только скорость и частоту, не
высоту волн. Импорт пишет громкость в `particleDensity` (uniform 32, его читают только Particle
Ribbons) и умножает высоту на `0.3 + 1.2 × громкость`: Prismatic/Violet Field — `amplitude_2`,
Siri Wave — `mainAmplitude`. В тишине остаётся линия, при речи волны плавно расходятся от центра.
Voice Membrane (одна изгибающаяся полоса) от голоса только качалась — заменена на Violet Field.
Aurora Veil, Neural Plasma и Violet Core линии не имеют — в выбор не включены. Правки завязаны
на имена из сгенерированного Metal: если редактор их сменит, импорт остановится с сообщением,
какой патч не лёг.

### Вкладка Customize

Боковое меню → App → Customize: живое превью капсулы с образцом голоса; выбор визуализации —
Classic bars (штатные полоски BetterWispr) или орб Prismatic Field / Violet Field / Siri Wave;
размер (48–112 pt), чувствительность к голосу и скорость (×0.5–×2), стеклянная оболочка, три цвета
волн (Reset возвращает цвета стиля); положение капсулы. Цвета в покое получаются из выбранных:
темнее и серее. Всё хранится в UserDefaults `fork.*`, схема AppSettings upstream не меняется;
применяется при следующем появлении капсулы. Шейдер у всех стилей один — стиль задают только
параметры (136 чисел). Карточки стилей — неподвижные миниатюры палитры: параметры орба
передаются через одну общую ячейку, поэтому живой орб на странице один (превью).

### Производительность

Замер 30.10.2026 (MacBook на Apple Silicon, окно 72 pt, образец голоса, 60 fps, 12 с, медиана трёх
запусков, CPU одного ядра по `top`): штатные полоски BetterWispr — 9,5%; орб, которому громкость
передаётся через SwiftUI на каждом кадре (`TimelineView`), — 8,3%; орб, который сам читает
громкость при отрисовке (`LiquidOrbAudioSource`, так сейчас), — 4,3%. Время GPU на кадр орба —
0,16–0,29 мс (Metal `gpuStartTime`/`gpuEndTime`), то есть ~1,5% кадра. Общая загрузка GPU по
`ioreg` для оценки не годится: шум системы больше вклада орба. Орб существует только пока видна
капсула диктовки; в покое его нет.

### Как добавить стиль

1. В редакторе выбрать стиль с центральной волной, настроить, Copy Code → SwiftUI, сохранить в файл.
2. `scripts/orb-seeds.sh файл.swift` — вставить вывод новой константой в `OrbStyleSeeds.swift`,
   добавить case в `OrbStyle` (название и `seeds`), номер стиля — в тест `OrbAppearanceTests`.
3. Если у стиля своя функция в шейдере без правки голоса — добавить патч в `scripts/orb-import.sh`
   и перезапустить импорт.

### Размер и поведение

`OrbWaveform.swift`: размер из настроек (орб раздвигает кнопки пилюли, а `pillPadding` растит стекло капсулы), скорость сглаживания `LevelSmoothing` (подъём 0.3, спад 0.1 за кадр),
состояния (запись — `thinking` с громкостью, ожидание микрофона и распознавание — `idle`).
У notetaker орб компактный (40 pt), его пилюля не меняется. С Reduce Motion или без Metal —
штатные полоски и размеры.

### Место появления

Customize → Position → «Capsule position»: над указателем мыши (по умолчанию), снизу по центру
(как в upstream), снизу слева, снизу справа. «Над указателем» фиксируется в начале диктовки и
держится до её конца, за мышью не едет; в покое капсула стоит снизу по центру. Чтобы капсула не висела в покое, выключить
«Floating recording capsule» — тогда она появляется только на время диктовки и созвона.

Текущий орб (Prismatic Field):
<https://lersent001.github.io/orb/#effect=orb-glass-liquid&style=spectrum&glass=1&state=thinking&activation=0.22&transition=0.65&preview=scene&text=Thinking...&speed=1.8&idleSpeed=0.48600000000000004&radius=0.72&contourDeform=0.03&idleContourDeform=0.009&zoom=0.46&idleZoom=0.4232&warp=4.4&idleWarp=1.9360000000000002&ridgeAmt=0.72&idleRidgeAmt=0.2736&sharp=2.2&idleSharp=2.2&bandDensity=2&idleBandDensity=2&metalDepth=0.25&idleMetalDepth=0.25&metalRoughness=0.22&idleMetalRoughness=0.22&chromaticShift=0.42&idleChromaticShift=0.42&metalScale=0.77&metalStretch=0.23&idleMetalStretch=0.23&metalAngle=65&metalOffset=0&metalPhase=0&metalEvolution=1&idleMetalEvolution=1&particleDensity=0.72&ribbonCount=5&ribbonWidth=0.42&idleRibbonWidth=0.42&ribbonTwist=1.25&idleRibbonTwist=1.25&ribbonFold=0.55&idleRibbonFold=0.55&ribbonBreath=0.3&idleRibbonBreath=0.3&particleSize=1.2&particleBloom=0.7&shade=0.06&idleShade=0.06&exposure=1.5&idleExposure=0.9299999999999999&sheen=0.26&gloss=0.24&glassOpacity=0.4&shellMidAlpha=0.18&shellEdgeAlpha=0.18&edgeSoftness=0.005&edgeGlow=0&idleEdgeGlow=0&colorA=%23FFFFFF&idleColorA=%23B4BBC2&colorB=%231677FF&idleColorB=%23285D8F&colorC=%23F249A0&idleColorC=%2391506F&colorD=%2335E6B2&idleColorD=%233F8873&highlightColor=%23FFFFFF&idleHighlightColor=%23D8DDE1&shellInner=%23FFFFFF&shellMid=%2366E8FF&shellEdge=%23D26CFF&sheenColor=%23EAF4FF&specColor=%23DCEAFF&canvasColor=%2303040A&glowColor=%231677FF&idleGlowColor=%23386789>

## Раздача DMG

Готовые сборки — в Releases форка, тег `vX.Y.Z-N` (голый `vX.Y.Z` занят тегом upstream и
не попадает под фильтр синхронизации), файл `BetterWispr-X.Y.Z.dmg`. `scripts/create-dmg.sh`
upstream требует macOS 27 (`diskutil image`), на macOS 26 — `hdiutil`:

```bash
CODESIGN_IDENTITY=- ./scripts/build-app.sh release
mkdir -p release/staging && ditto .build/release/BetterWispr.app release/staging/BetterWispr.app
ln -s /Applications release/staging/Applications
hdiutil create -volname BetterWispr -srcfolder release/staging -format UDZO -ov release/BetterWispr-X.Y.Z.dmg
gh release create vX.Y.Z-N --target orb --title "BetterWispr X.Y.Z" release/BetterWispr-X.Y.Z.dmg
```

Сборка только arm64 и без подписи Apple: на чужом Mac первый запуск — «Открыть всё равно»
в «Конфиденциальность и безопасность» или `xattr -dr com.apple.quarantine`.

## Ограничения

- Сборка подписывается ad-hoc. Подпись сертификатом Apple Development (30.10.2026) Gatekeeper
  после онлайн-проверки отправил в Корзину как «вредоносное ПО»; ad-hoc запускается. Цена:
  после каждой пересборки macOS снимает разрешение Accessibility — включить BetterWispr заново в
  «Системные настройки → Конфиденциальность и безопасность → Универсальный доступ».
  Другую подпись можно задать через `CODESIGN_IDENTITY`.
- Шейдер компилируется при первом показе орба (~150 мс на Apple Silicon), дальше берётся из кэша Metal.
- `VoiceLevels` даёт один общий уровень, поэтому все полосы орба (low/mid/high) получают его.
- «Над указателем» — это курсор мыши, не текстовая каретка.
