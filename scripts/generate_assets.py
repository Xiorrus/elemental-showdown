"""
Procedural Pixel Art Asset Generator for Elemental Showdown.
Milestone 3: Modular Character Sprite & Customization System.
Generates authentic retro GBA / Pokemon-style compact character sprites (128x128 frames, 512x512 sheets),
modular layer compositor (Shadow, Body/Skin, Face/Eyes, Apparel, Trim/Sash, Hair, VFX),
true 4-frame walk cycles (Down, Right, Left, Up),
true 4-directional attack animations (Down, Right, Left, Up),
and high-res tournament arena surfaces.
"""

import os
import math
import zlib
import struct
import time

def create_png(width, height, pixels):
    row_bytes = 1 + width * 4
    raw_data = bytearray(height * row_bytes)
    idx = 0
    for y in range(height):
        raw_data[idx] = 0  # filter type 0 (None)
        idx += 1
        row = pixels[y]
        for x in range(width):
            c = row[x]
            raw_data[idx] = c[0]
            raw_data[idx+1] = c[1]
            raw_data[idx+2] = c[2]
            raw_data[idx+3] = c[3]
            idx += 4
    
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw_data), 1)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')

def save_png(filepath, width, height, pixels):
    d = os.path.dirname(filepath)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(filepath, 'wb') as f:
        f.write(create_png(width, height, pixels))
    print(f"[Generated] {filepath} ({width}x{height})")

def blank_canvas(w, h, bg=(0, 0, 0, 0)):
    return [[bg for _ in range(w)] for _ in range(h)]

def set_px(canvas, x, y, color):
    if 0 <= y < len(canvas) and 0 <= x < len(canvas[0]):
        if color[3] == 255 or canvas[y][x][3] == 0:
            canvas[y][x] = color
        elif color[3] > 0:
            a = color[3] / 255.0
            bg = canvas[y][x]
            nr = int(color[0] * a + bg[0] * (1 - a))
            ng = int(color[1] * a + bg[1] * (1 - a))
            nb = int(color[2] * a + bg[2] * (1 - a))
            na = min(255, int(color[3] + bg[3] * (1 - a)))
            canvas[y][x] = (nr, ng, nb, na)

def draw_rect(canvas, x, y, w, h, color):
    if color[3] == 255:
        for cy in range(max(0, y), min(len(canvas), y + h)):
            row = canvas[cy]
            for cx in range(max(0, x), min(len(row), x + w)):
                row[cx] = color
    else:
        for cy in range(y, y + h):
            for cx in range(x, x + w):
                set_px(canvas, cx, cy, color)

def draw_rect_outline(canvas, x, y, w, h, color, thick=1):
    for t in range(thick):
        for cx in range(x + t, x + w - t):
            set_px(canvas, cx, y + t, color)
            set_px(canvas, cx, y + h - 1 - t, color)
        for cy in range(y + t, y + h - t):
            set_px(canvas, x + t, cy, color)
            set_px(canvas, x + w - 1 - t, cy, color)

def draw_circle(canvas, cx, cy, r, color):
    r2 = r * r
    for y in range(max(0, cy - r), min(len(canvas), cy + r + 1)):
        dy2 = (y - cy)**2
        row = canvas[y]
        for x in range(max(0, cx - r), min(len(row), cx + r + 1)):
            if (x - cx)**2 + dy2 <= r2:
                row[x] = color

def draw_ellipse(canvas, cx, cy, rx, ry, color):
    for y in range(max(0, cy - ry), min(len(canvas), cy + ry + 1)):
        row = canvas[y]
        for x in range(max(0, cx - rx), min(len(row), cx + rx + 1)):
            if ((x - cx) / float(rx))**2 + ((y - cy) / float(ry))**2 <= 1.0:
                set_px(canvas, x, y, color)

def draw_line(canvas, x0, y0, x1, y1, color, width=1):
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    hw = width // 2
    while True:
        for ox in range(-hw, hw + 1):
            for oy in range(-hw, hw + 1):
                set_px(canvas, x0 + ox, y0 + oy, color)
        if x0 == x1 and y0 == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x0 += sx
        if e2 < dx:
            err += dx
            y0 += sy

def blit(dest, src, dx, dy):
    for y in range(len(src)):
        for x in range(len(src[0])):
            c = src[y][x]
            if c[3] > 0:
                set_px(dest, dx + x, dy + y, c)

# ─────────────────────────────────────────────────────────────────────────────
#  CUSTOMIZATION CATALOGS (F14)
# ─────────────────────────────────────────────────────────────────────────────

SKIN_TONES = {
    "pale": {
        "base": (248, 238, 232, 255),
        "shadow": (214, 196, 190, 255),
    },
    "fair": {
        "base": (246, 206, 176, 255),
        "shadow": (212, 166, 136, 255),
    },
    "tan": {
        "base": (226, 172, 132, 255),
        "shadow": (186, 132, 96, 255),
    },
    "olive": {
        "base": (206, 162, 122, 255),
        "shadow": (166, 122, 86, 255),
    },
    "bronze": {
        "base": (176, 126, 86, 255),
        "shadow": (136, 92, 56, 255),
    },
    "ebony": {
        "base": (112, 76, 56, 255),
        "shadow": (76, 46, 32, 255),
    },
}

HAIR_COLORS = {
    "black": {
        "base": (28, 26, 32, 255),
        "highlight": (48, 44, 56, 255),
    },
    "brown": {
        "base": (78, 50, 32, 255),
        "highlight": (112, 76, 50, 255),
    },
    "blonde": {
        "base": (235, 195, 80, 255),
        "highlight": (255, 225, 125, 255),
    },
    "silver_white": {
        "base": (220, 224, 235, 255),
        "highlight": (255, 255, 255, 255),
    },
    "crimson": {
        "base": (195, 35, 30, 255),
        "highlight": (245, 65, 55, 255),
    },
    "electric_blue": {
        "base": (35, 115, 235, 255),
        "highlight": (85, 175, 255, 255),
    },
    "emerald_green": {
        "base": (35, 155, 75, 255),
        "highlight": (75, 210, 115, 255),
    },
    "violet": {
        "base": (135, 45, 175, 255),
        "highlight": (185, 85, 225, 255),
    },
}

