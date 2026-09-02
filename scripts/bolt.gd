class_name ProjectileBolt
extends Node2D

## Projectile của Queen: bolt thẳng hoặc skull tự tìm mục tiêu (phase 2).

const SparkFXScene := preload("res://scenes/fx/hit_spark.tscn")

var direction := Vector2.RIGHT
var speed := 540.0
var damage := 18
var homing := false
var target: Node2D
var lifetime := 4.0
var hit_radius := 26.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(muzzle: Vector2, dir: Vector2, proj_speed: float, dmg: int, hero: Node2D) -> void:
	global_position = muzzle
	direction = dir.normalized()
	speed = proj_speed
	damage = dmg
	target = hero
	homing = false
	_play("bolt")


func setup_skull(muzzle: Vector2, proj_speed: float, dmg: int, hero: Node2D) -> void:
	global_position = muzzle
	speed = proj_speed
	damage = dmg
	target = hero
	homing = true
	hit_radius = 34.0
	direction = Vector2(randf_range(-0.4, 0.4), -1.0).normalized()
	_play("skull")


func _play(anim: String) -> void:
	# gọi sau khi add_child — sprite có thể chưa ready nếu gọi ngay setup()
	await ready
	sprite.play(anim)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	if homing and is_instance_valid(target) and not target.is_dead():
		var to_target := (target.global_position + Vector2(0, -44) - global_position).normalized()
		direction = direction.slerp(to_target, 2.4 * delta).normalized()
	global_position += direction * speed * delta
	if homing:
		sprite.flip_h = direction.x < 0.0
	else:
		sprite.rotation = direction.angle()
	# ra ngoài màn hình arena (~240..(-120)) thì biến mất
	if global_position.x < -80.0 or global_position.x > 1240.0 or global_position.y < -80.0 or global_position.y > 760.0:
		queue_free()
		return
	if is_instance_valid(target) and not target.is_dead():
		if global_position.distance_to(target.global_position + Vector2(0, -44)) <= hit_radius:
			target.take_hit(damage, global_position.x)
			var spark := SparkFXScene.instantiate()
			get_parent().add_child(spark)
			spark.global_position = global_position
			queue_free()
