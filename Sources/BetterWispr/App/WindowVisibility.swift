import AppKit
import SwiftUI

/// Fork: whether the dashboard window is on screen. A closed (ordered-out), minimized or fully covered window keeps its
/// SwiftUI tree, so anything there that reads per-frame state — voice levels, the recording clock, the capsule preview —
/// re-laid out the whole window on every frame of a dictation (~50% CPU measured), stealing frames from the capsule.
extension EnvironmentValues {
    @Entry var windowIsVisible = true
}

extension View {
    func tracksWindowVisibility() -> some View { modifier(WindowVisibilityModifier()) }
}

private struct WindowVisibilityModifier: ViewModifier {
    @State private var visible = true

    func body(content: Content) -> some View {
        content
            .environment(\.windowIsVisible, visible)
            .background(WindowVisibilityReader { visible = $0 })
    }
}

private struct WindowVisibilityReader: NSViewRepresentable {
    let onChange: (Bool) -> Void

    func makeNSView(context: Context) -> ReaderView { ReaderView(onChange: onChange) }
    func updateNSView(_ view: ReaderView, context: Context) { view.onChange = onChange }

    final class ReaderView: NSView {
        var onChange: (Bool) -> Void
        private var observer: NSObjectProtocol?

        init(onChange: @escaping (Bool) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
        }

        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

        isolated deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let observer { NotificationCenter.default.removeObserver(observer) }
            observer = nil
            guard let window else { return }
            observer = NotificationCenter.default.addObserver(forName: NSWindow.didChangeOcclusionStateNotification,
                                                              object: window, queue: .main) { [weak self, weak window] _ in
                MainActor.assumeIsolated {
                    guard let window else { return }
                    self?.onChange(window.occlusionState.contains(.visible))
                }
            }
            // Not during the current view update: SwiftUI state can't change inside it.
            let visible = window.occlusionState.contains(.visible)
            DispatchQueue.main.async { [weak self] in self?.onChange(visible) }
        }
    }
}
