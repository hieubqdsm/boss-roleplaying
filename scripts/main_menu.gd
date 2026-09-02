class_name MainMenu
extends Control
const Style := preload("res://scripts/ui/ui_style.gd")

## Menu chính: New Game / Settings / Credits / Quit.

const SETTINGS_SCENE := preload("res://scenes/ui/settings_menu.tscn")
const SettingsScript := preload("res://scripts/ui/settings_menu.gd")

var _settings: SettingsScript


func _ready() -> void:
	GameAudio.play_music("menu")

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 90
	box.offset_top = -40
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var title := Style.label("BOSS", 44, Color("8f1d2c"))
	box.add_child(title)
	var title2 := Style.label("ROLEPLAYING", 30, Color("d9a441"))
	box.add_child(title2)
	var subtitle := Style.label("Bạn là trùm cuối. Hãy sống sót.", 9, Color(0.62, 0.56, 0.5))
	box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 26)
	box.add_child(spacer)

	_add_btn(box, "NEW GAME", _on_new_game)
	_add_btn(box, "CÀI ĐẶT", _on_settings)
	_add_btn(box, "CREDITS", _on_credits)
	_add_btn(box, "THOÁT", _on_quit)

	var hint := Style.label("A/D di chuyển  ·  J chém  ·  K pháo  ·  L nova  ·  ESC tạm dừng", 8, Color(0.45, 0.4, 0.38))
	hint.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = 24
	hint.offset_top = -30
	add_child(hint)

	var version := Style.label("M0 vertical slice", 8, Color(0.4, 0.36, 0.34))
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.offset_right = -24
	version.offset_top = -30
	add_child(version)


func _add_btn(parent: Node, text: String, handler: Callable) -> void:
	var b := Style.button(text, 14)
	b.custom_minimum_size = Vector2(280, 0)
	b.pressed.connect(handler)
	parent.add_child(b)


func _on_new_game() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/arena.tscn")


func _on_settings() -> void:
	GameAudio.play_sfx("ui_click")
	if _settings != null and is_instance_valid(_settings):
		return
	_settings = SETTINGS_SCENE.instantiate()
	_settings.set_anchors_preset(Control.PRESET_CENTER)
	_settings.closed.connect(func() -> void:
		_settings.queue_free()
		_settings = null
	)
	add_child(_settings)


func _on_credits() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/credits.tscn")


func _on_quit() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().quit()
