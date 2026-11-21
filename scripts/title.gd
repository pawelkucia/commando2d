extends Node2D
## Ekran tytułowy: logo z pikseli, animowani żołnierze i wybuchy w tle.

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

var t := 0.0
var boom_cd := 0.8
var logo: Node2D
var prompt: Label
var player_sprite: Sprite2D
var enemy_sprites: Array[Sprite2D] = []
var starting := false


func _ready() -> void:
	randomize()
	add_child(Sfx.new())
	add_child(ScreenMode.new())

	var bg := Sprite2D.new()
	bg.texture = Sprites.level_background(16, 14, [], 0)
	bg.centered = false
	bg.z_index = -10
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.size = Vector2(256, 224)
	shade.z_index = -9
	add_child(shade)

	# żołnierze na ścieżce
	player_sprite = Sprite2D.new()
	player_sprite.position = Vector2(128, 190)
	add_child(player_sprite)
	for i in 4:
		var s := Sprite2D.new()
		s.position = Vector2(40 + i * 60, 150 + (i % 2) * 12)
		add_child(s)
		enemy_sprites.append(s)

	logo = Node2D.new()
	logo.draw.connect(_draw_logo)
	add_child(logo)

	var best := Label.new()
	best.text = "HIGH SCORE %06d" % HighScore.get_best()
	best.position = Vector2(0, 108)
	best.size = Vector2(256, 12)
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(best, 8, Color(1, 0.9, 0.4))
	add_child(best)

	prompt = Label.new()
	prompt.text = "PRESS ENTER"
	prompt.position = Vector2(0, 124)
	prompt.size = Vector2(256, 14)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(prompt, 10, Color.WHITE)
	add_child(prompt)

	var hint := Label.new()
	hint.text = "WASD move  SPACE fire  G grenade"
	hint.position = Vector2(0, 210)
	hint.size = Vector2(256, 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(hint, 8, Color(0.85, 0.85, 0.85))
	add_child(hint)


func _style(l: Label, size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 4)


func _draw_logo() -> void:
	var step := 5 * SCALE + SCALE
	var x0 := (256.0 - (WORD.length() * step - SCALE)) / 2.0
	var y0 := 38.0 + sin(t * 2.0) * 2.0
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
		if enemy_sprites[i].position.x > 270.0:
			enemy_sprites[i].position.x = -14.0
		elif enemy_sprites[i].position.x < -14.0:
			enemy_sprites[i].position.x = 270.0

	boom_cd -= delta
	if boom_cd <= 0.0:
		boom_cd = randf_range(0.7, 1.6)
		var b := Boom.new()
		b.radius = randf_range(20.0, 34.0)
		b.position = Vector2(randf_range(16, 240), randf_range(150, 205))
		add_child(b)

	if not starting and Input.is_action_just_pressed("ui_accept"):
		starting = true
		Sfx.play("pickup")
		get_tree().create_timer(0.35).timeout.connect(func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