TEAM_PALETTES = {
    "team_alpha": {
        "primary": (36, 38, 46, 255),      # Charcoal Slate
        "secondary": (215, 40, 30, 255),   # Crimson Red
        "accent": (245, 185, 40, 255),     # Imperial Gold
        "pants": (210, 42, 28, 255),
        "boots": (24, 26, 32, 255),
        "vfx_core": (255, 245, 140, 255),
        "vfx_outer": (255, 120, 20, 255),
    },
    "team_zero": {
        "primary": (42, 28, 56, 255),      # Void Violet
        "secondary": (22, 20, 26, 255),    # Obsidian Black
        "accent": (185, 55, 240, 255),     # Neon Amethyst
        "pants": (26, 22, 34, 255),
        "boots": (20, 16, 28, 255),
        "vfx_core": (240, 200, 255, 255),
        "vfx_outer": (170, 40, 230, 255),
    },
    "team_water": {
        "primary": (24, 42, 84, 255),      # Deep Cobalt
        "secondary": (35, 140, 220, 255),  # Cyan Sea
        "accent": (110, 230, 255, 255),    # Aqua Foam
        "pants": (30, 105, 185, 255),
        "boots": (16, 24, 44, 255),
        "vfx_core": (220, 250, 255, 255),
        "vfx_outer": (40, 180, 245, 255),
    },
    "team_earth": {
        "primary": (58, 48, 38, 255),      # Earth Umber
        "secondary": (165, 85, 45, 255),   # Terracotta
        "accent": (65, 185, 110, 255),     # Jade Green
        "pants": (95, 68, 48, 255),
        "boots": (36, 28, 22, 255),
        "vfx_core": (225, 245, 180, 255),
        "vfx_outer": (75, 190, 80, 255),
    },
    "team_air": {
        "primary": (235, 240, 248, 255),   # Cloud White
        "secondary": (75, 85, 102, 255),   # Slate Grey
        "accent": (95, 195, 245, 255),     # Sky Azure
        "pants": (185, 195, 210, 255),
        "boots": (48, 54, 66, 255),
        "vfx_core": (245, 250, 255, 255),
        "vfx_outer": (120, 215, 255, 255),
    },
    "npc_official": {
        "primary": (24, 26, 32, 255),      # Obsidian Black
        "secondary": (245, 245, 248, 255), # Pure Ivory
        "accent": (225, 175, 45, 255),     # Gold Filigree
        "pants": (40, 42, 50, 255),
        "boots": (18, 20, 24, 255),
        "vfx_core": (255, 245, 200, 255),
        "vfx_outer": (230, 180, 50, 255),
    },
}

# ─────────────────────────────────────────────────────────────────────────────
#  MODULAR PROCEDURAL LAYER COMPOSITOR (128x128 Frame, 512x512 Sheet)
# ─────────────────────────────────────────────────────────────────────────────
FRAME_SIZE = 128
SHEET_SIZE = 512

def draw_shadow(canvas, cx, cy):
    """Layer 0: Ground Shadow Oval under character feet."""
    draw_ellipse(canvas, cx, cy + 26, 14, 5, (18, 20, 26, 110))

def draw_base_body(canvas, cx, cy, skin_dict, direction, anim_type, frame_idx):
    """
    Layer 1: Base Body & Skin (Head, Neck, Hands/Fists, Legs, Feet/Boots base).
    Handles walk cycle leg offsets and torso bob.
    """
    skin = skin_dict["base"]
    skin_shadow = skin_dict["shadow"]

    # Vertical torso bob: -1px on passing frames (1 and 3)
    bob = 0
    if anim_type == "walk" and frame_idx in (1, 3):
        bob = -1
    elif anim_type == "attack":
        if frame_idx == 0:
            bob = 1   # Windup crouch
        elif frame_idx == 1:
            bob = -1  # Thrust extension
        elif frame_idx == 2:
            bob = 0   # Full impact
        elif frame_idx == 3:
            bob = 0   # Recovery

    head_y = cy - 12 + bob
    torso_y = cy + bob
    feet_y = cy + 24

    # Legs & Feet contact offsets for 4-frame walk cycle
    left_off = 0
    right_off = 0
    if anim_type == "walk":
        if frame_idx == 0:
            left_off = 2
            right_off = -2
        elif frame_idx == 2:
            left_off = -2
            right_off = 2

    # Head circle
    draw_circle(canvas, cx, head_y, 8, skin)
    # Neck
    draw_rect(canvas, cx - 2, head_y + 6, 4, 3, skin_shadow)

    if direction == "down":
        # Hands at sides or thrusting
        if anim_type == "attack" and frame_idx in (1, 2):
            draw_circle(canvas, cx - 6, torso_y + 14, 3, skin)
            draw_circle(canvas, cx + 6, torso_y + 14, 3, skin)
        else:
            draw_circle(canvas, cx - 11, torso_y + 9 + left_off, 2, skin)
            draw_circle(canvas, cx + 11, torso_y + 9 + right_off, 2, skin)

    elif direction == "right":
        if anim_type == "attack" and frame_idx in (1, 2):
            draw_circle(canvas, cx + 14, torso_y + 6, 3, skin)
        else:
            draw_circle(canvas, cx + 4 + right_off, torso_y + 9, 2, skin)

    elif direction == "left":
        if anim_type == "attack" and frame_idx in (1, 2):
            draw_circle(canvas, cx - 14, torso_y + 6, 3, skin)
        else:
            draw_circle(canvas, cx - 4 - left_off, torso_y + 9, 2, skin)

    elif direction == "up":
        if anim_type == "attack" and frame_idx in (1, 2):
            draw_circle(canvas, cx - 5, head_y - 6, 3, skin)
            draw_circle(canvas, cx + 5, head_y - 6, 3, skin)
        else:
            draw_circle(canvas, cx - 10, torso_y + 9 + left_off, 2, skin)
            draw_circle(canvas, cx + 10, torso_y + 9 + right_off, 2, skin)

def draw_eyes_face(canvas, cx, cy, direction, anim_type, frame_idx):
    """Layer 2: Eyes & Facial Expression."""
    bob = -1 if (anim_type == "walk" and frame_idx in (1, 3)) else 0
    if anim_type == "attack" and frame_idx == 0:
        bob = 1
    head_y = cy - 12 + bob
    eye_col = (20, 22, 28, 255)

    if direction == "down":
        set_px(canvas, cx - 4, head_y, eye_col)
        set_px(canvas, cx + 3, head_y, eye_col)
        set_px(canvas, cx - 4, head_y - 2, eye_col) # Brow
        set_px(canvas, cx + 3, head_y - 2, eye_col)
    elif direction == "right":
        set_px(canvas, cx + 4, head_y - 1, eye_col)
        set_px(canvas, cx + 4, head_y - 2, eye_col)
    elif direction == "left":
        set_px(canvas, cx - 4, head_y - 1, eye_col)
        set_px(canvas, cx - 4, head_y - 2, eye_col)
    elif direction == "up":
        pass  # Back view: no eyes visible

