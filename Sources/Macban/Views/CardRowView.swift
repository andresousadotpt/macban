import AppKit
import SwiftUI
import MacbanCore

/// Lightweight card face for the board list. Drag uses `onDrag` (sets `DragSession`);
/// drop uses AppKit receivers that read `DragSession` synchronously.
@MainActor
struct CardRowView: View, Equatable {
    let board: BoardViewModel
    let columnId: String
    let card: Card
    @Environment(AppPreferences.self) private var preferences

    private var transfer: CardTransfer {
        CardTransfer(cardId: card.id, sourceColumnId: columnId)
    }

    nonisolated static func == (lhs: CardRowView, rhs: CardRowView) -> Bool {
        lhs.card == rhs.card && lhs.columnId == rhs.columnId
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "line.3.horizontal")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(width: 14)
                .padding(.top, 2)
            cardBody
        }
        .padding(preferences.scaledCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
        .background {
            ColumnDropReceiver(
                columnId: columnId,
                board: board,
                beforeCardId: card.id,
                isTargeted: .constant(false)
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onDrag {
            DragSession.begin(transfer)
            return NSItemProvider(object: DragSession.encode(transfer) as NSString)
        }
        .onTapGesture(count: 2) { openDetails() }
        .contextMenu {
            Button("Edit Details…") { openDetails() }
            Button(card.isCompleted ? "Mark Incomplete" : "Mark Complete") { toggleComplete() }
            Divider()
            Button("Delete", role: .destructive) { board.delete(card, from: columnId) }
        }
    }

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            if card.priority != .none {
                HStack(spacing: 3) {
                    Image(systemName: card.priority.symbol)
                    Text(card.priority.displayName)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(card.priority.color)
            }
            Text(card.title)
                .font(preferences.scaledCardFont)
                .strikethrough(card.isCompleted, color: .secondary)
                .foregroundStyle(card.isCompleted ? .secondary : .primary)
                .lineLimit(4)
            if hasMeta {
                HStack(spacing: 8) {
                    if !card.details.isEmpty {
                        Image(systemName: "text.alignleft")
                    }
                    if let due = card.dueDate {
                        Image(systemName: "calendar")
                        Text(DueDateStyle.text(for: due))
                            .foregroundStyle(
                                DueDateStyle.isOverdue(due) && !card.isCompleted ? .red : .secondary
                            )
                    }
                    if !card.checklist.isEmpty {
                        Image(systemName: "checklist")
                        Text("\(card.completedChecklistCount)/\(card.checklist.count)")
                    }
                    if !card.labels.isEmpty {
                        Image(systemName: "tag")
                        Text(card.labels.joined(separator: ", "))
                            .lineLimit(1)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var hasMeta: Bool {
        !card.details.isEmpty || card.dueDate != nil || !card.checklist.isEmpty || !card.labels.isEmpty
    }

    private func openDetails() {
        board.editTarget = BoardViewModel.EditTarget(columnId: columnId, cardId: card.id)
    }

    private func toggleComplete() {
        var updated = card
        updated.isCompleted.toggle()
        board.update(updated, in: columnId)
    }
}
