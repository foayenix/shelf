import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            PandaPixelView(cellSize: 8)
                .padding(26)
                .background(ShelfPalette.boot, in: RoundedRectangle(cornerRadius: Radius.sheet))
            Text("LazyLab")
                .font(ShelfFont.display(42))
                .italic()
                .rotationEffect(.degrees(-2))
                .foregroundStyle(ShelfPalette.ink)
                .padding(.top, Space.xl)
            Text("We make things for human use.")
                .font(ShelfFont.reading(16))
                .foregroundStyle(ShelfPalette.graphite)
                .padding(.top, Space.s)
            Text("Shelf 0.1.0").metaCaps(size: 9, color: ShelfPalette.faintGraphite)
                .padding(.top, Space.xxl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(ShelfPalette.paper.ignoresSafeArea())
        .presentationDetents([.medium])
    }
}
