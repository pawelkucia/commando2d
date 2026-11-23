extends Node2D
## Ekran tytułowy (układ pionowy): logo z pikseli, animowani żołnierze i wybuchy w tle.

const GLYPHS := {
	"C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"M": ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#"],
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
}
const WORD := "COMMANDO"
const SCALE := 4
const W := 224.0

var t := 0.0
var h := 400.0
var boom_cd := 0.8
var logo: Node2D
var prompt: Label
var player_sprite: Sprite2D
var enemy_sprites: Array[Sprite2D] = []
var starting := false
var touch_mode := false
var music_btn: MusicButton
var best: Label
var hint: Label
var lang_node: Node2D


func _ready() -> void:
	randomize()
	touch_mode = TouchControls.wanted()
	h = get_viewport_rect().size.y
	add_child(Sfx.new())
	add_child(ScreenMode.new())

	var rows := int(ceil(h / 16.0)) + 1
	var bg := Terrain.level_background_node(Terrain.COLS, rows, [], {}, 0, rows * 16.0, 0)
	bg.z_index = -10
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.size = Vector2(W, h)
	shade.z_index = -9
	add_child(shade)

	# żołnierze na ścieżce
	player_sprite = Sprite2D.new()
	player_sprite.position = Vector2(W / 2.0, h * 0.8)
	add_child(player_sprite)
	for i in 4:
		var s := Sprite2D.new()
		s.position = Vector2(30 + i * 52, h * 0.64 + (i % 2) * 14)
		add_child(s)
		enemy_sprites.append(s)

	music_btn = MusicButton.new()
	music_btn.position = Vector2(W - 26, 4)
	add_child(music_btn)

	logo = Node2D.new()
	logo.draw.connect(_draw_logo)
	add_child(logo)

	# ciemny panel pod napisami, żeby nie zlewały się z trawą
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0.55)
	box.set_corner_radius_all(6)
	box.border_color = Color(1, 0.8, 0.3, 0.5)
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	panel.position = Vector2(24, h * 0.32)
	panel.size = Vector2(W - 48, 48)
	add_child(panel)

	# przełącznik języka PL | EN — lewy górny róg, naprzeciw głośnika
	lang_node = Node2D.new()
	lang_node.draw.connect(_draw_lang)
	add_child(lang_node)

	best = Label.new()
	best.position = Vector2(0, h * 0.32 + 5)
	best.size = Vector2(W, 14)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(best, 11, Color(1, 0.88, 0.35))
	add_child(best)

	prompt = Label.new()
	prompt.position = Vector2(0, h * 0.32 + 23)
	prompt.size = Vector2(W, 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(prompt, 15, Color.WHITE)
	add_child(prompt)

	if not touch_mode:
		hint = Label.new()
		hint.position = Vector2(0, h - 18)
		hint.size = Vector2(W, 14)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_style(hint, 9, Color(0.92, 0.92, 0.92))
		add_child(hint)

	_apply_texts()


## Wpisuje teksty w bieżącym języku (wywoływane też po przełączeniu PL/EN).
func _apply_texts() -> void:
	best.text = "%s  %06d" % [Lang.t("high_score"), HighScore.get_best()]
	prompt.text = Lang.t("tap_start" if touch_mode else "press_enter")
	# dłuższy polski napis dostaje trochę mniejszą czcionkę, żeby zmieścił się w panelu
	prompt.add_theme_font_size_override("font_size", 15 if prompt.text.length() <= 14 else 12)
	if hint:
		hint.text = Lang.t("title_hint")
	lang_node.queue_redraw()
	# Label rozrasta się po dodaniu do drzewa (szerokość liczona dla domyślnej czcionki 16 px),
	# więc przywracamy pełną szerokość ekranu, żeby wyśrodkowanie było poprawne.
	for c in get_children():
		if c is Label:
			c.reset_size()
			c.size.x = W


func _lang_rect(i: int) -> Rect2:
	return Rect2(6 + i * 24, 5, 22, 14)


func _draw_lang() -> void:
	var font := ThemeDB.fallback_font
	for i in Lang.LANGS.size():
		var code: String = Lang.LANGS[i]
		var rect := _lang_rect(i)
		var on := code == Lang.get_lang()
		var box := StyleBoxFlat.new()
		box.bg_color = Color(1, 0.8, 0.3, 0.95) if on else Color(0, 0, 0, 0.5)
		box.border_color = Color(1, 0.8, 0.3, 0.9)
		box.set_border_width_all(1)
		box.set_corner_radius_all(3)
		lang_node.draw_style_box(box, rect)
		var col := Color(0.12, 0.08, 0.02) if on else Color(1, 1, 1, 0.85)
		lang_node.draw_string(font, Vector2(rect.position.x, rect.position.y + 10.5), code.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, col)


## Zwraca true, jeśli stuknięcie trafiło w przełącznik języka (i przełącza go).
func _lang_hit(pos: Vector2) -> bool:
	for i in Lang.LANGS.size():
		if _lang_rect(i).grow(4).has_point(pos):
			if Lang.LANGS[i] != Lang.get_lang():
				Lang.set_lang(Lang.LANGS[i])
				Sfx.play("pickup")
				_apply_texts()
			return true
	return false


func _style(l: Label, size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 4)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)


