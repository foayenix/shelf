import SwiftUI

enum Route: Hashable {
    case collection(UUID?)
    case reader(UUID)
}

struct RootView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LibraryModel.self) private var library
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if settings.onboarded {
                BookshelfView()
            } else {
                OnboardingView()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // Pick up notes the share extension saved while the app was backgrounded.
            if phase == .active { library.reloadFromDisk() }
        }
    }
}
