"""Draws the Play Store icon (512 x 512) and feature graphic (1024 x 500)
from the launcher artwork (res/drawable/ic_launcher_foreground.xml) and the
app's bundled fonts. Needs Pillow:
    python tool/make_store_graphics.py
Output: docs/release/graphics/.
"""
import os

from PIL import Image, ImageDraw, ImageFont

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out_dir = os.path.join(root, 'docs/release/graphics')
os.makedirs(out_dir, exist_ok=True)

NAVY = (0x1F, 0x3A, 0x4D)
PAPER = (0xF7, 0xF5, 0xF0)
FOLD = (0xD9, 0xD3, 0xC4)
GOLD = (0xE0, 0xA8, 0x4A)
MIST = (0xC9, 0xD3, 0xDA)
SS = 4  # supersampling for smooth edges


def mark(draw, ox, oy, s):
    """The launcher mark in its 108-unit canvas, at offset (ox, oy), scale s."""
    def box(x0, y0, x1, y1, fill, r=0):
        draw.rounded_rectangle(
            [ox + x0 * s, oy + y0 * s, ox + x1 * s, oy + y1 * s], r * s, fill=fill)
    # sheet with a cut corner
    draw.polygon([
        (ox + 38 * s, oy + 30 * s), (ox + 60 * s, oy + 30 * s),
        (ox + 72 * s, oy + 42 * s), (ox + 72 * s, oy + 76 * s),
        (ox + 70 * s, oy + 78 * s), (ox + 38 * s, oy + 78 * s),
        (ox + 36 * s, oy + 76 * s), (ox + 36 * s, oy + 32 * s),
    ], fill=PAPER)
    draw.polygon([
        (ox + 60 * s, oy + 30 * s), (ox + 60 * s, oy + 40 * s),
        (ox + 62 * s, oy + 42 * s), (ox + 72 * s, oy + 42 * s),
    ], fill=FOLD)
    box(42, 50, 66, 53, NAVY)
    box(42, 57, 66, 60, NAVY)
    box(42, 64, 58, 67, NAVY)
    box(42, 42, 54, 45, GOLD)


def icon():
    size = 512 * SS
    im = Image.new('RGB', (size, size), NAVY)
    # Larger than the launcher's safe zone: Play shows the icon unmasked.
    s = size / 108 * 1.35
    mark(ImageDraw.Draw(im), size / 2 - 54 * s, size / 2 - 54 * s, s)
    im = im.resize((512, 512), Image.LANCZOS)
    im.save(os.path.join(out_dir, 'icon_512.png'))


def feature():
    w, h = 1024 * SS, 500 * SS
    im = Image.new('RGB', (w, h), NAVY)
    d = ImageDraw.Draw(im)
    s = 380 * SS / 108
    mark(d, 40 * SS, (h - 108 * s) / 2, s)
    fonts = os.path.join(root, 'assets/fonts')
    title = ImageFont.truetype(os.path.join(fonts, 'SourceSerif4-SemiBold.ttf'), 104 * SS)
    line = ImageFont.truetype(os.path.join(fonts, 'Inter-Medium.ttf'), 34 * SS)
    small = ImageFont.truetype(os.path.join(fonts, 'Inter-Regular.ttf'), 28 * SS)
    x = 420 * SS
    d.text((x, 120 * SS), 'DocNook', font=title, fill=PAPER)
    d.rectangle([x, 252 * SS, x + 64 * SS, 258 * SS], fill=GOLD)
    d.text((x, 285 * SS), 'Read, scan, convert, combine.', font=line, fill=PAPER)
    d.text((x, 340 * SS), 'All on your phone. No internet needed.', font=small, fill=MIST)
    im = im.resize((1024, 500), Image.LANCZOS)
    im.save(os.path.join(out_dir, 'feature_graphic.png'))


icon()
feature()
print('wrote docs/release/graphics/icon_512.png and feature_graphic.png')
