class_name SlashArcFX
extends Node2D

## Vết chém của Queen — trăng khuyết trắng lõi + viền đỏ, rõ và đậm.

var radius := 130.0
var facing := 1
var _t := 0.0
const DURATION := 0.26


func launch(r: float, dir: int) -> void:
	radius = r
	facing = dir


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var a0 := -0.9 if facing > 0 else PI - 0.9
	var a1 := 0.9 if facing > 0 else PI + 0.9
	# viền đỏ đậm
	draw_arc(Vector2.ZERO, radius * (0.72 + 0.28 * k), a0, a1, 24,
		Color(0.9, 0.2, 0.25, 0.85 * (1.0 - k)), 9.0 * (1.0 - k * 0.55))
	# lõi trắng sáng
	draw_arc(Vector2.ZERO, radius * (0.74 + 0.26 * k), a0, a1, 24,
		Color(1.0, 0.96, 0.88, 0.95 * (1.0 - k)), 4.0)
	# hào sáng trong
	draw_arc(Vector2.ZERO, radius * (0.55 + 0.25 * k), a0, a1, 24,
		Color(1.0, 0.85, 0.6, 0.55 * (1.0 - k)), 2.0)