def draw_apparel(canvas, cx, cy, apparel_style, team_pal, direction, anim_type, frame_idx):
    """
    Layer 3: Apparel / Outfit (Gi, Robe, Vest) + Trousers + Boots.
    Implements true scissoring walk cycles and directional lunge postures.
    """
    bob = -1 if (anim_type == "walk" and frame_idx in (1, 3)) else 0
    if anim_type == "attack":
        if frame_idx == 0: bob = 1
        elif frame_idx == 1: bob = -1

    head_y = cy - 12 + bob
    torso_y = cy + bob
    legs_y = cy + 12 + bob
    feet_y = cy + 24

    prim = team_pal["primary"]
    sec = team_pal["secondary"]
    pants = team_pal["pants"]
    boots = team_pal["boots"]

    # Leg cycle offsets
    left_x = 0
    right_x = 0
    left_y = 0
    right_y = 0

    if anim_type == "walk":
        if direction in ("down", "up"):
            if frame_idx == 0:
                left_x, left_y = 2, 1
                right_x, right_y = -2, -1
            elif frame_idx == 2:
                left_x, left_y = -2, -1
                right_x, right_y = 2, 1
        elif direction in ("right", "left"):
            sign = 1 if direction == "right" else -1
            if frame_idx == 0:
                right_x = 3 * sign
                left_x = -3 * sign
            elif frame_idx == 2:
                right_x = -3 * sign
                left_x = 3 * sign

    # 1. Boots & Pants
    if direction == "down":
        # Pants
        draw_rect(canvas, cx - 8 + left_x, legs_y, 6, 9, pants)
        draw_rect(canvas, cx + 2 + right_x, legs_y, 6, 9, pants)
        # Boots
        draw_rect(canvas, cx - 8 + left_x, feet_y - 4 + left_y, 6, 6, boots)
        draw_rect(canvas, cx + 2 + right_x, feet_y - 4 + right_y, 6, 6, boots)

    elif direction == "up":
        # Back pants
        draw_rect(canvas, cx - 7 + left_x, legs_y, 5, 9, pants)
        draw_rect(canvas, cx + 2 + right_x, legs_y, 5, 9, pants)
        # Back boots
        draw_rect(canvas, cx - 7 + left_x, feet_y - 4 + left_y, 5, 6, boots)
        draw_rect(canvas, cx + 2 + right_x, feet_y - 4 + right_y, 5, 6, boots)

    elif direction == "right":
        # Profile legs scissoring
        draw_rect(canvas, cx - 5 + left_x, legs_y, 8, 9, pants)
        draw_rect(canvas, cx - 4 + right_x, feet_y - 4, 6, 6, boots)

    elif direction == "left":
        draw_rect(canvas, cx - 3 + left_x, legs_y, 8, 9, pants)
        draw_rect(canvas, cx - 2 + right_x, feet_y - 4, 6, 6, boots)

    # 2. Torso Outfit Styles
    if apparel_style == "martial_gi":
        if direction == "down":
            draw_rect(canvas, cx - 9, torso_y, 18, 13, prim)
            # V-neck wrap
            draw_rect(canvas, cx - 4, torso_y, 3, 10, sec)
            draw_rect(canvas, cx + 1, torso_y, 3, 10, sec)
            # Sleeves
            draw_rect(canvas, cx - 12, torso_y + 2, 4, 8, prim)
            draw_rect(canvas, cx + 8, torso_y + 2, 4, 8, prim)
        elif direction == "up":
            draw_rect(canvas, cx - 8, torso_y, 16, 13, prim)
            draw_rect(canvas, cx - 11, torso_y + 2, 4, 8, prim)
            draw_rect(canvas, cx + 7, torso_y + 2, 4, 8, prim)
        elif direction == "right":
            draw_rect(canvas, cx - 6, torso_y, 12, 13, prim)
            draw_rect(canvas, cx - 1, torso_y + 2, 4, 8, sec)
            draw_rect(canvas, cx + 1, torso_y + 3, 4, 7, prim)
        elif direction == "left":
            draw_rect(canvas, cx - 6, torso_y, 12, 13, prim)
            draw_rect(canvas, cx - 3, torso_y + 2, 4, 8, sec)
            draw_rect(canvas, cx - 5, torso_y + 3, 4, 7, prim)

    elif apparel_style == "warrior_robe":
        # Extended robe skirt reaching mid-thigh
        if direction == "down":
            draw_rect(canvas, cx - 10, torso_y, 20, 16, prim)
            draw_rect(canvas, cx - 10, torso_y + 14, 20, 2, sec) # Hemline
            draw_rect(canvas, cx - 3, torso_y, 6, 14, sec)       # Mantle
            draw_rect(canvas, cx - 13, torso_y + 2, 4, 9, prim)
            draw_rect(canvas, cx + 9, torso_y + 2, 4, 9, prim)
        elif direction == "up":
            draw_rect(canvas, cx - 9, torso_y, 18, 16, prim)
            draw_rect(canvas, cx - 9, torso_y + 14, 18, 2, sec)
            draw_rect(canvas, cx - 12, torso_y + 2, 4, 9, prim)
            draw_rect(canvas, cx + 8, torso_y + 2, 4, 9, prim)
        elif direction == "right":
            draw_rect(canvas, cx - 7, torso_y, 14, 16, prim)
            draw_rect(canvas, cx - 7, torso_y + 14, 14, 2, sec)
            draw_rect(canvas, cx + 1, torso_y + 3, 4, 8, prim)
        elif direction == "left":
            draw_rect(canvas, cx - 7, torso_y, 14, 16, prim)
            draw_rect(canvas, cx - 7, torso_y + 14, 14, 2, sec)
            draw_rect(canvas, cx - 5, torso_y + 3, 4, 8, prim)

    elif apparel_style == "armored_vest":
        # Heavy cuirass with shoulder plates
        if direction == "down":
            draw_rect(canvas, cx - 9, torso_y, 18, 12, prim)
            # Plate ribs
            draw_rect(canvas, cx - 7, torso_y + 2, 14, 2, sec)
            draw_rect(canvas, cx - 7, torso_y + 6, 14, 2, sec)
            # Shoulder pauldrons
            draw_rect(canvas, cx - 13, torso_y - 1, 5, 5, sec)
            draw_rect(canvas, cx + 8, torso_y - 1, 5, 5, sec)
        elif direction == "up":
            draw_rect(canvas, cx - 8, torso_y, 16, 12, prim)
            draw_rect(canvas, cx - 6, torso_y + 3, 12, 3, sec)
            draw_rect(canvas, cx - 12, torso_y - 1, 5, 5, sec)
            draw_rect(canvas, cx + 7, torso_y - 1, 5, 5, sec)
        elif direction == "right":
            draw_rect(canvas, cx - 6, torso_y, 12, 12, prim)
            draw_rect(canvas, cx - 4, torso_y + 3, 8, 3, sec)
            draw_rect(canvas, cx - 2, torso_y - 1, 6, 5, sec)
        elif direction == "left":
            draw_rect(canvas, cx - 6, torso_y, 12, 12, prim)
            draw_rect(canvas, cx - 4, torso_y + 3, 8, 3, sec)
            draw_rect(canvas, cx - 4, torso_y - 1, 6, 5, sec)

