import Foundation

/// Crash-safe file writes. `Data.write(options: .atomic)` writes to a temporary
/// file in the same directory and renames it into place, so a reader (or a sync
/// tool) never observes a half-written file.
public enum AtomicWrite {
    public static func write(_ data: Data, to url: URL) throws {
        let directory = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
        }
        try data.write(to: url, options: .atomic)
    }
}
