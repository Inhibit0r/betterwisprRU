/// Fork: replaces the export's baked uniform seeds so the app can switch styles and colours without a new export.
/// Read when an orb view is created and when it changes state; set it on the main thread before creating the view.
public enum LiquidOrbSeeds {
    nonisolated(unsafe) public static var current: (idle: [Float], thinking: [Float])?
}

/// Fork: the voice level, read by the orb on every frame it draws (main thread). Feeding audio through the view's
/// `audio` argument instead needs a SwiftUI update per frame, which measured about twice the CPU at the same 60 fps.
public enum LiquidOrbAudioSource {
    nonisolated(unsafe) public static var current: (() -> LiquidOrbAudio)?
}