func _draw_logo() -> void:
	var step := 5 * SCALE + SCALE
	var x0 := (W - (WORD.length() * step - SCALE)) / 2.0
	var y0 := h * 0.14 + sin(t * 2.0) * 2.0
	for pass_i in 2: # 0 = cień, 1 = litery
		for li in WORD.length():
			var rows: Array = GLYPHS[WORD[li]]
			for ry in 7:
				var row: String = rows[ry]
				for rx in 5:
					if row[rx] != "#":
						continue
					var pos := Vector2(x0 + li * step + rx * SCALE, y0 + ry * SCALE)
					if pass_i == 0:
						logo.draw_rect(Rect2(pos + Vector2(2, 2), Vector2(SCALE, SCALE)), Color(0.1, 0.05, 0.0))
					else:
						var k := ry / 6.0
						logo.draw_rect(Rect2(pos, Vector2(SCALE, SCALE)), Color(1.0, 0.85 - 0.45 * k, 0.2 - 0.1 * k))


func _input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed)
	# stuknięcie w głośnik albo w przełącznik języka nie startuje gry
	if tapped and not music_btn.hit(event.position) and not _lang_hit(event.position):
		_start()


func _process(delta: float) -> void:
	t += delta
	logo.queue_redraw()
	prompt.visible = int(t * 2.5) % 2 == 0 or starting
	Sprites.set_soldier(player_sprite, "player", Vector2.UP, t, true)
	var kinds := ["grunt", "grenadier", "sniper", "grunt"]
	for i in enemy_sprites.size():
		var face := Vector2.RIGHT if i % 2 == 0 else Vector2.LEFT
		Sprites.set_soldier(enemy_sprites[i], kinds[i], face, t + i, true)
		enemy_sprites[i].position.x += (14.0 if i % 2 == 0 else -14.0) * delta
		if enemy_sprites[i].position.x > W + 14.0:
			enemy_sprites[i].position.x = -14.0
		elif enemy_sprites[i].position.x < -14.0:
			enemy_sprites[i].position.x = W + 14.0

	boom_cd -= delta
	if boom_cd <= 0.0:
		boom_cd = randf_range(0.7, 1.6)
		var b := Boom.new()
		b.radius = randf_range(20.0, 34.0)
		b.position = Vector2(randf_range(16, W - 16), randf_range(h * 0.6, h * 0.92))
		add_child(b)

	if Input.is_action_just_pressed("ui_accept"):
		_start()


func _start() -> void:
	if starting:
		return
	starting = true
	Sfx.play("pickup")
	get_tree().create_timer(0.35).timeout.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
