extends Node2D
## Główna scena: buduje poziom, gracza, wrogów, bossa i HUD w kodzie.

const LEVEL_LEN := 3840.0
const VIEW_W := 256.0
const VIEW_H := 224.0
const COLS := 16
const BOSS_ROWS := 14
const RIVER_ROWS := [190, 130, 70] # wiersze kafelków (górny brzeg rzeki)

# --- balans / trudność: tu najłatwiej dostroić grę ---
const START_LIVES := 3
const START_GRENADES := 5
const EXTRA_LIFE_EVERY := 10000
const TREE_COUNT := 45
const ROCK_COUNT := 25
const ENEMY_COUNT := 55
const BIKER_COUNT := 10
const BUNKER_COUNT := 12
const POW_COUNT := 10
const CRATE_COUNT := 8
const MEDKIT_COUNT := 10
const MEDKIT_HEAL := 2
const POW_GRENADES := 2
const CRATE_GRENADES := 5

var player: Player
var boss: Boss
var hud: Label
var message: Label
var boss_bar_bg: ColorRect
var boss_bar: ColorRect
var energy_node: Node2D
var score := 0
var lives := START_LIVES
var game_over := false
var won := false
var placed: Array[Vector2] = []


func _ready() -> void:
	y_sort_enabled = true
	randomize()
	_setup_input()
	add_child(Sfx.new())
	add_child(ScreenMode.new())
	_build_background()
	_spawn_player()
	_spawn_obstacles()
	_spawn_bunkers()
	_spawn_pickups()
	_spawn_enemies()
	_spawn_boss()
	_build_hud()
	message.text = "WASD - move   SPACE - fire\nG - grenade   M - mute"
	get_tree().create_timer(4.0).timeout.connect(func(): if not (game_over or won): message.text = "")


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"fire": [KEY_SPACE, KEY_J],
		"grenade": [KEY_G, KEY_K],
		"restart": [KEY_ENTER, KEY_R],
		"mute": [KEY_M],
		"menu": [KEY_ESCAPE],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


# ---------------------------------------------------------------- świat

func _build_background() -> void:
	var rows := int((LEVEL_LEN + VIEW_H) / 16.0)
	var bg := Sprite2D.new()
	bg.texture = Sprites.level_background(COLS, rows, RIVER_ROWS, BOSS_ROWS)
	bg.centered = false
	bg.position = Vector2(0, -LEVEL_LEN)
	bg.z_index = -10
	add_child(bg)

	var water := Water.new()
	water.z_index = -9
	add_child(water)
	for r in RIVER_ROWS:
		var bc := Sprites.bridge_col(r)
		var wy: float = -LEVEL_LEN + (r + 1) * 16.0
		for tx in COLS:
			if tx < bc or tx > bc + 2:
				water.cells.append(Vector2(tx * 16.0, wy))
				water.cells.append(Vector2(tx * 16.0, wy + 16.0))
		_water_body(Rect2(0, wy, bc * 16.0, 32.0))
		_water_body(Rect2((bc + 3) * 16.0, wy, VIEW_W - (bc + 3) * 16.0, 32.0))


func _water_body(rect: Rect2) -> void:
	if rect.size.x <= 0.0:
		return
	var body := StaticBody2D.new()
	body.collision_layer = 32 # water: blokuje ruch, nie blokuje pocisków
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	add_child(body)


func _near_river(y: float) -> bool:
	for r in RIVER_ROWS:
		var ry: float = -LEVEL_LEN + r * 16.0
		if y > ry - 24.0 and y < ry + 64.0 + 24.0:
			return true
	return false


func _free_spot(min_dist := 24.0, y_min := -LEVEL_LEN + 260.0, y_max := -140.0) -> Vector2:
	for attempt in 40:
		var p := Vector2(randf_range(16.0, VIEW_W - 16.0), randf_range(y_min, y_max))
		if _near_river(p.y):
			continue
		var ok := true
		for q in placed:
			if q.distance_to(p) < min_dist:
				ok = false
				break
		if ok:
			placed.append(p)
			return p
	var fallback := Vector2(randf_range(16.0, VIEW_W - 16.0), randf_range(y_min, y_max))
	placed.append(fallback)
	return fallback


