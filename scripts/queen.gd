class_name Queen
extends Node2D

## The Dark Queen — NHÂN VẬT CỦA NGƯỜI CHƠI (boss).
## Di chuyển A/D, 3 kỹ năng: slash / bolt / nova. Phase 2 khi máu <= 40%.

const SlashFXScene := preload("res://scenes/fx/hit_spark.tscn")
const BoltScene := preload("res://scenes/entities/bolt.tscn")
const NovaScene := preload("res://scenes/fx/nova.tscn")
const HealthScript := preload("res://scripts/combat/health.gd")

signal damage_dealt(amount: int)
signal died

@export var move_speed := 280.0
@export var slash_range := 86.0
@export var slash_damage := 12
@export var slash_cooldown := 0.5
@export var bolt_damage := 18
@export var bolt_speed := 540.0
@export var bolt_cooldown := 0.9
@export var nova_damage := 30
@export var nova_radius := 150.0
@export var nova_cooldown := 5.0

var health: HealthScript
var facing := -1
var phase2 := false
var dead := false

var _cd_slash := 0.0
var _cd_bolt := 0.0
var _cd_nova := 0.0
var _invuln := 0.0
var _knock_x := 0.0
var _slash_pending := 0.0
var _nova_pending := 0.0
var _anim_lock := 0.0
var _target: Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	health = $Health
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	sprite.play("idle")


func setup(target: Node2D, bounds_x: Vector2, ground_y: float) -> void:
	_target = target
	_bounds = bounds_x
	_ground_y = ground_y
	position = Vector2(bounds_x.y - 180.0, ground_y)


var _bounds := Vector2(60, 1092)
var _ground_y := 590.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	_tick_cooldowns(delta)
	_update_facing()
	_move(delta)
	_skills(delta)
	_pending_hits(delta)
	_bob()


func _tick_cooldowns(delta: float) -> void:
	_cd_slash = maxf(0.0, _cd_slash - delta)
	_cd_bolt = maxf(0.0, _cd_bolt - delta)
	_cd_nova = maxf(0.0, _cd_nova - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_anim_lock = maxf(0.0, _anim_lock - delta)
	if _anim_lock <= 0.0 and not sprite.is_playing():
		sprite.play("idle")


func _update_facing() -> void:
	if is_instance_valid(_target):
		facing = 1 if _target.global_position.x > global_position.x else -1
	sprite.flip_h = facing < 0


func _move(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var speed := move_speed * (1.15 if phase2 else 1.0)
	_knock_x = move_toward(_knock_x, 0.0, 900.0 * delta)
	position.x += dir * speed * delta + _knock_x * delta
	position.x = clampf(position.x, _bounds.x, _bounds.y)
	position.y = _ground_y


func _skills(delta: float) -> void:
	if Input.is_action_just_pressed("skill_slash"):
		_try_slash()
	if Input.is_action_just_pressed("skill_bolt"):
		_try_bolt()
	if Input.is_action_just_pressed("skill_nova"):
		_try_nova()


func _try_slash() -> void:
	if _cd_slash > 0.0:
		return
	_cd_slash = slash_cooldown
	_slash_pending = 0.12
	_anim_lock = 0.25
	sprite.play("cast")
	sprite.speed_scale = 1.6
	GameAudio.play_sfx("slash")


func _try_bolt() -> void:
	if _cd_bolt > 0.0:
		return
	_cd_bolt = bolt_cooldown
	_anim_lock = 0.3
	sprite.play("cast")
	GameAudio.play_sfx("bolt_cast")
	var muzzle := global_position + Vector2(34.0 * facing, -58.0)
	if phase2:
		_spawn_bolt(muzzle, Vector2(facing, -0.14).normalized())
		_spawn_bolt(muzzle, Vector2(facing, 0.14).normalized())
	else:
		_spawn_bolt(muzzle, Vector2(facing, 0.0))


func _try_nova() -> void:
	if _cd_nova > 0.0:
		return
	_cd_nova = nova_cooldown
	_nova_pending = 0.28
	_anim_lock = 0.55
	sprite.play("nova")
	sprite.speed_scale = 1.0


func _spawn_bolt(muzzle: Vector2, dir: Vector2) -> void:
	var bolt := BoltScene.instantiate()
	get_parent().add_child(bolt)
	bolt.setup(
		muzzle, dir, bolt_speed, bolt_damage, _target
	)


func _pending_hits(delta: float) -> void:
	if _slash_pending > 0.0:
		_slash_pending -= delta
		if _slash_pending <= 0.0 and is_instance_valid(_target) and not _target.is_dead():
			var dx := (_target.global_position.x - global_position.x) * facing
			if dx > -20.0 and dx < slash_range:
				_hit_target(slash_damage, 220.0)
	if _nova_pending > 0.0:
		_nova_pending -= delta
		if _nova_pending <= 0.0:
			_fire_nova()


func _fire_nova() -> void:
	var radius := nova_radius * (1.25 if phase2 else 1.0)
	GameAudio.play_sfx("nova")
	var fx := NovaScene.instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position + Vector2(0, -56)
	fx.launch(radius)
	if is_instance_valid(_target) and not _target.is_dead():
		var dist := _target.global_position.distance_to(global_position + Vector2(0, -48))
		if dist <= radius:
			_hit_target(nova_damage, 520.0)
	if phase2 and is_instance_valid(_target) and not _target.is_dead():
		var skull := BoltScene.instantiate()
		get_parent().add_child(skull)
		skull.setup_skull(
			global_position + Vector2(0, -120), bolt_speed * 0.45, 12, _target
		)


func is_dead() -> bool:
	return dead


func _hit_target(dmg: int, knockback: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		return
	_target.take_hit(dmg, global_position.x, knockback * facing)
	damage_dealt.emit(dmg)
	var spark := SlashFXScene.instantiate()
	get_parent().add_child(spark)
	spark.global_position = _target.global_position + Vector2(0, -44)


## Hero chém trúng Queen.
func apply_hero_hit(dmg: int, from_x: float) -> void:
	if dead or _invuln > 0.0:
		return
	_invuln = 0.35
	_knock_x = 320.0 * (1 if global_position.x >= from_x else -1)
	health.take_damage(dmg)
	if not dead:
		_anim_lock = 0.3
		sprite.play("hurt")
		sprite.speed_scale = 1.0
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color(1.6, 0.7, 0.8), 0.06)
		tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	GameAudio.play_sfx("hurt_queen")


func cooldown_fractions() -> Vector3:
	return Vector3(
		1.0 - _cd_slash / slash_cooldown,
		1.0 - _cd_bolt / bolt_cooldown,
		1.0 - _cd_nova / nova_cooldown
	)


func _bob() -> void:
	sprite.position.y = -56.0 + sin(Time.get_ticks_msec() * 0.004) * 3.0


func _on_health_changed(cur: int, mx: int) -> void:
	if not phase2 and mx > 0 and float(cur) / float(mx) <= 0.4:
		phase2 = true
		var tw := create_tween().set_loops()
		tw.tween_property(self, "modulate", Color(1.0, 0.82, 0.9), 0.4)
		tw.tween_property(self, "modulate", Color(1.0, 0.95, 1.0), 0.4)


func _on_died() -> void:
	dead = true
	GameAudio.play_sfx("queen_die")
	sprite.play("death")
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 1.6)
	died.emit()
