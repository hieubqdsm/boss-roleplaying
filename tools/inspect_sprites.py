# inspect_sprites.py — phân tích sprite sheet: dính frame theo cột alpha + contact sheet có số thứ tự.
# Chạy:  python tools/inspect_sprites.py <sheet.png> <output_contact.png>
import sys
from PIL import Image, ImageDraw

def detect_columns(img):
    """Trả về list (x0, x1) của các dải cột có pixel không trong suốt."""
    alpha = img.convert("RGBA").getchannel("A")
    w, h = alpha.size
    px = alpha.load()
    cols = []
    start = None
    for x in range(w):
        opaque = any(px[x, y] > 8 for y in range(h))
        if opaque and start is None:
            start = x
        elif not opaque and start is not None:
            cols.append((start, x))
            start = None
    if start is not None:
        cols.append((start, w))
    return cols

def main():
    src, out = sys.argv[1], sys.argv[2]
    img = Image.open(src).convert("RGBA")
    cols = detect_columns(img)
    print(f"{src}: {img.size}, detected {len(cols)} frame-column(s):")
    for i, (x0, x1) in enumerate(cols):
        print(f"  frame {i}: x {x0}..{x1} (w={x1 - x0})")
    # contact sheet: các frame xếp cạnh nhau, đánh số
    if cols:
        fh = img.height
        total_w = sum(x1 - x0 for x0, x1 in cols) + 4 * len(cols)
        sheet = Image.new("RGBA", (total_w, fh + 14), (32, 32, 32, 255))
        d = ImageDraw.Draw(sheet)
        cx = 2
        for i, (x0, x1) in enumerate(cols):
            fw = x1 - x0
            sheet.paste(img.crop((x0, 0, x1, fh)), (cx, 0))
            d.text((cx + fw // 2 - 4, fh + 1), str(i), fill=(255, 255, 0, 255))
            cx += fw + 4
        sheet.save(out)
        print(f"contact sheet -> {out}")

if __name__ == "__main__":
    main()
