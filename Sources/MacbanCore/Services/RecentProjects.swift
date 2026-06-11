import Foundation

public struct RecentProject: Codable, Sendable, Identifiable, Hashable {
    public var path: String
    public var name: String
    public var lastOpened: Date

    public var id: String { path }
    public var url: URL { URL(fileURLWithPath: path) }

    public init(path: String, name: String, lastOpened: Date = Date()) {
        self.path = path
        self.name = name
        self.lastOpened = lastOpened
    }
}

/// Persists the list of recently opened projects in Application Support. Since the
/// app is non-sandboxed, plain file paths are sufficient (no security-scoped bookmarks).
public struct RecentProjectsStore: Sendable {
    private let fileURL: URL
    private let maxEntries: Int

    public init(maxEntries: Int = 10) {
        self.maxEntries = maxEntries
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("Macban", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("recents.json")
    }

    public func load() -> [RecentProject] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONCoding.decode([RecentProject].self, from: data) else {
            return []
        }
        // Drop entries whose folder no longer exists or is no longer a project.
        return entries
            .filter { ProjectLayout.isProject(at: $0.url) }
            .sorted { $0.lastOpened > $1.lastOpened }
    }

    public func record(_ project: RecentProject) {
        var entries = load().filter { $0.path != project.path }
        entries.insert(project, at: 0)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        try? AtomicWrite.write(JSONCoding.encode(entries), to: fileURL)
    }

    public func remove(path: String) {
        let entries = load().filter { $0.path != path }
        try? AtomicWrite.write(JSONCoding.encode(entries), to: fileURL)
    }

    /// Updates the display name for a recent entry without changing its last-opened time.
    public func updateName(path: String, name: String) {
        var entries = load()
        guard let index = entries.firstIndex(where: { $0.path == path }) else { return }
        entries[index].name = name
        try? AtomicWrite.write(JSONCoding.encode(entries), to: fileURL)
    }
}
