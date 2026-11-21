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


func _ready() -> void:
	collision_layer = 2      # player
	collision_mask = 1 | 32  # world + water
	add_to_group("player")
	sprite = Sprite2D.new()
	add_child(sprite)
	Sprites.set_soldier(sprite, "player", facing, 0.0, false)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(9, 9)
	shape.shape = rect
	add_child(shape)


func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	var moving := dir != Vector2.ZERO
	if moving:
		facing = Vector2.from_angle(snappedf(dir.angle(), PI / 4.0))
		walk_t += delta
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
	get_tree().current_scene.add_child(b)
	b.global_position = global_position + facing * 8.0
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
