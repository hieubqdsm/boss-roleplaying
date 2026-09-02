class_name Arena
extends Node2D

## Chế độ ENDLESS: hero hồi sinh vô hạn, mỗi lần mạnh "khôn" hơn (AI học đòn,
## aggression có trần). Ván chỉ kết thúc khi Queen gục. Queen hồi FULL máu
## mỗi round (souls-like boss). Thắng cuộc của hero = boss ngã, không có Victory.

const QueenScript := preload("res://scripts/queen.gd")
const HeroScript := preload("res://scripts/hero.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const EndScript := preload("res://scripts/ui/end_screen.gd")
const PauseScript := preload("res://scripts/ui/pause_menu.gd")

const GROUND_Y := 590.0
const X_MIN := 70.0
const X_MAX := 1082.0
const HERO_SPAWN_X := 150.0

@onready var queen: QueenScript = $Queen
@onready var hero: HeroScript = $Hero
@onready var hud: HudScript = $HUD
@onready var end_ui: EndScript = $EndUI
@onready var pause_ui: PauseScript = $PauseUI

var round_idx := 1
var heroes_fallen := 0
var fight_active := false
var fight_time := 0.0
var damage_dealt := 0
var damage_taken := 0

@onready var respawn_timer: Timer = $RespawnTimer
@onready var end_timer: Timer = $EndTimer


func _ready() -> void:
	hero.target = queen
	queen.setup(hero, Vector2(X_MIN, X_MAX), GROUND_Y)
	hero.position = Vector2(HERO_SPAWN_X, GROUND_Y)
	queen.damage_dealt.connect(func(amount: int) -> void: damage_dealt += amount)
	queen.damage_taken.connect(func(amount: int) -> void: damage_taken += amount)
	queen.died.connect(_on_queen_died)
	hero.died.connect(_on_hero_died)
	queen.health.health_changed.connect(hud.update_queen_hp)
	hero.health.health_changed.connect(hud.update_hero_hp)
	hud.setup(queen.health.max_health, hero.health.max_health)
	respawn_timer.timeout.connect(_respawn)
	end_timer.timeout.connect(_end_fight)
	queen.phase2_reached.connect(_on_phase2)
	hud.set_fallen(0)
	hero.load_memory()  # Mortholme: hero nhớ mọi ván trước qua user://hero_memory.cfg
	GameAudio.play_music("fight")
	_start_round(1)


func _process(delta: float) -> void:
	if not fight_active:
		return
	fight_time += delta
	hud.update_cooldowns(queen.cooldown_fractions())
	hud.update_hero_stamina(hero.stamina_frac(), hero.flasks_left())


func _on_phase2() -> void:
	hud.announce_phase2()
	GameAudio.play_sfx("round_start")


## Banner mở màn theo ký ức — mỗi lần gặp lại, hero "nhớ" bạn hơn.
func _memory_banner() -> String:
	var d := hero.deaths_total()
	if d == 0:
		return "A STRANGER COMES"
	if d < 5:
		return "THE HERO RETURNS — HE REMEMBERS"
	if d < 15:
		return "HE KNOWS YOUR TRICKS"
	return "HE HAS DIED A THOUSAND DEATHS FOR YOU"


func _start_round(round: int) -> void:
	round_idx = round
	fight_active = true
	queen.reset_for_round()
	hero.setup_round(round)
	hero.position = Vector2(HERO_SPAWN_X, GROUND_Y)
	hero.show()
	hud.update_hero_hp(hero.health.health, hero.health.max_health)
	hud.set_fallen(heroes_fallen)
	if round == 1:
		hud.show_banner(_memory_banner(), 1.6)
	else:
		hud.show_banner("ASCENSION %d" % round, 1.4)
	GameAudio.play_sfx("round_start")
	print("[ARENA] bắt đầu round %d — hero HP %d, queen HP %d" % [
		round, hero.health.health, queen.health.health
	])


func _respawn() -> void:
	_start_round(round_idx)


func _on_hero_died() -> void:
	heroes_fallen += 1
	hud.set_fallen(heroes_fallen)
	print("[ARENA] hero gục (lần thứ %d, round %d) → hồi sinh sau %.1fs" % [
		heroes_fallen, round_idx, respawn_timer.wait_time
	])
	hud.show_banner("THE HERO FALLS", 1.1)
	round_idx += 1
	respawn_timer.start()


func _on_queen_died() -> void:
	print("[ARENA] queen gục (round %d, %.1fs) → END (đã hạ %d hero)" % [
		round_idx, fight_time, heroes_fallen
	])
	fight_active = false
	end_timer.start()


func _end_fight() -> void:
	# Endless: kết thúc duy nhất khi Queen gục — luôn là màn "The Queen Falls".
	var stats := {
		"time": fight_time,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"heroes_fallen": heroes_fallen,
		"legacy": hero.memory_summary(),
	}
	hero.save_memory(queen.skill_uses, true)
	GameAudio.stop_music()
	GameAudio.play_sfx("defeat")
	pause_ui.process_mode = Node.PROCESS_MODE_DISABLED
	Events.fight_ended.emit(false, stats)
	end_ui.show_result(false, stats)
	print("[ARENA] kết thúc (endless) — stats=%s" % str(stats))
