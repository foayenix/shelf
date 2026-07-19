import SwiftUI

/// Working settings only — iCloud toggle and export-all arrive with Phase 4.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout = false

    var body: some View {
        @Bindable var settings = settings

        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Settings").metaCaps(color: ShelfPalette.ink)
                Spacer()
                Button("Done") { dismiss() }
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.graphite)
            }
            .padding(.top, Space.xl)

            Text("Library name").metaCaps(size: 9, color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            TextField("My library", text: $settings.libraryName)
                .font(ShelfFont.reading(19))
                .foregroundStyle(ShelfPalette.ink)
                .padding(.vertical, Space.m)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(ShelfPalette.ink.opacity(0.25)).frame(height: 1.5)
                }

            Text("Default paper").metaCaps(size: 9, color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            HStack(spacing: Space.m) {
                ForEach(ReadingTheme.allCases) { theme in
                    Button { settings.defaultTheme = theme } label: {
                        VStack(spacing: Space.s) {
                            Circle()
                                .fill(theme.background)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Circle().strokeBorder(
                                        theme.isDark ? .clear : theme.ink.opacity(0.25),
                                        lineWidth: 1
                                    )
                                )
                                .overlay(
                                    Circle()
                                        .strokeBorder(ShelfPalette.ember, lineWidth: settings.defaultTheme == theme ? 2 : 0)
                                        .padding(-4)
                                )
                            Text(theme.label)
                                .font(ShelfFont.mono(10))
                                .foregroundStyle(settings.defaultTheme == theme ? ShelfPalette.ink : ShelfPalette.graphite)
                        }
                    }
                }
            }
            .padding(.top, Space.l)

            Text("Reading size").metaCaps(size: 9, color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            HStack(spacing: Space.l) {
                Text("Aa").font(ShelfFont.reading(13)).foregroundStyle(ShelfPalette.graphite)
                Slider(value: $settings.readerFontSize, in: AppSettings.fontSizeRange, step: 1)
                Text("Aa").font(ShelfFont.reading(21)).foregroundStyle(ShelfPalette.ink)
            }
            .padding(.top, Space.s)
            Text("\(Int(settings.readerFontSize)) pt").metaCaps(size: 9)
                .padding(.top, Space.xs)

            Spacer()

            Button { showAbout = true } label: {
                HStack(spacing: Space.s) {
                    Text("LazyLab")
                        .font(ShelfFont.display(19))
                        .italic()
                        .rotationEffect(.degrees(-2))
                    Text("about").metaCaps(size: 9)
                }
                .foregroundStyle(ShelfPalette.graphite)
                .frame(maxWidth: .infinity)
            }
            .padding(.bottom, Space.xl)
        }
        .padding(.horizontal, Space.xl)
        .background(ShelfPalette.paper.ignoresSafeArea())
        .presentationDetents([.large])
        .sheet(isPresented: $showAbout) { AboutView() }
    }
}
