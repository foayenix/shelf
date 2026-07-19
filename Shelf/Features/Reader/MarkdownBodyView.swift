import SwiftUI
import MarkdownUI

/// One markdown block, themed to the token sheet: Literata body, Instrument Serif
/// headings, Plex Mono code, Ember links. The only file that touches MarkdownUI.
struct MarkdownBodyView: View {
    let markdown: String
    let theme: ReadingTheme
    let fontSize: CGFloat

    var body: some View {
        Markdown(markdown)
            .markdownTextStyle(\.text) {
                FontFamily(.custom(ShelfFont.readingName))
                FontSize(fontSize)
                ForegroundColor(theme.ink)
            }
            .markdownTextStyle(\.emphasis) {
                FontStyle(.italic)
            }
            .markdownTextStyle(\.strong) {
                FontWeight(.semibold)
            }
            .markdownTextStyle(\.link) {
                ForegroundColor(ShelfPalette.ember)
            }
            .markdownTextStyle(\.code) {
                FontFamily(.custom(ShelfFont.monoName))
                FontSize(.em(0.85))
                BackgroundColor(theme.ink.opacity(0.06))
            }
            .markdownBlockStyle(\.heading1) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom(ShelfFont.displayName))
                        FontSize(.em(1.45))
                    }
                    .markdownMargin(top: .em(1.2), bottom: .em(0.2))
            }
            .markdownBlockStyle(\.heading2) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom(ShelfFont.displayName))
                        FontSize(.em(1.25))
                    }
                    .markdownMargin(top: .em(1.1), bottom: .em(0.2))
            }
            .markdownBlockStyle(\.heading3) { configuration in
                configuration.label
                    .markdownTextStyle {
                        FontFamily(.custom(ShelfFont.displayName))
                        FontSize(.em(1.1))
                    }
                    .markdownMargin(top: .em(1), bottom: .em(0.2))
            }
            .markdownBlockStyle(\.blockquote) { configuration in
                configuration.label
                    .markdownTextStyle { FontStyle(.italic) }
                    .padding(.leading, 14)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(theme.rule).frame(width: 2)
                    }
            }
            .markdownBlockStyle(\.codeBlock) { configuration in
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .markdownTextStyle {
                            FontFamily(.custom(ShelfFont.monoName))
                            FontSize(.em(0.8))
                        }
                        .padding(Space.m)
                }
                .background(theme.ink.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .markdownMargin(top: .em(0.4), bottom: .em(0.4))
            }
            .lineSpacing(fontSize * 0.62)
            .environment(\.colorScheme, theme.isDark ? .dark : .light)
    }
}
