import SwiftUI
import ShelfKit

/// "Continue" card: the most recently opened, unfinished note.
struct ContinueReadingCard: View {
    let note: Note
    let progress: Double
    let action: () -> Void

    private var minutesLeft: Int {
        let remaining = Double(note.wordCount) * (1 - progress)
        return max(1, Int((remaining / 200).rounded()))
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Space.s) {
                HStack {
                    Text("Continue").metaCaps(size: 9, color: ShelfPalette.ember)
                    Spacer()
                    Text("\(minutesLeft) min left").metaCaps(size: 9)
                }
                Text(note.title)
                    .font(ShelfFont.reading(16).weight(.semibold))
                    .foregroundStyle(ShelfPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(ShelfPalette.ink.opacity(0.1))
                        Capsule().fill(ShelfPalette.ember)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 3)
                .padding(.top, Space.xs)
            }
            .padding(.horizontal, Space.l)
            .padding(.vertical, 14)
            .background(.white, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(ShelfPalette.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
