import SwiftUI
import ShelfKit

/// The signature element: every note is a book spine whose width tracks its word
/// count (≈ words/85, clamped 11–34pt) and whose height varies 76–96pt.
struct BookSpineView: View {
    let note: Note
    let position: Int
    let unread: Bool

    private var width: CGFloat {
        CGFloat(min(34, max(11, note.wordCount / 85)))
    }

    private var height: CGFloat {
        CGFloat(76 + ((note.wordCount * 7) % 20))
    }

    private var color: Color {
        unread ? ShelfPalette.ember : ShelfPalette.spineColors[position % ShelfPalette.spineColors.count]
    }

    var body: some View {
        UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2)
            .fill(color)
            .frame(width: width, height: height)
            .overlay(alignment: .top) {
                if width >= 17 {
                    Text(note.title.lowercased())
                        .font(ShelfFont.monoFixed(8))
                        .foregroundStyle(unread ? ShelfPalette.spineLabelUnread : ShelfPalette.spineLabel)
                        .lineLimit(1)
                        .fixedSize()
                        .frame(width: height - 14, alignment: .leading)
                        .rotationEffect(.degrees(90))
                        .frame(width: width, height: height - 14, alignment: .top)
                        .clipped()
                        .padding(.top, 7)
                }
            }
            .accessibilityLabel(note.title)
    }
}
