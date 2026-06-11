import SwiftUI
import MacbanCore

struct ColumnView: View {
    let board: BoardViewModel
    let column: Column
    @Environment(AppPreferences.self) private var preferences

    @State private var newCardTitle = ""
    @State private var isColumnTargeted = false
    @FocusState private var addFieldFocused: Bool

    private var cards: [Card] {
        board.cards(for: column.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            cardList
            Divider()
            addBar
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if column.kind == .backlog {
                Image(systemName: "tray.full")
                    .foregroundStyle(.secondary)
            }
            Text(column.title)
                .font(.headline.weight(.semibold))
            Text("\(cards.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(.quaternary, in: Capsule())
            Spacer()
        }
        .padding(preferences.scaledColumnHeaderPadding)
        .background(.regularMaterial)
    }

    private var cardList: some View {
        ScrollView {
            VStack(spacing: preferences.scaledCardSpacing) {
                ForEach(cards) { card in
                    CardRowView(board: board, columnId: column.id, card: card)
                }
                if isColumnTargeted {
                    dropPlaceholder
                }
            }
            .animation(nil, value: cards.map(\.id))
            .padding(preferences.scaledListPadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
        .background(isColumnTargeted ? Color.accentColor.opacity(0.06) : .clear)
        .background {
            ColumnDropReceiver(
                columnId: column.id,
                board: board,
                beforeCardId: nil,
                isTargeted: $isColumnTargeted
            )
        }
    }

    private var dropPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .strokeBorder(Color.accentColor.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            .frame(height: 44)
            .frame(maxWidth: .infinity)
    }

    private var addBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus")
                .foregroundStyle(.secondary)
            TextField("Add a card", text: $newCardTitle)
                .textFieldStyle(.plain)
                .focused($addFieldFocused)
                .onSubmit(addCard)
        }
        .padding(.horizontal, preferences.scaledListPadding.leading)
        .padding(.vertical, preferences.scaledListPadding.top)
    }

    private func addCard() {
        board.addCard(title: newCardTitle, to: column.id)
        newCardTitle = ""
        addFieldFocused = true
    }
}
