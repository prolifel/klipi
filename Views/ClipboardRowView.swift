import SwiftUI

struct ClipboardRowView: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onDelete: () -> Void
    var isSelected: Bool = false

    @State private var isHovered = false
    @State private var showCopied = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.preview)
                    .font(.body)
                    .lineLimit(2)
                    .foregroundColor(.primary)

                Text(item.formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ZStack {
                Button(action: {
                    copyWithFeedback()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 14))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Copy")

                if showCopied {
                    Text("Copied!")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor)
                        .cornerRadius(4)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.3) : (isHovered ? Color.accentColor.opacity(0.1) : Color.clear))
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            copyWithFeedback()
        }
    }

    private func copyWithFeedback() {
        onCopy()
        withAnimation {
            showCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                showCopied = false
            }
        }
    }
}