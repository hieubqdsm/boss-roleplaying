class_name Hero
extends Node2D

## Hero — AI thách đấu Queen, CHẾ ĐỘ ENDLESS:
## - Chết → hồi sinh sau 2.2s với "ký ức" (biết né loại đòn từng giết mình)
##   + aggression tăng dần CÓ TRẦN (không cộng máu/dame vô hạn).
## - Não AI: HeroBrain (thuần logic). Ký ức nằm ở đây (sống qua các lần chết).

const GhostFXScene := preload("res://scenes/fx/ghost_vanish.tscn")
const SparkFXScene := preload("res://scenes/fx/hit_spark.tscn")
const HealthScript := preload("res://scripts/combat/health.gd")
const BrainScript := preload("res://scripts/combat/hero_brain.gd")

signal died
signal damage_taken(amount: int)

@export var base_health := 55
@export var base_damage := 7
@export var base_speed := 120.0
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

## Ký ức học đòn — KHÔNG reset khi hero sống dậy.
var _memory := {"deaths": 0, "by": {}}

var _knock_x := 0.0
var _damage := 7
var _speed := 120.0
var _stagger := 0.32
var _respawn_flash := 0.0
var _jump_base_y := -1.0

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
	_jump_base_y = -1.0
	# Aggression tăng theo số lần đã chết, có trần — không scale vô hạn.
	var d := int(_memory.get("deaths", 0))
	_damage = base_damage + mini(6, d)
	_speed = base_speed + minf(30.0, 2.0 * d)
	_stagger = maxf(0.14, base_stagger - 0.02 * d)
	health.reset_to(base_health)
	modulate.a = 1.0
	sprite.play("idle")
	print("[HERO] sống dậy lần thứ %d — đã học: %s" % [round, str(_memory.get("by", {}))])


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
		_end_jump()
		sprite.play("idle")
		return

	var dist_x := target.global_position.x - global_position.x
	var cfg := {
		"attack_range": attack_range,
		"windup_time": maxf(0.32, windup_time - 0.015 * int(_memory.get("deaths", 0))),
		"strike_time": strike_time,
		"recover_time": recover_time,
		"stagger_time": _stagger,
		"backstep_time": 0.32,
		"jump_time": 0.45,
	}
	var res := brain.step(dist_x, cfg, brain_state, delta, _threats(), _memory)
	_apply_action(res, dist_x, delta)


## Quét mối đe doạ xung quanh: telegraph của Queen + đạn đang bay tới gần.
func _threats() -> Dictionary:
	var th := {"nova_windup": false, "bolt_near": false, "slash_windup": false}
	if is_instance_valid(target) and not target.is_dead() and target.has_method("is_charging_nova"):
		if target.is_charging_nova():
			var r: float = target.get_nova_radius()
			th["nova_windup"] = global_position.distance_to(target.global_position) < r * 1.15
		th["slash_windup"] = target.is_charging_slash()
	for b in get_tree().get_nodes_in_group("queen_bolts"):
		if is_instance_valid(b) and absf(b.global_position.x - global_position.x) < 240.0:
			th["bolt_near"] = true
			break
	return th


func _apply_action(res: Dictionary, dist_x: float, delta: float) -> void:
	var action := int(res["action"])
	var speed_scale := 1.6 if action == BrainScript.Action.BACKSTEP else 1.0
	var move := float(res["move_dir"]) * _speed * speed_scale
	_knock_x = move_toward(_knock_x, 0.0, 900.0 * delta)
	position.x += (move + _knock_x) * delta
	sprite.flip_h = dist_x < 0.0

	match action:
		BrainScript.Action.WINDUP:
			_end_jump()
			sprite.play("idle")
			# Telegraph: nhấp nháy đỏ dồn dập trước khi vung kiếm.
			sprite.modulate = Color(1.0, 0.45, 0.45) if fmod(brain_state["timer"], 0.16) < 0.08 else Color.WHITE
		BrainScript.Action.STRIKE:
			_end_jump()
			if sprite.animation != "attack" or not sprite.is_playing():
				sprite.play("attack")
				_strike_hit()
			sprite.modulate = Color.WHITE
		BrainScript.Action.RECOVER:
			_end_jump()
			sprite.modulate = Color.WHITE
			if sprite.animation != "attack":
				sprite.play("idle")
		BrainScript.Action.STAGGER:
			_end_jump()
			sprite.modulate = Color.WHITE
			sprite.play("hurt")
		BrainScript.Action.JUMP_DODGE:
			_do_jump()
			sprite.play("jump")
			sprite.modulate = Color.WHITE
		BrainScript.Action.BACKSTEP:
			_end_jump()
			sprite.play("run")
			sprite.modulate = Color.WHITE
		_:
			_end_jump()
			sprite.modulate = Color.WHITE
			if absf(dist_x) > 5.0:
				sprite.play("run")
			else:
				sprite.play("idle")


## Nhảy né: nhấc người theo cung, bất tử ngắn trong lúc trên không.
func _do_jump() -> void:
	if _jump_base_y < 0.0:
		_jump_base_y = position.y
		invuln = maxf(invuln, 0.3)
	var t: float = brain_state.get("timer", 0.0)
	position.y = _jump_base_y - 72.0 * sin(PI * clampf(t / 0.45, 0.0, 1.0))


func _end_jump() -> void:
	if _jump_base_y >= 0.0:
		position.y = _jump_base_y
		_jump_base_y = -1.0


func is_dead() -> bool:
	return dead


func _strike_hit() -> void:
	if not is_instance_valid(target) or target.is_dead():
		return
	var dx := absf(target.global_position.x - global_position.x)
	if dx <= attack_range * 1.35:
		target.apply_hero_hit(_damage, global_position.x)


## Queen đánh trúng hero. cause: "slash" | "bolt" | "nova" | "skull".
func take_hit(dmg: int, from_x: float, knockback_x := 240.0, cause := "slash") -> void:
	if dead or invuln > 0.0:
		return
	cause_last = cause
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
	_end_jump()
	_memory["deaths"] = int(_memory.get("deaths", 0)) + 1
	var by: Dictionary = _memory.get("by", {})
	by[cause_last] = int(by.get(cause_last, 0)) + 1
	_memory["by"] = by
	print("[HERO] gục ở round %d — chết vì '%s' (tổng chết: %d)" % [round_idx, cause_last, _memory["deaths"]])
	GameAudio.play_sfx("hero_die")
	sprite.play("hurt")
	var ghost := GhostFXScene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position + Vector2(0, -48)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	tw.tween_callback(hide)
	died.emit()


## Loại đòn cuối cùng trúng — để ghi vào ký ức khi chết.
var cause_last := "slash"
