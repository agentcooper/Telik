#!/usr/bin/env python3
"""Generate the Icon Composer app icon (Telik/AppIcon.icon) from the Apple 📺 emoji.

The icon is a single TV layer on a gradient fill, with a separate fill for the
dark appearance. macOS 26+ renders it natively (including dark and tinted
modes); for older systems actool derives a flat AppIcon.icns from it at build
time. A classic .appiconset can't do this: macOS ignores dark entries there.

Source: scripts/icon/television.png
(https://emojigraph.org/media/apple/television_1f4fa.png, 160x160).

Usage: python3 scripts/icon/make_icons.py   (needs numpy and pillow)
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
ICON = HERE.parent.parent / "Telik/AppIcon.icon"
EMOJI = HERE / "television.png"

# The system draws the icon shape over the whole canvas, so the TV is sized
# relative to it (~80% of the plate, as in the previous hand-drawn icon).
SIZE = 1024
TV_SIZE = 824

# Diagonal (top-left -> bottom-right) fill gradients per appearance.
FILLS = {
    "light": ((255, 255, 255), (180, 173, 156)),
    "dark": ((68, 68, 72), (22, 22, 25)),
}

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


def fill(colors) -> dict:
    srgb = lambda c: "srgb:" + ",".join(f"{v / 255:.5f}" for v in (*c, 255))
    return {
        "linear-gradient": [srgb(c) for c in colors],
        "orientation": {"start": {"x": 0, "y": 0}, "stop": {"x": 1, "y": 1}},
    }


def main() -> None:
    (ICON / "Assets").mkdir(parents=True, exist_ok=True)
    tv_layer().save(ICON / "Assets/tv.png", optimize=True)
    spec = {
        "fill": fill(FILLS["light"]),
        "fill-specializations": [{"appearance": "dark", "value": fill(FILLS["dark"])}],
        "groups": [
            {
                "layers": [{"image-name": "tv.png", "name": "tv"}],
                "shadow": {"kind": "neutral", "opacity": 0.5},
                "translucency": {"enabled": False, "value": 0.5},
            }
        ],
        "supported-platforms": {"squares": ["macOS"]},
    }
    (ICON / "icon.json").write_text(json.dumps(spec, indent=2) + "\n")
    print(f"wrote {ICON}")


if __name__ == "__main__":
    main()
