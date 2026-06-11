import AppKit
import Foundation

/// In-process drag state. macOS SwiftUI `dropDestination` + `CodableRepresentation`
/// decodes on the main thread and causes a visible freeze on drop; we set this when a
/// drag starts and read it synchronously in AppKit drop delegates instead.
@MainActor
enum DragSession {
    static let pasteboardType = NSPasteboard.PasteboardType("com.macban.card")

    static var active: CardTransfer?

    static func begin(_ transfer: CardTransfer) {
        active = transfer
    }

    static func end() {
        active = nil
    }

    static func encode(_ transfer: CardTransfer) -> String {
        "\(transfer.cardId.uuidString)|\(transfer.sourceColumnId)"
    }

    static func decode(_ raw: String) -> CardTransfer? {
        let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
        guard parts.count == 2, let id = UUID(uuidString: parts[0]) else { return nil }
        return CardTransfer(cardId: id, sourceColumnId: parts[1])
    }
}

struct CardTransfer: Equatable, Sendable {
    let cardId: UUID
    let sourceColumnId: String
}