func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector2(VIEW_W / 2.0, VIEW_H - 30.0)
	player.grenades = START_GRENADES
	player.y_min = -LEVEL_LEN + 64.0
	player.hit.connect(_on_player_hit)
	add_child(player)

	var cam := Camera2D.new()
	cam.offset = Vector2(0, -40)
	cam.limit_left = 0
	cam.limit_right = int(VIEW_W)
	cam.limit_top = int(-LEVEL_LEN)
	cam.limit_bottom = int(VIEW_H)
	player.add_child(cam)
	cam.make_current()


func _spawn_obstacles() -> void:
	for i in TREE_COUNT:
		_static_obstacle(Sprites.tree(), _free_spot(22.0), Vector2(0, -10), Vector2(8, 6), Vector2(0, -2))
	for i in ROCK_COUNT:
		_static_obstacle(Sprites.rock(), _free_spot(20.0), Vector2(0, -2), Vector2(12, 8), Vector2(0, 0))


func _static_obstacle(tex: Texture2D, pos: Vector2, sprite_off: Vector2, size: Vector2, shape_off: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	var s := Sprite2D.new()
	s.texture = tex
	s.position = sprite_off
	body.add_child(s)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = shape_off
	body.add_child(shape)
	add_child(body)


func _spawn_bunkers() -> void:
	for i in BUNKER_COUNT:
		var b := Bunker.new()
		b.position = _free_spot(40.0, -LEVEL_LEN + 300.0, -300.0)
		b.player = player
		b.died.connect(_on_enemy_died)
		add_child(b)


func _spawn_pickups() -> void:
	for i in POW_COUNT + CRATE_COUNT + MEDKIT_COUNT:
		var p := Pickup.new()
		if i < POW_COUNT:
			p.kind = "pow"
		elif i < POW_COUNT + CRATE_COUNT:
			p.kind = "crate"
		else:
			p.kind = "medkit"
		p.position = _free_spot(26.0, -LEVEL_LEN + 280.0, -200.0)
		p.collected.connect(_on_pickup)
		add_child(p)


func _pick_kind(y: float) -> String:
	var progress := -y / LEVEL_LEN
	var r := randf()
	if progress > 0.3 and r < 0.15:
		return "grenadier"
	if progress > 0.2 and r < 0.30:
		return "sniper"
	return "grunt"


func _spawn_enemies() -> void:
	for i in ENEMY_COUNT:
		var e := Enemy.new()
		var pos := _free_spot(18.0, -LEVEL_LEN + 300.0, -240.0)
		e.kind = _pick_kind(pos.y)
		e.position = pos
		e.player = player
		e.died.connect(_on_enemy_died)
		add_child(e)
	for i in BIKER_COUNT:
		var e := Enemy.new()
		e.kind = "biker"
		e.position = Vector2(randf_range(24.0, VIEW_W - 24.0), -randf_range(600.0, LEVEL_LEN - 400.0))
		e.player = player
		e.died.connect(_on_enemy_died)
		add_child(e)


func _spawn_boss() -> void:
	boss = Boss.new()
	boss.position = Vector2(VIEW_W / 2.0, -LEVEL_LEN + 100.0)
	boss.player = player
	boss.died.connect(_on_boss_died)
	add_child(boss)


# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.size = Vector2(VIEW_W, 12)
	layer.add_child(strip)
	hud = Label.new()
	hud.position = Vector2(4, 1)
	hud.add_theme_font_size_override("font_size", 8)
	layer.add_child(hud)

	energy_node = Node2D.new()
	energy_node.draw.connect(_draw_energy)
	layer.add_child(energy_node)

	boss_bar_bg = ColorRect.new()
	boss_bar_bg.color = Color(0, 0, 0, 0.7)
	boss_bar_bg.position = Vector2(62, 16)
	boss_bar_bg.size = Vector2(132, 8)
	boss_bar_bg.visible = false
	layer.add_child(boss_bar_bg)
	boss_bar = ColorRect.new()
	boss_bar.color = Color(0.9, 0.2, 0.15)
	boss_bar.position = Vector2(64, 18)
	boss_bar.size = Vector2(128, 4)
	boss_bar_bg.add_child(boss_bar)
	boss_bar.position = Vector2(2, 2)

	message = Label.new()
	message.position = Vector2(0, 90)
	message.size = Vector2(VIEW_W, 50)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 10)
	message.add_theme_color_override("font_outline_color", Color.BLACK)
	message.add_theme_constant_override("outline_size", 4)
	layer.add_child(message)


