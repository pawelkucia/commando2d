class_name Bunker
extends StaticBody2D
## Bunkier z workami z piaskiem. Ma kilka punktów życia, strzela i rzuca granaty.

signal died(points: int)

var hp := 8
var player: Node2D
var shoot_cd := randf_range(0.5, 1.5)
var shots := 0
var flash := 0.0
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("enemies")
	sprite = Sprite2D.new()
	sprite.texture = Sprites.bunker()
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 12)
	shape.shape = rect
	shape.position = Vector2(0, 2)
	add_child(shape)


func _physics_process(delta: float) -> void:
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			sprite.modulate = Color.WHITE
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	if to_player.length() > 170.0:
		return
	shoot_cd -= delta
	if shoot_cd <= 0.0:
		shoot_cd = 1.3
		shots += 1
		var dir := to_player.normalized()
		if shots % 4 == 0:
			var g := Grenade.new()
			get_tree().current_scene.add_child(g)
			g.launch(global_position, player.global_position, 1.2, false)
			Sfx.play("throw")
		else:
			var b := Bullet.new()
			b.from_player = false
			b.dir = dir
			get_tree().current_scene.add_child(b)
			b.global_position = global_position + dir * 18.0 # poza kolizją bunkra
			Sfx.play("enemy_shoot")


func take_hit(dmg: int = 1) -> void:
	hp -= dmg
	flash = 0.06
	sprite.modulate = Color(2.5, 2.5, 2.5)
	Sfx.play("boss_hit")
	if hp <= 0:
		var boom := Boom.new()
		boom.radius = 24.0
		get_tree().current_scene.add_child(boom)
		boom.global_position = global_position
		died.emit(400)
		queue_free()
