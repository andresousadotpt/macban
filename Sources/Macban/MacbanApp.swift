import SwiftUI
import AppKit

/// Ensures the process behaves as a normal foreground app even when launched as a
/// bare SPM executable (`swift run`). Without an explicit `.regular` activation
/// policy the window never becomes key, so text fields can't receive keyboard input.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

@main
struct MacbanApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var app = AppViewModel()
    @State private var preferences = AppPreferences.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .environment(preferences)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1240, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project…") { app.newProject() }
                    .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("Open Project…") { app.openProject() }
                    .keyboardShortcut("o", modifiers: [.command])
                Divider()
                Button("New Card") { app.quickAddToBacklog() }
                    .keyboardShortcut("n", modifiers: [.command])
                    .disabled(!app.hasOpenProject)
                Divider()
                Button("Close Project") { app.closeProject() }
                    .keyboardShortcut("w", modifiers: [.command])
                    .disabled(!app.hasOpenProject)
            }
        }

        Settings {
            MacbanSettingsView(preferences: preferences)
                .environment(app)
                .environment(preferences)
        }
    }
}
