import SwiftUI
import MacbanCore

extension CardPriority {
    var color: Color {
        switch self {
        case .none: return .secondary
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var symbol: String {
        switch self {
        case .none: return "minus"
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "flag.fill"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

/// Deterministic accent color for a label, derived from its text so the same label
/// always looks the same across cards.
func labelColor(for text: String) -> Color {
    let palette: [Color] = [.blue, .purple, .pink, .red, .orange, .green, .teal, .indigo, .mint, .brown]
    let hash = abs(text.hashValue)
    return palette[hash % palette.count]
}

enum DueDateStyle {
    static func text(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return formatter.string(from: date)
    }

    static func isOverdue(_ date: Date) -> Bool {
        date < Calendar.current.startOfDay(for: Date())
    }
}
