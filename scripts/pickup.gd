class_name Pickup
extends Area2D
## Przedmioty do zebrania: "pow" (jeniec do uwolnienia), "crate" (skrzynia z granatami), "medkit".
## Jeniec woła o pomoc w komiksowych dymkach. Im dłużej jest widoczny na ekranie
## i nikt go nie ratuje, tym bardziej się złości — aż w końcu klnie znaczkami.

signal collected(kind: String, pos: Vector2)

## Teksty okrzyków (w obu językach) są w Lang.POW_LINES, POW_THANKS i POW_SHOUT.
const MOOD_STEP := 6.0

var kind := "pow"
var t := randf() * 2.0
var sprite: Sprite2D
var seen := 0.0              # ile sekund jeniec był na ekranie
var bubble_cd := randf_range(0.3, 1.2)
var bubble: SpeechBubble
var last_line := ""
## Kiedy ostatnio któryś jeniec krzyczał — dwóch naraz brzmiałoby jak chór.
static var last_shout_ms := -10000
const SHOUT_GAP_MS := 900


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


func mood() -> int:
	return mini(int(seen / MOOD_STEP), 3)


func _process(delta: float) -> void:
	t += delta
	if kind != "pow":
		return
	var m := mood()
	# zdenerwowany jeniec szarpie się szybciej i podskakuje
	sprite.texture = Sprites.prisoner(int(t * (2.5 + m * 2.0)) % 2)
	sprite.position.y = -absf(sin(t * 14.0)) * 2.0 if m >= 3 else 0.0
	sprite.modulate = Color(1, 0.78, 0.75) if m >= 3 else Color.WHITE

	if not _on_screen():
		return
	if seen == 0.0:
		_first_shout()
	seen += delta
	if is_instance_valid(bubble):
		return
	bubble_cd -= delta
	if bubble_cd <= 0.0:
		_say(_pick_line(m), m, 1.6 + m * 0.2)
		# im większa złość, tym częściej się odzywa
		bubble_cd = randf_range(1.0, 2.2) - m * 0.25


## Jeniec właśnie pojawił się na ekranie: woła na głos, a dymek pokazuje to samo słowo.
func _first_shout() -> void:
	var now := Time.get_ticks_msec()
	if now - last_shout_ms < SHOUT_GAP_MS:
		return
	last_shout_ms = now
	var sound := "shout_help" if randf() < 0.6 else "shout_hey"
	Sfx.play(sound, randf_range(0.9, 1.15))
	_say(Lang.pick(Lang.POW_SHOUT)[sound], 0, 1.4)
	bubble_cd = randf_range(1.0, 2.0)


func _pick_line(m: int) -> String:
	var lines: Array = Lang.pick(Lang.POW_LINES)
	var pool: Array = lines[m]
	# przy wściekłości czasem jeszcze zirytowany tekst, czasem znaczki
	if m >= 3 and randf() < 0.25:
		pool = lines[2]
	var line: String = pool.pick_random()
	if line == last_line:
		line = pool.pick_random()
	last_line = line
	return line


func _say(text: String, m: int, life: float) -> void:
	bubble = SpeechBubble.new()
	bubble.text = text
	bubble.mood = m
	bubble.life = life
	bubble.position = Vector2(0, -12)
	add_child(bubble)


func _on_screen() -> bool:
	var p := get_global_transform_with_canvas().origin
	var h := get_viewport_rect().size.y
	return p.y > 20.0 and p.y < h - 4.0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if kind == "medkit" and body.hp >= Player.MAX_HP:
			return # pełna energia: apteczka zostaje na później
		if kind == "pow":
			_farewell()
		collected.emit(kind, global_position)
		queue_free()


## Uwolniony jeniec dziękuje (albo burczy, jeśli długo czekał).
func _farewell() -> void:
	var b := SpeechBubble.new()
	var angry := mood() >= 2
	b.text = (Lang.pick(Lang.POW_THANKS_ANGRY) if angry else Lang.pick(Lang.POW_THANKS)).pick_random()
	b.mood = 2 if angry else 0
	b.life = 1.3
	get_parent().add_child(b)
	b.global_position = global_position + Vector2(0, -18)
