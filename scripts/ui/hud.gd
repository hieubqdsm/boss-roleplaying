class_name FightHUD
extends CanvasLayer
const Style := preload("res://scripts/ui/ui_style.gd")
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

## HUD trận đấu (endless). CẤU TRÚC NODE KHAI TĨNH trong hud.tscn
## (review 2026-09-02: hết UI code-built — mở editor thấy cây ngay);
## script này chỉ WIring dữ liệu + style đồng bộ qua UIStyle.

@onready var queen_bar: ProgressBar = $Root/TopBar/QueenSide/QueenHealth
@onready var hero_bar: ProgressBar = $Root/TopBar/HeroSide/HeroHealth
@onready var hero_stamina_bar: ProgressBar = $Root/TopBar/HeroSide/HeroStamina
@onready var fallen_label: Label = $Root/TopBar/CenterSide/FallenLabel
@onready var banner: Label = $Root/Banner
@onready var cd_slash: ColorRect = $Root/SkillBar/SlashSlot/SlashFill/Veil
@onready var cd_bolt: ColorRect = $Root/SkillBar/BoltSlot/BoltFill/Veil
@onready var cd_nova: ColorRect = $Root/SkillBar/NovaSlot/NovaFill/Veil
@onready var _flask_row: HBoxContainer = $Root/TopBar/HeroSide/HeroFlasks
@onready var _flask_pips: Array[ColorRect] = [
	$Root/TopBar/HeroSide/HeroFlasks/Flask1,
	$Root/TopBar/HeroSide/HeroFlasks/Flask2,
	$Root/TopBar/HeroSide/HeroFlasks/Flask3,
]


func _ready() -> void:
	_style()
	_flask_row.visible = BrainScript.ESTUS_ENABLED


## Style đồng bộ qua UIStyle — không rải theme override trong tscn.
func _style() -> void:
	var named := {
		$Root/TopBar/HeroSide/HeroName: [10, Style.COL_TEXT],
		$Root/TopBar/QueenSide/QueenName: [10, Style.COL_GOLD],
		fallen_label: [10, Color("c8d4e0")],
		$Root/SkillBar/SlashSlot/SlashKey: [8, Style.COL_TEXT_DIM],
		$Root/SkillBar/BoltSlot/BoltKey: [8, Style.COL_TEXT_DIM],
		$Root/SkillBar/NovaSlot/NovaKey: [8, Style.COL_TEXT_DIM],
	}
	for label: Label in named:
		var size: int = named[label][0]
		var color: Color = named[label][1]
		label.add_theme_font_override("font", Style.font())
		label.add_theme_font_size_override("font_size", int(size * Style.FONT_SCALE))
		label.add_theme_color_override("font_color", color)
	banner.add_theme_font_override("font", Style.font())
	banner.add_theme_font_size_override("font_size", int(22 * Style.FONT_SCALE))
	banner.add_theme_color_override("font_color", Style.COL_GOLD)
	_style_bar(hero_bar, Color("3d6ea5"))
	_style_bar(queen_bar, Color("8f1d2c"))
	_style_bar(hero_stamina_bar, Color("3e8f6e"))


func _style_bar(bar: ProgressBar, fill: Color) -> void:
	bar.add_theme_stylebox_override("background", Style.flat(Color(0.05, 0.04, 0.07, 0.9), Color(0, 0, 0, 0.5), 1, 2))
	bar.add_theme_stylebox_override("fill", Style.flat(fill, Color(0, 0, 0, 0.4), 1, 2))


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


## Stamina (0..1) + số bình estus còn của hero.
func update_hero_stamina(frac: float, flasks: int) -> void:
	hero_stamina_bar.value = clampf(frac, 0.0, 1.0) * 100.0
	for i in _flask_pips.size():
		_flask_pips[i].color = Color("d9a441") if i < flasks else Color(0.25, 0.2, 0.24)


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
