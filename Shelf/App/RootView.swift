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
        .safeAreaInset(edge: .top) {
            StorageBanner(health: library.health)
        }
        .onChange(of: scenePhase) { _, phase in
            // Pick up notes the share extension saved while the app was backgrounded.
            if phase == .active {
                library.reloadFromDisk()
            }
            // Mirror to iCloud when leaving; cheap no-op when disabled/unavailable.
            if phase == .background, settings.iCloudEnabled, let paths = library.store?.paths {
                CloudMirror.syncInBackground(paths: paths)
            }
        }
        .task(id: settings.iCloudEnabled) {
            guard settings.iCloudEnabled, let paths = library.store?.paths else { return }
            await CloudMirror.sync(paths: paths)
            library.reloadFromDisk()
        }
    }
}

/// Storage problems are never silent: a shelf that isn't the real one loses notes,
/// and the user is the only one who can do anything about it.
private struct StorageBanner: View {
    let health: LibraryModel.Health

    private var message: String? {
        switch health {
        case .ready:
            return nil
        case .degraded(.temporary):
            return "Shelf can't reach its library. Notes saved now won't be kept — reinstalling usually fixes it."
        case .degraded:
            return "Saving to this device only. Notes from the share sheet won't appear until the App Group is available."
        case .unavailable(let reason):
            return reason
        }
    }

    var body: some View {
        if let message {
            Text(message)
                .font(ShelfFont.reading(13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Space.l)
                .padding(.vertical, Space.m)
                .background(ShelfPalette.ember)
        }
    }
}
