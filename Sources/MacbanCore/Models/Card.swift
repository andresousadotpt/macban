import Foundation

/// Card priority, ordered from lowest to highest. Mirrors the common Jira/Todoist
/// priority ladder.
public enum CardPriority: String, Codable, Sendable, CaseIterable, Identifiable {
    case none
    case low
    case medium
    case high
    case urgent

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }

    /// Higher means more urgent; useful for sorting.
    public var rank: Int {
        switch self {
        case .none: return 0
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        }
    }
}

/// A single sub-task / checklist item on a card (Todoist sub-tasks, Jira checklists).
public struct ChecklistItem: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

/// A single kanban card. Cards live inside a column file (`columns/{columnId}.json`)
/// as an ordered array; `order` mirrors the array index and is renumbered on save.
///
/// Decoding is lenient (missing fields fall back to defaults) so projects created by
/// older versions keep opening. Encoding omits empty/default fields to keep the JSON
/// small and easy to diff for sync tools.
public struct Card: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public var title: String
    /// Free-form notes / description (stored as `description` on disk).
    public var details: String
    public var priority: CardPriority
    public var dueDate: Date?
    public var labels: [String]
    public var checklist: [ChecklistItem]
    public var isCompleted: Bool
    public var order: Int
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        details: String = "",
        priority: CardPriority = .none,
        dueDate: Date? = nil,
        labels: [String] = [],
        checklist: [ChecklistItem] = [],
        isCompleted: Bool = false,
        order: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.priority = priority
        self.dueDate = dueDate
        self.labels = labels
        self.checklist = checklist
        self.isCompleted = isCompleted
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public var completedChecklistCount: Int {
        checklist.filter(\.isDone).count
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case details = "description"
        case priority
        case dueDate
        case labels
        case checklist
        case isCompleted
        case order
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        details = try container.decodeIfPresent(String.self, forKey: .details) ?? ""
        priority = try container.decodeIfPresent(CardPriority.self, forKey: .priority) ?? .none
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        labels = try container.decodeIfPresent([String].self, forKey: .labels) ?? []
        checklist = try container.decodeIfPresent([ChecklistItem].self, forKey: .checklist) ?? []
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        if !details.isEmpty { try container.encode(details, forKey: .details) }
        if priority != .none { try container.encode(priority, forKey: .priority) }
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        if !labels.isEmpty { try container.encode(labels, forKey: .labels) }
        if !checklist.isEmpty { try container.encode(checklist, forKey: .checklist) }
        if isCompleted { try container.encode(isCompleted, forKey: .isCompleted) }
        try container.encode(order, forKey: .order)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
