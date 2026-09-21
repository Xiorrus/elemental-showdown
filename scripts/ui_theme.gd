# ui_theme.gd
# Central design system for Elemental Showdown.
# Enforces cohesive dark-fantasy martial arts RPG aesthetics across all screens:
# - Restrained, elegant palette (obsidian canvas, slate surfaces, warm ivory text, antique gold highlights)
# - Element accents applied strictly where functionally meaningful
# - Spacing scale: 4, 8, 12, 16, 24, 32, 48px
# - Clear button hierarchy: Primary (burnished gold), Secondary (slate outline), Tertiary (ghost)
# - No unnecessary enclosing boxes; uses spacing, elevation, and subtle dividers
class_name UITheme
extends RefCounted

# ── 1. Color Palette ──────────────────────────────────────────────────────────
const BG_DARK           = Color(0.035, 0.045, 0.07, 1.0)   # Deep obsidian arena background
const BG_OVERLAY        = Color(0.02, 0.03, 0.05, 0.85)    # Translucent glass / modal backdrop

const SURFACE_BASE      = Color(0.06, 0.08, 0.12, 0.95)   # Base surface for content cards
const SURFACE_RAISED    = Color(0.09, 0.12, 0.18, 0.95)   # Slightly elevated cards & active elements
const SURFACE_SUNKEN    = Color(0.04, 0.05, 0.08, 0.90)   # Inset tracks, wells, empty slots

const BORDER_SUBTLE     = Color(0.18, 0.23, 0.32, 0.70)   # Clean, thin card separation (1px)
const BORDER_FAINT      = Color(0.12, 0.16, 0.22, 0.50)   # Minimalist grouping lines
const BORDER_GOLD       = Color(0.82, 0.65, 0.24, 0.90)   # Antique gold focus/selection highlight
const BORDER_GOLD_DIM   = Color(0.60, 0.48, 0.18, 0.60)   # Subtle gold accent

const GOLD_PRIMARY      = Color(0.92, 0.76, 0.30, 1.0)    # Primary action fill & major heading text
const GOLD_HOVER        = Color(1.00, 0.86, 0.45, 1.0)    # Active hover state
const GOLD_DARK         = Color(0.55, 0.42, 0.12, 1.0)    # Shadow/accent

const TEXT_PRIMARY      = Color(0.92, 0.94, 0.98, 1.0)    # Warm ivory / crisp readable text
const TEXT_SECONDARY    = Color(0.65, 0.72, 0.82, 1.0)    # Muted readable metadata & descriptions
const TEXT_MUTED        = Color(0.42, 0.48, 0.58, 0.9)    # Labels, captions, empty slot hints
const TEXT_DARK         = Color(0.08, 0.07, 0.05, 1.0)    # Contrast text on gold buttons

# Element Accents (applied with purpose, not saturated everywhere)
const ELEM_FIRE         = Color(0.90, 0.32, 0.24, 1.0)
const ELEM_WATER        = Color(0.24, 0.58, 0.92, 1.0)
const ELEM_EARTH        = Color(0.35, 0.72, 0.42, 1.0)
const ELEM_AIR          = Color(0.22, 0.78, 0.72, 1.0)
const ELEM_ZERO         = Color(0.72, 0.42, 0.92, 1.0)

const ELEMENT_COLORS = {
	"fire":  ELEM_FIRE,
	"water": ELEM_WATER,
	"earth": ELEM_EARTH,
	"air":   ELEM_AIR,
	"zero":  ELEM_ZERO
}

# ── 2. Spacing Scale ──────────────────────────────────────────────────────────
const SPACE_XS = 4
const SPACE_SM = 8
const SPACE_MD = 12
const SPACE_LG = 16
const SPACE_XL = 24
const SPACE_2XL = 32
const SPACE_3XL = 48

# ── 3. StyleBox Factories ─────────────────────────────────────────────────────

# Base Card: Clean, dark slate surface with 1px subtle border and soft rounded corners
static func make_card_style(raised: bool = false, focus: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = SURFACE_RAISED if raised else SURFACE_BASE
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = BORDER_GOLD if focus else (BORDER_SUBTLE if raised else BORDER_FAINT)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 12
	sb.content_margin_top = 10
	sb.content_margin_right = 12
	sb.content_margin_bottom = 10
	return sb

# Sunken Inset: For empty slots, stat tracks, and search fields
static func make_sunken_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = SURFACE_SUNKEN
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = BORDER_FAINT
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	return sb

# Primary Action Button: Burnished gold surface with dark text and subtle outer gleam
static func make_btn_primary(hovered: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	if pressed:
		sb.bg_color = Color(0.78, 0.62, 0.20, 1.0)
	elif hovered:
		sb.bg_color = GOLD_HOVER
		sb.shadow_color = Color(0.92, 0.76, 0.30, 0.35)
		sb.shadow_size = 8
	else:
		sb.bg_color = GOLD_PRIMARY
		sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		sb.shadow_size = 4

	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = Color(1.0, 0.95, 0.70, 0.9) if (hovered or pressed) else BORDER_GOLD
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 16
	sb.content_margin_top = 10
	sb.content_margin_right = 16
	sb.content_margin_bottom = 10
	return sb

# Secondary Button: Slate surface, clean 1px border, warm ivory text
static func make_btn_secondary(hovered: bool = false, active: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	if active:
		sb.bg_color = Color(0.12, 0.16, 0.24, 0.95)
		sb.border_color = BORDER_GOLD
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
	elif hovered:
		sb.bg_color = Color(0.10, 0.14, 0.22, 0.95)
		sb.border_color = Color(0.45, 0.60, 0.85, 0.9)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
	else:
		sb.bg_color = SURFACE_BASE
		sb.border_color = BORDER_SUBTLE
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1

	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 14
	sb.content_margin_top = 8
	sb.content_margin_right = 14
	sb.content_margin_bottom = 8
	return sb

# Tertiary / Ghost Button: Frameless, minimal padding, ideal for subtle actions (Bench, Unequip)
static func make_btn_ghost(hovered: bool = false) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.20, 0.30, 0.50) if hovered else Color(0.0, 0.0, 0.0, 0.0)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = BORDER_FAINT if hovered else Color(0.0, 0.0, 0.0, 0.0)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	sb.content_margin_left = 8
	sb.content_margin_top = 4
	sb.content_margin_right = 8
	sb.content_margin_bottom = 4
	return sb

# Compact Pill / Tag: For League tier chips, stat badges, and element pills
static func make_pill_style(accent_color: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.85)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = accent_color if accent_color != Color.TRANSPARENT else BORDER_FAINT
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_bottom_left = 12
	sb.content_margin_left = 10
	sb.content_margin_top = 4
	sb.content_margin_right = 10
	sb.content_margin_bottom = 4
	return sb
