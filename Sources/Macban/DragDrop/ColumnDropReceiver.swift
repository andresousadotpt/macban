import AppKit
import SwiftUI
/// AppKit drop target that applies card moves synchronously from `DragSession`,
/// bypassing SwiftUI's slow Transferable decode path.
struct ColumnDropReceiver: NSViewRepresentable {
    let columnId: String
    let board: BoardViewModel
    var beforeCardId: UUID?
    @Binding var isTargeted: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(columnId: columnId, board: board, beforeCardId: beforeCardId, isTargeted: $isTargeted)
    }

    func makeNSView(context: Context) -> DropReceiverNSView {
        let view = DropReceiverNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: DropReceiverNSView, context: Context) {
        context.coordinator.columnId = columnId
        context.coordinator.board = board
        context.coordinator.beforeCardId = beforeCardId
        nsView.coordinator = context.coordinator
    }

    @MainActor
    final class Coordinator: NSObject {
        var columnId: String
        var board: BoardViewModel
        var beforeCardId: UUID?
        var isTargeted: Binding<Bool>

        init(columnId: String, board: BoardViewModel, beforeCardId: UUID?, isTargeted: Binding<Bool>) {
            self.columnId = columnId
            self.board = board
            self.beforeCardId = beforeCardId
            self.isTargeted = isTargeted
        }

        func handleDrop(_ transfer: CardTransfer) {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                board.move(
                    cardId: transfer.cardId,
                    from: transfer.sourceColumnId,
                    to: columnId,
                    before: beforeCardId
                )
            }
            DragSession.end()
            if isTargeted.wrappedValue { isTargeted.wrappedValue = false }
        }
    }
}

@MainActor
final class DropReceiverNSView: NSView {
    weak var coordinator: ColumnDropReceiver.Coordinator?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([DragSession.pasteboardType, .string])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard DragSession.active != nil else { return [] }
        coordinator?.isTargeted.wrappedValue = true
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        DragSession.active != nil ? .move : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        coordinator?.isTargeted.wrappedValue = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        DragSession.active != nil
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let coordinator, let transfer = DragSession.active else { return false }
        coordinator.handleDrop(transfer)
        return true
    }
}