def draw_trim_sash(canvas, cx, cy, apparel_style, team_pal, direction, anim_type, frame_idx):
    """Layer 4: Trim, Sash Belt & Knots."""
    bob = -1 if (anim_type == "walk" and frame_idx in (1, 3)) else 0
    if anim_type == "attack" and frame_idx == 0:
        bob = 1
    torso_y = cy + bob
    accent = team_pal["accent"]

    # Belt band across waist
    if direction == "down":
        draw_rect(canvas, cx - 9, torso_y + 9, 18, 3, accent)
        # Sash knot tails hanging down
        draw_rect(canvas, cx - 2, torso_y + 12, 2, 5, accent)
        draw_rect(canvas, cx + 1, torso_y + 12, 2, 4, accent)
    elif direction == "up":
        draw_rect(canvas, cx - 8, torso_y + 9, 16, 3, accent)
        # Rear sash tails sway
        sway = -1 if frame_idx in (0, 1) else 1
        draw_rect(canvas, cx - 2 + sway, torso_y + 12, 4, 5, accent)
    elif direction == "right":
        draw_rect(canvas, cx - 6, torso_y + 9, 12, 3, accent)
        draw_rect(canvas, cx + 2, torso_y + 12, 2, 4, accent)
    elif direction == "left":
        draw_rect(canvas, cx - 6, torso_y + 9, 12, 3, accent)
        draw_rect(canvas, cx - 4, torso_y + 12, 2, 4, accent)

def draw_hair(canvas, cx, cy, hair_style, hair_col_key, team_pal, direction, anim_type, frame_idx):
    """
    Layer 5: Hair Style & Color + Headband Accent.
    Styles: spiky, topknot, short, flowing.
    Colors: black, brown, blonde, silver_white, crimson, electric_blue, emerald_green, violet.
    """
    bob = -1 if (anim_type == "walk" and frame_idx in (1, 3)) else 0
    if anim_type == "attack" and frame_idx == 0:
        bob = 1
    head_y = cy - 12 + bob

    hair_data = HAIR_COLORS[hair_col_key]
    hair = hair_data["base"]
    hi = hair_data["highlight"]
    accent = team_pal["accent"]

    if hair_style == "spiky":
        # Martial Spiky: upward spikes
        if direction == "down":
            draw_rect(canvas, cx - 8, head_y - 8, 16, 4, hair)
            # Spikes
            draw_line(canvas, cx - 7, head_y - 7, cx - 9, head_y - 12, hi, 2)
            draw_line(canvas, cx - 2, head_y - 8, cx - 3, head_y - 14, hi, 2)
            draw_line(canvas, cx + 3, head_y - 8, cx + 4, head_y - 14, hi, 2)
            draw_line(canvas, cx + 7, head_y - 7, cx + 9, head_y - 12, hi, 2)
            # Headband
            draw_rect(canvas, cx - 8, head_y - 3, 16, 3, accent)
        elif direction == "up":
            draw_circle(canvas, cx, head_y, 8, hair)
            draw_rect(canvas, cx - 8, head_y - 6, 16, 8, hair)
            draw_line(canvas, cx - 6, head_y - 6, cx - 8, head_y - 12, hi, 2)
            draw_line(canvas, cx, head_y - 6, cx, head_y - 14, hi, 2)
            draw_line(canvas, cx + 6, head_y - 6, cx + 8, head_y - 12, hi, 2)
            # Headband knot down back
            draw_rect(canvas, cx - 8, head_y - 2, 16, 3, accent)
            draw_rect(canvas, cx - 2, head_y + 1, 4, 6, accent)
        elif direction == "right":
            draw_rect(canvas, cx - 6, head_y - 7, 10, 5, hair)
            draw_line(canvas, cx - 4, head_y - 7, cx - 7, head_y - 12, hi, 2)
            draw_line(canvas, cx + 1, head_y - 7, cx + 2, head_y - 13, hi, 2)
            draw_rect(canvas, cx - 7, head_y - 2, 13, 3, accent)
            draw_rect(canvas, cx - 11, head_y, 5, 2, accent) # Ribbon tail trailing left
        elif direction == "left":
            draw_rect(canvas, cx - 4, head_y - 7, 10, 5, hair)
            draw_line(canvas, cx + 4, head_y - 7, cx + 7, head_y - 12, hi, 2)
            draw_line(canvas, cx - 1, head_y - 7, cx - 2, head_y - 13, hi, 2)
            draw_rect(canvas, cx - 6, head_y - 2, 13, 3, accent)
            draw_rect(canvas, cx + 6, head_y, 5, 2, accent)

    elif hair_style == "topknot":
        # Samurai / Ronin Topknot
        if direction in ("down", "up"):
            draw_rect(canvas, cx - 7, head_y - 7, 14, 5, hair)
            draw_circle(canvas, cx, head_y - 10, 3, hair)
            draw_rect(canvas, cx - 1, head_y - 13, 3, 4, hi)
            draw_rect(canvas, cx - 8, head_y - 2, 16, 3, accent)
            if direction == "up":
                draw_circle(canvas, cx, head_y, 7, hair)
        elif direction == "right":
            draw_rect(canvas, cx - 6, head_y - 7, 10, 5, hair)
            draw_circle(canvas, cx - 2, head_y - 10, 3, hair)
            draw_rect(canvas, cx - 4, head_y - 13, 3, 4, hi)
            draw_rect(canvas, cx - 7, head_y - 2, 13, 3, accent)
        elif direction == "left":
            draw_rect(canvas, cx - 4, head_y - 7, 10, 5, hair)
            draw_circle(canvas, cx + 2, head_y - 10, 3, hair)
            draw_rect(canvas, cx + 1, head_y - 13, 3, 4, hi)
            draw_rect(canvas, cx - 6, head_y - 2, 13, 3, accent)

    elif hair_style == "short":
        # Clean Crop / Monk fade
        if direction in ("down", "up"):
            draw_circle(canvas, cx, head_y - 1, 8, hair)
            draw_rect(canvas, cx - 8, head_y - 7, 16, 5, hi)
        elif direction in ("right", "left"):
            draw_circle(canvas, cx, head_y - 1, 8, hair)
            draw_rect(canvas, cx - 6, head_y - 7, 12, 5, hi)

    elif hair_style == "flowing":
        # Shoulder-length flowing locks
        if direction == "down":
            draw_rect(canvas, cx - 8, head_y - 7, 16, 5, hair)
            draw_rect(canvas, cx - 9, head_y - 2, 3, 12, hair)
            draw_rect(canvas, cx + 6, head_y - 2, 3, 12, hair)
            draw_rect(canvas, cx - 8, head_y - 2, 16, 2, accent)
        elif direction == "up":
            draw_circle(canvas, cx, head_y, 8, hair)
            draw_rect(canvas, cx - 8, head_y, 16, 14, hair)
            draw_rect(canvas, cx - 6, head_y + 10, 12, 5, hi)
        elif direction == "right":
            draw_rect(canvas, cx - 6, head_y - 7, 11, 5, hair)
            draw_rect(canvas, cx - 8, head_y - 2, 4, 12, hair)
            draw_rect(canvas, cx - 7, head_y - 2, 12, 2, accent)
        elif direction == "left":
            draw_rect(canvas, cx - 5, head_y - 7, 11, 5, hair)
            draw_rect(canvas, cx + 4, head_y - 2, 4, 12, hair)
            draw_rect(canvas, cx - 5, head_y - 2, 12, 2, accent)

