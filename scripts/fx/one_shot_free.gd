extends CPUParticles2D

## Particle one-shot tự huỷ — gắn cho hit_spark.tscn.

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(queue_free)
