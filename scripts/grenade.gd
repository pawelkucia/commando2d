class_name Grenade
extends Node2D
## Granat leci łukiem do celu i wybucha obszarowo.
## Gracza: zabija wrogów w promieniu. Wroga: rani gracza (miejsce lądowania jest zaznaczone).

const RADIUS_PLAYER := 32.0
const RADIUS_ENEMY := 26.0

var from_player := true
var start := Vector2.ZERO
var target := Vector2.ZERO
var duration := 0.7
var t := 0.0


## Wywołaj PO add_child.
func launch(from: Vector2, to: Vector2, dur: float, player_owned: bool) -> void:
	global_position = from
	start = from
	target = to
	duration = dur
	from_player = player_owned
	z_index = 3


func _process(delta: float) -> void:
	t += delta
	var k := minf(t / duration, 1.0)
	global_position = start.lerp(target, k)
	queue_redraw()
	if k >= 1.0:
		_explode()


func _explode() -> void:
	var radius := RADIUS_PLAYER if from_player else RADIUS_ENEMY
	var boom := Boom.new()
	boom.radius = radius
	get_tree().current_scene.add_child(boom)
	boom.global_position = global_position
	Sfx.play("explosion")
	if from_player:
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.global_position.distance_to(global_position) <= radius:
				e.take_hit(3)
	else:
		for p in get_tree().get_nodes_in_group("player"):
			if p.global_position.distance_to(global_position) <= radius:
				p.take_hit(2)
	queue_free()


func _draw() -> void:
	var k := minf(t / duration, 1.0)
	var h := sin(PI * k) * 14.0
	draw_rect(Rect2(-2, 0, 4, 2), Color(0, 0, 0, 0.35)) # cień
	draw_rect(Rect2(-2, -h - 2, 4, 4), Color(0.2, 0.38, 0.18))
	draw_rect(Rect2(-1, -h - 2, 2, 1), Color(0.6, 0.8, 0.5))
	if not from_player and int(t * 8.0) % 2 == 0:
		var c := target - global_position
		draw_arc(c, RADIUS_ENEMY, 0.0, TAU, 20, Color(1, 0.3, 0.2, 0.8), 1.0)
