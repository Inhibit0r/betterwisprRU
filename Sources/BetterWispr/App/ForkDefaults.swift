import AppKit
import BetterWisprCore
import Carbon.HIToolbox
import SwiftUI

/// Fork: first-run defaults that differ from upstream — dictation on Right Command and no idle capsule, since the
/// menu bar has everything the capsule offers. Set once, before onboarding, so existing users keep their choices.
/// Upstream's own defaults in AppSettings stay untouched, keeping its tests and merges clean.
@MainActor enum ForkDefaults {
    static let appliedKey = "fork.defaultsApplied"
    static let rightCommand = DictationShortcut(keyCode: UInt32(kVK_RightCommand), modifiers: [], key: "Right Command")

    static func applyOnFirstRun(_ model: AppModel) {
        guard !UserDefaults.standard.bool(forKey: appliedKey) else { return }
        UserDefaults.standard.set(true, forKey: appliedKey)
        guard model.needsOnboarding else { return }
        if let rightCommand { model.settings.shortcut = rightCommand }
        model.settings.showCapsule = false
        model.saveSettings()
    }
}

/// Fork: Shift+Command pressed together and released with no other key opens Settings. Commands like ⇧⌘T press a
/// key in between, so they never count. If Right Command dictation started on the way into the chord, it is
/// dropped silently. Global monitors need Accessibility, which modifier-key dictation already asks for.
@MainActor final class SettingsChord {
    static let openSettings = Notification.Name("fork.openSettings")
    private static let modifiers: NSEvent.ModifierFlags = [.control, .option, .shift, .command, .function]

    private let model: AppModel
    private var monitors: [Any] = []
    private var armed = false
    private var dictationBefore = false

    init(model: AppModel) {
        self.model = model
        let handle: (NSEvent) -> Void = { [weak self] event in MainActor.assumeIsolated { self?.handle(event) } }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown], handler: handle) { monitors.append(global) }
        if let local = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown], handler: { handle($0); return $0 }) {
            monitors.append(local)
        }
    }

    isolated deinit { monitors.forEach(NSEvent.removeMonitor) }

    func handle(_ event: NSEvent) {
        guard event.type == .flagsChanged else { armed = false; return }
        let held = event.modifierFlags.intersection(Self.modifiers)
        if held.isEmpty {
            if armed { fire() }
            armed = false
        } else if held == [.shift, .command] {
            // Right Command pressed first starts dictation a moment before Shift joins; that one belongs to the chord.
            if !armed { dictationBefore = model.isBusy && model.recordingDuration >= 1 }
            armed = true
        } else if !held.isSubset(of: [.shift, .command]) {
            armed = false
        }
    }

    private func fire() {
        if model.phase == .preparing || model.phase == .recording, !dictationBefore { model.discardRecording() }
        NotificationCenter.default.post(name: Self.openSettings, object: nil)
    }
}

/// Fork: opens the dashboard on Settings when the chord fires. Lives in the menu bar label, the one view that is
/// always on screen and can reach `openWindow`.
struct OpenSettingsListener: View {
    let model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear.onReceive(NotificationCenter.default.publisher(for: SettingsChord.openSettings)) { _ in
            model.selectedPage = .settings
            openWindow(id: "dashboard")
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
}
