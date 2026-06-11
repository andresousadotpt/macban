import SwiftUI
import MacbanCore

struct WelcomeView: View {
    @Environment(AppViewModel.self) private var app

    var body: some View {
        HStack(spacing: 0) {
            hero
            Divider()
            recents
                .frame(width: 320)
        }
        .background(.background)
    }

    private var hero: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.split.3x1.fill")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.tint)
            VStack(spacing: 6) {
                Text("macban")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                Text("A local-first kanban for macOS")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 12) {
                Button {
                    app.newProject()
                } label: {
                    Label("New Project", systemImage: "plus")
                        .frame(maxWidth: 220)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)

                Button {
                    app.openProject()
                } label: {
                    Label("Open Project", systemImage: "folder")
                        .frame(maxWidth: 220)
                }
                .controlSize(.large)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }

    private var recents: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent Projects")
                .font(.headline)
                .padding(16)

            Divider()

            if app.recents.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No recent projects")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(app.recents) { recent in
                        RecentRow(recent: recent)
                            .contentShape(Rectangle())
                            .onTapGesture { app.open(url: recent.url) }
                            .contextMenu {
                                Button("Open") { app.open(url: recent.url) }
                                Button("Remove from List", role: .destructive) {
                                    app.removeRecent(recent)
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .background(.quaternary.opacity(0.4))
    }
}

private struct RecentRow: View {
    let recent: RecentProject

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.stack.3d.up")
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(recent.name)
                    .font(.body)
                Text(recent.url.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
