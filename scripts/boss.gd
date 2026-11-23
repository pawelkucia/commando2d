class_name Boss
extends AnimatableBody2D
## Boss na końcu poziomu: czołg-forteca. Kołysze się na boki i strzela wachlarzem pocisków
## oraz granatami; poniżej połowy życia strzela gęściej.

signal died(points: int)

const MAX_HP := 40

var hp := MAX_HP
var player: Node2D
var active := false
var t := 0.0
var shoot_cd := 1.5
var volleys := 0
var base_x := 128.0
var flash := 0.0
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 1 | 4 # blokuje gracza i przyjmuje jego pociski
	collision_mask = 0
	add_to_group("enemies")
	base_x = position.x
	sprite = Sprite2D.new()
	sprite.texture = Sprites.boss()
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(48, 28)
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			sprite.modulate = Color.WHITE
	if not active:
		if player.global_position.y < global_position.y + 300.0:
			active = true
		return
	t += delta
	position.x = base_x + sin(t * 0.9) * 55.0
	shoot_cd -= delta
	if shoot_cd <= 0.0:
		shoot_cd = 1.4 if hp > MAX_HP / 2 else 0.9
		_fire()


func _fire() -> void:
	volleys += 1
	var origin := global_position + Vector2(0, 24)
	var aim := (player.global_position - origin).normalized()
	var n := 3 if hp > MAX_HP / 2 else 5
	for i in n:
		var b := Bullet.new()
		b.from_player = false
		b.dir = aim.rotated((i - (n - 1) / 2.0) * 0.28)
		get_tree().current_scene.add_child(b)
		b.global_position = origin
	Sfx.play("enemy_shoot")
	if volleys % 3 == 0:
		var g := Grenade.new()
		get_tree().current_scene.add_child(g)
		g.launch(origin, player.global_position, 1.2, false)


func take_hit(dmg: int = 1) -> void:
	hp -= dmg
	flash = 0.06
	sprite.modulate = Color(2.5, 2.5, 2.5)
	Sfx.play("boss_hit")
	if hp <= 0:
		var scene := get_tree().current_scene
		for i in 7:
			var boom := Boom.new()
			boom.radius = randf_range(24.0, 40.0)
			boom.delay = i * 0.18
			scene.add_child(boom)
			boom.global_position = global_position + Vector2(randf_range(-28, 28), randf_range(-16, 16))
		died.emit(5000)
		queue_free()
