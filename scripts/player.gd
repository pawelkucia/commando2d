class_name Player
extends CharacterBody2D
## Żołnierz sterowany w 8 kierunkach. Strzela w stronę, w którą ostatnio szedł.

signal hit

const SPEED := 90.0
const FIRE_COOLDOWN := 0.12
const MAX_HP := 6
const HIT_INVULN := 1.0

var facing := Vector2.UP
var grenades := 5
var hp := MAX_HP
var invuln := 0.0
var fire_cd := 0.0
var walk_t := 0.0
var x_min := 8.0
var x_max := 248.0
var y_min := -100000.0
var y_max := 216.0
var sprite: Sprite2D
var aim_locked := false
var aim_marker: Node2D


func _ready() -> void:
	collision_layer = 2      # player
	collision_mask = 1 | 32  # world + water
	add_to_group("player")
	Sprites.add_shadow(self)
	sprite = Sprite2D.new()
	sprite.position = Vector2(0, -4)
	add_child(sprite)
	Sprites.set_soldier(sprite, "player", facing, 0.0, false)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 12)
	shape.shape = rect
	add_child(shape)
	aim_marker = Node2D.new()
	aim_marker.z_index = 5
	aim_marker.visible = false
	aim_marker.draw.connect(_draw_aim)
	add_child(aim_marker)


## Znacznik zablokowanego celu: dwie strzałki przed lufą, lekko pulsujące.
func _draw_aim() -> void:
	var pulse := 0.7 + 0.25 * sin(Time.get_ticks_msec() * 0.012)
	var c := Color(1.0, 0.85, 0.25, pulse)
	var side := facing.orthogonal()
	var origin := Vector2(0, -3)
	for i in 2:
		var tip := origin + facing * (22.0 + i * 6.0)
		var back := tip - facing * 5.0
		var pts := PackedVector2Array([back + side * 4.5, tip, back - side * 4.5])
		aim_marker.draw_polyline(pts, Color(0, 0, 0, pulse * 0.5), 3.0) # ciemny obrys dla kontrastu
		aim_marker.draw_polyline(pts, c, 1.5)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	var moving := dir != Vector2.ZERO
	# blokada celu: trzymanie strzału (Spacja/J/FIRE) albo Shift (blokada bez strzelania).
	# Żołnierz chodzi w dowolną stronę, ale dalej patrzy i strzela tam, gdzie patrzył.
	aim_locked = Input.is_action_pressed("aim_lock") or Input.is_action_pressed("fire")
	if moving:
		if not aim_locked:
			facing = Vector2.from_angle(snappedf(dir.angle(), PI / 4.0))
		walk_t += delta
	aim_marker.visible = aim_locked
	if aim_locked:
		aim_marker.queue_redraw()
	Sprites.set_soldier(sprite, "player", facing, walk_t, moving)
	move_and_slide()
	position.x = clampf(position.x, x_min, x_max)
	position.y = clampf(position.y, y_min, y_max)

	fire_cd -= delta
	if Input.is_action_pressed("fire") and fire_cd <= 0.0:
		fire_cd = FIRE_COOLDOWN
		_shoot()
	if Input.is_action_just_pressed("grenade") and grenades > 0:
		grenades -= 1
		_throw_grenade()

	if invuln > 0.0:
		invuln -= delta
		sprite.visible = int(invuln * 12.0) % 2 == 0
	else:
		sprite.visible = true


func _shoot() -> void:
	var b := Bullet.new()
	b.from_player = true
	b.dir = facing
	var muzzle := global_position + facing * 10.0 + Vector2(0, -3)
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle
	var fl := MuzzleFlash.new()
	fl.dir = facing
	get_tree().current_scene.add_child(fl)
	fl.global_position = muzzle
	Sfx.play("shoot")


func _throw_grenade() -> void:
	var g := Grenade.new()
	get_tree().current_scene.add_child(g)
	g.launch(global_position, global_position + facing * 90.0, 0.7, true)
	Sfx.play("throw")


func take_hit(dmg: int = 1) -> void:
	if invuln > 0.0:
		return
	hp = maxi(hp - dmg, 0)
	invuln = HIT_INVULN
	hit.emit()
