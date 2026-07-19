import SwiftUI
import ShelfKit

struct BookshelfView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(AppSettings.self) private var settings
    @Environment(ReadingProgressStore.self) private var progress

    @State private var path: [Route] = []
    @State private var showCapture = false
    @State private var showSettings = false
    @State private var showSearch = false

    private var dateLine: String {
        Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var continueItem: (note: Note, progress: Double)? {
        guard let candidate = progress.continueCandidate(among: library.notes.map(\.id)),
              let note = library.note(id: candidate.noteId)
        else { return nil }
        return (note, candidate.entry.progress)
    }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                        if let item = continueItem {
                            ContinueReadingCard(note: item.note, progress: item.progress) {
                                path.append(.reader(item.note.id))
                            }
                            .padding(.top, 22)
                        }
                        shelves
                    }
                    .padding(.horizontal, Space.xl)
                    .padding(.bottom, 120)
                }
                fab
            }
            .background(ShelfPalette.paper.ignoresSafeArea())
            .navigationBarHidden(true)
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .collection(let id):
                    CollectionDetailView(collectionId: id) { note in
                        path.append(.reader(note.id))
                    }
                case .reader(let noteId):
                    ReaderView(noteId: noteId)
                }
            }
        }
        .sheet(isPresented: $showCapture) { CaptureSheetView() }
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showSearch) {
            SearchView { note in
                showSearch = false
                path.append(.reader(note.id))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack {
                Text(dateLine).metaCaps()
                Spacer()
                Button { showSearch = true } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ShelfPalette.ink)
                        .frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(ShelfPalette.ink.opacity(0.2), lineWidth: 1))
                }
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ShelfPalette.ink)
                        .frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(ShelfPalette.ink.opacity(0.2), lineWidth: 1))
                }
            }
            .padding(.top, Space.l)

            Text(settings.libraryName)
                .font(ShelfFont.display(38))
                .foregroundStyle(ShelfPalette.ink)
                .padding(.top, Space.xs)

            Text("\(library.collections.count + 1) shelves · \(library.notes.count) notes")
                .metaCaps()
        }
    }

    private var shelves: some View {
        VStack(alignment: .leading, spacing: Space.xxl) {
            let inboxNotes = library.notes(in: nil)
            if library.notes.isEmpty {
                EmptyShelfView(shelfName: "Inbox") { showCapture = true }
                    .padding(.top, Space.xl)
            } else {
                ShelfRowView(
                    name: "Inbox",
                    pinned: true,
                    notes: inboxNotes,
                    onOpenShelf: { path.append(.collection(nil)) },
                    onOpenNote: { path.append(.reader($0.id)) }
                )
                ForEach(library.collections) { collection in
                    ShelfRowView(
                        name: collection.name,
                        pinned: false,
                        notes: library.notes(in: collection.id),
                        onOpenShelf: { path.append(.collection(collection.id)) },
                        onOpenNote: { path.append(.reader($0.id)) }
                    )
                }
            }
        }
        .padding(.top, 34)
    }

    private var fab: some View {
        Button { showCapture = true } label: {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(ShelfPalette.ember, in: Circle())
                .shadow(color: ShelfPalette.ember.opacity(0.35), radius: 10, y: 8)
        }
        .padding(.trailing, Space.xl)
        .padding(.bottom, Space.xl)
        .accessibilityLabel("New note")
    }
}
