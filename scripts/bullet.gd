class_name Bullet
extends Area2D
## Pocisk gracza lub wroga.

var dir := Vector2.UP
var speed := 220.0
var from_player := true
var dmg := 1
var big := false
var life := 2.0


func _ready() -> void:
	z_index = 4
	if from_player:
		collision_layer = 8    # player_bullet
		collision_mask = 1 | 4 # world + enemy
	else:
		collision_layer = 16   # enemy_bullet
		collision_mask = 1 | 2 # world + player
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 3.0 if big else 2.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if from_player:
		if body.is_in_group("enemies"):
			body.take_hit(dmg)
	elif body.is_in_group("player"):
		body.take_hit(dmg)
	queue_free()


func _draw() -> void:
	var s := 4.0 if big else 3.0
	var o := -s / 2.0
	var core := Color(1, 0.9, 0.3) if from_player else Color(1, 0.3, 0.2)
	draw_circle(Vector2.ZERO, s + 1.5, Color(core.r, core.g, core.b, 0.25)) # poświata
	draw_rect(Rect2(-dir * 3.0 - Vector2(1, 1), Vector2(2, 2)), Color(core.r, core.g, core.b, 0.4)) # smuga
	draw_rect(Rect2(o, o, s, s), core)
	draw_rect(Rect2(o + 1, o + 1, 1, 1), Color.WHITE if from_player else Color(1, 0.85, 0.5))
