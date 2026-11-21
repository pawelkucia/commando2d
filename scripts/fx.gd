class_name Puff
extends Node2D
## Garść pikseli rozlatujących się z miejsca trafienia.

var color := Color(0.9, 0.2, 0.15)
var count := 10
var t := 0.0
var parts: Array = []


func _ready() -> void:
	z_index = 5
	for i in count:
		parts.append([Vector2.ZERO, Vector2.from_angle(randf() * TAU) * randf_range(25.0, 70.0)])


func _process(delta: float) -> void:
	t += delta
	for p in parts:
		p[0] += p[1] * delta
	queue_redraw()
	if t > 0.45:
		queue_free()


func _draw() -> void:
	var a := 1.0 - t / 0.45
	for p in parts:
		draw_rect(Rect2(p[0], Vector2(2, 2)), Color(color.r, color.g, color.b, a))
