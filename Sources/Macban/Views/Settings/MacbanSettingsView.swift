import SwiftUI

struct MacbanSettingsView: View {
    @Environment(AppViewModel.self) private var app
    @Bindable var preferences: AppPreferences

    @State private var selection: SettingsPane = .appearance

    private var availablePanes: [SettingsPane] {
        var panes: [SettingsPane] = [.appearance]
        if app.hasOpenProject { panes.append(.project) }
        return panes
    }

    var body: some View {
        NavigationSplitView {
            List(availablePanes, selection: $selection) { pane in
                Label(pane.title, systemImage: pane.icon)
                    .tag(pane)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(minWidth: 640, minHeight: 480)
        .onChange(of: app.hasOpenProject) { _, hasProject in
            if !hasProject, selection == .project {
                selection = .appearance
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .appearance:
            AppearanceSettingsPane(preferences: preferences)
        case .project:
            if let board = app.board {
                ProjectSettingsPane(board: board)
            } else {
                ContentUnavailableView(
                    "No Project Open",
                    systemImage: "folder",
                    description: Text("Open a project to edit its name, columns, and location.")
                )
            }
        }
    }
}
