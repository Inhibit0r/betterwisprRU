import AppKit
import BetterWisprCore
import SwiftUI

/// Fork: the Customize page — what the dictation capsule draws, how the orb looks and where the capsule appears.
struct CustomizeView: View {
    @AppStorage(OrbAppearance.Key.visualizer) private var visualizer = CapsuleVisualizer.orb
    @AppStorage(OrbAppearance.Key.style) private var style = OrbStyle.prismaticField
    @AppStorage(OrbAppearance.Key.size) private var size = 72.0
    @AppStorage(OrbAppearance.Key.sensitivity) private var sensitivity = 1.0
    @AppStorage(OrbAppearance.Key.speed) private var speed = 1.0
    @AppStorage(OrbAppearance.Key.glass) private var glass = true
    @AppStorage(OrbAppearance.Key.colors[0]) private var color1 = ""
    @AppStorage(OrbAppearance.Key.colors[1]) private var color2 = ""
    @AppStorage(OrbAppearance.Key.colors[2]) private var color3 = ""
    @State private var samplesVoice = true
    @State private var language = AppLanguage.selected

    private var appearance: OrbAppearance {
        OrbAppearance(visualizer: visualizer, style: style, size: size, sensitivity: sensitivity, speed: speed,
                      glass: glass, colors: [color1, color2, color3])
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SettingsSection("Preview") {
                    CapsulePreview(appearance: appearance, samplesVoice: samplesVoice)
                    RowDivider()
                    SettingToggle("Sample voice", caption: "Plays a sample voice in the preview. While you dictate, the capsule follows yours.", isOn: $samplesVoice)
                }

                SettingsSection("Visualizer") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 136), spacing: 12)], spacing: 12) {
                        VisualizerCard(title: "Classic bars", subtitle: "BetterWispr default", isSelected: visualizer == .bars) {
                            BarsThumbnail()
                        } action: {
                            visualizer = .bars
                        }
                        ForEach(OrbStyle.allCases, id: \.self) { orbStyle in
                            VisualizerCard(title: orbStyle.title, subtitle: "Waves open as you speak", isSelected: visualizer == .orb && style == orbStyle) {
                                OrbThumbnail(seeds: orbStyle.seeds.thinking)
                            } action: {
                                visualizer = .orb
                                style = orbStyle
                            }
                        }
                    }
                    .padding(16)
                }

                SettingsSection("Orb") {
                    slider("Size", caption: "\(Int(size)) pt", value: $size, in: OrbAppearance.sizes, step: 4)
                    RowDivider()
                    slider("Voice sensitivity", caption: "How far quiet speech opens the waves.", value: $sensitivity, in: OrbAppearance.factors, step: 0.1)
                    RowDivider()
                    slider("Speed", caption: "How fast the waves travel.", value: $speed, in: OrbAppearance.factors, step: 0.1)
                    RowDivider()
                    SettingToggle("Glass shell", caption: "A refracting glass edge around the orb.", isOn: $glass)
                    RowDivider()
                    SettingRow("Wave colors", caption: "Pick your own or reset to the style's.") {
                        HStack(spacing: 10) {
                            ColorPicker("Wave 1", selection: colorBinding($color1, offset: OrbAppearance.colorOffsets[0]), supportsOpacity: false)
                            ColorPicker("Wave 2", selection: colorBinding($color2, offset: OrbAppearance.colorOffsets[1]), supportsOpacity: false)
                            ColorPicker("Wave 3", selection: colorBinding($color3, offset: OrbAppearance.colorOffsets[2]), supportsOpacity: false)
                            Button("Reset") { color1 = ""; color2 = ""; color3 = "" }
                                .disabled(color1.isEmpty && color2.isEmpty && color3.isEmpty)
                        }
                        .labelsHidden()
                    }
                } footer: {
                    Text(visualizer == .bars ? "Choose an orb above to use these." : "Orb by LerSent001 (MIT). Changes apply the next time the capsule appears.")
                }
                .disabled(visualizer == .bars)

                SettingsSection("Language") {
                    SettingRow("Interface language", caption: language.needsRelaunch ? "Restart BetterWispr to switch." : nil) {
                        HStack(spacing: 10) {
                            if language.needsRelaunch {
                                Button("Restart") { AppLanguage.relaunch() }
                            }
                            Picker("Interface language", selection: $language) {
                                ForEach(AppLanguage.allCases) { option in
                                    Text(verbatim: option == .system ? "Same as Mac".localized : option.nativeName).tag(option)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                        }
                    }
                }
                .onChange(of: language) { language.select() }

                SettingsSection("Position") {
                    CapsulePlacementRow()
                } footer: {
                    Text("To keep the screen clear between dictations, turn off Floating recording capsule in Settings.")
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .toggleStyle(.switch)
    }

    private func slider(_ title: String, caption: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double) -> some View {
        SettingRow(title, caption: caption) {
            Slider(value: value, in: range, step: step)
                .frame(width: 180)
                .accessibilityLabel(title.localized)
        }
    }

    /// Shows the style's own colour until one is picked; picking stores it as hex.
    private func colorBinding(_ hex: Binding<String>, offset: Int) -> Binding<Color> {
        Binding {
            let rgb = OrbAppearance.rgb(hex.wrappedValue) ?? Array(style.seeds.thinking[offset..<offset + 3])
            return Color(.sRGB, red: Double(rgb[0]), green: Double(rgb[1]), blue: Double(rgb[2]))
        } set: { color in
            guard let srgb = NSColor(color).usingColorSpace(.sRGB) else { return }
            hex.wrappedValue = OrbAppearance.hex(red: srgb.redComponent, green: srgb.greenComponent, blue: srgb.blueComponent)
        }
    }
}

private struct VisualizerCard<Thumbnail: View>: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    @ViewBuilder let thumbnail: Thumbnail
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                thumbnail
                    .frame(height: 64)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.85), in: .rect(cornerRadius: 8, style: .continuous))
                // Two lines reserved for each, so every card in a row has the same height whatever the wording.
                VStack(spacing: 2) {
                    Text(title.localized).font(.callout.weight(.semibold))
                        .lineLimit(2, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle.localized).font(.caption).foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04), in: .rect(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title.localized), \(subtitle.localized)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// A still frame of BetterWispr's level bars.
