class_name FloatText
extends Label
## Unoszący się napis, np. "+500".

var t := 0.0


func _ready() -> void:
	z_index = 20
	add_theme_font_size_override("font_size", 8)
	add_theme_color_override("font_color", Color(1, 1, 0.4))
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 3)


func _process(delta: float) -> void:
	t += delta
	position.y -= 24.0 * delta
	modulate.a = clampf(2.0 - t * 2.0, 0.0, 1.0)
	if t > 1.0:
		queue_free()
