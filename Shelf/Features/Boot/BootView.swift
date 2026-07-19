import SwiftUI

/// Retro boot moment — first launch only, straight into onboarding when done.
struct BootView: View {
    let noteCount: Int
    let onFinished: () -> Void

    @State private var step = 0

    private let totalBlocks = 12
    private var bootLines: [String] {
        ["SHELF OS 1.0", "mounting library … ok", "restoring \(noteCount) notes … ok"]
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                PandaPixelView(cellSize: 10, animated: true)
                Text("LazyLab")
                    .font(ShelfFont.display(46))
                    .italic()
                    .rotationEffect(.degrees(-2))
                    .foregroundStyle(Color(hex: 0xF2EDE4))
                    .padding(.top, 28)
                Text("we make things for human use")
                    .font(ShelfFont.mono(11))
                    .kerning(0.9)
                    .foregroundStyle(ShelfPalette.graphite)
                    .padding(.top, 6)
            }
            .opacity(step > 0 ? 1 : 0)
            .offset(y: step > 0 ? 0 : 10)
            .animation(.easeOut(duration: 0.9), value: step > 0)

            Spacer()

            VStack(spacing: 14) {
                VStack(spacing: 5) {
                    ForEach(Array(bootLines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(ShelfFont.mono(10))
                            .kerning(1)
                            .foregroundStyle(ShelfPalette.graphite)
                            .opacity(step > index + 1 ? 1 : 0)
                    }
                }
                HStack(spacing: 5) {
                    ForEach(0..<totalBlocks, id: \.self) { index in
                        Rectangle()
                            .fill(index < filledBlocks ? ShelfPalette.ember : Color(hex: 0xF2EDE4).opacity(0.14))
                            .frame(width: 14, height: 8)
                    }
                }
            }
            .padding(.bottom, Space.xxxl)
        }
        .frame(maxWidth: .infinity)
        .background(ShelfPalette.boot.ignoresSafeArea())
        .task(runSequence)
    }

    private var filledBlocks: Int {
        min(totalBlocks, max(0, (step - 1) * 2))
    }

    @Sendable
    private func runSequence() async {
        for _ in 0..<8 {
            try? await Task.sleep(for: .seconds(0.28))
            step += 1
        }
        try? await Task.sleep(for: .seconds(0.5))
        onFinished()
    }
}
