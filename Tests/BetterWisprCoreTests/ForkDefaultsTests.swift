import AppKit
@testable import BetterWisprCore
import Carbon.HIToolbox
import Testing
@testable import BetterWispr

// Fork: the ⇧⌘ chord that opens Settings, and the first-run defaults.

private func flags(_ modifiers: NSEvent.ModifierFlags, key: Int = kVK_Shift) -> NSEvent {
    NSEvent.keyEvent(with: .flagsChanged, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                     characters: "", charactersIgnoringModifiers: "", isARepeat: false, keyCode: UInt16(key))!
}

private func keyDown(_ modifiers: NSEvent.ModifierFlags) -> NSEvent {
    NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                     characters: "t", charactersIgnoringModifiers: "t", isARepeat: false, keyCode: UInt16(kVK_ANSI_T))!
}

@Test @MainActor func shiftCommandAloneOpensSettingsButCommandsAndOtherModifiersDoNot() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: folder) }
    let chord = SettingsChord(model: AppModel(store: LocalStore(directory: folder), startsServices: false))
    var opened = 0
    let observer = NotificationCenter.default.addObserver(forName: SettingsChord.openSettings, object: nil, queue: nil) { _ in opened += 1 }
    defer { NotificationCenter.default.removeObserver(observer) }

    for event in [flags(.shift), flags([.shift, .command], key: kVK_Command), flags(.shift, key: kVK_Command), flags([])] { chord.handle(event) }
    #expect(opened == 1)

    // ⇧⌘T is a command, not the chord.
    for event in [flags(.shift), flags([.shift, .command], key: kVK_Command), keyDown([.shift, .command]), flags([])] { chord.handle(event) }
    #expect(opened == 1)

    // Option joining makes it another combination.
    for event in [flags([.shift, .command]), flags([.shift, .command, .option], key: kVK_Option), flags([])] { chord.handle(event) }
    #expect(opened == 1)

    // Command alone is dictation, not the chord.
    for event in [flags(.command, key: kVK_RightCommand), flags([])] { chord.handle(event) }
    #expect(opened == 1)
}

@Test @MainActor func forkDefaultsApplyOnceAndOnlyBeforeOnboarding() throws {
    let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: folder)
        UserDefaults.standard.removeObject(forKey: ForkDefaults.appliedKey)
    }
    let saved = UserDefaults.standard.object(forKey: ForkDefaults.appliedKey)
    defer { UserDefaults.standard.set(saved, forKey: ForkDefaults.appliedKey) }

    UserDefaults.standard.removeObject(forKey: ForkDefaults.appliedKey)
    let fresh = AppModel(store: LocalStore(directory: folder), startsServices: false)
    ForkDefaults.applyOnFirstRun(fresh)
    #expect(fresh.settings.shortcut == ForkDefaults.rightCommand)
    #expect(!fresh.settings.showCapsule)
    #expect(AppModel(store: LocalStore(directory: folder), startsServices: false).settings.shortcut == ForkDefaults.rightCommand)

    UserDefaults.standard.removeObject(forKey: ForkDefaults.appliedKey)
    let existing = AppModel(store: LocalStore(directory: folder), startsServices: false)
    existing.settings.completedOnboardingVersion = AppModel.onboardingVersion
    existing.settings.shortcut = .optionSpace
    existing.settings.showCapsule = true
    ForkDefaults.applyOnFirstRun(existing)
    #expect(existing.settings.shortcut == .optionSpace)
    #expect(existing.settings.showCapsule)
}
