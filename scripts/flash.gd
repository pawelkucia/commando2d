class_name MuzzleFlash
extends Node2D
## Krótki błysk z lufy.

var dir := Vector2.UP
var t := 0.0


func _ready() -> void:
	z_index = 5


func _process(delta: float) -> void:
	t += delta
	queue_redraw()
	if t > 0.06:
		queue_free()


func _draw() -> void:
	var a := 1.0 - t / 0.06
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.8, 0.3, 0.35 * a))
	draw_rect(Rect2(-1.5, -1.5, 3, 3), Color(1.0, 0.95, 0.6, a))
	draw_rect(Rect2(dir * 3.0 - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.85, 0.4, a))
