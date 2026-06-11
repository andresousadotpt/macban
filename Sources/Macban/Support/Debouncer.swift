import Foundation

/// Coalesces rapid operations keyed by an identifier (e.g. a column id) so that a
/// burst of edits results in a single disk write once activity settles.
@MainActor
final class Debouncer {
    private var tasks: [String: Task<Void, Never>] = [:]
    private let delay: Duration

    init(delay: Duration = .milliseconds(400)) {
        self.delay = delay
    }

    func schedule(_ key: String, _ operation: @escaping @Sendable () async -> Void) {
        tasks[key]?.cancel()
        tasks[key] = Task { [delay] in
            try? await Task.sleep(for: delay)
            if Task.isCancelled { return }
            await operation()
        }
    }
}
