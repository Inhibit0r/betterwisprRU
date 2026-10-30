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

    static let diameter: CGFloat = 72
    private static let compactDiameter: CGFloat = 40
    private static let hasMetal = MTLCreateSystemDefaultDevice() != nil

    static func isShown(animated: Bool) -> Bool { animated && hasMetal }
    /// The dictation pill grows to hold the orb; upstream sizes apply when the bars are shown.
    static func pillHeight(animated: Bool) -> CGFloat { isShown(animated: animated) ? diameter + 8 : 28 }
    static func pillExtraWidth(animated: Bool) -> CGFloat { isShown(animated: animated) ? diameter - 36 : 0 }

    var body: some View {
        if Self.isShown(animated: animated) {
            let size = compact ? Self.compactDiameter : Self.diameter
            TimelineView(.animation) { context in
                LiquidOrbView(state: state, audio: audio(at: context.date))
            }
            .frame(width: size, height: size)
            .frame(width: compact ? 28 : size, height: compact ? 14 : size)
            .allowsHitTesting(false)
        } else {
            Waveform(mode: mode, animated: animated, count: count)
        }
    }

    private var state: LiquidOrbState {
        if case .listening = mode { .thinking } else { .idle }
    }

    /// VoiceLevels carries one broadband level, so every orb band follows it.
    private func audio(at date: Date) -> LiquidOrbAudio {
        guard case .listening(let levels) = mode else { return LiquidOrbAudio() }
        let level = smoothing.next(levels.value(at: date))
        return LiquidOrbAudio(low: level, mid: level, high: level, all: level)
    }
}

/// Eases the level so the waves open and close smoothly with speech instead of twitching per syllable.
private final class LevelSmoothing {
    private var value: Float = 0

    func next(_ target: Float) -> Float {
        value += (target - value) * (target > value ? 0.3 : 0.1)
        return value
    }
}
