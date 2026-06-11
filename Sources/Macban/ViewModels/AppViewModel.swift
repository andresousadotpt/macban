import AppKit
import Observation
import MacbanCore

/// Top-level app state: which project (if any) is open, the recent-projects list,
/// and the new/open flows backed by native file panels.
@MainActor
@Observable
final class AppViewModel {
    private(set) var board: BoardViewModel?
    private(set) var recents: [RecentProject] = []
    var errorMessage: String?

    @ObservationIgnored private let recentsStore = RecentProjectsStore()

    init() {
        refreshRecents()
        openLatestIfAvailableOnLaunch()
    }

    var hasOpenProject: Bool { board != nil }

    func refreshRecents() {
        recents = recentsStore.load()
    }

    /// Opens the most recently used project once at launch. If none exists, or it was
    /// removed from disk, the welcome screen stays visible.
    private func openLatestIfAvailableOnLaunch() {
        guard let latest = recents.first else { return }
        open(url: latest.url)
    }

    func newProject() {
        let panel = NSSavePanel()
        panel.title = "New macban Project"
        panel.prompt = "Create"
        panel.message = "Choose where to create the project folder. It can live in any synced folder (Syncthing, iCloud Drive, Dropbox, ...)."
        panel.nameFieldLabel = "Project Name:"
        panel.nameFieldStringValue = "My Kanban"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let url = panel.url else { return }
        let parent = url.deletingLastPathComponent()
        let name = url.lastPathComponent
        do {
            let root = try ProjectStore.create(name: name, in: parent)
            open(url: root)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func openProject() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open"
        panel.message = "Choose a macban project folder."

        guard panel.runModal() == .OK, let url = panel.url else { return }
        open(url: url)
    }

    func open(url: URL) {
        guard ProjectLayout.isProject(at: url) else {
            errorMessage = "\(url.lastPathComponent) is not a macban project (no config.json)."
            recentsStore.remove(path: url.path)
            refreshRecents()
            return
        }
        Task {
            do {
                let viewModel = try await BoardViewModel.load(url: url)
                viewModel.onProjectNameChanged = { [weak self] name in
                    self?.syncRecentName(path: url.path, name: name)
                }
                board = viewModel
                recentsStore.record(RecentProject(path: url.path, name: viewModel.config.name))
                refreshRecents()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func syncRecentName(path: String, name: String) {
        recentsStore.updateName(path: path, name: name)
        refreshRecents()
    }

    func closeProject() {
        board = nil
        refreshRecents()
    }

    func removeRecent(_ project: RecentProject) {
        recentsStore.remove(path: project.path)
        refreshRecents()
    }

    /// Adds a card to the backlog of the open board (used by the New Card command).
    func quickAddToBacklog() {
        guard let board, let backlog = board.backlogColumn else { return }
        board.addCard(title: "New Card", to: backlog.id)
    }
}
