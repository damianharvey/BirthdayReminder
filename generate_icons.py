#!/usr/bin/env python3
"""Generate stylish sage green birthday cake app icons for all iOS sizes."""

import math
import json
import os
from PIL import Image, ImageDraw, ImageFilter

OUTPUT_DIR = "BirthdayReminder/Assets.xcassets/AppIcon.appiconset"

# Colors
BG_TOP       = (236, 245, 232)   # very pale sage / almost white
BG_BOTTOM    = (212, 230, 206)   # soft pale sage
CAKE_SAGE    = (112, 158, 104)   # richer sage green cake
CAKE_DARK    = ( 82, 128,  76)   # darker cake shadow
FROSTING     = (245, 240, 228)   # warm cream frosting
FROSTING2    = (235, 228, 212)   # slightly darker cream
CANDLE1      = (220, 235, 218)   # pale sage candle
CANDLE2      = (200, 220, 196)
FLAME_OUTER  = (255, 210,  80)   # warm yellow
FLAME_INNER  = (255, 255, 200)   # bright center
DRIP         = (240, 232, 215)   # cream drip
PLATE        = (200, 220, 196)   # sage plate


def ease(t):
    return t * t * (3 - 2 * t)


def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.ellipse([x0, y0, x0 + 2*radius, y0 + 2*radius], fill=fill)
    draw.ellipse([x1 - 2*radius, y0, x1, y0 + 2*radius], fill=fill)
    draw.ellipse([x0, y1 - 2*radius, x0 + 2*radius, y1], fill=fill)
    draw.ellipse([x1 - 2*radius, y1 - 2*radius, x1, y1], fill=fill)


