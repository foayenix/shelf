import SwiftUI
import UIKit
import ShelfKit

/// In-app capture: paste → auto title → pick shelf → save. Three taps.
struct CaptureSheetView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var draft: CaptureDraft?
    @State private var pastedText = ""
    @State private var title = ""
    @State private var collectionId: UUID?
    @State private var errorMessage: String?

    private var saveTarget: String {
        library.collectionName(id: collectionId)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("New note").metaCaps(color: ShelfPalette.ink)
                Spacer()
                Text("paste → title → shelf").metaCaps(size: 9)
            }
            .padding(.top, Space.xl)

            pasteBox
                .padding(.top, 14)

            if draft != nil {
                Text("Title · auto — tap to edit").metaCaps(size: 9)
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
                CollectionChipsView(selection: $collectionId)
                    .padding(.top, Space.m)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(ShelfFont.reading(14))
                    .foregroundStyle(ShelfPalette.ember)
                    .padding(.top, Space.l)
            }

            Spacer(minLength: Space.xl)

            Button(action: save) {
                Text("Save to \(saveTarget)")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { collectionId = restoredCollection() }
    }

    @ViewBuilder
    private var pasteBox: some View {
        if let draft {
            VStack(alignment: .leading, spacing: Space.s) {
                Text(draft.body)
                    .font(ShelfFont.reading(14))
                    .foregroundStyle(ShelfPalette.ink.opacity(0.75))
                    .lineLimit(3)
                HStack(spacing: Space.s) {
                    Text("pasted · \(draft.wordCount.formatted()) words · \(WordCount.readingMinutes(wordCount: draft.wordCount)) min")
                        .metaCaps(size: 9)
                    if draft.truncated {
                        Text("trimmed to 100k characters").metaCaps(size: 9, color: ShelfPalette.ember)
                    }
                }
            }
            .padding(Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShelfPalette.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.card))
            .onTapGesture(perform: paste)
        } else {
            Button(action: paste) {
                VStack(spacing: Space.s) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 22))
                        .foregroundStyle(ShelfPalette.graphite)
                    Text("Tap to paste")
                        .font(ShelfFont.reading(15))
                        .foregroundStyle(ShelfPalette.graphite)
                }
                .frame(maxWidth: .infinity, minHeight: 110)
                .background(ShelfPalette.ink.opacity(0.05), in: RoundedRectangle(cornerRadius: Radius.card))
            }
        }
    }

    private func paste() {
        errorMessage = nil
        guard let text = UIPasteboard.general.string else {
            errorMessage = "Nothing on the clipboard."
            return
        }
        do {
            let processed = try CaptureProcessor.process(text: text)
            draft = processed
            title = processed.title
        } catch {
            errorMessage = "Clipboard is empty text."
        }
    }

    private func save() {
        guard let draft else { return }
        let finalTitle = title.trimmingCharacters(in: .whitespaces)
        do {
            _ = try library.saveCapture(
                draft,
                title: finalTitle.isEmpty ? draft.title : finalTitle,
                collectionId: collectionId
            )
            settings.lastUsedCollectionId = collectionId
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            errorMessage = "Couldn't save — try again."
        }
    }

    /// Defaults to the last shelf used, if it still exists.
    private func restoredCollection() -> UUID? {
        guard let last = settings.lastUsedCollectionId,
              library.collection(id: last) != nil
        else { return nil }
        return last
    }
}
