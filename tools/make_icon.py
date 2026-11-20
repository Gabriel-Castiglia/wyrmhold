"""
Forja for macOS: draws the application icon, an anvil with two crossed hammers.
Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
Date: November 20, 2026
SPDX-License-Identifier: GPL-2.0-only

Engraving style: the anvil and hammers of the trade card of Elwell and Taylor, smiths of London
(c. 1766; British Museum, Heal 85.99, public domain), cut out of the card by the outline in
assets/icon_forja.json and drawn by tools/engraving.py, as in the Windows version; the tile
follows the macOS icon grid (an 824 px rounded square centred on a 1024 px canvas).

Writes:
  icono/icono-1024.png    the app icon on the default (black) tile; scripts/compilar.sh
                          makes the .icns from it
  assets/icon_layer.wyi   the drawing without the tile colour, 1024 px, which the app lays
                          on the tile colour of the chosen accent for the Dock icon:
                          "WYI2", uint16 size, then raw DEFLATE of, per pixel, T, K, R, G, B
                          (bytes) where the pixel is  rgb = RGB + tile * K / 255,
                          alpha = T  (premultiplied)
  build/icon_sheet.png    a look at every accent
The layer comes from drawing the icon twice, on black and on white: whatever changes
between the two is how much of the tile shows through.

Run:  python3 tools/make_icon.py      (needs numpy, opencv-python, Pillow)
"""
import pathlib
import struct
import sys
import zlib

import cv2
import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import engraving  # noqa: E402

S = engraving.S
CANVAS, BOX = 1024, 824
M, col = engraving.motif(engraving.load(ROOT / "assets" / "icon_forja.json"))
tile = engraving.rounded_tile(200 / 1024)

on0 = engraving.compose(M, col, (0, 0, 0))
on1 = engraving.compose(M, col, (255, 255, 255))
k = np.clip((on1 - on0).mean(axis=2) / 255, 0, 1)         # how much of the tile shows through
fg = np.clip(on0, 0, 255)                                  # the drawing, premultiplied


def placed(a):
    """a (S x S, any channels) shrunk to the 824 px box and centred on the 1024 px canvas."""
    a = cv2.resize(a.astype(np.float32), (BOX, BOX), interpolation=cv2.INTER_AREA)
    out = np.zeros((CANVAS, CANVAS) + a.shape[2:], np.float32)
    o = (CANVAS - BOX) // 2
    out[o:o + BOX, o:o + BOX] = a
    return out


T = placed(tile)
K = placed(k * tile)
P = placed(fg * tile[..., None])


def icon(rgb, size=CANVAS):
    """The icon on a tile of colour rgb, as an RGBA image of the given size."""
    pre = P + np.array(rgb, np.float32) * K[..., None]
    rgba = np.dstack([pre, T * 255])
    if size != CANVAS:
        rgba = cv2.resize(rgba, (size, size), interpolation=cv2.INTER_AREA)
    a = rgba[..., 3:4]
    rgb_ = np.where(a > 0, rgba[..., :3] * 255 / np.maximum(a, 1e-6), 0)
    return Image.fromarray(np.clip(np.dstack([rgb_, a]), 0, 255).round().astype(np.uint8), "RGBA")


BLACK = (0x22, 0x24, 0x2C)                     # the default accent's tile (Accent.black in Theme.swift)
(ROOT / "build").mkdir(exist_ok=True)
(ROOT / "icono").mkdir(exist_ok=True)
icon(BLACK).save(ROOT / "icono" / "icono-1024.png")

layer = np.dstack([T * 255, K * 255, P]).round().clip(0, 255).astype(np.uint8)
z = zlib.compressobj(9, zlib.DEFLATED, -15)
packed = z.compress(layer.tobytes()) + z.flush()
(ROOT / "assets" / "icon_layer.wyi").write_bytes(b"WYI2" + struct.pack("<H", CANVAS) + packed)

tiles = [BLACK, (0x2F, 0x6F, 0xE0), (0xB8, 0x86, 0x0B), (0x6D, 0x28, 0xD9), (0x0E, 0xA5, 0xE9), (0xEA, 0x58, 0x0C),
         (0xDC, 0x26, 0x26), (0xEA, 0xB3, 0x08), (0x16, 0xA3, 0x4A), (0x0D, 0x94, 0x88), (0xDB, 0x27, 0x77), (0xF1, 0xF5, 0xF9)]
sheet = Image.new("RGB", (6 * 170 + 20, 2 * 170 + 20), (246, 246, 248))
for i, t in enumerate(tiles):
    im = icon(t, 150)
    sheet.paste(im, (20 + (i % 6) * 170, 20 + (i // 6) * 170), im)
sheet.save(ROOT / "build" / "icon_sheet.png")
print("icon: icono/icono-1024.png, assets/icon_layer.wyi (%d bytes) written" % (len(packed) + 6))
