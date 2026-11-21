class_name Water
extends Node2D
## Animowana woda rzek (dwie klatki). `cells` to lewe górne rogi kafelków 16x16.

var cells: Array[Vector2] = []
var frame := 0
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if t >= 0.5:
		t = 0.0
		frame = 1 - frame
		queue_redraw()


func _draw() -> void:
	var tex := Sprites.water(frame)
	for c in cells:
		draw_texture(tex, c)
