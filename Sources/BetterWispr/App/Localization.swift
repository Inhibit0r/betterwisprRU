import Foundation

extension String {
    /// Fork: this interface string in the chosen language (Resources/ru.lproj), or itself when it has no translation.
    /// SwiftUI translates string literals by itself; strings passed around as `String` need this at the `Text`.
    var localized: String { Bundle.main.localizedString(forKey: self, value: nil, table: nil) }
}
