class_name SlashArcFX
extends Node2D

## Arc chém của Queen — FX hiển thị tầm đánh cận chiến, tự huỷ.

var radius := 130.0
var facing := 1
var _t := 0.0
const DURATION := 0.18


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
	var col := Color(0.95, 0.55, 0.45, 0.85 * (1.0 - k))
	# cung 100° hướng về phía trước (mặc định phải), lật theo facing
	var a0 := -0.9 if facing > 0 else PI - 0.9
	var a1 := 0.9 if facing > 0 else PI + 0.9
	draw_arc(Vector2.ZERO, radius * (0.6 + 0.4 * k), a0, a1, 20, col, 5.0 * (1.0 - k * 0.6))
	draw_arc(Vector2.ZERO, radius * 0.7 * (0.6 + 0.4 * k), a0, a1, 20,
		Color(1.0, 0.85, 0.6, 0.5 * (1.0 - k)), 3.0)
