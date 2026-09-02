class_name FightHUD
extends CanvasLayer
const Style := preload("res://scripts/ui/ui_style.gd")

## HUD trận đấu (endless): 2 thanh máu, counter hero đã gục, cooldown 3 kỹ năng,
## banner thông báo + banner phase 2.

var queen_bar: ProgressBar
var hero_bar: ProgressBar
var fallen_label: Label
var banner: Label
var cd_slash: ColorRect
var cd_bolt: ColorRect
var cd_nova: ColorRect


func _ready() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 18
	top.add_theme_constant_override("separation", 24)
	root.add_child(top)

	# ── Phe Queen (trái) ──
	var qside := VBoxContainer.new()
	qside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(qside)
	qside.add_child(Style.label("THE DARK QUEEN", 10, Color("d9a441")))
	queen_bar = Style.health_bar(380, Color("8f1d2c"))
	queen_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	qside.add_child(queen_bar)

	# ── Counter hero gục (giữa) ──
	var mid := VBoxContainer.new()
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(mid)
	fallen_label = Style.label("FALLEN 0", 10, Color("c8d4e0"))
	fallen_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mid.add_child(fallen_label)

	# ── Phe Hero (phải) ──
	var hside := VBoxContainer.new()
	hside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hside)
	var hname := Style.label("THE HERO", 10, Color("c8d4e0"))
	hname.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hside.add_child(hname)
	hero_bar = Style.health_bar(380, Color("3d6ea5"))
	hero_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	hside.add_child(hero_bar)

	# ── Cooldown 3 kỹ năng (góc dưới trái) ──
	var cds := HBoxContainer.new()
	cds.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	cds.offset_left = 24
	cds.offset_bottom = -20
	cds.offset_top = -92
	cds.add_theme_constant_override("separation", 10)
	root.add_child(cds)
	cd_slash = _cd_slot(cds, "SLASH  J")
	cd_bolt = _cd_slot(cds, "BOLT   K")
	cd_nova = _cd_slot(cds, "NOVA   L")

	# ── Banner giữa màn ──
	banner = Style.label("", 22, Color("d9a441"), true)
	banner.set_anchors_preset(Control.PRESET_CENTER)
	banner.pivot_offset = Vector2(60, 12)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.modulate.a = 0.0
	root.add_child(banner)


func _cd_slot(parent: Control, title: String) -> ColorRect:
	var box := VBoxContainer.new()
	parent.add_child(box)
	var lbl := Style.label(title, 8, Color(0.62, 0.56, 0.5))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lbl)
	var slot := ColorRect.new()
	slot.custom_minimum_size = Vector2(56, 56)
	slot.color = Color(0.14, 0.1, 0.16, 0.92)
	box.add_child(slot)
	# overlay tối phủ theo cooldown — con của slot, cao chiếm theo phần trăm
	var veil := ColorRect.new()
	veil.color = Color(0, 0, 0, 0.65)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(veil)
	return veil


func setup(queen_max: int, hero_max: int) -> void:
	queen_bar.max_value = queen_max
	queen_bar.value = queen_max
	hero_bar.max_value = hero_max
	hero_bar.value = hero_max


func update_queen_hp(cur: int, mx: int) -> void:
	queen_bar.max_value = mx
	queen_bar.value = cur


func update_hero_hp(cur: int, mx: int) -> void:
	hero_bar.max_value = mx
	hero_bar.value = cur


func set_fallen(count: int) -> void:
	fallen_label.text = "FALLEN %d" % count


func announce_phase2() -> void:
	show_banner("THE QUEEN AWAKENS", 1.6)


func update_cooldowns(fracs: Vector3) -> void:
	_apply_cd(cd_slash, fracs.x)
	_apply_cd(cd_bolt, fracs.y)
	_apply_cd(cd_nova, fracs.z)


func _apply_cd(veil: ColorRect, ready_frac: float) -> void:
	ready_frac = clampf(ready_frac, 0.0, 1.0)
	# veil phủ từ đỉnh slot xuống, chiếm phần (1 - ready) — đầy dần khi hồi
	veil.anchor_top = 0.0
	veil.anchor_bottom = 1.0 - ready_frac
	veil.modulate = Color(1, 1, 1, 0.35) if ready_frac >= 1.0 else Color(1, 1, 1, 1)


var _banner_tw: Tween


func show_banner(text: String, duration: float) -> void:
	banner.text = text
	if _banner_tw != null and _banner_tw.is_valid():
		_banner_tw.kill()
	_banner_tw = create_tween()
	banner.scale = Vector2(0.6, 0.6)
	_banner_tw.parallel().tween_property(banner, "modulate:a", 1.0, 0.18)
	_banner_tw.parallel().tween_property(banner, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tw.tween_interval(duration)
	_banner_tw.tween_property(banner, "modulate:a", 0.0, 0.4)
