"""
Wyrmhold for macOS: draws the application icon, a dragon guarding its tower.
Copyright (C) 2026 Gabriel Castiglia. Licensed under the GNU GPL, version 2 only.
Date: November 10, 2026
SPDX-License-Identifier: GPL-2.0-only

Engraving style: Athanasius Kircher's winged dragon
(Mundus Subterraneus, Amsterdam 1665; public domain, scan from Wikimedia Commons) lies
behind the battlement of a round tower drawn here with the same kind of hatching, breathing
golden fire; the tower's window shows a lit keyhole. Cream body, ink lines, flat tile.
The drawing is the one of the Windows version; the tile follows the macOS icon grid
(an 824 px rounded square centred on a 1024 px canvas).

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

Run:  python3 tools/make_icon.py      (needs numpy, opencv-python, scipy, Pillow)
"""
import struct
import sys
import zlib
from pathlib import Path

import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
src = str(ROOT / "assets" / "kircher_winged_dragon_1665.jpg")
mirror = True                                   # the dragon faces right
S = 1024
FLAME_X = 0.135                                 # the fire jet: this share of the width, at the mouth
CREAM = np.array([244, 236, 218], np.float32)
INK = np.array([22, 20, 24], np.float32)
FIRE = np.array([255, 190, 70], np.float32)

# ------------------------------------------------------------------ the dragon
g = cv2.imread(src, cv2.IMREAD_GRAYSCALE)
paper = cv2.GaussianBlur(cv2.dilate(g, np.ones((15, 15), np.uint8)), (0, 0), 25)
norm = np.clip(g.astype(np.float32) / np.maximum(paper.astype(np.float32), 1), 0, 1)
ink = norm < 0.70
closed = cv2.morphologyEx(ink.astype(np.uint8), cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)))
filled = ndimage.binary_fill_holes(closed)
lab, n = ndimage.label(filled)
sizes = ndimage.sum(filled, lab, range(1, n + 1))
big = 1 + int(np.argmax(sizes))
body = lab == big
# keep the separate strokes of the flame near the mouth (components that are large enough and
# lie in the band of the head), drop the specks of the paper
ys, xs = np.nonzero(body)
x0, x1, y0, y1 = xs.min(), xs.max(), ys.min(), ys.max()
keep = body.copy()
for k in range(1, n + 1):
    if k == big or sizes[k - 1] < 60:
        continue
    cy, cx = ndimage.center_of_mass(lab == k)
    if cy < y0 + (y1 - y0) * 0.35:
        keep |= lab == k
sil = keep
ys, xs = np.nonzero(sil)
x0, x1, y0, y1 = xs.min() - 8, xs.max() + 8, ys.min() - 8, ys.max() + 8
crop = lambda a: a[y0:y1, x0:x1]
norm_c, sil_c, body_c = crop(norm), crop(sil), crop(body)
fx = np.arange(sil_c.shape[1])[None, :]
fy = np.arange(sil_c.shape[0])[:, None]
flame_c = sil_c & ((fx < sil_c.shape[1] * FLAME_X) & (fy < sil_c.shape[0] * 0.36))
if mirror:
    norm_c, sil_c, flame_c = norm_c[:, ::-1], sil_c[:, ::-1], flame_c[:, ::-1]

# placement on the tile
DW = 900                                        # dragon width on the 1024 tile
sc = DW / norm_c.shape[1]
DH = int(norm_c.shape[0] * sc)
rs = lambda a, interp: cv2.resize(a.astype(np.float32), (DW, DH), interpolation=interp)
d_norm = rs(norm_c, cv2.INTER_AREA)
d_sil = cv2.GaussianBlur(rs(sil_c, cv2.INTER_AREA), (0, 0), 0.8)
d_fl = rs(flame_c, cv2.INTER_AREA)
DX, DY = (S - DW) // 2 + 10, 150

# ------------------------------------------------------------------ the tower (drawn, hatched)
TS = 4                                          # supersampling for the drawn parts
T = Image.new("L", (S * TS, S * TS), 0)         # silhouette
L = Image.new("L", (S * TS, S * TS), 0)         # ink lines
dt, dl = ImageDraw.Draw(T), ImageDraw.Draw(L)
tx0, tx1 = 322, 702                             # tower body
top = DY + DH - 40                              # battlement walk, under the dragon's feet
mer_h, n_mer = 74, 5
q = lambda *v: [c * TS for c in v]
dt.rectangle(q(tx0, top, tx1, S + 10), fill=255)
# corbelled parapet, a little wider than the body
px0, px1 = tx0 - 22, tx1 + 22
dt.rectangle(q(px0, top - 6, px1, top + 46), fill=255)
dt.polygon([(px0 * TS, (top + 46) * TS), (tx0 * TS, (top + 74) * TS), (tx1 * TS, (top + 74) * TS), (px1 * TS, (top + 46) * TS)], fill=255)
mw = (px1 - px0) / (2 * n_mer - 1)
M = Image.new("L", (S * TS, S * TS), 0)
dm = ImageDraw.Draw(M)
for i in range(n_mer):
    a = px0 + 2 * i * mw
    dm.rectangle(q(a, top - 6 - mer_h, a + mw, top), fill=255)
T.paste(255, mask=M)
tower = np.array(T.resize((S, S), Image.LANCZOS), np.float32) / 255
merl = np.array(M.resize((S, S), Image.LANCZOS), np.float32) / 255

