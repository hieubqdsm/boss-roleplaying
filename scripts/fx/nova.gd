class_name NovaFX
extends Node2D

## Vòng nova lan rộng quanh Queen — thuần FX; damage do Queen áp.

var radius := 150.0
var _t := 0.0
const DURATION := 0.32


func launch(r: float) -> void:
	radius = r


func _process(delta: float) -> void:
	_t += delta
	if _t >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := _t / DURATION
	var r := radius * (0.15 + 0.85 * k)
	var col := Color(0.95, 0.35, 0.45, 0.9 * (1.0 - k))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, col, 6.0 * (1.0 - k * 0.5))
	draw_arc(Vector2.ZERO, r * 0.82, 0.0, TAU, 48, Color(1.0, 0.8, 0.55, 0.5 * (1.0 - k)), 3.0)
