import AppKit
import SwiftUI

/// Fork: the interface language. macOS picks it at launch from AppleLanguages in the app's own defaults,
/// so a change needs a relaunch; translations live in Resources/<language>.lproj.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system, english = "en", russian = "ru"

    static let chosenKey = "fork.languageChosen"
    var id: String { rawValue }

    /// Shown in its own language so it can be found whatever the current one is.
    var nativeName: String {
        switch self {
        case .system: "System"
        case .english: "English"
        case .russian: "Русский"
        }
    }

    /// The language set for this app, as opposed to the Mac's.
    static var selected: AppLanguage {
        let domain = Bundle.main.bundleIdentifier.flatMap { UserDefaults.standard.persistentDomain(forName: $0) }
        let code = (domain?["AppleLanguages"] as? [String])?.first.map { String($0.prefix(2)) }
        return code.flatMap(AppLanguage.init) ?? .system
    }

    /// The language the interface is showing now.
    static var running: AppLanguage {
        Bundle.main.preferredLocalizations.first.map { String($0.prefix(2)) }.flatMap(AppLanguage.init) ?? .english
    }

    func select() {
        if self == .system {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([rawValue], forKey: "AppleLanguages")
        }
    }

    /// Whether this choice shows a different language than the running interface, so applying it needs a relaunch.
    var needsRelaunch: Bool {
        let wanted = self == .system
            ? Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: Locale.preferredLanguages).first.map { String($0.prefix(2)) }
            : rawValue
        return wanted != AppLanguage.running.rawValue
    }

    /// Opens a new copy once this one has quit, so the new copy reads the language again.
    @MainActor static func relaunch() {
        let script = "while kill -0 \(ProcessInfo.processInfo.processIdentifier) 2>/dev/null; do sleep 0.2; done; open \"$0\""
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script, Bundle.main.bundlePath]
        try? process.run()
        NSApp.terminate(nil)
    }
}

/// Fork: asks for the interface language once, before onboarding, styled like the onboarding pages.
struct LanguageChoiceGate: View {
    @AppStorage(AppLanguage.chosenKey) private var chosen = false
    @State private var selection = AppLanguage.running == .russian ? AppLanguage.russian : .english

    var body: some View {
        if !chosen {
            VStack(spacing: 0) {
                VStack(spacing: 28) {
                    SymbolTile(symbol: "globe", color: .teal, size: 88)
                        .frame(height: 96)
                    VStack(spacing: 10) {
                        Text(verbatim: "Choose your language")
                            .font(.largeTitle.bold())
                        Text(verbatim: "Выберите язык интерфейса")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 10) {
                        option(.english, detail: "Английский")
                        option(.russian, detail: "Russian")
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack {
                    Text(verbatim: selection == .russian ? "Можно сменить в разделе «Оформление»." : "You can change it later in Customize.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        selection.select()
                        chosen = true
                        if selection.needsRelaunch { AppLanguage.relaunch() }
                    } label: {
                        Text(verbatim: selection == .russian ? "Продолжить" : "Continue")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
                .controlSize(.large)
                .padding(20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .transition(.opacity)
        }
    }

    private func option(_ language: AppLanguage, detail: String) -> some View {
        let isSelected = selection == language
        return Button { selection = language } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: language.nativeName).font(.title3.weight(.semibold))
                    Text(verbatim: detail).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.primary.opacity(0.04), in: .rect(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language.nativeName)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
