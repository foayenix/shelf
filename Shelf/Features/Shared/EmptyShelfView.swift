import SwiftUI

/// First-run empty shelf: the panda appears as an invitation, not a mascot-first
/// design. `onCapture == nil` hides the paste button (e.g. inside a collection).
struct EmptyShelfView: View {
    let shelfName: String
    let onCapture: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(ShelfPalette.ink)
                .frame(height: 3)
                .padding(.top, 70)

            VStack(spacing: 0) {
                PandaPixelView(cellSize: 6)
                    .padding(22)
                    .background(ShelfPalette.boot, in: RoundedRectangle(cornerRadius: 22))

                Text("Nothing on this shelf.")
                    .font(ShelfFont.display(27))
                    .foregroundStyle(ShelfPalette.ink)
                    .padding(.top, 26)

                Text("Save a good response from Claude with the share sheet, or paste one here.")
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.graphite)
                    .multilineTextAlignment(.center)
                    .padding(.top, Space.s)
                    .padding(.horizontal, Space.xl)

                if let onCapture {
                    Button(action: onCapture) {
                        Text("Paste your first note")
                            .font(ShelfFont.reading(15).weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 26)
                            .frame(minHeight: 48)
                            .background(ShelfPalette.ember, in: Capsule())
                    }
                    .padding(.top, 26)

                    Text("tip: share sheet → shelf")
                        .metaCaps(size: 9, color: ShelfPalette.faintGraphite)
                        .padding(.top, Space.l)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, Space.xxxl)
        }
    }
}
