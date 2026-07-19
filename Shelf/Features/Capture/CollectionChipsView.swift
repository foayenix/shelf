import SwiftUI
import ShelfKit

/// Shelf picker chips: Inbox, each collection, and "+ new".
struct CollectionChipsView: View {
    @Environment(LibraryModel.self) private var library

    @Binding var selection: UUID?
    @State private var showNewShelf = false
    @State private var newShelfName = ""

    var body: some View {
        FlowLayout(spacing: Space.s) {
            chip(label: "Inbox", id: nil)
            ForEach(library.collections) { collection in
                chip(label: collection.name, id: collection.id)
            }
            Button { showNewShelf = true } label: {
                Text("+ new")
                    .font(ShelfFont.reading(14))
                    .foregroundStyle(ShelfPalette.graphite)
                    .padding(.horizontal, Space.l)
                    .padding(.vertical, Space.s)
                    .overlay(
                        Capsule().strokeBorder(
                            ShelfPalette.ink.opacity(0.3),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                        )
                    )
            }
        }
        .alert("New shelf", isPresented: $showNewShelf) {
            TextField("Name", text: $newShelfName)
            Button("Create") {
                let trimmed = newShelfName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty, let created = library.createCollection(named: trimmed) {
                    selection = created.id
                }
                newShelfName = ""
            }
            Button("Cancel", role: .cancel) { newShelfName = "" }
        }
    }

    private func chip(label: String, id: UUID?) -> some View {
        let selected = selection == id
        return Button { selection = id } label: {
            Text(label)
                .font(ShelfFont.reading(14))
                .foregroundStyle(selected ? ShelfPalette.paper : ShelfPalette.ink)
                .padding(.horizontal, Space.l)
                .padding(.vertical, Space.s)
                .background(selected ? ShelfPalette.ink : .clear, in: Capsule())
                .overlay(
                    Capsule().strokeBorder(
                        selected ? .clear : ShelfPalette.ink.opacity(0.25),
                        lineWidth: 1
                    )
                )
        }
    }
}

