extends Node2D
## Główna scena: buduje poziom, gracza, wrogów, bossa i HUD w kodzie.

const LEVEL_LEN := 3840.0
const VIEW_W := 224.0        # szerokość widoku i świata (układ pionowy)
const WORLD_BOTTOM := 448.0  # dolna krawędź świata (zapas pod wysokie ekrany telefonów)
const START_Y := 200.0
const COLS := Terrain.COLS
const BOSS_ROWS := 14
const RIVER_ROWS := [190, 130, 70]        # wiersze kafelków (górny brzeg rzeki)
const TRENCH_ROWS := [222, 160, 105, 40]  # wiersze kafelków z rowami

# --- balans / trudność: tu najłatwiej dostroić grę ---
const START_LIVES := 3
const START_GRENADES := 5
const EXTRA_LIFE_EVERY := 10000
const TREE_COUNT := 55
const ROCK_COUNT := 30
const HILL_COUNT := 8
const TRENCH_GUARDS := 2 # wrogów okopanych za każdym rowem
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
var cam: Camera2D
var touch: TouchControls
var touch_mode := false
var end_time := 0
var score := 0
var lives := START_LIVES
var game_over := false
var won := false
var placed: Array[Vector2] = []
var trench_gaps := {} # wiersz rowu -> kolumny przejść
var shake := 0.0


func _ready() -> void:
	y_sort_enabled = true
	randomize()
	_setup_input()
	add_child(Sfx.new())
	add_child(ScreenMode.new())
	_plan_trenches()
	_build_background()
	_spawn_player()
	_spawn_obstacles()
	_spawn_bunkers()
	_spawn_pickups()
	_spawn_enemies()
	_spawn_trench_guards()
	_spawn_boss()
	_build_vignette()
	_build_hud()
	touch_mode = TouchControls.wanted()
	if touch_mode:
		touch = TouchControls.new()
		add_child(touch)
		message.text = Lang.t("intro_touch")
	else:
		message.text = Lang.t("intro_keys")
	get_tree().create_timer(4.0).timeout.connect(func(): if not (game_over or won): message.text = "")


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"fire": [KEY_SPACE, KEY_J],
		"grenade": [KEY_G, KEY_K],
		"aim_lock": [KEY_SHIFT], # blokada kierunku bez strzelania (trzymanie strzału też blokuje)
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

## Rowy: przejście na ścieżce (2 kafelki) + jedno losowe przejście z boku.
func _plan_trenches() -> void:
	for r in TRENCH_ROWS:
		var c := Terrain.path_center(r)
		var side := randi_range(0, 2) if randf() < 0.5 else randi_range(COLS - 3, COLS - 2)
		trench_gaps[r] = [c - 1, c, side, side + 1]


func _build_background() -> void:
	var rows := int((LEVEL_LEN + WORLD_BOTTOM) / 16.0)
	var bg := Terrain.level_background_node(COLS, rows, RIVER_ROWS, trench_gaps, BOSS_ROWS, LEVEL_LEN)
	bg.position = Vector2(0, -LEVEL_LEN)
	bg.z_index = -10
	add_child(bg)

	var water := Water.new()
	water.z_index = -9
	add_child(water)
	for r in RIVER_ROWS:
		var bc := Terrain.bridge_col(r)
		var wy: float = -LEVEL_LEN + (r + 1) * 16.0
		for tx in COLS:
			if tx < bc or tx > bc + 2:
				water.cells.append(Vector2(tx * 16.0, wy))
				water.edges.append(1)
				water.cells.append(Vector2(tx * 16.0, wy + 16.0))
				water.edges.append(2)
		_blocker_body(Rect2(0, wy, bc * 16.0, 32.0))
		_blocker_body(Rect2((bc + 3) * 16.0, wy, VIEW_W - (bc + 3) * 16.0, 32.0))

	# rowy: blokują ruch (jak woda), pociski przelatują nad nimi
	for r in TRENCH_ROWS:
		var gaps: Array = trench_gaps[r]
		var ty: float = -LEVEL_LEN + r * 16.0
		var start := -1
		for tx in COLS + 1:
			var solid := tx < COLS and not (tx in gaps)
			if solid and start < 0:
				start = tx
			elif not solid and start >= 0:
				_blocker_body(Rect2(start * 16.0, ty + 1.0, (tx - start) * 16.0, 14.0))
				start = -1


