import SwiftUI
import UIKit
import ShelfKit

/// Minimal capture sheet: detected title (editable), shelf picker defaulting to
/// Inbox / last used, Save. Under three seconds end-to-end.
struct ShareCaptureView: View {
    let input: ShareInput
    let onDone: () -> Void
    let onCancel: () -> Void

    @State private var store: ShelfStore?
    @State private var collections: [NoteCollection] = []
    @State private var draft: CaptureDraft?
    @State private var title = ""
    @State private var collectionId: UUID?
    @State private var errorMessage: String?

    private var targetName: String {
        collections.first { $0.id == collectionId }?.name ?? "Inbox"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("Save to Shelf").metaCaps(color: ShelfPalette.ink)
                Spacer()
                Button("Cancel", action: onCancel)
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.graphite)
            }
            .padding(.top, Space.xl)

            if let draft {
                VStack(alignment: .leading, spacing: Space.s) {
                    Text(draft.body)
                        .font(ShelfFont.reading(14))
                        .foregroundStyle(ShelfPalette.ink.opacity(0.75))
                        .lineLimit(3)
                    HStack(spacing: Space.s) {
                        Text("\(draft.wordCount.formatted()) words · \(WordCount.readingMinutes(wordCount: draft.wordCount)) min")
                            .metaCaps(size: 9)
                        if draft.truncated {
                            Text("trimmed to 100k characters").metaCaps(size: 9, color: ShelfPalette.ember)
                        }
                    }
                }
                .padding(Space.l)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(ShelfPalette.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.card))
                .padding(.top, 14)

                Text("Title — tap to edit").metaCaps(size: 9)
                    .padding(.top, Space.xl)
                TextField("Title", text: $title)
                    .font(ShelfFont.reading(19).weight(.semibold))
                    .foregroundStyle(ShelfPalette.ink)
                    .padding(.vertical, Space.m)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(ShelfPalette.ink.opacity(0.25)).frame(height: 1.5)
                    }

                Text("Shelf").metaCaps(size: 9)
                    .padding(.top, Space.xl)
                chips.padding(.top, Space.m)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(ShelfFont.reading(15))
                    .foregroundStyle(ShelfPalette.ember)
                    .padding(.top, Space.xl)
            }

            Spacer(minLength: Space.xl)

            Button(action: save) {
                Text("Save to \(targetName)")
                    .font(ShelfFont.reading(17).weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        draft == nil ? ShelfPalette.graphite : ShelfPalette.ember,
                        in: Capsule()
                    )
            }
            .disabled(draft == nil)
        }
        .padding(.horizontal, Space.xl)
        .padding(.bottom, Space.xxl)
        .background(ShelfPalette.paper.ignoresSafeArea())
        .onAppear(perform: setUp)
    }

    private var chips: some View {
        FlowLayout(spacing: Space.s) {
            chip(label: "Inbox", id: nil)
            ForEach(collections) { collection in
                chip(label: collection.name, id: collection.id)
            }
        }
    }

    private func chip(label: String, id: UUID?) -> some View {
        let selected = collectionId == id
        return Button { collectionId = id } label: {
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

    private func setUp() {
        guard store == nil else { return }
        do {
            let opened = try ShelfEnvironment.makeGroupStore()
            store = opened
            collections = opened.collections
        } catch {
            errorMessage = "Can't open your shelf."
            return
        }

        switch input {
        case .text(let text):
            do {
                let processed = try CaptureProcessor.process(text: text)
                draft = processed
                title = processed.title
            } catch {
                errorMessage = "Nothing to save — the selection was empty."
            }
        case .url(let url):
            let processed = CaptureProcessor.process(url: url)
            draft = processed
            title = processed.title
        case .empty:
            errorMessage = "Nothing to save — share text or a link."
        }

        // Default to the last shelf used, if it still exists.
        if let last = ShelfEnvironment.sharedDefaults.string(forKey: ShelfEnvironment.Key.lastCollection)
            .flatMap(UUID.init),
           collections.contains(where: { $0.id == last }) {
            collectionId = last
        }
    }

    private func save() {
        guard let store, let draft else { return }
        let finalTitle = title.trimmingCharacters(in: .whitespaces)
        do {
            _ = try store.createNote(
                body: draft.body,
                title: finalTitle.isEmpty ? draft.title : finalTitle,
                collectionId: collectionId,
                source: .shareExtension
            )
            ShelfEnvironment.sharedDefaults.set(collectionId?.uuidString, forKey: ShelfEnvironment.Key.lastCollection)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onDone()
        } catch {
            errorMessage = "Couldn't save — try again."
        }
    }
}
