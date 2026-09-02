class_name HealthComponent
extends Node

## Máu chung cho mọi entity — composition node (docs/CODING.md §3).

signal health_changed(current: int, maximum: int)
signal died

@export var max_health := 100

var health := 0
var dead := false


func _ready() -> void:
	if health <= 0:
		health = max_health


func take_damage(amount: int) -> void:
	if dead or amount <= 0:
		return
	health = maxi(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		dead = true
		died.emit()


func heal(amount: int) -> void:
	if dead:
		return
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func reset_to(new_max: int) -> void:
	max_health = new_max
	health = new_max
	dead = false
	health_changed.emit(health, max_health)
