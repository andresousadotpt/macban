import SwiftUI

struct AppearanceSettingsPane: View {
    @Bindable var preferences: AppPreferences

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $preferences.theme) {
                    ForEach(AppPreferences.ThemeMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            } header: {
                Text("Theme")
            } footer: {
                Text("Choose light, dark, or follow the system setting.")
            }

            Section {
                Picker("Accent", selection: $preferences.accent) {
                    ForEach(AppPreferences.AccentChoice.allCases) { choice in
                        HStack(spacing: 8) {
                            if let color = choice.color {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)
                            } else {
                                Image(systemName: "circle.lefthalf.filled")
                                    .foregroundStyle(.secondary)
                            }
                            Text(choice.label)
                        }
                        .tag(choice)
                    }
                }
            } header: {
                Text("Accent Color")
            } footer: {
                Text("Used for buttons, links, and drag highlights.")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Board Zoom")
                        Spacer()
                        Text(preferences.zoomLabel)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $preferences.zoom, in: 0.85 ... 1.25, step: 0.05)
                }

                Picker("Column Width", selection: $preferences.columnWidth) {
                    ForEach(AppPreferences.ColumnWidth.allCases) { width in
                        Text(width.label).tag(width)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Picker("Card Density", selection: $preferences.cardDensity) {
                    ForEach(AppPreferences.CardDensity.allCases) { density in
                        Text(density.label).tag(density)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                Toggle("Highlight backlog column", isOn: $preferences.highlightBacklog)
            } header: {
                Text("Board Layout")
            } footer: {
                Text("Zoom scales the whole board. Column width and card density adjust spacing independently.")
            }

            Section {
                Button("Reset to Defaults") {
                    preferences.resetAppearance()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Appearance")
    }
}
