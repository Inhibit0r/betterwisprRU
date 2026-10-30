import AppKit
import Darwin
import SwiftUI
import Testing
@testable import BetterWispr
@testable import BetterWisprCore

// Fork: the Customize page animates a capsule preview. Driven per frame it re-laid out the whole page (~35% of a core
// here, ~40% in the app, against ~18% for the capsule itself); it must cost no more than the capsule it shows.

private func cpuSeconds() -> Double {
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    func seconds(_ time: timeval) -> Double { Double(time.tv_sec) + Double(time.tv_usec) / 1_000_000 }
    return seconds(usage.ru_utime) + seconds(usage.ru_stime)
}

/// Runs the real app event loop, which ties animations to the display; RunLoop.run alone lets them spin a core.
@MainActor private func runApp(for seconds: TimeInterval) {
    Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
        MainActor.assumeIsolated {
            NSApp.stop(nil)
            NSApp.postEvent(NSEvent.otherEvent(with: .applicationDefined, location: .zero, modifierFlags: [], timestamp: 0,
                                               windowNumber: 0, context: nil, subtype: 0, data1: 0, data2: 0)!, atStart: true)
        }
    }
    NSApp.run()
}

/// Share of one core the process spends while `view` is on screen.
@MainActor private func coreShare(_ view: some View, seconds: TimeInterval = 3) -> Double {
    // A test process is no running app: without this, animations aren't tied to the display and spin a whole core.
    NSApplication.shared.setActivationPolicy(.accessory)
    NSApplication.shared.finishLaunching()
    let window = NSWindow(contentRect: NSRect(x: 80, y: 80, width: 760, height: 680), styleMask: [.titled], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.contentView = NSHostingView(rootView: view.frame(width: 760, height: 680).tracksWindowVisibility())
    window.orderFrontRegardless()
    defer {
        window.orderOut(nil)
        window.contentView = nil
        runApp(for: 0.3)
    }
    runApp(for: 0.8)
    let cpu = cpuSeconds(), wall = Date()
    runApp(for: seconds)
    return (cpuSeconds() - cpu) / Date().timeIntervalSince(wall)
}

/// Bars only: the orb is Metal, which a test process never draws, so it would pass at 0% and prove nothing.
/// One animating view costs a big page about 8 points more than the bare capsule; driving the preview per frame as
/// before added another driver on top (35% here against 18%), which this catches.
/// Run alone (`BETTERWISPR_PERF=1 swift test --filter customizePreview`): it owns the main thread and needs a quiet CPU.
@MainActor @Test(.enabled(if: ProcessInfo.processInfo.environment["BETTERWISPR_PERF"] == "1"))
func customizePreviewCostsAboutAsMuchAsTheCapsule() {
    let defaults = UserDefaults.standard
    let saved = defaults.object(forKey: OrbAppearance.Key.visualizer)
    defer { defaults.set(saved, forKey: OrbAppearance.Key.visualizer) }
    defaults.set(CapsuleVisualizer.bars.rawValue, forKey: OrbAppearance.Key.visualizer)

    let empty = coreShare(Color.clear)
    let capsule = coreShare(OrbWaveform(mode: .listening(SampleVoice.track(from: .now, length: 10)), animated: true, count: 9))
    let page = coreShare(CustomizeView())
    print("Customize page \(Int((page - empty) * 100))%, capsule alone \(Int((capsule - empty) * 100))% of a core")
    #expect(page - empty <= capsule - empty + 0.10)
}