## Przeszkoda blokująca ruch, ale nie pociski (warstwa "water"): rzeki i rowy.
func _blocker_body(rect: Rect2) -> void:
	if rect.size.x <= 0.0:
		return
	var body := StaticBody2D.new()
	body.collision_layer = 32
	body.collision_mask = 0
	body.position = rect.get_center()
	var shape := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	shape.shape = rs
	body.add_child(shape)
	add_child(body)


## Czy punkt leży na ścieżce (z zapasem) — drzewa i skały jej nie blokują.
func _on_path(p: Vector2) -> bool:
	var img_y := p.y + LEVEL_LEN
	var cx := Terrain.path_px(img_y)
	return p.x > cx - Terrain.path_half(img_y, true) - 10.0 and p.x < cx + Terrain.path_half(img_y, false) + 10.0


func _near_blocker(y: float) -> bool:
	for r in RIVER_ROWS:
		var ry: float = -LEVEL_LEN + r * 16.0
		if y > ry - 24.0 and y < ry + 64.0 + 24.0:
			return true
	for r in TRENCH_ROWS:
		var ty: float = -LEVEL_LEN + r * 16.0
		if y > ty - 22.0 and y < ty + 16.0 + 22.0:
			return true
	return false


## Losuje wolne miejsce. `height` = jak wysoko obiekt sięga ponad swoją podstawę
## (żeby np. wzgórze nie nachodziło na rzekę).
func _free_spot(min_dist := 24.0, y_min := -LEVEL_LEN + 260.0, y_max := -140.0, height := 0.0,
		clear_path := false) -> Vector2:
	for attempt in 40:
		var p := Vector2(randf_range(16.0, VIEW_W - 16.0), randf_range(y_min, y_max))
		if _near_blocker(p.y) or _near_blocker(p.y - height):
			continue
		if clear_path and _on_path(p):
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
	player.position = Vector2(VIEW_W / 2.0, START_Y)
	player.grenades = START_GRENADES
	player.x_max = VIEW_W - 8.0
	player.y_min = -LEVEL_LEN + 64.0
	player.y_max = START_Y + 24.0
	player.hit.connect(_on_player_hit)
	add_child(player)

	cam = Camera2D.new()
	cam.limit_left = 0
	cam.limit_right = int(VIEW_W)
	cam.limit_top = int(-LEVEL_LEN)
	cam.limit_bottom = int(WORLD_BOTTOM)
	player.add_child(cam)
	cam.make_current()


## Roślinność zależy od strefy: łąka (dęby, sosny) -> dżungla (palmy) -> wyżyna (sosny, skały).
func _spawn_obstacles() -> void:
	for i in HILL_COUNT:
		var p := _free_spot(64.0, -LEVEL_LEN + 320.0, -280.0, 40.0)
		p.x = randf_range(6.0, 26.0) if i % 2 == 0 else randf_range(VIEW_W - 26.0, VIEW_W - 6.0)
		placed[placed.size() - 1] = p
		var zone := Terrain.zone_of(-p.y / LEVEL_LEN)
		_static_obstacle(Terrain.hill(zone), p, Vector2(0, -18), Vector2(50, 28), Vector2(0, -14))
	for i in TREE_COUNT:
		var p := _free_spot(22.0, -LEVEL_LEN + 260.0, -140.0, 30.0, true)
		var zone := Terrain.zone_of(-p.y / LEVEL_LEN)
		var r := randf()
		var kind := "oak"
		match zone:
			0:
				kind = "oak" if r < 0.7 else "pine"
			1:
				kind = "palm" if r < 0.6 else "oak"
			_:
				kind = "pine" if r < 0.6 else ("palm" if r < 0.75 else "oak")
		match kind:
			"oak":
				_static_obstacle(Terrain.oak(randi() % 2), p, Vector2(0, -12), Vector2(8, 6), Vector2(0, -2))
			"pine":
				_static_obstacle(Terrain.pine(), p, Vector2(0, -14), Vector2(6, 5), Vector2(0, -2))
			_:
				var flip := randf() < 0.5
				var s := _static_obstacle(Terrain.palm(), p, Vector2(-3 if flip else 3, -17), Vector2(6, 5), Vector2(0, -2))
				s.flip_h = flip
	for i in ROCK_COUNT:
		var p := _free_spot(20.0, -LEVEL_LEN + 260.0, -140.0, 10.0, true)
		match randi() % 3:
			0:
				_static_obstacle(Terrain.rock(0), p, Vector2(0, -7), Vector2(18, 10), Vector2(0, -5))
			1:
				_static_obstacle(Terrain.rock(1), p, Vector2(0, -5), Vector2(18, 8), Vector2(0, -4))
			_:
				_static_obstacle(Terrain.rock(2), p, Vector2(0, -4), Vector2(18, 6), Vector2(0, -3))


