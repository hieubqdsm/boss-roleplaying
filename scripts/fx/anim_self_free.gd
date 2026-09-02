extends AnimatedSprite2D

## Chạy 1 animation rồi tự huỷ (ghost_vanish, ...).

@export var autoplay_name := "ghost_vanish"


func _ready() -> void:
	play(autoplay_name)
	animation_finished.connect(queue_free)
