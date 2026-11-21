class_name Enemy
extends CharacterBody2D
## Wrogowie: "grunt" (piechur), "sniper" (stoi i celuje), "grenadier" (rzuca granaty),
## "biker" (motocyklista pędzący w dół ekranu).

signal died(points: int)

const ACTIVE_DIST := 190.0
const POINTS := {"grunt": 100, "sniper": 300, "grenadier": 200, "biker": 150}

var kind := "grunt"
var player: Node2D
var shoot_cd := randf_range(1.0, 2.5)
var strafe := 1.0
var walk_t := 0.0
var flash := 0.0
var active := false
var sprite: Sprite2D


func _ready() -> void:
	collision_layer = 4                              # enemy
	collision_mask = 0 if kind == "biker" else 1 | 32 # world + water
	add_to_group("enemies")
	strafe = 1.0 if randf() < 0.5 else -1.0
	if kind == "sniper":
		shoot_cd = randf_range(1.5, 3.0)
	sprite = Sprite2D.new()
	add_child(sprite)
	if kind == "biker":
		sprite.texture = Sprites.biker(0)
	else:
		Sprites.set_soldier(sprite, kind, Vector2.DOWN, 0.0, false)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(9, 9)
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	if flash > 0.0:
		flash -= delta
		sprite.modulate = Color.WHITE
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if kind == "biker":
		_biker(delta, dist)
		return
	if dist > ACTIVE_DIST:
		velocity = Vector2.ZERO
		return
	var dir := to_player.normalized()
	var moving := false
	shoot_cd -= delta

	match kind:
		"grunt":
			if dist > 70.0:
				velocity = dir * 38.0
			else:
				velocity = dir.orthogonal() * strafe * 28.0
			moving = true
			if dist < 170.0 and shoot_cd <= 0.0:
				shoot_cd = randf_range(1.6, 3.2)
				_fire(dir.rotated(randf_range(-0.12, 0.12)), 90.0, false)
		"sniper":
			velocity = Vector2.ZERO
			if dist < ACTIVE_DIST:
				if shoot_cd <= 0.5:
					sprite.modulate = Color(1.0, 0.55, 0.55) # zapowiedź strzału
				if shoot_cd <= 0.0:
					shoot_cd = 3.0
					sprite.modulate = Color.WHITE
					_fire(dir, 160.0, true)
		"grenadier":
			if dist > 110.0:
				velocity = dir * 30.0
				moving = true
			elif dist < 80.0:
				velocity = -dir * 30.0
				moving = true
			else:
				velocity = Vector2.ZERO
			if shoot_cd <= 0.0:
				shoot_cd = 3.4
				var g := Grenade.new()
				get_tree().current_scene.add_child(g)
				var lead: Vector2 = player.velocity * 0.5 if "velocity" in player else Vector2.ZERO
				g.launch(global_position, player.global_position + lead, 1.1, false)
				Sfx.play("throw")
	move_and_slide()
	if moving:
		walk_t += delta
	Sprites.set_soldier(sprite, kind, dir, walk_t, moving)


func _biker(delta: float, dist: float) -> void:
	if not active:
		if dist < 260.0:
			active = true
		else:
			return
	global_position.y += 120.0 * delta
	walk_t += delta
	sprite.texture = Sprites.biker(int(walk_t * 10.0) % 2)
	var d := player.global_position - global_position
	if absf(d.x) < 9.0 and absf(d.y) < 11.0:
		player.take_hit(2) # taranowanie motocyklem
	if global_position.y > player.global_position.y + 200.0:
		queue_free()


func _fire(dir: Vector2, speed: float, big: bool) -> void:
	var b := Bullet.new()
	b.from_player = false
	b.dir = dir
	b.speed = speed
	b.big = big
	b.dmg = 2 if big else 1 # pocisk snajpera boli bardziej
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + dir * 8.0
	Sfx.play("enemy_shoot")


func take_hit(_dmg: int = 1) -> void:
	var puff := Puff.new()
	puff.color = Color(0.9, 0.2, 0.15)
	get_tree().current_scene.add_child(puff)
	puff.global_position = global_position
	Sfx.play("die")
	died.emit(POINTS[kind])
	queue_free()
