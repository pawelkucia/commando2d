class_name Scorch
extends Sprite2D
## Ślad po wybuchu na ziemi; powoli znika.

const LIFE := 8.0
var t := 0.0


func _ready() -> void:
	texture = Sprites.scorch()
	z_index = -8


func _process(delta: float) -> void:
	t += delta
	modulate.a = clampf((LIFE - t) / 2.0, 0.0, 1.0)
	if t > LIFE:
		queue_free()
