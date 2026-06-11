import SwiftUI

struct RootView: View {
    @Environment(AppViewModel.self) private var app
    @Environment(AppPreferences.self) private var preferences

    var body: some View {
        @Bindable var app = app
        Group {
            if let board = app.board {
                NavigationStack {
                    BoardScreen(board: board)
                }
            } else {
                WelcomeView()
            }
        }
        .frame(minWidth: 720, minHeight: 500)
        .preferredColorScheme(preferences.theme.colorScheme)
        .tint(preferences.accent.color)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { app.errorMessage != nil },
                set: { if !$0 { app.errorMessage = nil } }
            ),
            presenting: app.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { app.errorMessage = nil }
        } message: { message in
            Text(message)
        }
    }
}
