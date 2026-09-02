class_name UIStyle

## Helper tĩnh tạo font/stylebox cho mọi UI — giữ menu code gọn, đồng bộ màu.
## Font size áp qua add_theme_font_size_override ở từng control (Button/Label helper lo sẵn).

const FONT_PATH := "res://assets/fonts/VT323-Regular.ttf"

const COL_BG := Color("120b16")
const COL_PANEL := Color(0.10, 0.07, 0.13, 0.94)
const COL_ACCENT := Color("8f1d2c")
const COL_GOLD := Color("d9a441")
const COL_TEXT := Color("e8dcc8")
const COL_TEXT_DIM := Color(0.62, 0.56, 0.5)

static var _font_file: FontFile


static func font() -> FontFile:
	if _font_file == null:
		_font_file = load(FONT_PATH) as FontFile
	return _font_file


static func flat(bg: Color, border: Color = COL_ACCENT, width: int = 2, radius: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func button(text: String, font_size: int = 14) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", font_size)
	b.add_theme_color_override("font_color", COL_TEXT)
	b.add_theme_color_override("font_hover_color", COL_GOLD)
	b.add_theme_color_override("font_pressed_color", Color("ffcf70"))
	b.add_theme_color_override("font_focus_color", COL_TEXT)
	b.add_theme_stylebox_override("normal", flat(Color(0.16, 0.1, 0.18, 0.9)))
	b.add_theme_stylebox_override("hover", flat(Color(0.28, 0.13, 0.2, 0.95), COL_GOLD))
	b.add_theme_stylebox_override("pressed", flat(Color(0.08, 0.05, 0.1), COL_GOLD))
	b.add_theme_stylebox_override("focus", flat(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func label(text: String, font_size: int, color: Color = COL_TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(COL_PANEL, Color(0.35, 0.2, 0.25), 2, 6))
	return p


static func health_bar(width: int, fill: Color, bg := Color(0.05, 0.04, 0.07, 0.9)) -> ProgressBar:
	var pb := ProgressBar.new()
	pb.custom_minimum_size = Vector2(width, 16)
	pb.min_value = 0
	pb.max_value = 100
	pb.value = 100
	pb.show_percentage = false
	pb.add_theme_stylebox_override("background", flat(bg, Color(0, 0, 0, 0.5), 1, 2))
	var sb := flat(fill, Color(0, 0, 0, 0.4), 1, 2)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pb.add_theme_stylebox_override("fill", sb)
	return pb
