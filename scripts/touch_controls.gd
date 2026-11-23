class_name TouchControls
extends CanvasLayer
## Wirtualny joystick (lewa strona ekranu, pojawia się pod palcem) oraz przyciski
## FIRE i GREN (prawa strona). Wstrzykuje te same akcje, co klawiatura.
## Trzymanie FIRE blokuje kierunek strzału (jak Shift na klawiaturze): joystickiem
## można wtedy chodzić na boki i do tyłu, a żołnierz dalej strzela w tę samą stronę.

const STICK_R := 36.0
const DEADZONE := 0.25

var enabled := true : set = _set_enabled
var stick_id := -1
var stick_origin := Vector2.ZERO
var stick_pos := Vector2.ZERO
var fire_id := -1
var gren_id := -1
var canvas: Node2D


## Czy pokazać sterowanie dotykowe: telefon/tablet albo flaga `--touch` (do testów na PC).
static func wanted() -> bool:
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") \
		or "--touch" in OS.get_cmdline_args() or "--touch" in OS.get_cmdline_user_args()


func _ready() -> void:
	layer = 10
	canvas = Node2D.new()
	canvas.draw.connect(_draw_controls)
	add_child(canvas)


func _process(_delta: float) -> void:
	if enabled:
		canvas.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


func _set_enabled(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		_release_all()


func _release_all() -> void:
	stick_id = -1
	fire_id = -1
	gren_id = -1
	_apply_stick(Vector2.ZERO)
	Input.action_release("fire")
	Input.action_release("aim_lock")
	Input.action_release("grenade")


# ---------------------------------------------------------------- geometria

func _size() -> Vector2:
	return get_viewport().get_visible_rect().size


func _fire_c() -> Vector2:
	var s := _size()
	return Vector2(s.x - 46.0, s.y - 70.0)


func _gren_c() -> Vector2:
	var s := _size()
	return Vector2(s.x - 98.0, s.y - 108.0)


func _idle_stick_c() -> Vector2:
	return Vector2(62.0, _size().y - 72.0)


# ---------------------------------------------------------------- wejście

func _input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.index, event.position)
		else:
			_release(event.index)
	elif event is InputEventScreenDrag:
		if event.index == stick_id:
			_move_stick(event.position)


func _press(idx: int, pos: Vector2) -> void:
	if fire_id == -1 and pos.distance_to(_fire_c()) <= 30.0 * 1.3:
		fire_id = idx
		Input.action_press("fire")
		Input.action_press("aim_lock")
	elif gren_id == -1 and pos.distance_to(_gren_c()) <= 22.0 * 1.3:
		gren_id = idx
		Input.action_press("grenade")
	elif stick_id == -1 and pos.x < _size().x * 0.55 and pos.y > _size().y * 0.3:
		stick_id = idx
		stick_origin = pos
		stick_pos = pos


func _release(idx: int) -> void:
	if idx == stick_id:
		stick_id = -1
		_apply_stick(Vector2.ZERO)
	elif idx == fire_id:
		fire_id = -1
		Input.action_release("fire")
		Input.action_release("aim_lock")
	elif idx == gren_id:
		gren_id = -1
		Input.action_release("grenade")


func _move_stick(pos: Vector2) -> void:
	var v := (pos - stick_origin).limit_length(STICK_R)
	stick_pos = stick_origin + v
	_apply_stick(v / STICK_R)


## Poniżej martwej strefy brak ruchu, powyżej — pełna prędkość w wybranym kierunku.
func _apply_stick(v: Vector2) -> void:
	if v.length() < DEADZONE:
		v = Vector2.ZERO
	else:
		v = v.normalized()
	_axis("move_left", -v.x)
	_axis("move_right", v.x)
	_axis("move_up", -v.y)
	_axis("move_down", v.y)


func _axis(action: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


# ---------------------------------------------------------------- rysowanie

func _draw_controls() -> void:
	var active := stick_id != -1
	var base_c := stick_origin if active else _idle_stick_c()
	var knob := stick_pos if active else base_c
	canvas.draw_circle(base_c, STICK_R, Color(1, 1, 1, 0.08))
	canvas.draw_arc(base_c, STICK_R, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 1.5)
	canvas.draw_circle(knob, 14.0, Color(1, 1, 1, 0.45 if active else 0.2))
	_button(_fire_c(), 30.0, Lang.t("fire_btn"), fire_id != -1, Color(1.0, 0.4, 0.3))
	_button(_gren_c(), 22.0, Lang.t("gren_btn"), gren_id != -1, Color(0.5, 0.9, 0.4))


func _button(c: Vector2, r: float, label: String, pressed: bool, color: Color) -> void:
	canvas.draw_circle(c, r, Color(color.r, color.g, color.b, 0.5 if pressed else 0.2))
	canvas.draw_arc(c, r, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.8), 1.5)
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, Vector2(c.x - r, c.y + 3.0), label, HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 8, Color(1, 1, 1, 0.9))
