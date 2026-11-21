class_name Boom
extends Sprite2D
## Animowany wybuch (4 klatki pixel artu).

var radius := 32.0
var delay := 0.0
var t := 0.0


func _ready() -> void:
	z_index = 6
	scale = Vector2.ONE * radius / 16.0
	visible = delay <= 0.0
	texture = Sprites.explosion(0)


func _process(delta: float) -> void:
	t += delta
	if t < delay:
		return
	if not visible:
		visible = true
		Sfx.play("explosion")
	var f := int((t - delay) / 0.1)
	if f > 3:
		queue_free()
	else:
		texture = Sprites.explosion(f)
