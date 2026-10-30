import AppKit
import Testing
@testable import BetterWispr

/// Fork: capsule placement keeps the upstream bottom-center spot and pins "above the pointer" once shown.
@Test func capsulePlacementOrigins() {
    let screen = NSRect(x: 0, y: 25, width: 1440, height: 850)
    let panel = NSRect(x: 300, y: 400, width: 440, height: 240)
    let pointer = NSPoint(x: 700, y: 500)
    #expect(CapsulePlacement.bottomCenter.origin(in: screen, pointer: pointer, panel: panel, isVisible: false) == NSPoint(x: 500, y: 37))
    #expect(CapsulePlacement.bottomLeft.origin(in: screen, pointer: pointer, panel: panel, isVisible: false) == NSPoint(x: 8, y: 37))
    #expect(CapsulePlacement.bottomRight.origin(in: screen, pointer: pointer, panel: panel, isVisible: false) == NSPoint(x: 992, y: 37))
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: pointer, panel: panel, isVisible: false) == NSPoint(x: 480, y: 498))
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: pointer, panel: panel, isVisible: true) == panel.origin)
    // Near a corner the panel stays on screen.
    #expect(CapsulePlacement.cursor.origin(in: screen, pointer: NSPoint(x: 5, y: 870), panel: panel, isVisible: false) == NSPoint(x: 0, y: 635))
}
