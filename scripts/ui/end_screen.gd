class_name EndScreen
extends CanvasLayer
const Style := preload("res://scripts/ui/ui_style.gd")

## Màn kết thúc: VICTORY khi hạ hero đủ 5 round, DEFEAT khi Queen gục.
## Hiện stats trận + 2 lựa chọn.

var _title: Label
var _stats: Label
var _panel: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	visible = false

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.65)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = Style.panel()
	center.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(box)

	_title = Style.label("", 24, Color("8f1d2c"), true)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)

	_stats = Style.label("", 10, Color(0.62, 0.56, 0.5))
	_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_stats)

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 14)
	box.add_child(btn_row)

	var again := Style.button("ĐÁNH LẠI", 12)
	again.pressed.connect(_on_again)
	btn_row.add_child(again)

	var menu := Style.button("MENU CHÍNH", 12)
	menu.pressed.connect(_on_menu)
	btn_row.add_child(menu)


func show_result(victory: bool, stats: Dictionary) -> void:
	# Endless: chỉ còn màn thua — tham số victory giữ cho tương thích signal.
	_title.text = "THE QUEEN FALLS"
	_title.add_theme_color_override("font_color", Color("8f1d2c"))
	var minutes := int(stats.get("time", 0.0)) / 60
	var seconds := int(stats.get("time", 0.0)) % 60
	_stats.text = "Hero đã gục: %d   ·   Thời gian trị vì: %02d:%02d\nSát thương gây ra: %d   ·   Sát thương nhận: %d\n%s" % [
		stats.get("heroes_fallen", 0), minutes, seconds,
		stats.get("damage_dealt", 0), stats.get("damage_taken", 0),
		stats.get("legacy", "")
	]
	visible = true


func _on_again() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
