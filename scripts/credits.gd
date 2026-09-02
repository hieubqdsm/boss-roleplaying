class_name Credits
extends Control
const Style := preload("res://scripts/ui/ui_style.gd")

## Credits — nguồn asset + license (bắt buộc ghi nhận CC-BY, phần còn lại CC0).


func _ready() -> void:
	GameAudio.play_music("menu")

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := Style.panel()
	center.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	box.add_child(Style.label("CREDITS", 18, Color("d9a441")))
	box.add_child(_line("BOSS ROLEPLAYING — M0 vertical slice", 9, Color("e8dcc8")))

	var credit_text := "Sorceress sprite — 'Animated Sorcerer Witch' (CC-BY 3.0)\n    nguồn: opengameart.org/content/animated-sorcerer-witch\n\nGothic Hero, Gothic Castle, Old Dark Castle, Fire Skull,\nGhost, Hell Beast fireball — 'Gothicvania Patreon's\nCollection' by Luis Zuno (ansimuz) — public domain (CC0)\n    nguồn: opengameart.org/content/gothicvania-patreons-collection\n\nNhạc: '8-bit Monstervania I' (CC0),\n    'Abandoned Castle loop' by starninjas (CC0)\n\nSFX: 'The Essential Retro Video Game Sound Effects\n    Collection [512 sounds]' by Juhani Junkala (CC0)\n\nFont: Press Start 2P — OFL (Google Fonts)"
	var body := Style.label(credit_text, 8, Color(0.62, 0.56, 0.5))
	box.add_child(body)

	var back := Style.button("QUAY LẠI", 12)
	back.pressed.connect(_on_back)
	box.add_child(back)


func _line(text: String, size: int, color: Color) -> Label:
	return Style.label(text, size, color)


func _on_back() -> void:
	GameAudio.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
