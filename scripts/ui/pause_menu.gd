class_name PauseMenu
extends CanvasLayer
const Style := preload("res://scripts/ui/ui_style.gd")
const SettingsScript := preload("res://scripts/ui/settings_menu.gd")

## Pause overlay (ESC). process_mode ALWAYS để vẫn nhận input khi paused.

signal closed

var _menu_box: VBoxContainer
var _settings: SettingsScript
var _settings_open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel()
	center.add_child(panel)

	_menu_box = VBoxContainer.new()
	_menu_box.add_theme_constant_override("separation", 10)
	panel.add_child(_menu_box)

	_menu_box.add_child(Style.label("TẠM DỪNG", 18, Color("d9a441")))
	var sep := HSeparator.new()
	_menu_box.add_child(sep)
	_add_button("TIẾP TỤC", _on_resume)
	_add_button("ĐÁNH LẠI", _on_restart)
	_add_button("CÀI ĐẶT", _on_settings)
	_add_button("VỀ MENU CHÍNH", _on_main_menu)

	_settings = load("res://scenes/ui/settings_menu.tscn").instantiate()
	_settings.visible = false
	_settings.closed.connect(_on_settings_closed)
	panel.add_child(_settings)

	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if _settings_open:
		_on_settings_closed()
		return
	visible = not visible
	get_tree().paused = visible
	if visible:
		GameAudio.play_sfx("ui_click")


func _add_button(text: String, handler: Callable) -> void:
	var b := Style.button(text, 12)
	b.pressed.connect(handler)
	_menu_box.add_child(b)


func _on_resume() -> void:
	GameAudio.play_sfx("ui_click")
	visible = false
	get_tree().paused = false
	closed.emit()


func _on_restart() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_settings() -> void:
	GameAudio.play_sfx("ui_click")
	_settings_open = true
	_menu_box.visible = false
	_settings.visible = true


func _on_settings_closed() -> void:
	_settings_open = false
	_settings.visible = false
	_menu_box.visible = true
