import AppKit
import LiquidOrb

/// Fork: orb styles whose waves open from the centre line with the voice (patched in scripts/orb-import.sh).
enum OrbStyle: String, CaseIterable {
    case prismaticField, violetField, siriWave

    var title: String {
        switch self {
        case .prismaticField: "Prismatic Field"
        case .violetField: "Violet Field"
        case .siriWave: "Siri Wave"
        }
    }

    var seeds: (idle: [Float], thinking: [Float]) {
        switch self {
        case .prismaticField: OrbStyleSeeds.prismaticField
        case .violetField: OrbStyleSeeds.violetField
        case .siriWave: OrbStyleSeeds.siriWave
        }
    }
}

/// Fork: what the capsule draws while you dictate — BetterWispr's own level bars or an orb.
enum CapsuleVisualizer: String {
    case orb, bars
}

/// Fork: the Customize page, kept in UserDefaults beside AppSettings so the upstream settings schema stays unchanged.
struct OrbAppearance: Hashable {
    var visualizer = CapsuleVisualizer.orb
    var style = OrbStyle.prismaticField
    var size: Double = 72
    var sensitivity: Double = 1
    var speed: Double = 1
    var glass = true
    /// Hex colours replacing the style's three wave colours; an empty string keeps the style's own.
    var colors = ["", "", ""]

    enum Key {
        static let visualizer = "fork.visualizer"
        static let style = "fork.orb.style", size = "fork.orb.size", sensitivity = "fork.orb.sensitivity"
        static let speed = "fork.orb.speed", glass = "fork.orb.glass"
        static let colors = ["fork.orb.color1", "fork.orb.color2", "fork.orb.color3"]
    }

    static let sizes = 48.0...112.0
    static let factors = 0.5...2.0
    /// Seed offsets of the wave colours (colorB, colorC, colorD), each RGBA.
    static let colorOffsets = [44, 48, 52]
    private static let speedIndex = 3, glassIndex = 19

    static var current: OrbAppearance {
        let defaults = UserDefaults.standard
        var appearance = OrbAppearance()
        appearance.visualizer = defaults.string(forKey: Key.visualizer).flatMap(CapsuleVisualizer.init) ?? appearance.visualizer
        appearance.style = defaults.string(forKey: Key.style).flatMap(OrbStyle.init) ?? appearance.style
        if let size = defaults.object(forKey: Key.size) as? Double { appearance.size = sizes.clamped(size) }
        if let sensitivity = defaults.object(forKey: Key.sensitivity) as? Double { appearance.sensitivity = factors.clamped(sensitivity) }
        if let speed = defaults.object(forKey: Key.speed) as? Double { appearance.speed = factors.clamped(speed) }
        if let glass = defaults.object(forKey: Key.glass) as? Bool { appearance.glass = glass }
        appearance.colors = Key.colors.map { defaults.string(forKey: $0) ?? "" }
        return appearance
    }

    /// The style's seeds with this customization applied; idle colours are a dimmer, greyer take on the chosen ones.
    var seeds: (idle: [Float], thinking: [Float]) {
        var (idle, thinking) = style.seeds
        idle[Self.speedIndex] *= Float(speed)
        thinking[Self.speedIndex] *= Float(speed)
        idle[Self.glassIndex] = glass ? 1 : 0
        thinking[Self.glassIndex] = glass ? 1 : 0
        for (hex, offset) in zip(colors, Self.colorOffsets) {
            guard let rgb = Self.rgb(hex) else { continue }
            let luminance = 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]
            for channel in 0..<3 {
                thinking[offset + channel] = rgb[channel]
                idle[offset + channel] = (rgb[channel] * 0.75 + luminance * 0.25) * 0.65
            }
        }
        return (idle, thinking)
    }

    /// Hands this appearance to the orb renderer; call before creating an orb view.
    func install() {
        LiquidOrbSeeds.current = seeds
    }

    static func rgb(_ hex: String) -> [Float]? {
        guard hex.count == 7, hex.hasPrefix("#"), let value = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        return [Float((value >> 16) & 0xFF) / 255, Float((value >> 8) & 0xFF) / 255, Float(value & 0xFF) / 255]
    }

    static func hex(red: Double, green: Double, blue: Double) -> String {
        func byte(_ value: Double) -> Int { Int((min(1, max(0, value)) * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
    }
}

private extension ClosedRange where Bound == Double {
    func clamped(_ value: Double) -> Double { Swift.min(upperBound, Swift.max(lowerBound, value)) }
}