def draw_vfx(canvas, cx, cy, team_pal, direction, attack_phase):
    """
    Layer 6: Directional Elemental VFX Arc / Burst.
    attack_phase:
      0: Anticipation (gathering glow at core)
      1: Strike (projecting elemental spark toward target)
      2: Impact (full explosive ring and particle burst)
      3: Recovery (dissipating embers)
    """
    vfx_core = team_pal["vfx_core"]
    vfx_outer = team_pal["vfx_outer"]

    if attack_phase == 0:
        # Subtle energy gather at chest
        draw_circle(canvas, cx, cy + 2, 5, vfx_outer)
        draw_circle(canvas, cx, cy + 2, 2, vfx_core)

    elif attack_phase == 1:
        # Thrust forward in strike direction
        if direction == "down":
            draw_circle(canvas, cx, cy + 20, 10, vfx_outer)
            draw_circle(canvas, cx, cy + 20, 5, vfx_core)
        elif direction == "right":
            draw_circle(canvas, cx + 22, cy + 4, 10, vfx_outer)
            draw_circle(canvas, cx + 22, cy + 4, 5, vfx_core)
        elif direction == "left":
            draw_circle(canvas, cx - 22, cy + 4, 10, vfx_outer)
            draw_circle(canvas, cx - 22, cy + 4, 5, vfx_core)
        elif direction == "up":
            draw_circle(canvas, cx, cy - 18, 10, vfx_outer)
            draw_circle(canvas, cx, cy - 18, 5, vfx_core)

    elif attack_phase == 2:
        # Full elemental blast burst (radius 22px)
        tx, ty = cx, cy
        if direction == "down":
            tx, ty = cx, cy + 26
        elif direction == "right":
            tx, ty = cx + 28, cy + 4
        elif direction == "left":
            tx, ty = cx - 28, cy + 4
        elif direction == "up":
            tx, ty = cx, cy - 24

        draw_circle(canvas, tx, ty, 20, vfx_outer)
        draw_circle(canvas, tx, ty, 12, vfx_core)
        draw_circle(canvas, tx, ty, 6, (255, 255, 255, 255))
        # Burst rays
        for ang in [0, 45, 90, 135, 180, 225, 270, 315]:
            rad = math.radians(ang)
            rx = int(tx + math.cos(rad) * 26)
            ry = int(ty + math.sin(rad) * 26)
            draw_line(canvas, tx, ty, rx, ry, vfx_core, 2)

    elif attack_phase == 3:
        # Dissipating particle trail
        tx, ty = cx, cy
        if direction == "down": tx, ty = cx, cy + 20
        elif direction == "right": tx, ty = cx + 22, cy + 4
        elif direction == "left": tx, ty = cx - 22, cy + 4
        elif direction == "up": tx, ty = cx, cy - 16

        draw_circle(canvas, tx, ty, 8, vfx_outer)
        draw_circle(canvas, tx, ty, 3, vfx_core)

def composite_character_frame(config, direction="down", anim_type="walk", frame_idx=0):
    """
    Renders a single 128x128 frame composited from discrete layers:
    Shadow -> Base Body -> Face/Eyes -> Apparel -> Trim/Sash -> Hair -> VFX.
    Integer-centered at (64, 64) with boots grounded at Y=88.
    """
    canvas = blank_canvas(FRAME_SIZE, FRAME_SIZE)
    cx, cy = 64, 64

    skin_dict = SKIN_TONES[config.get("skin", "fair")]
    hair_style = config.get("hair_style", "spiky")
    hair_col = config.get("hair_color", "crimson")
    apparel_style = config.get("apparel", "martial_gi")
    team_pal = TEAM_PALETTES[config.get("team", "team_alpha")]

    # Layer 0: Ground Shadow
    draw_shadow(canvas, cx, cy)

    # Layer 1: Base Body & Skin
    draw_base_body(canvas, cx, cy, skin_dict, direction, anim_type, frame_idx)

    # Layer 2: Eyes & Face
    draw_eyes_face(canvas, cx, cy, direction, anim_type, frame_idx)

    # Layer 3: Apparel / Outfit
    draw_apparel(canvas, cx, cy, apparel_style, team_pal, direction, anim_type, frame_idx)

    # Layer 4: Trim & Sash
    draw_trim_sash(canvas, cx, cy, apparel_style, team_pal, direction, anim_type, frame_idx)

    # Layer 5: Hair Style & Color
    draw_hair(canvas, cx, cy, hair_style, hair_col, team_pal, direction, anim_type, frame_idx)

    # Layer 6: Directional VFX (for attack sheets)
    if anim_type == "attack":
        draw_vfx(canvas, cx, cy, team_pal, direction, frame_idx)

    return canvas

def build_modular_walk_sheet(config):
    """
    Builds a 512x512 sprite sheet with true 4-frame walk cycles:
    Row 0: Down (South) - Front view, boots scissoring left/right, torso bob
    Row 1: Right (East) - Profile view facing East, leg stride & arm swing
    Row 2: Left (West)  - Profile view facing West
    Row 3: Up (North)   - Back view, boots lift & plant, rear hair sway
    """
    sheet = blank_canvas(SHEET_SIZE, SHEET_SIZE)
    directions = ["down", "right", "left", "up"]

    for row_idx, direction in enumerate(directions):
        for col_idx in range(4):
            frame = composite_character_frame(config, direction=direction, anim_type="walk", frame_idx=col_idx)
            blit(sheet, frame, col_idx * FRAME_SIZE, row_idx * FRAME_SIZE)

    return sheet

