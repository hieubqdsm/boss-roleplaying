class_name Hero
extends Node2D

## Hero — AI thách đấu Queen. Chết thì ARENA gọi setup_round() để hồi sinh
## mạnh hơn. Não AI nằm ở HeroBrain (thuần logic, test headless được).

const GhostFXScene := preload("res://scenes/fx/ghost_vanish.tscn")
const SparkFXScene := preload("res://scenes/fx/hit_spark.tscn")
const HealthScript := preload("res://scripts/combat/health.gd")
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

signal died
signal damage_taken(amount: int)

@export var base_health := 55
@export var health_bonus_per_round := 20
@export var base_damage := 7
@export var damage_bonus_per_round := 2
@export var base_speed := 120.0
@export var speed_bonus_per_round := 12.0
@export var base_stagger := 0.32
@export var attack_range := 58.0
@export var windup_time := 0.45
@export var strike_time := 0.22
@export var recover_time := 0.55

var health: HealthScript
var brain := BrainScript.new()
var brain_state := {}
var target: Node2D
var invuln := 0.0
var dead := false
var round_idx := 1

var _knock_x := 0.0
var _damage := 7
var _speed := 120.0
var _stagger := 0.32
var _respawn_flash := 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = $Health
	health.died.connect(_on_died)
	sprite.play("idle")


func setup_round(round: int) -> void:
	round_idx = round
	brain_state = {}
	dead = false
	invuln = 0.9
	_respawn_flash = 0.9
	_knock_x = 0.0
	_damage = base_damage + damage_bonus_per_round * (round - 1)
	_speed = base_speed + speed_bonus_per_round * (round - 1)
	_stagger = maxf(0.14, base_stagger - 0.035 * (round - 1))
	health.reset_to(base_health + health_bonus_per_round * (round - 1))
	modulate.a = 1.0
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		return
	invuln = maxf(0.0, invuln - delta)
	_respawn_flash = maxf(0.0, _respawn_flash - delta)
	if _respawn_flash > 0.0 and fmod(_respawn_flash, 0.18) < 0.09:
		modulate.a = 0.45
	else:
		modulate.a = 1.0

	if not is_instance_valid(target) or target.is_dead():
		sprite.play("idle")
		return

	var dist_x := target.global_position.x - global_position.x
	var cfg := {
		"attack_range": attack_range,
		"windup_time": windup_time - 0.03 * (round_idx - 1),
		"strike_time": strike_time,
		"recover_time": recover_time,
		"stagger_time": _stagger,
		"retreat_time": 0.0,
	}
	var res := brain.step(dist_x, cfg, brain_state, delta)
	_apply_action(res, dist_x, delta)


func _apply_action(res: Dictionary, dist_x: float, delta: float) -> void:
	var move := float(res["move_dir"]) * _speed
	_knock_x = move_toward(_knock_x, 0.0, 900.0 * delta)
	position.x += (move + _knock_x) * delta
	sprite.flip_h = dist_x < 0.0

	match int(res["action"]):
		BrainScript.Action.APPROACH:
			sprite.play("run")
		BrainScript.Action.RETREAT:
			sprite.play("run")
		BrainScript.Action.WINDUP:
			sprite.play("idle")
			# Telegraph: nhấp nháy đỏ dồn dập trước khi vung kiếm.
			sprite.modulate = Color(1.0, 0.45, 0.45) if fmod(brain_state["timer"], 0.16) < 0.08 else Color.WHITE
		BrainScript.Action.STRIKE:
			if sprite.animation != "attack" or not sprite.is_playing():
				sprite.play("attack")
				_strike_hit()
			sprite.modulate = Color.WHITE
		BrainScript.Action.RECOVER:
			sprite.modulate = Color.WHITE
			if sprite.animation != "attack":
				sprite.play("idle")
		BrainScript.Action.STAGGER:
			sprite.modulate = Color.WHITE
			sprite.play("hurt")
		_:
			sprite.modulate = Color.WHITE
			sprite.play("idle")


func is_dead() -> bool:
	return dead


func _strike_hit() -> void:
	if not is_instance_valid(target) or target.is_dead():
		return
	var dx := absf(target.global_position.x - global_position.x)
	if dx <= attack_range * 1.35:
		target.apply_hero_hit(_damage, global_position.x)


## Queen đánh trúng hero. knockback_x: hướng đẩy (đã nhân dấu).
func take_hit(dmg: int, from_x: float, knockback_x := 240.0) -> void:
	if dead or invuln > 0.0:
		return
	health.take_damage(dmg)
	damage_taken.emit(dmg)
	GameAudio.play_sfx("hit_hero")
	var spark := SparkFXScene.instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position + Vector2(0, -44)
	if not dead:
		brain.on_damaged(brain_state)
		_knock_x = knockback_x
		sprite.modulate = Color.WHITE


func _on_died() -> void:
	dead = true
	GameAudio.play_sfx("hero_die")
	sprite.play("hurt")
	var ghost := GhostFXScene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position + Vector2(0, -48)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(hide)
	died.emit()
