class_name SlashArcFX
extends AnimatedSprite2D

## Vết chém của Queen — sprite "Pixel Art Sword Slash" (CC0), 3 biến thể random.

const ANIMS := ["slash_a", "slash_b", "slash_c"]
const BASE_FRAME_W := 52.0  # frame gốc ~52px ngang

var _radius := 130.0


func launch(radius: float, dir: int) -> void:
	_radius = radius
	flip_h = dir < 0
	scale = Vector2.ONE * (radius / BASE_FRAME_W)
	play(ANIMS[randi() % ANIMS.size()])
	animation_finished.connect(queue_free)
