import BetterWisprCore
import LiquidOrb
import Metal
import SwiftUI

/// Fork: shows the Liquid Orb where the capsule drew level bars; falls back to the bars without Metal or with Reduce Motion.
struct OrbWaveform: View {
    let mode: Waveform.Mode
    let animated: Bool
    let count: Int
    @State private var smoothing = LevelSmoothing()

    /// The orb overflows the 28 pt pill instead of resizing it, so the upstream layout stays untouched.
    static let diameter: CGFloat = 56
    private static let hasMetal = MTLCreateSystemDefaultDevice() != nil

    var body: some View {
        if animated, Self.hasMetal {
            TimelineView(.animation) { context in
                LiquidOrbView(state: state, audio: audio(at: context.date))
            }
            .frame(width: Self.diameter, height: Self.diameter)
            .frame(width: 28, height: 14)
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

/// Follows syllables like a level meter: jumps up fast, drops back in pauses without flicker.
private final class LevelSmoothing {
    private var value: Float = 0

    func next(_ target: Float) -> Float {
        value += (target - value) * (target > value ? 0.55 : 0.2)
        return value
    }
}
