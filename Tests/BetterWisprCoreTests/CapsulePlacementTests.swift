import AppKit
import Testing
@testable import BetterWispr

/// Fork: capsule placement keeps the upstream bottom-center spot and pins "above the pointer" for a whole dictation.
@MainActor @Test func capsulePlacementOrigins() {
    let screen = NSRect(x: 0, y: 25, width: 1440, height: 850)
    let panel = NSRect(x: 300, y: 400, width: 440, height: 240)
    let pointer = NSPoint(x: 700, y: 500)
    #expect(CapsulePlacement.bottomCenter.origin(in: screen, pointer: pointer, panel: panel, dictating: true) == NSPoint(x: 500, y: 37))
    #expect(CapsulePlacement.bottomLeft.origin(in: screen, pointer: pointer, panel: panel, dictating: true) == NSPoint(x: 8, y: 37))
    #expect(CapsulePlacement.bottomRight.origin(in: screen, pointer: pointer, panel: panel, dictating: true) == NSPoint(x: 992, y: 37))
    // Near a corner the panel stays on screen.
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: NSPoint(x: 5, y: 870), panel: panel, dictating: true) == NSPoint(x: 0, y: 635))
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: pointer, panel: panel, dictating: false) == NSPoint(x: 500, y: 37))
}

/// With "Floating recording capsule" on the panel never hides, so the pointer must be read when dictation starts.
@MainActor @Test func cursorPlacementAnchorsWhenDictationStartsOnAVisibleCapsule() {
    let screen = NSRect(x: 0, y: 25, width: 1440, height: 850)
    let resting = NSRect(x: 500, y: 37, width: 440, height: 240)
    let start = NSPoint(x: 700, y: 500), moved = NSPoint(x: 1200, y: 300)
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: start, panel: resting, dictating: false) == resting.origin)
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: start, panel: resting, dictating: true) == NSPoint(x: 480, y: 498))
    // Moving the pointer mid-dictation (each phase change repositions) leaves the capsule where it started.
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: moved, panel: resting, dictating: true) == NSPoint(x: 480, y: 498))
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: moved, panel: resting, dictating: false) == resting.origin)
    // The next dictation reads the pointer again.
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: moved, panel: resting, dictating: true) == NSPoint(x: 980, y: 298))
}
