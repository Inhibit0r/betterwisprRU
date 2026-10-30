import BetterWisprCore
import LiquidOrb
import Metal
import SwiftUI

/// Fork: shows the Liquid Orb where the capsule drew level bars; falls back to the bars without Metal or with Reduce Motion.
struct OrbWaveform: View {
    let mode: Waveform.Mode
    let animated: Bool
    let count: Int
    /// The narrow notetaker pill keeps a small orb that overflows it instead of resizing it.
    var compact = false
    @State private var smoothing = LevelSmoothing()

    private static let compactDiameter: CGFloat = 40
    private static let hasMetal = MTLCreateSystemDefaultDevice() != nil

    static func isShown(animated: Bool) -> Bool { animated && hasMetal }
    /// The orb widens the 28 pt dictation pill past its fixed frame (two 24 pt buttons leave 44 pt for it);
    /// this padding grows the capsule glass around it without touching upstream's frame line.
    static func pillPadding(animated: Bool) -> EdgeInsets {
        guard isShown(animated: animated) else { return EdgeInsets() }
        let vertical = (pillHeight(animated: animated) - 28) / 2
        let horizontal = max(4, (CGFloat(OrbAppearance.current.size) - 44) / 2 + 4)
        return EdgeInsets(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }
    static func pillHeight(animated: Bool) -> CGFloat {
        isShown(animated: animated) ? max(28, CGFloat(OrbAppearance.current.size) + 8) : 28
    }

    var body: some View {
        if Self.isShown(animated: animated) {
            let appearance = OrbAppearance.current
            let size = compact ? Self.compactDiameter : CGFloat(appearance.size)
            let _ = appearance.install()
            // The orb redraws itself at 60 fps and asks for the level per frame; this body only runs when levels change.
            let _ = (LiquidOrbAudioSource.current = { [mode, smoothing] in
                Self.audio(for: mode, at: .now, smoothing: smoothing, sensitivity: Float(appearance.sensitivity))
            })
            LiquidOrbView(state: state)
                .frame(width: size, height: size)
                .frame(width: compact ? 28 : size, height: compact ? 14 : size)
                .allowsHitTesting(false)
                .onDisappear { LiquidOrbAudioSource.current = nil }
        } else {
            Waveform(mode: mode, animated: animated, count: count)
        }
    }

    private var state: LiquidOrbState {
        if case .listening = mode { .thinking } else { .idle }
    }

    /// VoiceLevels carries one broadband level, so every orb band follows it.
    private static func audio(for mode: Waveform.Mode, at date: Date, smoothing: LevelSmoothing, sensitivity: Float) -> LiquidOrbAudio {
        guard case .listening(let levels) = mode else { return LiquidOrbAudio() }
        let level = min(1, smoothing.next(levels.value(at: date)) * sensitivity)
        return LiquidOrbAudio(low: level, mid: level, high: level, all: level)
    }
}

/// Eases the level so the waves open and close smoothly with speech instead of twitching per syllable.
final class LevelSmoothing {
    private var value: Float = 0

    func next(_ target: Float) -> Float {
        value += (target - value) * (target > value ? 0.3 : 0.1)
        return value
    }
}
