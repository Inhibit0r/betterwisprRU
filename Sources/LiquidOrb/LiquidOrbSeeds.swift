/// Fork: replaces the export's baked uniform seeds so the app can switch styles and colours without a new export.
/// Read when an orb view is created and when it changes state; set it on the main thread before creating the view.
public enum LiquidOrbSeeds {
    nonisolated(unsafe) public static var current: (idle: [Float], thinking: [Float])?
}