def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def draw_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size

    # --- Background gradient (approximate with banded rects) ---
    for y in range(s):
        t = y / s
        color = lerp_color(BG_TOP, BG_BOTTOM, ease(t))
        draw.line([(0, y), (s, y)], fill=color + (255,))

    # Clip to rounded square
    mask = Image.new("L", (s, s), 0)
    mask_draw = ImageDraw.Draw(mask)
    r = int(s * 0.22)
    mask_draw.rounded_rectangle([0, 0, s, s], radius=r, fill=255)
    bg = img.copy()
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    img.paste(bg, mask=mask)
    draw = ImageDraw.Draw(img)

    # Scale helper
    def sc(v):
        return int(v * s / 1024)

    cx = s // 2

    # --- Plate / base shadow ---
    plate_w = sc(620)
    plate_h = sc(38)
    plate_y = sc(780)
    plate_rx = plate_h // 2
    draw_rounded_rect(draw,
        [cx - plate_w//2, plate_y, cx + plate_w//2, plate_y + plate_h],
        plate_rx, PLATE)

    # --- Bottom cake layer ---
    b_w = sc(560)
    b_h = sc(200)
    b_y = sc(588)
    b_rx = sc(22)
    # shadow side
    draw_rounded_rect(draw,
        [cx - b_w//2 + sc(8), b_y + sc(8), cx + b_w//2 + sc(8), b_y + b_h + sc(8)],
        b_rx, CAKE_DARK)
    draw_rounded_rect(draw,
        [cx - b_w//2, b_y, cx + b_w//2, b_y + b_h],
        b_rx, CAKE_SAGE)

    # frosting drip over bottom layer
    drip_y = b_y - sc(12)
    drip_h = sc(36)
    draw_rounded_rect(draw,
        [cx - b_w//2 + sc(4), drip_y, cx + b_w//2 - sc(4), drip_y + drip_h],
        sc(16), FROSTING)
    # small drips down
    for dx in [-sc(160), -sc(60), sc(40), sc(150), sc(220), -sc(230)]:
        dw = sc(22)
        dh = sc(55) + (abs(dx) % sc(20))
        draw.ellipse([cx + dx - dw//2, drip_y + drip_h - sc(10),
                      cx + dx + dw//2, drip_y + drip_h + dh], fill=DRIP)

    # --- Top cake layer ---
    t_w = sc(400)
    t_h = sc(170)
    t_y = sc(388)
    t_rx = sc(20)
    draw_rounded_rect(draw,
        [cx - t_w//2 + sc(8), t_y + sc(8), cx + t_w//2 + sc(8), t_y + t_h + sc(8)],
        t_rx, CAKE_DARK)
    draw_rounded_rect(draw,
        [cx - t_w//2, t_y, cx + t_w//2, t_y + t_h],
        t_rx, CAKE_SAGE)

    # frosting drip over top layer
    top_drip_y = t_y - sc(12)
    top_drip_h = sc(32)
    draw_rounded_rect(draw,
        [cx - t_w//2 + sc(4), top_drip_y, cx + t_w//2 - sc(4), top_drip_y + top_drip_h],
        sc(14), FROSTING)
    for dx in [-sc(100), sc(20), sc(120), -sc(150)]:
        dw = sc(18)
        dh = sc(45) + (abs(dx) % sc(15))
        draw.ellipse([cx + dx - dw//2, top_drip_y + top_drip_h - sc(8),
                      cx + dx + dw//2, top_drip_y + top_drip_h + dh], fill=DRIP)

    # --- Candles ---
    candle_positions = [cx - sc(100), cx, cx + sc(100)]
    candle_colors = [CANDLE1, CANDLE2, CANDLE1]
    cw = sc(30)
    ch = sc(110)
    candle_base_y = top_drip_y - sc(2)

    for i, (cpx, cc) in enumerate(zip(candle_positions, candle_colors)):
        cy_top = candle_base_y - ch
        # candle body
        draw_rounded_rect(draw,
            [cpx - cw//2, cy_top, cpx + cw//2, candle_base_y],
            cw // 2, cc)
        # candle highlight
        draw.rectangle([cpx - cw//2 + sc(4), cy_top + sc(8),
                        cpx - cw//2 + sc(10), candle_base_y - sc(8)],
                       fill=(255, 255, 255, 80))
        # wick
        wick_x = cpx
        wick_y_bottom = cy_top + sc(4)
        wick_y_top = cy_top - sc(14)
        draw.line([(wick_x, wick_y_bottom), (wick_x, wick_y_top)],
                  fill=(80, 60, 40, 220), width=max(1, sc(4)))

        # flame outer
        fw = sc(28)
        fh = sc(46)
        fy = wick_y_top - fh + sc(10)
        draw.ellipse([wick_x - fw//2, fy, wick_x + fw//2, fy + fh],
                     fill=FLAME_OUTER + (230,))
        # flame inner
        iw = sc(14)
        ih = sc(26)
        iy = wick_y_top - ih + sc(8)
        draw.ellipse([wick_x - iw//2, iy, wick_x + iw//2, iy + ih],
                     fill=FLAME_INNER + (255,))

    # Soft glow on candles (blur a bright overlay)
    if size >= 120:
        glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        for cpx in candle_positions:
            candle_base_y2 = top_drip_y - sc(2)
            cy_top2 = candle_base_y2 - ch
            wick_y_top2 = cy_top2 - sc(14)
            gdraw.ellipse([cpx - sc(30), wick_y_top2 - sc(30),
                           cpx + sc(30), wick_y_top2 + sc(30)],
                          fill=(255, 240, 140, 60))
        glow = glow.filter(ImageFilter.GaussianBlur(radius=max(1, sc(18))))
        img = Image.alpha_composite(img, glow)

    return img


# All required iOS icon sizes
SIZES = [
    (20, "Icon-20.png"),
    (29, "Icon-29.png"),
    (40, "Icon-40.png"),
    (58, "Icon-58.png"),
    (60, "Icon-60.png"),
    (76, "Icon-76.png"),
    (80, "Icon-80.png"),
    (87, "Icon-87.png"),
    (120, "Icon-120.png"),
    (152, "Icon-152.png"),
    (167, "Icon-167.png"),
    (180, "Icon-180.png"),
    (1024, "Icon-1024.png"),
]

os.makedirs(OUTPUT_DIR, exist_ok=True)

# Generate 1024 master, then resize
print("Drawing 1024x1024 master...")
master = draw_icon(1024)

for size, filename in SIZES:
    path = os.path.join(OUTPUT_DIR, filename)
    if size == 1024:
        img = master.copy()
    else:
        img = master.resize((size, size), Image.LANCZOS)
    # Convert to RGB PNG (no alpha) as required by App Store
    final = Image.new("RGB", (size, size), (255, 255, 255))
    final.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
    final.save(path, "PNG")
    print(f"  Saved {size}x{size} -> {filename}")

print("\nAll icons generated!")
