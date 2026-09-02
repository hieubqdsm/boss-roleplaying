class_name Arena
extends Node2D

## Vòng lặp ván đấu: setup 2 phe, đếm round hero hồi sinh, hiện kết thúc.

const QueenScript := preload("res://scripts/queen.gd")
const HeroScript := preload("res://scripts/hero.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const EndScript := preload("res://scripts/ui/end_screen.gd")
const PauseScript := preload("res://scripts/ui/pause_menu.gd")

const MAX_ROUNDS := 5
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
var fight_active := false
var fight_time := 0.0
var damage_dealt := 0
var damage_taken := 0
var _respawn_timer := 0.0
var _end_timer := 0.0

const ROMAN := ["I", "II", "III", "IV", "V"]


func _ready() -> void:
	hero.target = queen
	queen.setup(hero, Vector2(X_MIN, X_MAX), GROUND_Y)
	hero.position = Vector2(HERO_SPAWN_X, GROUND_Y)
	queen.damage_dealt.connect(func(amount: int) -> void: damage_dealt += amount)
	hero.damage_taken.connect(func(amount: int) -> void: damage_taken += amount)
	queen.died.connect(_on_queen_died)
	hero.died.connect(_on_hero_died)
	queen.health.health_changed.connect(hud.update_queen_hp)
	hero.health.health_changed.connect(hud.update_hero_hp)
	hud.setup(queen.health.max_health, hero.health.max_health)
	hud.set_round(1, MAX_ROUNDS)
	GameAudio.play_music("fight")
	_start_round(1)


func _process(delta: float) -> void:
	if not fight_active:
		return
	fight_time += delta
	hud.update_cooldowns(queen.cooldown_fractions())
	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_respawn()
	if _end_timer > 0.0:
		_end_timer -= delta
		if _end_timer <= 0.0:
			_end_fight()


func _start_round(round: int) -> void:
	round_idx = round
	fight_active = true
	hero.setup_round(round)
	hero.position = Vector2(HERO_SPAWN_X, GROUND_Y)
	hero.show()
	hud.update_hero_hp(hero.health.health, hero.health.max_health)
	hud.show_banner("ASCENSION %s" % ROMAN[round - 1], 1.4)
	GameAudio.play_sfx("round_start")


func _respawn() -> void:
	_start_round(round_idx)


func _on_hero_died() -> void:
	damage_dealt += 0
	hud.show_banner("THE HERO FALLS", 1.1)
	var next := round_idx + 1
	if next > MAX_ROUNDS:
		fight_active = false
		_end_timer = 1.6
		return
	round_idx = next
	_respawn_timer = 2.2


func _on_queen_died() -> void:
	fight_active = false
	_end_timer = 1.8


func _end_fight() -> void:
	var victory := not queen.dead
	var stats := {
		"time": fight_time,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"rounds": 1 if round_idx == 1 else round_idx,
	}
	GameAudio.stop_music()
	GameAudio.play_sfx("victory" if victory else "defeat")
	pause_ui.process_mode = Node.PROCESS_MODE_DISABLED
	Events.fight_ended.emit(victory, stats)
	end_ui.show_result(victory, stats)
