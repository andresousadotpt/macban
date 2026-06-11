import SwiftUI

/// App-wide appearance and layout preferences, persisted in UserDefaults.
@MainActor
@Observable
final class AppPreferences {
    static let shared = AppPreferences()

    enum ThemeMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    enum AccentChoice: String, CaseIterable, Identifiable {
        case system
        case blue
        case purple
        case pink
        case orange
        case green
        case teal

        var id: String { rawValue }

        var label: String {
            switch self {
            case .system: "System"
            default: rawValue.capitalized
            }
        }

        var color: Color? {
            switch self {
            case .system: nil
            case .blue: .blue
            case .purple: .purple
            case .pink: .pink
            case .orange: .orange
            case .green: .green
            case .teal: .teal
            }
        }
    }

    enum ColumnWidth: String, CaseIterable, Identifiable {
        case compact
        case standard
        case wide

        var id: String { rawValue }

        var label: String { rawValue.capitalized }

        var minWidth: CGFloat {
            switch self {
            case .compact: 220
            case .standard: 280
            case .wide: 340
            }
        }
    }

    enum CardDensity: String, CaseIterable, Identifiable {
        case compact
        case comfortable

        var id: String { rawValue }

        var label: String { rawValue.capitalized }

        var cardPadding: CGFloat {
            switch self {
            case .compact: 8
            case .comfortable: 12
            }
        }

        var cardSpacing: CGFloat {
            switch self {
            case .compact: 6
            case .comfortable: 10
            }
        }

        var cardFont: Font {
            switch self {
            case .compact: .callout
            case .comfortable: .body
            }
        }

        var columnHeaderPadding: EdgeInsets {
            switch self {
            case .compact: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
            case .comfortable: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
            }
        }
    }

    var theme: ThemeMode {
        didSet { save(theme.rawValue, for: Keys.theme) }
    }

    var accent: AccentChoice {
        didSet { save(accent.rawValue, for: Keys.accent) }
    }

    /// Board zoom from 0.85 (compact) to 1.25 (large).
    var zoom: Double {
        didSet { save(zoom, for: Keys.zoom) }
    }

    var columnWidth: ColumnWidth {
        didSet { save(columnWidth.rawValue, for: Keys.columnWidth) }
    }

    var cardDensity: CardDensity {
        didSet { save(cardDensity.rawValue, for: Keys.cardDensity) }
    }

    var highlightBacklog: Bool {
        didSet { save(highlightBacklog, for: Keys.highlightBacklog) }
    }

    var zoomScale: CGFloat { CGFloat(zoom) }

    var zoomLabel: String { "\(Int((zoom * 100).rounded()))%" }

    var scaledCardPadding: CGFloat { cardDensity.cardPadding * zoomScale }

    var scaledCardSpacing: CGFloat { cardDensity.cardSpacing * zoomScale }

    var scaledListPadding: EdgeInsets {
        let base = cardDensity.cardSpacing + 4
        let amount = base * zoomScale
        return EdgeInsets(top: amount, leading: amount, bottom: amount, trailing: amount)
    }

    var scaledColumnHeaderPadding: EdgeInsets {
        let insets = cardDensity.columnHeaderPadding
        return EdgeInsets(
            top: insets.top * zoomScale,
            leading: insets.leading * zoomScale,
            bottom: insets.bottom * zoomScale,
            trailing: insets.trailing * zoomScale
        )
    }

    var scaledCardFont: Font {
        switch cardDensity {
        case .compact:
            return zoom > 1.05 ? .body : .callout
        case .comfortable:
            return zoom > 1.1 ? .title3 : .body
        }
    }

    private enum Keys {
        static let theme = "macban.preferences.theme"
        static let accent = "macban.preferences.accent"
        static let zoom = "macban.preferences.zoom"
        static let columnWidth = "macban.preferences.columnWidth"
        static let cardDensity = "macban.preferences.cardDensity"
        static let highlightBacklog = "macban.preferences.highlightBacklog"
    }

    private init() {
        let defaults = UserDefaults.standard
        theme = ThemeMode(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .system
        accent = AccentChoice(rawValue: defaults.string(forKey: Keys.accent) ?? "") ?? .system
        zoom = defaults.object(forKey: Keys.zoom) as? Double ?? 1.0
        columnWidth = ColumnWidth(rawValue: defaults.string(forKey: Keys.columnWidth) ?? "") ?? .standard
        cardDensity = CardDensity(rawValue: defaults.string(forKey: Keys.cardDensity) ?? "") ?? .comfortable
        highlightBacklog = defaults.object(forKey: Keys.highlightBacklog) as? Bool ?? true
    }

    func resetAppearance() {
        theme = .system
        accent = .system
        zoom = 1.0
        columnWidth = .standard
        cardDensity = .comfortable
        highlightBacklog = true
    }

    private func save(_ value: String, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func save(_ value: Double, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func save(_ value: Bool, for key: String) {
        UserDefaults.standard.set(value, forKey: key)
    }
}

enum SettingsPane: String, CaseIterable, Identifiable {
    case appearance
    case project

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appearance: "Appearance"
        case .project: "Project"
        }
    }

    var icon: String {
        switch self {
        case .appearance: "paintbrush"
        case .project: "folder"
        }
    }
}
