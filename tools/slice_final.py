# slice_final.py — cắt frame từ sprite sheet (theo cột alpha) + sinh SpriteFrames .tres cho Godot 4.
# Nguồn layout đã được xác nhận bằng tools/inspect_sprites.py + xem contact sheet.
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
A = os.path.join(ROOT, "assets")


def detect_columns(img, threshold=8):
    alpha = img.convert("RGBA").getchannel("A")
    w, h = alpha.size
    px = alpha.load()
    cols, start = [], None
    for x in range(w):
        opaque = any(px[x, y] > threshold for y in range(h))
        if opaque and start is None:
            start = x
        elif not opaque and start is not None:
            cols.append((start, x))
            start = None
    if start is not None:
        cols.append((start, w))
    return cols


def save_frames(img, cols, out_dir, prefix, pad=2):
    os.makedirs(out_dir, exist_ok=True)
    paths = []
    for i, (x0, x1) in enumerate(cols):
        box = (max(0, x0 - pad), 0, min(img.width, x1 + pad), img.height)
        frame = img.crop(box)
        p = os.path.join(out_dir, f"{prefix}{i}.png")
        frame.save(p)
        paths.append(p)
    return paths


def save_uniform(img, count, out_dir, prefix, rows=1):
    os.makedirs(out_dir, exist_ok=True)
    fw, fh = img.width // count, img.height // rows
    paths = []
    n = 0
    for r in range(rows):
        for c in range(count):
            frame = img.crop((c * fw, r * fh, (c + 1) * fw, (r + 1) * fh))
            p = os.path.join(out_dir, f"{prefix}{n}.png")
            frame.save(p)
            paths.append(p)
            n += 1
    return paths


def rel(p):
    return "res://" + os.path.relpath(p, ROOT).replace("\\", "/")


def emit_sprite_frames(path, anims):
    """anims: list of (name, [paths], fps, loop). Ghi SpriteFrames .tres format 3."""
    lines = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (len(anims) and sum(len(f) for _, f, _, _ in anims) + 1)]
    ids = {}
    for _, frames, _, _ in anims:
        for f in frames:
            if f in ids:
                continue
            ids[f] = f"tex_{os.path.basename(f)[:-4]}"
            lines.append(f'[ext_resource type="Texture2D" path="{rel(f)}" id="{ids[f]}"]')
    anim_entries = []
    for name, frames, fps, loop in anims:
        fl = ", ".join(
            '{"duration": 1.0, "texture": ExtResource("%s")}' % ids[f] for f in frames
        )
        anim_entries.append(
            '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (fl, str(loop).lower(), name, fps)
        )
    lines.append("[resource]")
    lines.append("animations = [%s]" % ",\n".join(anim_entries))
    with open(path, "w", newline="\n") as fp:
        fp.write("\n\n".join(lines) + "\n")
    print("wrote", rel(path))


def main():
    # ── QUEEN ─────────────────────────────────────────────
    qs = Image.open(os.path.join(A, "sprites/queen/sorceress_sheet.png")).convert("RGBA")
    qcols = detect_columns(qs)
    assert len(qcols) == 17, f"queen frame count changed: {len(qcols)}"
    qdir = os.path.join(A, "sprites/queen")
    for i in range(17):  # xoá frame cũ nếu chạy lại
        fp = os.path.join(qdir, f"f{i}.png")
        if os.path.exists(fp):
            os.remove(fp)
    qf = save_frames(qs, qcols, qdir, "f")
    emit_sprite_frames(
        os.path.join(qdir, "queen_frames.tres"),
        [
            ("idle", [qf[0], qf[1]], 3.0, True),
            ("cast", [qf[2], qf[3], qf[4], qf[5]], 9.0, False),
            ("nova", [qf[6], qf[7], qf[5]], 7.0, False),
            ("hurt", [qf[12], qf[13]], 8.0, False),
            ("death", [qf[14], qf[15], qf[16]], 4.0, False),
        ],
    )

    # ── BOLT (projectile của queen — frame 8..11 của sheet) ──
    bdir = os.path.join(A, "sprites/fx")
    bolt_frames = [qf[8], qf[9], qf[10], qf[11]]

    # ── HERO ──────────────────────────────────────────────
    hdir = os.path.join(A, "sprites/hero")
    hero = {}
    for anim in ["idle", "run", "attack", "hurt", "jump"]:
        img = Image.open(os.path.join(hdir, f"gothic-hero-{anim}.png")).convert("RGBA")
        cols = detect_columns(img)
        for f in os.listdir(hdir):
            if f.startswith(f"{anim}_"):
                os.remove(os.path.join(hdir, f))
        hero[anim] = save_frames(img, cols, hdir, f"{anim}_")
        print(f"hero/{anim}: {len(hero[anim])} frames")
    emit_sprite_frames(
        os.path.join(hdir, "hero_frames.tres"),
        [
            ("idle", hero["idle"], 4.0, True),
            ("run", hero["run"], 12.0, True),
            ("attack", hero["attack"], 11.0, False),
            ("hurt", hero["hurt"], 8.0, False),
            ("jump", hero["jump"], 8.0, False),
        ],
    )

    # ── FX ────────────────────────────────────────────────
    ghost = Image.open(os.path.join(bdir, "ghost-vanish.png")).convert("RGBA")
    for f in os.listdir(bdir):
        if f.startswith("ghostv_"):
            os.remove(os.path.join(bdir, f))
    gf = save_uniform(ghost, 7, bdir, "ghostv_")

    skull = Image.open(os.path.join(bdir, "fire-skull.png")).convert("RGBA")
    for f in os.listdir(bdir):
        if f.startswith("skull_"):
            os.remove(os.path.join(bdir, f))
    sf = save_uniform(skull, 6, bdir, "skull_", rows=2)

    emit_sprite_frames(
        os.path.join(bdir, "fx_frames.tres"),
        [
            ("bolt", bolt_frames, 10.0, True),
            ("ghost_vanish", gf, 9.0, False),
            ("skull", sf, 10.0, True),
        ],
    )
    print("done")


if __name__ == "__main__":
    main()
