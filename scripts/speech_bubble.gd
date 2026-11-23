class_name SpeechBubble
extends Node2D
## Komiksowy dymek nad postacią. Ogonek wskazuje punkt (0, 0) węzła, a sam dymek
## jest dosuwany do krawędzi ekranu, żeby się nie obcinał.
## mood: 0-1 zwykły dymek, 2 zirytowany (pomarańczowa ramka), 3 wściekły (poszarpany, czerwony, trzęsie się).

const FONT_SIZE := 8
const VIEW_W := 224.0
const MARGIN := 2.0

var text := "HELP!"
var mood := 0
var life := 2.0
var t := 0.0
var jitter := Vector2.ZERO


func _ready() -> void:
	z_index = 30
	z_as_relative = false


func _process(delta: float) -> void:
	t += delta
	if mood >= 3:
		jitter = Vector2(randi_range(-1, 1), randi_range(-1, 0))
	if t >= life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var pad := Vector2(5, 3) if mood < 3 else Vector2(8, 6)
	var size := Vector2(ceilf(tw) + pad.x * 2.0, FONT_SIZE + 2.0 + pad.y * 2.0)
	# wyskakiwanie: przez pierwsze 0.08 s dymek jest 2 px niżej
	var lift := 0.0 if t > 0.08 else 2.0
	var gx := global_position.x
	var m := MARGIN + (size.x * 0.1 if mood >= 3 else 0.0) # kolce wystają poza prostokąt
	var left := clampf(-size.x / 2.0, m - gx, VIEW_W - m - gx - size.x)
	var rect := Rect2(Vector2(roundf(left), -size.y - 6.0 + lift) + jitter, size)

	var fill := Color(1, 1, 0.96)
	var ink := Color(0.08, 0.06, 0.05)
	var text_col := ink
	match mood:
		2:
			ink = Color(0.75, 0.35, 0.05)
		3:
			fill = Color(1, 0.93, 0.55)
			ink = Color(0.7, 0.05, 0.05)
			text_col = Color(0.8, 0.05, 0.05)

	# ogonek: trójkąt od dolnej krawędzi dymku do postaci
	var tip := Vector2(0, -1 + lift)
	var bx := clampf(0.0, rect.position.x + 5.0, rect.end.x - 9.0)
	var tail := PackedVector2Array([
		Vector2(bx, rect.end.y - 1), Vector2(bx + 5, rect.end.y - 1), tip])

	if mood >= 3:
		var pts := _spiky(rect)
		var outline := PackedVector2Array()
		for p in pts:
			outline.append(p)
		outline.append(pts[0])
		draw_colored_polygon(tail, fill)
		draw_polyline(PackedVector2Array([tail[0], tip, tail[1]]), ink, 1.0)
		draw_colored_polygon(pts, fill)
		draw_polyline(outline, ink, 1.0)
	else:
		# zaokrąglony prostokąt: ramka 1 px, ścięte rogi
		var r := rect
		draw_rect(Rect2(r.position + Vector2(1, 0), Vector2(r.size.x - 2, r.size.y)), ink)
		draw_rect(Rect2(r.position + Vector2(0, 1), Vector2(r.size.x, r.size.y - 2)), ink)
		draw_rect(r.grow(-1), fill)
		draw_colored_polygon(tail, ink)
		var inner := PackedVector2Array([tail[0] + Vector2(1, -1), tail[1] + Vector2(-1, -1), tip + Vector2(0, -2)])
		draw_colored_polygon(inner, fill)
		# lekki cień pod dymkiem
		draw_rect(Rect2(r.position.x + 2, r.end.y, r.size.x - 3, 1), Color(0, 0, 0, 0.25))

	var base := Vector2(rect.position.x + pad.x, rect.position.y + pad.y + FONT_SIZE)
	draw_string(font, base.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, text_col)


## Poszarpany "wykrzyczany" kształt wokół prostokąta.
func _spiky(rect: Rect2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var c := rect.get_center()
	var rx := rect.size.x / 2.0 * 1.15
	var ry := rect.size.y / 2.0 * 1.35
	var n := 20
	for i in n:
		var a := TAU * i / n
		var k := 1.08 if i % 2 == 0 else 0.86
		pts.append((c + Vector2(cos(a) * rx * k, sin(a) * ry * k)).round())
	return pts
