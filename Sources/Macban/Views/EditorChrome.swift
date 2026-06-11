import SwiftUI

/// Shared styling for the card editor — grouped sections and fields that read
/// clearly in both light and dark mode on macOS.
enum EditorChrome {
    static let fieldCornerRadius: CGFloat = 8

    static var fieldBackground: Color {
        Color(nsColor: .textBackgroundColor)
    }

    static var sectionBackground: Color {
        Color(nsColor: .controlBackgroundColor)
    }

    static var separator: Color {
        Color(nsColor: .separatorColor)
    }
}

struct EditorSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content
        }
    }
}

struct EditorField<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(EditorChrome.fieldBackground, in: RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: EditorChrome.fieldCornerRadius, style: .continuous)
                    .strokeBorder(EditorChrome.separator.opacity(0.55), lineWidth: 1)
            )
    }
}
