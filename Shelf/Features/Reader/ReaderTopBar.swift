import SwiftUI

struct ReaderTopBar: View {
    let theme: ReadingTheme
    let collectionName: String
    let position: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: Space.m) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.ink)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            Text(collectionName).metaCaps(size: 9, color: theme.meta)
            Spacer()
            Text(position).metaCaps(size: 9, color: theme.meta)
        }
        .padding(.horizontal, Space.m)
        .padding(.bottom, Space.m)
        .background(theme.barBackground)
    }
}
