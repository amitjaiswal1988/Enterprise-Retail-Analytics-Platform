"""Generate ShopStar Retail logo PNGs — Amazon-style professional wordmark.

Original design (does NOT copy Amazon's trademark): a clean navy wordmark with
an orange "smile" swoosh that sweeps beneath the text and ends in a star tip.
Pure-Pillow renderer (no cairo needed). Draws at 4x then downscales with LANCZOS
for crisp anti-aliased edges. Re-run any time to regenerate.

    python Python/generate_logo.py
"""
from __future__ import annotations

import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

FONT_REG = r"C:\Windows\Fonts\segoeui.ttf"
FONT_BOLD = r"C:\Windows\Fonts\segoeuib.ttf"

# Brand palette (Navy + Orange — enterprise retail)
NAVY = (27, 54, 93)      # #1B365D  primary
NAVY_HI = (44, 82, 130)  # lighter navy for subtle gradient
ORANGE = (247, 148, 29)  # #F7941D  secondary / smile
ORANGE_HI = (255, 179, 71)
INK = (27, 54, 93)
SLATE = (120, 132, 148)

S = 4  # supersample factor


# --------------------------------------------------------------------------- #
# helpers
# --------------------------------------------------------------------------- #
def _blend(a, b, t):
    return a + (b - a) * np.clip(t, 0, 1)


def diagonal_gradient(w, h, c0, c1):
    """2-stop diagonal gradient as an RGB array."""
    yy, xx = np.mgrid[0:h, 0:w]
    t = (xx + yy) / (w + h - 2)
    img = np.zeros((h, w, 3), dtype=np.uint8)
    for i in range(3):
        img[..., i] = np.clip(_blend(c0[i], c1[i], t), 0, 255)
    return img


def rounded_mask(w, h, radius):
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w - 1, h - 1], radius=radius, fill=255)
    return m


def star_points(cx, cy, outer, inner, rot=-math.pi / 2):
    pts = []
    for k in range(10):
        r = outer if k % 2 == 0 else inner
        a = rot + k * math.pi / 5
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def smile_crescent(cx, cy, radius, t_max, a_left, a_right, steps=140):
    """Tapered crescent 'smile' polygon (thick in the middle, 0 at the ends).

    Angles are in radians; a smile lives in the lower half (sin > 0 = downward).
    """
    outer, inner = [], []
    for k in range(steps + 1):
        f = k / steps
        theta = a_left + (a_right - a_left) * f
        thick = t_max * math.sin(math.pi * f)  # 0 -> max -> 0
        ox = cx + radius * math.cos(theta)
        oy = cy + radius * math.sin(theta)
        ix = cx + (radius - thick) * math.cos(theta)
        iy = cy + (radius - thick) * math.sin(theta)
        outer.append((ox, oy))
        inner.append((ix, iy))
    return outer + inner[::-1]


def draw_smile(img, cx, cy, radius, t_max, star_r):
    """Orange gradient smile swoosh ending in a star at the right tip."""
    a_left, a_right = math.pi * 0.86, math.pi * 0.14  # left -> right, dipping down
    poly = smile_crescent(cx, cy, radius, t_max, a_left, a_right)

    xs = [p[0] for p in poly]
    ys = [p[1] for p in poly]
    x0, y0 = int(min(xs)) - 4 * S, int(min(ys)) - 4 * S
    x1, y1 = int(max(xs)) + 4 * S, int(max(ys)) + star_r * 3
    w, h = x1 - x0, y1 - y0

    grad = Image.fromarray(
        diagonal_gradient(w, h, ORANGE, ORANGE_HI), "RGB"
    ).convert("RGBA")
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.polygon([(px - x0, py - y0) for px, py in poly], fill=255)

    # star at the right tip of the smile
    rtx = cx + radius * math.cos(a_right)
    rty = cy + radius * math.sin(a_right)
    md.polygon(
        star_points(rtx - x0, rty - y0 - star_r * 0.2, star_r, star_r * 0.42),
        fill=255,
    )
    grad.putalpha(mask)
    img.alpha_composite(grad, (x0, y0))


# --------------------------------------------------------------------------- #
# full horizontal lockup
# --------------------------------------------------------------------------- #
def build_full():
    W, H = 620 * S, 190 * S
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    f_word = ImageFont.truetype(FONT_BOLD, 82 * S)
    x, y = 40 * S, 34 * S
    draw.text((x, y), "Shop", font=f_word, fill=NAVY)
    w_shop = draw.textlength("Shop", font=f_word)
    draw.text((x + w_shop, y), "Star", font=f_word, fill=ORANGE)
    w_total = draw.textlength("ShopStar", font=f_word)

    # smile swoosh beneath the wordmark, spanning its width
    smile_cx = x + w_total / 2
    draw_smile(
        img,
        cx=smile_cx,
        cy=y - 62 * S,       # centre well above so the arc dips under the text
        radius=118 * S,
        t_max=15 * S,
        star_r=17 * S,
    )

    draw = ImageDraw.Draw(img)
    # tagline
    f_tag = ImageFont.truetype(FONT_REG, 23 * S)
    tag = "SMART SHOPPING, SMARTER ANALYTICS"
    tx, ty = x + 4 * S, y + 108 * S
    for ch in tag:
        draw.text((tx, ty), ch, font=f_tag, fill=SLATE)
        tx += draw.textlength(ch, font=f_tag) + 2.5 * S

    return img.resize((620, 190), Image.LANCZOS)


# --------------------------------------------------------------------------- #
# square app icon
# --------------------------------------------------------------------------- #
def build_icon():
    W = 256 * S
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    grad = Image.fromarray(diagonal_gradient(W, W, NAVY, NAVY_HI), "RGB").convert("RGBA")
    grad.putalpha(rounded_mask(W, W, 58 * S))
    img.alpha_composite(grad, (0, 0))
    draw = ImageDraw.Draw(img)

    # white "S" monogram
    f = ImageFont.truetype(FONT_BOLD, 150 * S)
    bbox = draw.textbbox((0, 0), "S", font=f)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((W - tw) / 2 - bbox[0], 42 * S - bbox[1]), "S", font=f, fill=(255, 255, 255, 255))

    # orange smile + star beneath the monogram
    draw_smile(img, cx=W / 2, cy=118 * S, radius=86 * S, t_max=13 * S, star_r=15 * S)

    return img.resize((256, 256), Image.LANCZOS)


if __name__ == "__main__":
    build_full().save("Images/ShopStar_Logo_Full.png")
    build_icon().save("Images/ShopStar_Logo_Icon.png")
    print("Saved: Images/ShopStar_Logo_Full.png, Images/ShopStar_Logo_Icon.png")
