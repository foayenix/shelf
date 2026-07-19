import SwiftUI

@main
struct ShelfApp: App {
    @State private var library = LibraryModel.makeDefault()
    @State private var settings = AppSettings()
    @State private var progress = ReadingProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(library)
                .environment(settings)
                .environment(progress)
                // The app surface is Paper; only the Reader goes dark.
                .preferredColorScheme(.light)
                .tint(ShelfPalette.ember)
        }
    }
}
