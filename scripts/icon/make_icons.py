#!/usr/bin/env python3
"""Generate the light and dark macOS app icons from the Apple 📺 emoji.

Source: scripts/icon/television.png
(https://emojigraph.org/media/apple/television_1f4fa.png, 160x160).

Usage: python3 scripts/icon/make_icons.py
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

HERE = Path(__file__).resolve().parent
ICONSET = HERE.parent.parent / "Telik/Assets.xcassets/AppIcon.appiconset"
EMOJI = HERE / "television.png"

SIZE = 1024
PLATE = (100, 924)  # plate spans [100, 924) on both axes
SQUIRCLE_N = 5.0
TV_SIZE = 664  # rendered emoji size in px (TV body ends up ~638px wide)
SS = 4  # supersampling for the plate mask

# Plate gradients along the top-left -> bottom-right diagonal, as
# (x + y, (r, g, b)) knots. The light one is sampled from the original icon.
PLATES = {
    "light": [
        (200, (255, 255, 255)),
        (450, (254, 254, 254)),
        (950, (225, 222, 214)),
        (1170, (212, 207, 197)),
        (1392, (198, 193, 179)),
        (1680, (186, 179, 163)),
        (1846, (180, 173, 156)),
    ],
    "dark": [
        (200, (68, 68, 72)),
        (1846, (22, 22, 25)),
    ],
}

SLOTS = [  # (base filename, pixel size)
    ("icon_16x16@2x", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]


def squircle_mask() -> Image.Image:
    n = SIZE * SS
    lo, hi = PLATE[0] * SS, PLATE[1] * SS
    c, r = (lo + hi - 1) / 2, (hi - lo) / 2
    yy, xx = np.mgrid[0:n, 0:n].astype(np.float32)
    inside = (np.abs((xx - c) / r) ** SQUIRCLE_N + np.abs((yy - c) / r) ** SQUIRCLE_N) <= 1
    big = Image.fromarray((inside * 255).astype(np.uint8), "L")
    return big.resize((SIZE, SIZE), Image.LANCZOS)


def shadow(mask: Image.Image, opacity: float, blur: float, dy: int) -> Image.Image:
    a = np.asarray(mask.filter(ImageFilter.GaussianBlur(blur))).astype(np.float32) * opacity
    a = np.roll(a, dy, axis=0)
    out = np.zeros((SIZE, SIZE, 4), np.uint8)
    out[..., 3] = a.clip(0, 255).astype(np.uint8)
    return Image.fromarray(out, "RGBA")


def gradient(knots) -> Image.Image:
    yy, xx = np.mgrid[0:SIZE, 0:SIZE]
    diag = (xx + yy).astype(np.float32)
    xs = [k for k, _ in knots]
    rgb = np.stack([np.interp(diag, xs, [c[i] for _, c in knots]) for i in range(3)], -1)
    alpha = np.full((SIZE, SIZE, 1), 255, np.float32)
    return Image.fromarray(np.concatenate([rgb, alpha], -1).astype(np.uint8), "RGBA")


def main_body(mask: np.ndarray) -> np.ndarray:
    """Keep only the 4-connected region containing the image centre."""
    h, w = mask.shape
    region = np.zeros_like(mask)
    region[h // 2, w // 2] = True
    while True:
        grown = region.copy()
        grown[1:, :] |= region[:-1, :]
        grown[:-1, :] |= region[1:, :]
        grown[:, 1:] |= region[:, :-1]
        grown[:, :-1] |= region[:, 1:]
        grown &= mask
        if np.array_equal(grown, region):
            return region
        region = grown


def tv_layer() -> Image.Image:
    # Upscale in premultiplied space so transparent pixels don't bleed dark fringes.
    src = np.asarray(Image.open(EMOJI).convert("RGBA")).astype(np.float32)
    # Drop stray faint pixels (the source has one in its top-right corner)
    # that would otherwise become visible specks on the plate.
    src[..., 3] *= main_body(src[..., 3] > 0)
    pm = src.copy()
    pm[..., :3] *= src[..., 3:] / 255
    chans = [Image.fromarray(pm[..., i]).resize((TV_SIZE, TV_SIZE), Image.LANCZOS) for i in range(4)]
    pm = np.stack([np.asarray(ch) for ch in chans], -1).clip(0, 255)
    a = pm[..., 3:]
    rgb = np.where(a > 0, pm[..., :3] * 255 / np.maximum(a, 1e-3), 0)
    tv = Image.fromarray(np.concatenate([rgb, a], -1).clip(0, 255).astype(np.uint8), "RGBA")
    layer = Image.new("RGBA", (SIZE, SIZE))
    off = (SIZE - TV_SIZE) // 2
    layer.alpha_composite(tv, (off, off))
    return layer


def main() -> None:
    mask = squircle_mask()
    tv = tv_layer()
    tv_alpha = tv.getchannel("A")
    for appearance, knots in PLATES.items():
        icon = Image.new("RGBA", (SIZE, SIZE))
        icon.alpha_composite(shadow(mask, 0.30, 14, 10))
        plate = gradient(knots)
        plate.putalpha(mask)
        icon.alpha_composite(plate)
        tv_shadow_opacity = 0.35 if appearance == "light" else 0.6
        icon.alpha_composite(shadow(tv_alpha, tv_shadow_opacity, 10, 8))
        icon.alpha_composite(tv)
        suffix = "" if appearance == "light" else "~dark"
        for name, size in SLOTS:
            img = icon if size == SIZE else icon.resize((size, size), Image.LANCZOS)
            img.save(ICONSET / f"{name}{suffix}.png", optimize=True)
        print(f"wrote {appearance} icons")


if __name__ == "__main__":
    main()
