class_name Boom
extends Sprite2D
## Animowany wybuch (4 klatki pixel artu) + ślad na ziemi i lekkie trzęsienie kamery.

var radius := 32.0
var delay := 0.0
var t := 0.0
var started := false


func _ready() -> void:
	z_index = 6
	scale = Vector2.ONE * radius / 16.0
	visible = delay <= 0.0
	texture = Sprites.explosion(0)
	if delay <= 0.0:
		_start()


func _start() -> void:
	started = true
	visible = true
	if delay > 0.0:
		Sfx.play("explosion")
	var scene := get_tree().current_scene
	if scene.has_method("add_shake"):
		scene.add_shake(radius / 10.0)
	var s := Scorch.new()
	s.scale = Vector2.ONE * radius / 22.0
	s.position = global_position + Vector2(0, 3) # scena główna leży w (0, 0)
	scene.add_child.call_deferred(s)


func _process(delta: float) -> void:
	t += delta
	if t < delay:
		return
	if not started:
		_start()
	var f := int((t - delay) / 0.1)
	if f > 3:
		queue_free()
	else:
		texture = Sprites.explosion(f)
