import AppKit
import SwiftUI

/// Fork: where the recording capsule appears. Kept in UserDefaults beside AppSettings so the upstream settings schema stays unchanged.
enum CapsulePlacement: String, CaseIterable {
    case bottomCenter, bottomLeft, bottomRight, cursor

    static let defaultsKey = "fork.capsulePlacement"
    static let defaultValue = CapsulePlacement.cursor
    static var current: CapsulePlacement {
        UserDefaults.standard.string(forKey: defaultsKey).flatMap(CapsulePlacement.init) ?? defaultValue
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
    /// Above the pointer is read when a dictation starts and kept until the capsule is back at rest, so it does not
    /// follow the pointer; the always-visible resting capsule never hides, so the panel's visibility cannot mark the start.
    @MainActor func origin(in screen: NSRect, pointer: NSPoint, panel: NSRect, dictating: Bool) -> NSPoint {
        let bottomCenter = NSPoint(x: screen.midX - panel.width / 2, y: screen.minY + 12)
        guard self == .cursor, dictating else {
            Self.cursorAnchor = nil
            switch self {
            case .bottomLeft: return NSPoint(x: screen.minX + 8, y: screen.minY + 12)
            case .bottomRight: return NSPoint(x: screen.maxX - panel.width - 8, y: screen.minY + 12)
            case .bottomCenter, .cursor: return bottomCenter
            }
        }
        if let anchor = Self.cursorAnchor { return anchor }
        let anchor = NSPoint(x: min(max(pointer.x - panel.width / 2, screen.minX), screen.maxX - panel.width),
                             y: min(max(pointer.y - 2, screen.minY), screen.maxY - panel.height))
        Self.cursorAnchor = anchor
        return anchor
    }

    @MainActor private static var cursorAnchor: NSPoint?
}

struct CapsulePlacementRow: View {
    @AppStorage(CapsulePlacement.defaultsKey) private var placement = CapsulePlacement.defaultValue

    var body: some View {
        SettingRow("Capsule position", caption: "Where the capsule appears while you dictate. Above the pointer is set when dictation starts and stays put; at rest the capsule sits at the bottom center.") {
            Picker("Capsule position", selection: $placement) {
                ForEach(CapsulePlacement.allCases, id: \.self) { Text($0.title.localized).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
        }
    }
}