def build_modular_attack_sheet(config):
    """
    Builds a 512x512 sprite sheet with true 4-directional attack animations:
    Row 0: Down Attack (South) - downward thrust and downward elemental blast
    Row 1: Right Attack (East) - rightward lunge and blast
    Row 2: Left Attack (West)  - leftward lunge and blast
    Row 3: Up Attack (North)   - upward thrust (back view) and blast
    Columns: 0=Anticipation, 1=Thrust, 2=Impact/Burst, 3=Recovery
    """
    sheet = blank_canvas(SHEET_SIZE, SHEET_SIZE)
    directions = ["down", "right", "left", "up"]

    for row_idx, direction in enumerate(directions):
        for col_idx in range(4):
            frame = composite_character_frame(config, direction=direction, anim_type="attack", frame_idx=col_idx)
            blit(sheet, frame, col_idx * FRAME_SIZE, row_idx * FRAME_SIZE)

    return sheet

# ─────────────────────────────────────────────────────────────────────────────
#  PRESET CHARACTER VISUAL CONFIGURATIONS
# ─────────────────────────────────────────────────────────────────────────────

PRESETS = {
    "player": {
        "skin": "fair",
        "hair_style": "spiky",
        "hair_color": "crimson",
        "apparel": "martial_gi",
        "team": "team_alpha",
    },
    "enemy": {
        "skin": "pale",
        "hair_style": "topknot",
        "hair_color": "electric_blue",
        "apparel": "martial_gi",
        "team": "team_water",
    },
    "earth": {
        "skin": "olive",
        "hair_style": "short",
        "hair_color": "brown",
        "apparel": "armored_vest",
        "team": "team_earth",
    },
    "air": {
        "skin": "tan",
        "hair_style": "flowing",
        "hair_color": "silver_white",
        "apparel": "warrior_robe",
        "team": "team_air",
    },
    "zero": {
        "skin": "pale",
        "hair_style": "spiky",
        "hair_color": "violet",
        "apparel": "warrior_robe",
        "team": "team_zero",
    },
    "fire": {
        "skin": "bronze",
        "hair_style": "spiky",
        "hair_color": "crimson",
        "apparel": "martial_gi",
        "team": "team_alpha",
    },
    "water": {
        "skin": "pale",
        "hair_style": "topknot",
        "hair_color": "electric_blue",
        "apparel": "martial_gi",
        "team": "team_water",
    },
}

# ─────────────────────────────────────────────────────────────────────────────
#  ARENA TILESET, FLOOR, STADIUM, COURTYARD (Preserved High-Res Visuals)
# ─────────────────────────────────────────────────────────────────────────────

def generate_arena_tileset(out_path):
    print("Generating Cobblestone Arena Tileset...")
    W, H = 1024, 1024
    canvas = blank_canvas(W, H)
    TILE_SIZE = 128

    MORTAR     = (42, 45, 54, 255)
    STONE_BASE = (72, 78, 92, 255)
    STONE_LIGHT= (92, 98, 114, 255)
    STONE_DARK = (56, 60, 72, 255)
    STONE_ALT  = (65, 71, 84, 255)
    STONE_WARM = (82, 85, 96, 255)
    GOLD_RUNIC = (215, 165, 45, 255)
    BORDER_DARK= (32, 34, 42, 255)

    def draw_paved_tile(tx, ty, is_center=False):
        ox = tx * TILE_SIZE
        oy = ty * TILE_SIZE
        draw_rect(canvas, ox, oy, TILE_SIZE, TILE_SIZE, MORTAR)

        paver_h = 30
        for row in range(4):
            ry = oy + row * 32 + 1
            offset = 16 if (row % 2 == 1) else 0
            for col in range(-1, 5):
                rx = ox + col * 32 + offset + 1
                rw = 30
                seed = (tx * 17 + ty * 31 + row * 7 + col * 13) % 4
                col_val = [STONE_BASE, STONE_LIGHT, STONE_ALT, STONE_WARM][seed]

                for py in range(paver_h):
                    for px in range(rw):
                        gx = rx + px
                        gy = ry + py
                        if ox <= gx < ox + TILE_SIZE and oy <= gy < oy + TILE_SIZE:
                            if py == 0 or px == 0:
                                set_px(canvas, gx, gy, STONE_LIGHT)
                            elif py == paver_h - 1 or px == rw - 1:
                                set_px(canvas, gx, gy, STONE_DARK)
                            else:
                                set_px(canvas, gx, gy, col_val)

        draw_rect_outline(canvas, ox, oy, TILE_SIZE, TILE_SIZE, BORDER_DARK, 1)
        if is_center:
            draw_circle(canvas, ox + 64, oy + 64, 48, GOLD_RUNIC)
            draw_circle(canvas, ox + 64, oy + 64, 44, STONE_BASE)
            draw_circle(canvas, ox + 64, oy + 64, 18, GOLD_RUNIC)
            draw_circle(canvas, ox + 64, oy + 64, 14, STONE_DARK)

    for ty in range(8):
        for tx in range(8):
            is_c = (tx in (3, 4) and ty in (3, 4))
            draw_paved_tile(tx, ty, is_c)

    save_png(out_path, W, H, canvas)

def generate_arena_floor(out_path):
    print("Generating 1152x640 Tournament Arena Floor...")
    W, H = 1152, 640
    canvas = blank_canvas(W, H)
    TILE_SIZE = 64
    COLS, ROWS = 18, 10

    MORTAR      = (38, 40, 48, 255)
    STONE_BASE  = (68, 74, 88, 255)
    STONE_LIGHT = (88, 95, 110, 255)
    STONE_DARK  = (50, 54, 66, 255)
    STONE_ALT   = (62, 68, 80, 255)
    STONE_WARM  = (76, 80, 92, 255)
    GOLD_RUNIC  = (220, 170, 50, 255)
    BORDER_DARK = (28, 30, 38, 255)

    for ty in range(ROWS):
        for tx in range(COLS):
            ox = tx * TILE_SIZE
            oy = ty * TILE_SIZE
            draw_rect(canvas, ox, oy, TILE_SIZE, TILE_SIZE, MORTAR)

            paver_h = 30
            for row in range(2):
                ry = oy + row * 32 + 1
                offset = 16 if (row % 2 == 1) else 0
                for col in range(-1, 3):
                    rx = ox + col * 32 + offset + 1
                    rw = 30
                    seed = (tx * 19 + ty * 37 + row * 11 + col * 7) % 4
                    col_val = [STONE_BASE, STONE_LIGHT, STONE_ALT, STONE_WARM][seed]

                    for py in range(paver_h):
                        for px in range(rw):
                            gx = rx + px
                            gy = ry + py
                            if ox <= gx < ox + TILE_SIZE and oy <= gy < oy + TILE_SIZE:
                                if py == 0 or px == 0:
                                    set_px(canvas, gx, gy, STONE_LIGHT)
                                elif py == paver_h - 1 or px == rw - 1:
                                    set_px(canvas, gx, gy, STONE_DARK)
                                else:
                                    set_px(canvas, gx, gy, col_val)

            draw_rect_outline(canvas, ox, oy, TILE_SIZE, TILE_SIZE, BORDER_DARK, 1)

    draw_rect_outline(canvas, 0, 0, W, H, BORDER_DARK, 4)
    draw_rect_outline(canvas, 4, 4, W - 8, H - 8, GOLD_RUNIC, 2)
    draw_rect_outline(canvas, 8, 8, W - 16, H - 16, BORDER_DARK, 2)

    CX, CY = W // 2, H // 2
    draw_circle(canvas, CX, CY, 96, GOLD_RUNIC)
    draw_circle(canvas, CX, CY, 92, STONE_DARK)
    draw_circle(canvas, CX, CY, 88, STONE_BASE)
    draw_circle(canvas, CX, CY, 52, GOLD_RUNIC)
    draw_circle(canvas, CX, CY, 48, STONE_DARK)

    save_png(out_path, W, H, canvas)

