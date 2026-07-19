import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LibraryModel.self) private var library
    @Environment(\.dismiss) private var dismiss

    @State private var showAbout = false
    private struct ExportItem: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    @State private var exportItem: ExportItem?
    @State private var exportFailed = false

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

            Text("Your shelf").metaCaps(size: 9, color: ShelfPalette.ember)
                .padding(.top, Space.xxl)
            Toggle(isOn: $settings.iCloudEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud mirror")
                        .font(ShelfFont.reading(16))
                        .foregroundStyle(ShelfPalette.ink)
                    if !CloudMirror.isAvailable {
                        Text("needs the iCloud Documents capability + an iCloud account")
                            .font(ShelfFont.mono(9))
                            .foregroundStyle(ShelfPalette.graphite)
                    }
                }
            }
            .disabled(!CloudMirror.isAvailable)
            .tint(ShelfPalette.ember)
            .padding(.top, Space.m)

            Button(action: exportAll) {
                HStack {
                    Text("Export everything")
                        .font(ShelfFont.reading(16))
                        .foregroundStyle(ShelfPalette.ink)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(ShelfPalette.graphite)
                }
            }
            .padding(.top, Space.l)
            Text(exportFailed ? "export failed — try again" : "zip of index.json + every note as markdown")
                .font(ShelfFont.mono(9))
                .foregroundStyle(exportFailed ? ShelfPalette.ember : ShelfPalette.graphite)
                .padding(.top, 2)

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
        .sheet(item: $exportItem) { item in
            ActivityView(items: [item.url])
        }
    }

    private func exportAll() {
        exportFailed = false
        do {
            exportItem = ExportItem(url: try ShelfExporter.exportZip(of: library.store.paths))
        } catch {
            exportFailed = true
        }
    }
}
