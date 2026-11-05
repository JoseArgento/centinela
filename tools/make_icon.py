#!/usr/bin/env python3
"""Draws Centinela/Media/icon.tga: an ink eye on a parchment disc with a gold rim, 64x64, like the
other addons' icons (the addon compartment and the minimap button use it). Own art, no game assets."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Centinela" / "Media" / "icon.tga"

S = 512  # drawn big, scaled down
PARCHMENT, PARCHMENT_DARK = (242, 227, 192, 255), (222, 201, 158, 255)
GOLD, GOLD_DEEP = (216, 168, 69, 255), (148, 112, 31, 255)
INK = (58, 35, 19, 255)


def main() -> None:
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    # disc with a two-tone gold rim
    d.ellipse((8, 8, S - 8, S - 8), fill=GOLD_DEEP)
    d.ellipse((22, 22, S - 22, S - 22), fill=GOLD)
    d.ellipse((38, 38, S - 38, S - 38), fill=PARCHMENT_DARK)
    d.ellipse((50, 50, S - 50, S - 50), fill=PARCHMENT)
    # the eye: an almond (two parabolic arcs) in ink, the iris in gold, the pupil in ink, a glint
    cx, cy, w, h = S / 2, S / 2, 200, 118

    def almond(w, h):
        pts = []
        n = 60
        for i in range(n + 1):
            x = -w + 2 * w * i / n
            pts.append((cx + x, cy - h * (1 - (x / w) ** 2)))
        for i in range(n, -1, -1):
            x = -w + 2 * w * i / n
            pts.append((cx + x, cy + h * (1 - (x / w) ** 2)))
        return pts

    d.polygon(almond(w, h), fill=INK)
    d.polygon(almond(w - 26, h - 24), fill=PARCHMENT)
    r = 74
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=INK)
    r2 = 50
    d.ellipse((cx - r2, cy - r2, cx + r2, cy + r2), fill=GOLD_DEEP)
    r3 = 26
    d.ellipse((cx - r3, cy - r3, cx + r3, cy + r3), fill=INK)
    d.ellipse((cx - 52, cy - 58, cx - 26, cy - 32), fill=PARCHMENT)
    out = im
    small = out.resize((64, 64), Image.LANCZOS)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    small.save(OUT, format="TGA", orientation=-1)
    small.save(OUT.with_suffix(".png"))
    print(OUT, small.size)


if __name__ == "__main__":
    main()
