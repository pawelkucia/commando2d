class_name Pickup
extends Area2D
## Przedmioty do zebrania: "pow" (jeniec do uwolnienia) i "crate" (skrzynia z granatami).

signal collected(kind: String, pos: Vector2)

var kind := "pow"
var t := randf() * 2.0
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # player
	sprite = Sprite2D.new()
	add_child(sprite)
	match kind:
		"crate":
			sprite.texture = Sprites.crate()
		"medkit":
			sprite.texture = Sprites.medkit()
		_:
			sprite.texture = Sprites.prisoner(0)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	if kind == "pow":
		sprite.texture = Sprites.prisoner(int(t * 2.5) % 2)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if kind == "medkit" and body.hp >= Player.MAX_HP:
			return # pełna energia: apteczka zostaje na później
		collected.emit(kind, global_position)
		queue_free()
