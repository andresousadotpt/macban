import Foundation

/// Watches a directory for changes using a GCD `DispatchSource`. macban uses it to
/// notice edits made by sync tools (Syncthing, iCloud Drive, Dropbox) to a board's
/// `columns/` folder and reload the affected board.
///
/// Events are coalesced with a short debounce, and the watcher can be muted for a
/// brief window while the app performs its own writes so it does not react to itself.
public final class FileWatcher: @unchecked Sendable {
    private let url: URL
    private let debounce: TimeInterval
    private let queue = DispatchQueue(label: "com.macban.filewatcher")
    private var source: DispatchSourceFileSystemObject?
    private var descriptor: Int32 = -1
    private var pendingWork: DispatchWorkItem?
    private var mutedUntil: Date = .distantPast
    private let onChange: @Sendable () -> Void

    public init(url: URL, debounce: TimeInterval = 0.4, onChange: @escaping @Sendable () -> Void) {
        self.url = url
        self.debounce = debounce
        self.onChange = onChange
    }

    deinit {
        stop()
    }

    public func start() {
        queue.async { [weak self] in
            self?.beginWatching()
        }
    }

    /// Ignore change events for the next `interval` seconds. Call this around the
    /// app's own saves so self-inflicted writes do not trigger a reload.
    public func mute(for interval: TimeInterval) {
        queue.async { [weak self] in
            self?.mutedUntil = Date().addingTimeInterval(interval)
        }
    }

    public func stop() {
        queue.sync {
            pendingWork?.cancel()
            pendingWork = nil
            source?.cancel()
            source = nil
        }
    }

    private func beginWatching() {
        guard source == nil else { return }
        descriptor = open(url.path, O_EVTONLY)
        guard descriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .rename, .delete, .extend],
            queue: queue
        )
        let fd = descriptor
        source.setEventHandler { [weak self] in
            self?.handleEvent()
        }
        source.setCancelHandler {
            close(fd)
        }
        self.source = source
        source.resume()
    }

    private func handleEvent() {
        if Date() < mutedUntil { return }
        pendingWork?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        pendingWork = work
        queue.asyncAfter(deadline: .now() + debounce, execute: work)
    }
}
