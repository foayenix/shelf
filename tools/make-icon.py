#!/usr/bin/env python3
"""Regenerates the App Store icon from the design tokens.

    pip install pillow && python3 tools/make-icon.py

The App Store rejects icons with an alpha channel, so this writes flat RGB.
One 1024x1024 is all iOS 17+ needs — the system derives every other size.
"""
from PIL import Image, ImageDraw

OUT = "Shelf/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"

S = 1024
BOOT = (0x14, 0x12, 0x10)     # ShelfPalette.boot
CREAM = (0xF2, 0xED, 0xE4)    # spine label / paper on dark
EMBER = (0xE8, 0x75, 0x2C)    # ShelfPalette.ember
GRAPH = (0x8B, 0x85, 0x7B)    # ShelfPalette.graphite
MID = (0x5A, 0x54, 0x4B)      # spine neutral

# Four spines only: at 60pt on the home screen, five plus gaps turns to mush.
SPINES = [(120, 380, CREAM), (90, 460, GRAPH), (150, 540, EMBER), (110, 420, MID)]
GAP = 40
RULE_H = 32
F = 4  # supersample, then downscale for clean edges


def main() -> None:
    img = Image.new("RGB", (S * F, S * F), BOOT)
    draw = ImageDraw.Draw(img)

    def rr(x0, y0, x1, y1, radius, fill):
        draw.rounded_rectangle(
            [x0 * F, y0 * F, x1 * F, y1 * F], radius=radius * F, fill=fill
        )

    tallest = max(h for _, h, _ in SPINES)
    # Geometric centre sits a touch high, which is what reads as centred.
    rule_y = (S - (tallest + RULE_H)) // 2 - 20 + tallest

    total = sum(w for w, _, _ in SPINES) + GAP * (len(SPINES) - 1)
    x = (S - total) / 2
    rr(x - 76, rule_y, x + total + 76, rule_y + RULE_H, RULE_H // 2, CREAM)
    for width, height, colour in SPINES:
        rr(x, rule_y - height, x + width, rule_y + 3, 14, colour)
        x += width + GAP

    img = img.resize((S, S), Image.LANCZOS)
    assert img.mode == "RGB", "App Store icons must have no alpha channel"
    img.save(OUT, "PNG", optimize=True)
    print(f"wrote {OUT} {img.size} {img.mode}")


if __name__ == "__main__":
    main()
