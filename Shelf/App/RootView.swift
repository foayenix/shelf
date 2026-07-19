import SwiftUI

enum Route: Hashable {
    case collection(UUID?)
    case reader(UUID)
}

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LibraryModel.self) private var library
    @Environment(\.scenePhase) private var scenePhase

    @State private var bootDone = false

    var body: some View {
        Group {
            if settings.onboarded {
                BookshelfView()
            } else if bootDone {
                OnboardingView()
                    .transition(.opacity)
            } else {
                BootView(noteCount: library.notes.count) {
                    withAnimation(.easeInOut(duration: 0.5)) { bootDone = true }
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Pick up notes the share extension saved while the app was backgrounded.
            if phase == .active {
                library.reloadFromDisk()
            }
            // Mirror to iCloud when leaving; cheap no-op when disabled/unavailable.
            if phase == .background, settings.iCloudEnabled {
                CloudMirror.syncInBackground(paths: library.store.paths)
            }
        }
        .task(id: settings.iCloudEnabled) {
            guard settings.iCloudEnabled else { return }
            await CloudMirror.sync(paths: library.store.paths)
            library.reloadFromDisk()
        }
    }
}
