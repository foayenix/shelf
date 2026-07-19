import SwiftUI
import ShelfKit

struct NoteRowView: View {
    @Environment(LibraryModel.self) private var library
    @Environment(ReadingProgressStore.self) private var progress

    let note: Note

    private var meta: String {
        let date = note.createdAt.formatted(.dateTime.day().month(.abbreviated))
        let minutes = max(1, Int((Double(note.wordCount) / 200).rounded()))
        return "\(date) · \(minutes) min · \(note.wordCount.formatted()) words"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            HStack(spacing: Space.s) {
                if progress.isUnread(note.id) {
                    Circle().fill(ShelfPalette.ember).frame(width: 6, height: 6)
                }
                Text(note.title)
                    .font(ShelfFont.reading(17).weight(.semibold))
                    .foregroundStyle(ShelfPalette.ink)
                    .multilineTextAlignment(.leading)
                if note.favourite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ShelfPalette.ember)
                }
            }
            if !library.preview(of: note.id).isEmpty {
                Text(library.preview(of: note.id))
                    .font(ShelfFont.reading(14).italic())
                    .foregroundStyle(ShelfPalette.graphite)
                    .lineLimit(1)
            }
            Text(meta).metaCaps(size: 9)
                .padding(.top, Space.xs)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Space.l)
        .contentShape(Rectangle())
    }
}