lw = 5 * TS
# outline: drawn from the silhouette edges
edge = cv2.morphologyEx((np.array(T) > 127).astype(np.uint8), cv2.MORPH_GRADIENT, np.ones((lw, lw), np.uint8))
lines = edge.astype(np.float32)
# stone courses (slightly curved: it is round) and staggered joints
for r, y in enumerate(range(top + 96, S + 40, 44)):
    sag = 10
    pts = [(x * TS, (y + sag * (1 - ((x - (tx0 + tx1) / 2) / ((tx1 - tx0) / 2)) ** 2)) * TS) for x in range(tx0, tx1 + 1, 4)]
    dl.line(pts, fill=255, width=3 * TS)
    off = 0 if r % 2 else 38
    for x in range(tx0 + 20 + off, tx1 - 10, 76):
        yy = y + sag * (1 - ((x - (tx0 + tx1) / 2) / ((tx1 - tx0) / 2)) ** 2)
        dl.line(q(x, yy, x, yy + 44), fill=255, width=3 * TS)
# cylinder shading: vertical hatching, denser toward the edges and on the shadow side
cxm, half = (tx0 + tx1) / 2, (tx1 - tx0) / 2
for x in np.arange(tx0 + 3, tx1 - 2, 7.0):
    u = (x - cxm) / half                         # -1 .. 1
    shade = (abs(u) ** 1.6) * 0.9 + (0.35 if (u > 0) == (not mirror) else 0) * max(0, abs(u) - 0.1)
    if shade < 0.32:
        continue
    w = (1 + 2.2 * shade) * TS
    dl.line(q(x, top + 80, x, S + 10), fill=255, width=int(w))
# parapet shading under the corbels and the merlons' side faces
for x in np.arange(px0 + 4, px1, 9.0):
    dl.line(q(x, top + 40, x, top + 70), fill=255, width=2 * TS)
for i in range(n_mer):
    a = px0 + 2 * i * mw
    for k in range(3):
        xx = a + mw - 6 - k * 6 if not mirror else a + 6 + k * 6
        dl.line(q(xx, top - mer_h, xx, top - 8), fill=255, width=2 * TS)
# arched window with a keyhole-shaped light
wx, wy, ww = cxm, top + 230, 60
dl.rectangle(q(wx - ww / 2, wy, wx + ww / 2, wy + 120), fill=255)
dl.pieslice(q(wx - ww / 2, wy - ww / 2, wx + ww / 2, wy + ww / 2), 180, 360, fill=255)
glow = Image.new("L", (S * TS, S * TS), 0)
dg = ImageDraw.Draw(glow)
dg.ellipse(q(wx - 12, wy + 22, wx + 12, wy + 46), fill=255)
dg.polygon(q(wx - 7, wy + 40, wx + 7, wy + 40, wx + 13, wy + 92, wx - 13, wy + 92), fill=255)
tl = np.maximum(np.array(L, np.float32) / 255, lines)
tl = cv2.resize(tl, (S, S), interpolation=cv2.INTER_AREA) * tower
tglow = np.array(glow.resize((S, S), Image.LANCZOS), np.float32) / 255


# ------------------------------------------------------------------ compose
def compose(bg):
    """The whole drawing over a plain background of colour bg (float RGB)."""
    img = np.empty((S, S, 3), np.float32)
    img[:] = bg
    # tower
    t3 = tower[..., None]
    img = img * (1 - t3) + CREAM * t3
    img = img * (1 - tl[..., None]) + INK * tl[..., None]
    img = img * (1 - tglow[..., None]) + FIRE * tglow[..., None]
    # soft shadow of the dragon on the tower and the tile
    sh = np.zeros((S, S), np.float32)
    sh[DY:DY + DH, DX:DX + DW] = d_sil
    sh = cv2.GaussianBlur(np.roll(sh, (14, 0), (0, 1)), (0, 0), 10) * 0.35
    img *= (1 - sh[..., None])
    # dragon
    reg = img[DY:DY + DH, DX:DX + DW]
    tone = np.clip((d_norm - 0.22) / 0.48, 0, 1)[..., None]
    dcol = INK + (CREAM - INK) * tone
    dcol = np.where(d_fl[..., None] > 0.3, FIRE * tone + INK * (1 - tone) * 0.6 + FIRE * (1 - tone) * 0.4, dcol)
    a = d_sil[..., None]
    reg[:] = reg * (1 - a) + dcol * a

    # the merlons again, in front of the dragon (it lies behind the battlement)
    m3 = merl[..., None]
    mcol = np.empty_like(img); mcol[:] = CREAM
    mcol = mcol * (1 - tl[..., None]) + INK * tl[..., None]
    img = img * (1 - m3) + mcol * m3
    # shadow of the merlons on the dragon
    msh = cv2.GaussianBlur(np.roll(merl, (-10, 8 if not mirror else -8), (0, 1)), (0, 0), 6) * 0.3 * (1 - merl)
    img *= (1 - msh[..., None])
    return img


# rounded tile, on the macOS grid: an 824 px square with the corner of Apple's template
CANVAS, BOX = 1024, 824
m = Image.new("L", (S * 4, S * 4), 0)
ImageDraw.Draw(m).rounded_rectangle((0, 0, S * 4 - 1, S * 4 - 1), radius=round(185.4 / BOX * S) * 4, fill=255)
tile = np.array(m.resize((S, S), Image.LANCZOS), np.float32) / 255

on0 = compose(np.zeros(3, np.float32))
on1 = compose(np.full(3, 255, np.float32))
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
