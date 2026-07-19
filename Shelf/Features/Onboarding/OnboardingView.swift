import SwiftUI

/// One screen, two steps: name your library, pick your paper. The retro boot
/// animation lands in Phase 4 and will precede this on first launch.
struct OnboardingView: View {
    @Environment(AppSettings.self) private var settings
    @State private var name = ""
    @State private var theme: ReadingTheme = .paper

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Set up · two steps").metaCaps()
                .padding(.top, Space.xxl)
            Text("Set up your shelf.")
                .font(ShelfFont.display(34))
                .foregroundStyle(ShelfPalette.ink)
                .padding(.top, Space.s)

            Text("Step 1 — name your library").metaCaps(color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            TextField("My library", text: $name)
                .font(ShelfFont.reading(21))
                .foregroundStyle(ShelfPalette.ink)
                .padding(.vertical, Space.m)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ShelfPalette.ink).frame(height: 1.5)
                }

            Text("Step 2 — pick your paper").metaCaps(color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            HStack(spacing: Space.m) {
                ForEach(ReadingTheme.allCases) { candidate in
                    PaperSwatch(theme: candidate, selected: candidate == theme)
                        .onTapGesture { theme = candidate }
                }
            }
            .padding(.top, Space.l)

            Spacer()

            Button(action: finish) {
                Text("Start reading")
                    .font(ShelfFont.reading(17).weight(.medium))
                    .foregroundStyle(ShelfPalette.paper)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(ShelfPalette.ink, in: Capsule())
            }

            HStack(spacing: Space.s) {
                Text("LazyLab")
                    .font(ShelfFont.display(19))
                    .italic()
                    .rotationEffect(.degrees(-2))
                Text("we make things for human use")
                    .font(ShelfFont.mono(9))
                    .foregroundStyle(ShelfPalette.faintGraphite)
            }
            .foregroundStyle(ShelfPalette.graphite)
            .frame(maxWidth: .infinity)
            .padding(.top, Space.xl)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, Space.xxl)
        .background(ShelfPalette.paper.ignoresSafeArea())
    }

    private func finish() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { settings.libraryName = trimmed }
        settings.defaultTheme = theme
        settings.onboarded = true
    }
}

private struct PaperSwatch: View {
    let theme: ReadingTheme
    let selected: Bool

    var body: some View {
        VStack(spacing: Space.s) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Aa")
                    .font(ShelfFont.display(26))
                    .foregroundStyle(theme.ink)
                ForEach(0..<3, id: \.self) { line in
                    Rectangle()
                        .fill(theme.ink.opacity(0.2))
                        .frame(width: line == 2 ? 40 : nil, height: 2)
                        .frame(maxWidth: line == 2 ? 40 : .infinity, alignment: .leading)
                        .padding(.top, line == 0 ? Space.l : Space.s)
                }
                Spacer(minLength: 0)
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity)
            .frame(height: 148)
            .background(theme.background, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(theme.isDark ? .clear : theme.ink.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(ShelfPalette.ember, lineWidth: selected ? 2 : 0)
            )

            Text(theme.label)
                .font(ShelfFont.mono(10))
                .foregroundStyle(selected ? ShelfPalette.ink : ShelfPalette.graphite)
        }
    }
}
