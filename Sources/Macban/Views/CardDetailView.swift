import SwiftUI
import MacbanCore

/// Full editor for a card's fields. Changes live-save through the board view model.
struct CardDetailView: View {
    @Bindable var board: BoardViewModel
    let target: BoardViewModel.EditTarget

    @State private var draft: Card
    @State private var hasDueDate: Bool
    @State private var newLabel = ""
    @State private var newChecklistItem = ""
    @FocusState private var titleFocused: Bool

    init(board: BoardViewModel, target: BoardViewModel.EditTarget) {
        self.board = board
        self.target = target
        let card = board.card(target.cardId, in: target.columnId) ?? Card(title: "")
        _draft = State(initialValue: card)
        _hasDueDate = State(initialValue: card.dueDate != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    titleField
                    metaGrid
                    labelsSection
                    descriptionSection
                    checklistSection
                }
                .padding(20)
            }
            .scrollIndicators(.automatic)
            Divider()
            footer
        }
        .frame(width: 520, height: 600)
        .onAppear { titleFocused = true }
        .onChange(of: draft) { _, newValue in
            board.update(newValue, in: target.columnId)
        }
        .onChange(of: hasDueDate) { _, enabled in
            if enabled {
                if draft.dueDate == nil { draft.dueDate = Calendar.current.startOfDay(for: Date()) }
            } else {
                draft.dueDate = nil
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Toggle(isOn: $draft.isCompleted) {
                Text(draft.isCompleted ? "Completed" : "Mark complete")
                    .font(.subheadline)
            }
            .toggleStyle(.checkbox)
            Spacer()
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color(nsColor: .controlBackgroundColor), in: Circle())
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
            .help("Close")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var titleField: some View {
        TextField("Card title", text: $draft.title, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: 22, weight: .semibold, design: .rounded))
            .focused($titleFocused)
            .lineLimit(1...4)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(EditorChrome.fieldBackground, in: RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous)
                    .strokeBorder(EditorChrome.separator.opacity(0.55), lineWidth: 1)
            )
    }

    private var metaGrid: some View {
        HStack(alignment: .top, spacing: 12) {
            metaCard(title: "Priority", icon: "flag") {
                Picker("Priority", selection: $draft.priority) {
                    ForEach(CardPriority.allCases) { priority in
                        Label(priority.displayName, systemImage: priority.symbol)
                            .tag(priority)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            metaCard(title: "Due date", icon: "calendar") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Set due date", isOn: $hasDueDate)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: Binding(
                                get: { draft.dueDate ?? Date() },
                                set: { draft.dueDate = $0 }
                            ),
                            displayedComponents: [.date]
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                    }
                }
            }
        }
    }

    private func metaCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(EditorChrome.sectionBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(EditorChrome.separator.opacity(0.4), lineWidth: 1)
        )
    }

    private var labelsSection: some View {
        EditorSection(title: "Labels", icon: "tag") {
            VStack(alignment: .leading, spacing: 10) {
                if !draft.labels.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(draft.labels, id: \.self) { label in
                            LabelChip(text: label) {
                                draft.labels.removeAll { $0 == label }
                            }
                        }
                    }
                }
                EditorField {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.tint)
                        TextField("Add a label", text: $newLabel)
                            .textFieldStyle(.plain)
                            .onSubmit(addLabel)
                    }
                }
            }
        }
    }

    private var descriptionSection: some View {
        EditorSection(title: "Description", icon: "text.alignleft") {
            ZStack(alignment: .topLeading) {
                if draft.details.isEmpty {
                    Text("Add notes, context, or acceptance criteria…")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $draft.details)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.never)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .frame(minHeight: 100, maxHeight: 140)
            }
            .background(EditorChrome.fieldBackground, in: RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous)
                    .strokeBorder(EditorChrome.separator.opacity(0.55), lineWidth: 1)
            )
        }
    }

    private var checklistSection: some View {
        EditorSection(title: "Checklist", icon: "checklist") {
            VStack(alignment: .leading, spacing: 8) {
                if !draft.checklist.isEmpty {
                    HStack {
                        Spacer()
                        Text("\(draft.completedChecklistCount) of \(draft.checklist.count) done")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 6) {
                        ForEach($draft.checklist) { $item in
                            HStack(spacing: 8) {
                                Toggle("", isOn: $item.isDone)
                                    .toggleStyle(.checkbox)
                                    .labelsHidden()
                                TextField("Item", text: $item.title)
                                    .textFieldStyle(.plain)
                                    .strikethrough(item.isDone)
                                    .foregroundStyle(item.isDone ? .secondary : .primary)
                                Button {
                                    draft.checklist.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                        }
                    }
                    .background(EditorChrome.fieldBackground, in: RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous)
                            .strokeBorder(EditorChrome.separator.opacity(0.55), lineWidth: 1)
                    )
                }
                EditorField {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.tint)
                        TextField("Add checklist item", text: $newChecklistItem)
                            .textFieldStyle(.plain)
                            .onSubmit(addChecklistItem)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Button(role: .destructive) {
                if let card = board.card(target.cardId, in: target.columnId) {
                    board.delete(card, from: target.columnId)
                }
                close()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.red)
            Spacer()
            Button("Done", action: close)
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func close() {
        board.editTarget = nil
    }

    private func addLabel() {
        let trimmed = newLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !draft.labels.contains(trimmed) else {
            newLabel = ""
            return
        }
        draft.labels.append(trimmed)
        newLabel = ""
    }

    private func addChecklistItem() {
        let trimmed = newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        draft.checklist.append(ChecklistItem(title: trimmed))
        newChecklistItem = ""
    }
}

private struct LabelChip: View {
    let text: String
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(labelColor(for: text))
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.medium))
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(labelColor(for: text).opacity(0.18), in: Capsule())
    }
}
