class_name Water
extends Node2D
## Animowana woda rzek (3 klatki). `cells` to lewe górne rogi kafelków 16x16,
## `edges` mówi, z której strony kafelek ma pianę (1 = góra, 2 = dół).

var cells: Array[Vector2] = []
var edges: Array[int] = []
var frame := 0
var t := 0.0


func _process(delta: float) -> void:
	t += delta
	if t >= 0.3:
		t = 0.0
		frame = (frame + 1) % 3
		queue_redraw()


func _draw() -> void:
	for i in cells.size():
		draw_texture(Terrain.water(frame, edges[i]), cells[i])