func _static_obstacle(tex: Texture2D, pos: Vector2, sprite_off: Vector2, size: Vector2, shape_off: Vector2) -> Sprite2D:
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
	return s


## Wrogowie okopani tuż za rowami (rów zatrzymuje ich tak samo jak gracza).
func _spawn_trench_guards() -> void:
	for r in TRENCH_ROWS:
		var gaps: Array = trench_gaps[r]
		var ty: float = -LEVEL_LEN + r * 16.0
		for i in TRENCH_GUARDS:
			var tx := randi_range(0, COLS - 1)
			for attempt in 10:
				if not (tx in gaps):
					break
				tx = randi_range(0, COLS - 1)
			var e := Enemy.new()
			e.kind = "grunt"
			e.position = Vector2(tx * 16.0 + 8.0, ty - 10.0)
			e.player = player
			e.died.connect(_on_enemy_died)
			add_child(e)


## Delikatna winieta: przyciemnione rogi ekranu.
func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.4))
	g.add_point(0.55, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 64
	tex.height = 64
	var tr := TextureRect.new()
	tr.texture = tex
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(tr)


## Wywoływane przez wybuchy: krótkie trzęsienie kamery.
func add_shake(amount: float) -> void:
	shake = minf(maxf(shake, amount), 4.0)


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
	layer.layer = 2 # nad winietą
	add_child(layer)
	var strip := ColorRect.new()
	strip.color = Color(0, 0, 0, 0.55)
	strip.size = Vector2(VIEW_W, 27)
	layer.add_child(strip)
	hud = Label.new()
	hud.position = Vector2(4, 1)
	hud.add_theme_font_size_override("font_size", 8)
	layer.add_child(hud)

	var music_btn := MusicButton.new()
	music_btn.position = Vector2(VIEW_W - 26, 1) # rząd 1, nad paskiem energii
	layer.add_child(music_btn)

	energy_node = Node2D.new()
	energy_node.draw.connect(_draw_energy)
	layer.add_child(energy_node)

	boss_bar_bg = ColorRect.new()
	boss_bar_bg.color = Color(0, 0, 0, 0.7)
	boss_bar_bg.position = Vector2((VIEW_W - 132.0) / 2.0, 31)
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
		energy_node.draw_rect(Rect2(VIEW_W - 88 + i * 14, 18, 12, 6), c)


func _process(delta: float) -> void:
	hud.text = Lang.t("hud") % [score, lives, player.grenades]
	energy_node.queue_redraw()
	# gracz w ok. 58% wysokości ekranu: więcej widać z przodu, a dół zostaje na kciuki
	var h := get_viewport_rect().size.y
	shake = move_toward(shake, 0.0, delta * 10.0)
	cam.offset = Vector2(randf_range(-shake, shake), -0.08 * h + randf_range(-shake, shake))
	message.position.y = h * 0.3
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
		Sfx.toggle_music()


# ---------------------------------------------------------------- zdarzenia

func _add_score(points: int) -> void:
	var before := floori(float(score) / EXTRA_LIFE_EVERY)
	score += points
	if floori(float(score) / EXTRA_LIFE_EVERY) > before:
		lives += 1
		_popup(Lang.t("one_up"), player.global_position)
		Sfx.play("rescue")


func _popup(text: String, pos: Vector2) -> void:
	var p := FloatText.new()
	p.text = text
	add_child(p)
	p.global_position = pos - Vector2(12, 16)


func _input(event: InputEvent) -> void:
	# na telefonie ekran końca gry: dotknięcie restartuje (po krótkiej zwłoce)
	if (game_over or won) and event is InputEventScreenTouch and event.pressed \
			and Time.get_ticks_msec() - end_time > 800:
		get_tree().reload_current_scene()


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
		_popup(Lang.t("plus_grenades") % CRATE_GRENADES, pos)
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
		message.text = _end_text(Lang.t("game_over"))


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
	message.text = _end_text(Lang.t("mission_complete"))


func _end_text(title: String) -> String:
	end_time = Time.get_ticks_msec()
	if touch != null:
		touch.enabled = false
	var record := HighScore.submit(score)
	var text := title + "\n" + Lang.t("score_line") % score
	if record:
		text += "  " + Lang.t("new_record")
	return text + "\n" + Lang.t("tap_restart" if touch_mode else "keys_restart")
