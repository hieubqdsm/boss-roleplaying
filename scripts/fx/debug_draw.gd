class_name DebugDraw
extends Node2D

## Overlay debug generic — vẽ LÊN TRÊN sprite (z_index cao), nhận danh sách
## shape mỗi frame từ entity cha. Dùng khi bật GameSettings.debug_hitbox.
## shapes: [{"type": "rect"|"line"|"arc"|"dot", ...mỗi loại có toạ độ riêng...}]

var shapes: Array = []


func _ready() -> void:
	z_index = 100
	# không đụng input, không cản gì



func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	for s in shapes:
		match String(s.get("type", "")):
			"rect":
				draw_rect(Rect2(s["pos"], s["size"]), s["color"], false, float(s.get("width", 2.0)))
			"line":
				draw_line(s["from"], s["to"], s["color"], float(s.get("width", 2.0)))
			"arc":
				draw_arc(s["pos"], float(s["radius"]), 0.0, TAU, int(s.get("points", 32)), s["color"], float(s.get("width", 1.5)))
			"dot":
				draw_circle(s["pos"], float(s["radius"]), s["color"])
