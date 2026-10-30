import AppKit
import LiquidOrb
import SwiftUI

/// Fork: Settings → Orb — style and customization of the capsule orb, with a live preview.
struct OrbSettingsSection: View {
    @AppStorage(OrbAppearance.Key.style) private var style = OrbStyle.prismaticField
    @AppStorage(OrbAppearance.Key.size) private var size = 72.0
    @AppStorage(OrbAppearance.Key.sensitivity) private var sensitivity = 1.0
    @AppStorage(OrbAppearance.Key.speed) private var speed = 1.0
    @AppStorage(OrbAppearance.Key.glass) private var glass = true
    @AppStorage(OrbAppearance.Key.colors[0]) private var color1 = ""
    @AppStorage(OrbAppearance.Key.colors[1]) private var color2 = ""
    @AppStorage(OrbAppearance.Key.colors[2]) private var color3 = ""
    @State private var simulatesVoice = true

    private var appearance: OrbAppearance {
        OrbAppearance(style: style, size: size, sensitivity: sensitivity, speed: speed, glass: glass, colors: [color1, color2, color3])
    }

    var body: some View {
        SettingsSection("Orb") {
            SettingRow("Preview", caption: simulatesVoice ? "Waves follow a sample voice; while you dictate they follow yours." : "Resting look, as while the text is transcribed.") {
                HStack(spacing: 16) {
                    Toggle("Sample voice", isOn: $simulatesVoice)
                    OrbPreview(appearance: appearance, simulatesVoice: simulatesVoice)
                }
            }
            RowDivider()
            SettingRow("Style", caption: "Each style opens its waves from the centre as you speak.") {
                Picker("Style", selection: $style) {
                    ForEach(OrbStyle.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                .labelsHidden()
                .fixedSize()
            }
            RowDivider()
            slider("Size", caption: "\(Int(size)) pt", value: $size, in: OrbAppearance.sizes, step: 4)
            RowDivider()
            slider("Voice sensitivity", caption: "How far quiet speech opens the waves.", value: $sensitivity, in: OrbAppearance.factors, step: 0.1)
            RowDivider()
            slider("Speed", caption: "How fast the waves travel.", value: $speed, in: OrbAppearance.factors, step: 0.1)
            RowDivider()
            SettingToggle("Glass shell", caption: "A refracting glass edge around the orb.", isOn: $glass)
            RowDivider()
            SettingRow("Wave colors") {
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
            Text("Orb by LerSent001 (MIT). Applies the next time the capsule appears.")
        }
    }

    private func slider(_ title: String, caption: String, value: Binding<Double>, in range: ClosedRange<Double>, step: Double) -> some View {
        SettingRow(title, caption: caption) {
            Slider(value: value, in: range, step: step)
                .frame(width: 180)
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

/// A live orb for the settings; rebuilt whenever the appearance changes, since seeds are read when it is created.
private struct OrbPreview: View {
    let appearance: OrbAppearance
    let simulatesVoice: Bool
    @State private var smoothing = LevelSmoothing()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let _ = appearance.install()
        TimelineView(.animation(paused: reduceMotion)) { context in
            LiquidOrbView(state: simulatesVoice ? .thinking : .idle, audio: audio(at: context.date))
        }
        .frame(width: appearance.size, height: appearance.size)
        .frame(width: OrbAppearance.sizes.upperBound, height: OrbAppearance.sizes.upperBound)
        .id(appearance)
        .accessibilityHidden(true)
    }

    /// Syllables under a slow phrase envelope, eased like the capsule's level.
    private func audio(at date: Date) -> LiquidOrbAudio {
        guard simulatesVoice else { return LiquidOrbAudio() }
        let t = date.timeIntervalSinceReferenceDate
        let voice = Float((0.65 + 0.35 * sin(t * 1.3)) * (0.4 + 0.6 * max(0, sin(t * 9))))
        let level = min(1, smoothing.next(voice) * Float(appearance.sensitivity))
        return LiquidOrbAudio(low: level, mid: level, high: level, all: level)
    }
}