private struct BarsThumbnail: View {
    var body: some View {
        HStack(spacing: 2.5) {
            ForEach(Array([0.2, 0.45, 0.8, 1, 0.7, 0.95, 0.55, 0.3, 0.15].enumerated()), id: \.offset) { _, height in
                Capsule().fill(.white.opacity(0.95)).frame(width: 2, height: 3 + 22 * height)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The style's palette around a bright centre line — live orbs share one renderer configuration, so cards stay still.
private struct OrbThumbnail: View {
    let seeds: [Float]

    var body: some View {
        ZStack {
            Circle().fill(Color.black)
            ForEach(Array(OrbAppearance.colorOffsets.enumerated()), id: \.offset) { index, offset in
                Ellipse()
                    .fill(color(at: offset))
                    .frame(width: 34 - CGFloat(index) * 6, height: 12 - CGFloat(index) * 2)
                    .offset(x: CGFloat(index - 1) * 5)
                    .blur(radius: 2.5)
                    .blendMode(.screen)
            }
            Capsule().fill(color(at: 40).opacity(0.9)).frame(width: 44, height: 1.5)
            Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1)
        }
        .frame(width: 52, height: 52)
        .accessibilityHidden(true)
    }

    private func color(at offset: Int) -> Color {
        Color(.sRGB, red: Double(seeds[offset]), green: Double(seeds[offset + 1]), blue: Double(seeds[offset + 2]))
    }
}

/// The dictation capsule as it will look, with a sample voice; rebuilt when the appearance changes, since orb seeds
/// are read when an orb is created. It is the capsule's own OrbWaveform fed a ready-made level track: the orb and the
/// bars animate that track themselves, so this body runs when the track is renewed instead of every frame — per-frame
/// updates here re-laid out the whole page (~40% of a core measured). Stopped while the window is hidden.
private struct CapsulePreview: View {
    let appearance: OrbAppearance
    let samplesVoice: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.windowIsVisible) private var windowIsVisible

    private static let track: TimeInterval = 30

    var body: some View {
        let animated = !reduceMotion && windowIsVisible
        let orb = OrbWaveform.isShown(animated: animated)
        TimelineView(.periodic(from: .now, by: Self.track)) { context in
            HStack(spacing: 4) {
                Image(systemName: "xmark")
                    .frame(width: 18, height: 18)
                    .background(.white.opacity(0.2), in: Circle())
                    .frame(width: 24, height: 24)
                OrbWaveform(mode: samplesVoice ? .listening(SampleVoice.track(from: context.date, length: Self.track + 5)) : .waiting, animated: animated, count: 9)
                    .padding(.horizontal, orb ? 4 : 8)
                Image(systemName: "checkmark")
                    .foregroundStyle(.black)
                    .frame(width: 18, height: 18)
                    .background(.white, in: Circle())
                    .frame(width: 24, height: 24)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .frame(height: orb ? appearance.size + 8 : 28)
            .background(Color.black.opacity(0.8), in: Capsule())
            .overlay { Capsule().strokeBorder(.white.opacity(0.16)) }
        }
        .id(appearance)
        .frame(maxWidth: .infinity)
        .frame(height: OrbAppearance.sizes.upperBound + 40)
        .background(Color.black.opacity(0.35))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Capsule preview")
    }

}

/// Syllables under a slow phrase envelope, as a level track the capsule visualizers play on their own.
enum SampleVoice {
    static func track(from start: Date, length: TimeInterval) -> VoiceLevels {
        let step = 0.02
        let origin = start.timeIntervalSinceReferenceDate
        let values = (0..<Int(length / step)).map { index in
            let t = origin + Double(index) * step
            return Float((0.65 + 0.35 * sin(t * 1.3)) * (0.4 + 0.6 * max(0, sin(t * 9))))
        }
        return VoiceLevels(values: values, start: start, step: step)
    }
}
