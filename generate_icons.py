#!/usr/bin/env python3
"""Generate iOS app icons from a 1024x1024 SVG master."""

import json
import os
import subprocess
import tempfile
from PIL import Image

SVG_SOURCE = "/Users/dharvey/Downloads/BirthdayBell_iOS_1024.svg"
OUTPUT_DIR = "Birthday Bell/Assets.xcassets/AppIcon.appiconset"

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

# Convert SVG to 1024x1024 PNG using sips (macOS built-in)
print(f"Converting SVG master: {SVG_SOURCE}")
with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
    tmp_path = tmp.name

subprocess.run(
    ["sips", "-s", "format", "png", SVG_SOURCE, "--out", tmp_path],
    check=True,
    capture_output=True,
)

master = Image.open(tmp_path).convert("RGBA")
if master.size != (1024, 1024):
    master = master.resize((1024, 1024), Image.LANCZOS)
    print(f"  Resized from {master.size} to 1024x1024")
else:
    print("  Master is 1024x1024")

os.unlink(tmp_path)

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