def generate_cobblestone_courtyard(out_path):
    print("Generating 512x512 Seamless Cobblestone Courtyard...")
    W, H = 512, 512
    canvas = blank_canvas(W, H)

    MORTAR     = (28, 30, 36, 255)
    STONE_BASE = (54, 58, 68, 255)
    STONE_LIGHT= (70, 75, 88, 255)
    STONE_DARK = (40, 43, 52, 255)
    STONE_ALT  = (48, 52, 62, 255)
    STONE_WARM = (60, 64, 74, 255)

    for y in range(H):
        for x in range(W):
            set_px(canvas, x, y, MORTAR)

    paver_h = 30
    for row in range(16):
        ry = row * 32 + 1
        offset = 16 if (row % 2 == 1) else 0
        for col in range(-1, 18):
            rx = col * 32 + offset + 1
            rw = 30
            seed = (row * 13 + col * 29) % 4
            col_val = [STONE_BASE, STONE_LIGHT, STONE_ALT, STONE_WARM][seed]

            for py in range(paver_h):
                for px in range(rw):
                    gx = (rx + px) % W
                    gy = (ry + py) % H
                    if py == 0 or px == 0:
                        set_px(canvas, gx, gy, STONE_LIGHT)
                    elif py == paver_h - 1 or px == rw - 1:
                        set_px(canvas, gx, gy, STONE_DARK)
                    else:
                        set_px(canvas, gx, gy, col_val)

    save_png(out_path, W, H, canvas)

