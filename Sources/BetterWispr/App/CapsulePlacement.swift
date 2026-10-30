import AppKit
import SwiftUI

/// Fork: where the recording capsule appears. Kept in UserDefaults beside AppSettings so the upstream settings schema stays unchanged.
enum CapsulePlacement: String, CaseIterable {
    case bottomCenter, bottomLeft, bottomRight, cursor

    static let defaultsKey = "fork.capsulePlacement"
    static var current: CapsulePlacement {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(CapsulePlacement.init) ?? .bottomCenter
    }

    var title: String {
        switch self {
        case .bottomCenter: "Bottom center"
        case .bottomLeft: "Bottom left"
        case .bottomRight: "Bottom right"
        case .cursor: "Above the pointer"
        }
    }

    /// Origin of the capsule panel, whose content sits centered 16 pt above its bottom edge.
    /// Above the pointer is decided when the capsule appears; while it stays up it does not follow the pointer.
    func origin(in screen: NSRect, pointer: NSPoint, panel: NSRect, isVisible: Bool) -> NSPoint {
        switch self {
        case .bottomCenter:
            return NSPoint(x: screen.midX - panel.width / 2, y: screen.minY + 12)
        case .bottomLeft:
            return NSPoint(x: screen.minX + 8, y: screen.minY + 12)
        case .bottomRight:
            return NSPoint(x: screen.maxX - panel.width - 8, y: screen.minY + 12)
        case .cursor:
            if isVisible { return panel.origin }
            let x = min(max(pointer.x - panel.width / 2, screen.minX), screen.maxX - panel.width)
            let y = min(max(pointer.y - 2, screen.minY), screen.maxY - panel.height)
            return NSPoint(x: x, y: y)
        }
    }
}

struct CapsulePlacementRow: View {
    @AppStorage(CapsulePlacement.defaultsKey) private var placement = CapsulePlacement.bottomCenter

    var body: some View {
        SettingRow("Capsule position", caption: "Where the capsule appears while you dictate. Above the pointer stays where it first appeared.") {
            Picker("Capsule position", selection: $placement) {
                ForEach(CapsulePlacement.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
        }
    }
}
