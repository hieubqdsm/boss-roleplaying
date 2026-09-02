class_name SettingsMenu
extends Control
const Style := preload("res://scripts/ui/ui_style.gd")

## Panel cài đặt dùng chung (instanced trong main menu và pause menu).
## Chỉnh là áp dụng + lưu ngay (user://settings.cfg).

signal closed

var _rows := VBoxContainer.new()


func _ready() -> void:
	var panel := Style.panel()
	add_child(panel)
	panel.add_child(_rows)
	_rows.add_theme_constant_override("separation", 10)
	_rows.add_child(Style.label("CÀI ĐẶT", 14, Color("d9a441")))

	_slider_row("Âm lượng chung", GameSettings.master_volume, func(v: float) -> void:
		GameSettings.master_volume = v
	)
	_slider_row("Nhạc", GameSettings.music_volume, func(v: float) -> void:
		GameSettings.music_volume = v
	)
	_slider_row("Hiệu ứng", GameSettings.sfx_volume, func(v: float) -> void:
		GameSettings.sfx_volume = v
	)

	_toggle_row("Toàn màn hình", GameSettings.fullscreen, func(pressed: bool) -> void:
		GameSettings.fullscreen = pressed
	)
	_toggle_row("V-Sync", GameSettings.vsync, func(pressed: bool) -> void:
		GameSettings.vsync = pressed
	)

	var back := Style.button("ĐÓNG", 11)
	back.pressed.connect(_on_back)
	_rows.add_child(back)
	_custom_minimum()


func _custom_minimum() -> void:
	custom_minimum_size = Vector2(360, 0)


func _slider_row(title: String, initial: float, setter: Callable) -> void:
	var row := VBoxContainer.new()
	_rows.add_child(row)
	row.add_child(Style.label(title, 9, Color(0.62, 0.56, 0.5)))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = initial * 100.0
	slider.custom_minimum_size = Vector2(280, 18)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	slider.value_changed.connect(func(v: float) -> void:
		setter.call(v / 100.0)
		GameSettings.apply_settings()
		GameSettings.save_settings()
	)


func _toggle_row(title: String, initial: bool, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_rows.add_child(row)
	var lbl := Style.label(title, 9, Color(0.62, 0.56, 0.5))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)
	var toggle := CheckButton.new()
	toggle.button_pressed = initial
	row.add_child(toggle)
	toggle.toggled.connect(func(pressed: bool) -> void:
		setter.call(pressed)
		GameSettings.apply_settings()
		GameSettings.save_settings()
	)


func _on_back() -> void:
	GameAudio.play_sfx("ui_click")
	closed.emit()