def generate_stadium_arena(out_path):
    print("Building Dark Cobblestone Tournament Stadium...")
    t0 = time.time()
    W, H = 2304, 1792
    CX, CY = W // 2, H // 2
    canvas = blank_canvas(W, H)

    STAGE_W = 1152
    STAGE_H = 640
    STAGE_OX = CX - STAGE_W // 2
    STAGE_OY = CY - STAGE_H // 2

    STAND_T = STAGE_OY - 256
    STAND_B = STAGE_OY + STAGE_H + 256
    STAND_L = STAGE_OX - 256
    STAND_R = STAGE_OX + STAGE_W + 256

    COURT_MORTAR     = (28, 30, 36, 255)
    COURT_STONE_BASE = (54, 58, 68, 255)
    COURT_STONE_LIGHT= (70, 75, 88, 255)
    COURT_STONE_DARK = (40, 43, 52, 255)
    COURT_STONE_ALT  = (48, 52, 62, 255)
    COURT_STONE_WARM = (60, 64, 74, 255)

    STAND_BENCH_TOP  = (64, 70, 84, 255)
    STAND_BENCH_EDGE = (86, 94, 112, 255)
    STAND_RISER      = (40, 44, 54, 255)
    STAND_SHADOW     = (24, 26, 32, 255)

    WALL_STONE       = (52, 56, 68, 255)
    WALL_CAP         = (82, 88, 106, 255)
    RAILING_POST     = (130, 136, 154, 255)
    RAILING_BAR      = (96, 102, 118, 255)

    STAGE_MORTAR     = (34, 36, 44, 255)
    STAGE_STONE      = (68, 74, 88, 255)
    STAGE_LIGHT      = (88, 95, 110, 255)
    STAGE_DARK       = (50, 54, 66, 255)
    STAGE_ALT        = (62, 68, 80, 255)
    STAGE_WARM       = (76, 80, 92, 255)
    GOLD_RUNIC       = (225, 175, 45, 255)
    BORDER_DARK      = (24, 26, 32, 255)

    paver_h = 30
    for y_idx in range(H // 32 + 1):
        ry = y_idx * 32
        offset = 16 if (y_idx % 2 == 1) else 0
        for x_idx in range(-1, W // 32 + 2):
            rx = x_idx * 32 + offset
            rw = 30
            seed = (y_idx * 13 + x_idx * 29) % 5
            col_val = [COURT_STONE_BASE, COURT_STONE_LIGHT, COURT_STONE_ALT, COURT_STONE_WARM, COURT_STONE_DARK][seed]

            for py in range(paver_h):
                for px in range(rw):
                    gx = rx + px
                    gy = ry + py
                    if 0 <= gx < W and 0 <= gy < H:
                        if py == 0 or px == 0:
                            set_px(canvas, gx, gy, COURT_STONE_LIGHT)
                        elif py == paver_h - 1 or px == rw - 1:
                            set_px(canvas, gx, gy, COURT_STONE_DARK)
                        else:
                            set_px(canvas, gx, gy, col_val)

    for y in range(H):
        for x in range(W):
            in_arena = (STAND_L <= x < STAND_R) and (STAND_T <= y < STAND_B)
            if not in_arena:
                dx = max(0, STAND_L - x, x - (STAND_R - 1))
                dy = max(0, STAND_T - y, y - (STAND_B - 1))
                dist = int(math.sqrt(dx*dx + dy*dy)) if (dx > 0 and dy > 0) else max(dx, dy)
                sub = dist % 36
                if sub < 28:
                    if sub < 3:
                        set_px(canvas, x, y, STAND_BENCH_EDGE)
                    else:
                        set_px(canvas, x, y, STAND_BENCH_TOP)
                else:
                    set_px(canvas, x, y, STAND_RISER)

    WALL_W = 10
    draw_rect(canvas, STAND_L, STAND_T - WALL_W, STAND_R - STAND_L, WALL_W, WALL_STONE)
    draw_line(canvas, STAND_L, STAND_T, STAND_R, STAND_T, WALL_CAP, 2)
    draw_line(canvas, STAND_L, STAND_T - WALL_W, STAND_R, STAND_T - WALL_W, STAND_SHADOW, 2)

    draw_rect(canvas, STAND_L, STAND_B, STAND_R - STAND_L, WALL_W, WALL_STONE)
    draw_line(canvas, STAND_L, STAND_B, STAND_R, STAND_B, WALL_CAP, 2)
    draw_line(canvas, STAND_L, STAND_B + WALL_W, STAND_R, STAND_B + WALL_W, STAND_SHADOW, 2)

    draw_rect(canvas, STAND_L - WALL_W, STAND_T, WALL_W, STAND_B - STAND_T, WALL_STONE)
    draw_line(canvas, STAND_L, STAND_T, STAND_L, STAND_B, WALL_CAP, 2)

    draw_rect(canvas, STAND_R, STAND_T, WALL_W, STAND_B - STAND_T, WALL_STONE)
    draw_line(canvas, STAND_R, STAND_T, STAND_R, STAND_B, WALL_CAP, 2)

    def draw_railing(x0, y0, x1, y1):
        draw_line(canvas, x0, y0, x1, y1, RAILING_BAR, 2)
        length = int(math.sqrt((x1 - x0)**2 + (y1 - y0)**2))
        steps = max(1, length // 48)
        for s in range(steps + 1):
            px = int(x0 + (x1 - x0) * (s / float(steps)))
            py = int(y0 + (y1 - y0) * (s / float(steps)))
            draw_rect(canvas, px - 2, py - 6, 4, 12, RAILING_POST)
            draw_circle(canvas, px, py - 6, 3, GOLD_RUNIC)

    draw_railing(STAND_L + 8, STAND_T - 4, STAND_R - 8, STAND_T - 4)
    draw_railing(STAND_L + 8, STAND_B + 4, STAND_R - 8, STAND_B + 4)
    draw_railing(STAND_L - 4, STAND_T + 8, STAND_L - 4, STAND_B - 8)
    draw_railing(STAND_R + 4, STAND_T + 8, STAND_R + 4, STAND_B - 8)

    draw_rect(canvas, STAGE_OX - 8, STAGE_OY - 4, STAGE_W + 20, STAGE_H + 20, (18, 20, 26, 170))
    TILE_SZ = 64
    COLS, ROWS = 18, 10
    for ty in range(ROWS):
        for tx in range(COLS):
            ox = STAGE_OX + tx * TILE_SZ
            oy = STAGE_OY + ty * TILE_SZ
            draw_rect(canvas, ox, oy, TILE_SZ, TILE_SZ, STAGE_MORTAR)
            p_h = 30
            for row in range(2):
                ry = oy + row * 32 + 1
                offset = 16 if (row % 2 == 1) else 0
                for col in range(-1, 3):
                    rx = ox + col * 32 + offset + 1
                    rw = 30
                    seed = (tx * 19 + ty * 37 + row * 11 + col * 7) % 4
                    col_val = [STAGE_STONE, STAGE_LIGHT, STAGE_ALT, STAGE_WARM][seed]

                    for py in range(p_h):
                        for px in range(rw):
                            gx = rx + px
                            gy = ry + py
                            if ox <= gx < ox + TILE_SZ and oy <= gy < oy + TILE_SZ:
                                if py == 0 or px == 0:
                                    set_px(canvas, gx, gy, STAGE_LIGHT)
                                elif py == p_h - 1 or px == rw - 1:
                                    set_px(canvas, gx, gy, STAGE_DARK)
                                else:
                                    set_px(canvas, gx, gy, col_val)
            draw_rect_outline(canvas, ox, oy, TILE_SZ, TILE_SZ, BORDER_DARK, 1)

    draw_rect_outline(canvas, STAGE_OX, STAGE_OY, STAGE_W, STAGE_H, BORDER_DARK, 5)
    draw_rect_outline(canvas, STAGE_OX + 5, STAGE_OY + 5, STAGE_W - 10, STAGE_H - 10, GOLD_RUNIC, 3)
    draw_rect_outline(canvas, STAGE_OX + 8, STAGE_OY + 8, STAGE_W - 16, STAGE_H - 16, (40, 44, 55, 255), 2)

    draw_circle(canvas, CX, CY, 96, GOLD_RUNIC)
    draw_circle(canvas, CX, CY, 92, STAGE_DARK)
    draw_circle(canvas, CX, CY, 88, STAGE_STONE)
    draw_circle(canvas, CX, CY, 52, GOLD_RUNIC)
    draw_circle(canvas, CX, CY, 48, STAGE_DARK)
    draw_circle(canvas, CX, CY, 22, GOLD_RUNIC)
    draw_circle(canvas, CX, CY, 18, (28, 30, 38, 255))

    for angle_deg in [0, 45, 90, 135, 180, 225, 270, 315]:
        rad = math.radians(angle_deg)
        x1 = int(CX + math.cos(rad) * 48)
        y1 = int(CY + math.sin(rad) * 48)
        x2 = int(CX + math.cos(rad) * 92)
        y2 = int(CY + math.sin(rad) * 92)
        draw_line(canvas, x1, y1, x2, y2, GOLD_RUNIC, 2)

    save_png(out_path, W, H, canvas)
    print(f"Tournament Stadium generated in {time.time() - t0:.2f}s!")

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(base_dir, "..", "assets")
    os.makedirs(assets_dir, exist_ok=True)

    print("=== Generating Modular Character Sprites & Tournament Assets (Milestone 3) ===")

    # 1. Surfaces & Arena Backgrounds
    generate_stadium_arena(os.path.join(assets_dir, "stadium_arena.png"))
    generate_arena_tileset(os.path.join(assets_dir, "arena_tileset.png"))
    generate_arena_floor(os.path.join(assets_dir, "arena_floor.png"))
    generate_cobblestone_courtyard(os.path.join(assets_dir, "cobblestone_courtyard.png"))

    # 2. Modular Character Sheets (512x512, 128x128 frames)
    # Target sheet sets required by Task 1:
    targets = [
        ("player", PRESETS["player"]),
        ("enemy",  PRESETS["enemy"]),
        ("earth",  PRESETS["earth"]),
        ("air",    PRESETS["air"]),
        ("zero",   PRESETS["zero"]),
        ("fire",   PRESETS["fire"]),
        ("water",  PRESETS["water"]),
    ]

    for prefix, cfg in targets:
        print(f"Generating Modular Sheets for: {prefix} (Team: {cfg['team']}, Hair: {cfg['hair_style']}/{cfg['hair_color']}, Apparel: {cfg['apparel']})...")
        walk_sheet = build_modular_walk_sheet(cfg)
        save_png(os.path.join(assets_dir, f"{prefix}_walk.png"), SHEET_SIZE, SHEET_SIZE, walk_sheet)

        attack_sheet = build_modular_attack_sheet(cfg)
        save_png(os.path.join(assets_dir, f"{prefix}_attack.png"), SHEET_SIZE, SHEET_SIZE, attack_sheet)

    print("=== All Modular Character Assets Successfully Generated! ===")

if __name__ == "__main__":
    main()
