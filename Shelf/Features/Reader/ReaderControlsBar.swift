import SwiftUI

/// Floating pill: text size, theme dots, progress. Matches the mockup's bottom bar.
struct ReaderControlsBar: View {
    let theme: ReadingTheme
    let progressLabel: String
    let onSmaller: () -> Void
    let onLarger: () -> Void
    let onTheme: (ReadingTheme) -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onSmaller) {
                Text("Aa−").font(ShelfFont.reading(13)).foregroundStyle(theme.ink)
            }
            Button(action: onLarger) {
                Text("Aa+").font(ShelfFont.reading(17)).foregroundStyle(theme.ink)
            }

            Rectangle().fill(theme.rule).frame(width: 1, height: 20)

            ForEach(ReadingTheme.allCases) { candidate in
                Button { onTheme(candidate) } label: {
                    Circle()
                        .fill(candidate.background)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle().strokeBorder(
                                candidate.isDark ? .clear : candidate.ink.opacity(0.25),
                                lineWidth: 1
                            )
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(ShelfPalette.ember, lineWidth: candidate == theme ? 2 : 0)
                                .padding(-3)
                        )
                }
            }

            Rectangle().fill(theme.rule).frame(width: 1, height: 20)

            Text(progressLabel).metaCaps(size: 9, color: theme.meta)
        }
        .padding(.horizontal, 18)
        .frame(minHeight: 48)
        .background(theme.barBackground, in: Capsule())
        .overlay(Capsule().strokeBorder(theme.rule, lineWidth: 1))
        .shadow(color: ShelfPalette.boot.opacity(0.12), radius: 12, y: 6)
    }
}