## Pasek energii gracza: segmenty zielone, czerwone przy niskim stanie.
func _draw_energy() -> void:
	var low := player.hp <= 2
	for i in Player.MAX_HP:
		var c := Color(0.2, 0.2, 0.2, 0.8)
		if i < player.hp:
			c = Color(0.95, 0.25, 0.15) if low else Color(0.3, 0.85, 0.3)
		energy_node.draw_rect(Rect2(158 + i * 16, 3, 14, 6), c)


func _process(_delta: float) -> void:
	hud.text = "SCORE %06d   LIVES %d   GRENADES %d" % [score, lives, player.grenades]
	energy_node.queue_redraw()
	if is_instance_valid(boss) and boss.active:
		boss_bar_bg.visible = true
		boss_bar.size.x = 128.0 * float(maxi(boss.hp, 0)) / Boss.MAX_HP
	else:
		boss_bar_bg.visible = false
	if (game_over or won) and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if (game_over or won) and Input.is_action_just_pressed("menu"):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
	if Input.is_action_just_pressed("mute"):
		Sfx.toggle_mute()


# ---------------------------------------------------------------- zdarzenia

func _add_score(points: int) -> void:
	var before := floori(float(score) / EXTRA_LIFE_EVERY)
	score += points
	if floori(float(score) / EXTRA_LIFE_EVERY) > before:
		lives += 1
		_popup("1UP", player.global_position)
		Sfx.play("rescue")


func _popup(text: String, pos: Vector2) -> void:
	var p := FloatText.new()
	p.text = text
	add_child(p)
	p.global_position = pos - Vector2(12, 16)


func _on_enemy_died(points: int) -> void:
	_add_score(points)


func _on_pickup(kind: String, pos: Vector2) -> void:
	if kind == "pow":
		_add_score(500)
		player.grenades += POW_GRENADES
		_popup("+500", pos)
		Sfx.play("rescue")
	elif kind == "medkit":
		player.hp = mini(player.hp + MEDKIT_HEAL, Player.MAX_HP)
		_popup("+%d HP" % MEDKIT_HEAL, pos)
		Sfx.play("pickup")
	else:
		player.grenades = mini(player.grenades + CRATE_GRENADES, 99)
		_popup("+%d G" % CRATE_GRENADES, pos)
		Sfx.play("pickup")


func _on_player_hit() -> void:
	if game_over:
		return
	Sfx.play("hit")
	var puff := Puff.new()
	puff.color = Color(0.9, 0.2, 0.15)
	add_child(puff)
	puff.global_position = player.global_position
	if player.hp > 0:
		return
	lives -= 1
	if lives > 0:
		player.hp = Player.MAX_HP # nowe życie = pełna energia
		player.invuln = 2.5
	else:
		game_over = true
		player.set_physics_process(false)
		Sfx.stop_music()
		Sfx.play("gameover")
		message.text = _end_text("GAME OVER")


func _on_boss_died(points: int) -> void:
	_add_score(points)
	Sfx.stop_music()
	get_tree().create_timer(1.6).timeout.connect(_level_complete)


func _level_complete() -> void:
	if game_over:
		return
	won = true
	player.set_physics_process(false)
	Sfx.play("win")
	message.text = _end_text("MISSION COMPLETE")


func _end_text(title: String) -> String:
	var record := HighScore.submit(score)
	var text := "%s\nSCORE %06d" % [title, score]
	if record:
		text += "  NEW RECORD!"
	return text + "\nENTER - restart   ESC - title"
