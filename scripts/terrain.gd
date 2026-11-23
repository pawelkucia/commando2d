class_name Terrain
extends RefCounted
## Teren i roślinność: kafelki podłoża w 3 strefach (łąka, dżungla, sucha wyżyna), woda z pianą,
## most, rowy, twierdza, drzewa (dąb, sosna, palma), skały, wzniesienia oraz "pieczenie" tła poziomu.

const COLS := 14 # szerokość świata w kafelkach 16 px (224 px)

## Palety trawy per strefa: [baza, ciemna, jasna, kwiaty]
const GRASS := [
	[Color(0.24, 0.53, 0.22), Color(0.18, 0.44, 0.18), Color(0.33, 0.62, 0.28), Color(0.98, 0.92, 0.5)],
	[Color(0.15, 0.45, 0.25), Color(0.1, 0.36, 0.2), Color(0.23, 0.55, 0.3), Color(0.95, 0.35, 0.4)],
	[Color(0.47, 0.53, 0.26), Color(0.38, 0.44, 0.2), Color(0.57, 0.61, 0.33), Color(0.9, 0.85, 0.75)],
]
const BARK := Color(0.42, 0.28, 0.15)
const ROCK := Color(0.53, 0.53, 0.55)


## Środek ścieżki (w pikselach) dla wiersza obrazu tła; droga płynnie się wije.
static func path_px(img_y: float) -> float:
	return 112.0 + 34.0 * sin(img_y * 0.0045) + 10.0 * sin(img_y * 0.013 + 1.0)


## Pół-szerokość ścieżki z lewej / prawej (lekko nierówne brzegi).
static func path_half(img_y: float, left: bool) -> float:
	if left:
		return 30.0 + 1.5 * sin(img_y * 0.31) + sin(img_y * 0.83 + 2.0)
	return 30.0 + 1.5 * sin(img_y * 0.27 + 1.0) + sin(img_y * 0.71)


## Kolumna kafelka, w której leży środek ścieżki (do mostów i przejść przez rowy).
static func path_center(ty: int) -> int:
	return int(round(path_px(ty * 16.0 + 8.0) / 16.0))


static func bridge_col(river_row: int) -> int:
	return clampi(path_center(river_row) - 1, 1, COLS - 4)


## Strefa wg postępu p (0 = start, 1 = twierdza). Granice leżą z dala od rzek i rowów.
static func zone_of(p: float) -> int:
	if p < 0.267:
		return 0
	if p < 0.633:
		return 1
	return 2


## Płynna wersja strefy (0..2, krok 0.25) — kolor trawy przechodzi stopniowo między strefami.
static func zone_t(p: float) -> float:
	var t := clampf((p - 0.267) / 0.06 + 0.5, 0.0, 1.0) + clampf((p - 0.633) / 0.06 + 0.5, 0.0, 1.0)
	return snappedf(t, 0.25)


static func _grass_pal(t: float) -> Array:
	var i := mini(int(t), 1)
	var f := t - i
	var a: Array = GRASS[i]
	var b: Array = GRASS[i + 1]
	var out := []
	for k in 3:
		out.append((a[k] as Color).lerp(b[k], f))
	out.append(GRASS[int(round(t))][3])
	return out


# ---------------------------------------------------------------- pomocnicze kafelków
# Rysowanie z zawijaniem krawędzi => sąsiednie kafelki łączą się bez widocznych szwów.

static func _tp(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, 16), posmod(y, 16), c)


static func _tdisc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for j in range(cy - r, cy + r + 1):
		for i in range(cx - r, cx + r + 1):
			if (i - cx) * (i - cx) + (j - cy) * (j - cy) <= r * r + r:
				_tp(img, i, j, c)


static func _grass_img(t: float, v: int) -> Image:
	var pal := _grass_pal(t)
	var base: Color = pal[0]
	var dark: Color = pal[1]
	var light: Color = pal[2]
	var img := Sprites._new(16, 16)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + int(t * 4.0) * 37 + v * 7
	for i in 3:
		_tdisc(img, rng.randi_range(0, 15), rng.randi_range(0, 15), rng.randi_range(1, 2), Sprites._sh(base, 0.93))
	for i in 2:
		_tdisc(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, Sprites._lt(base, 0.06))
	for i in 6: # źdźbła
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		_tp(img, x, y, dark)
		_tp(img, x - 1, y - 1, dark)
		_tp(img, x + 1, y - 2, light)
	if v == 3: # kwiatki
		for i in 2:
			var x := rng.randi_range(0, 15)
			var y := rng.randi_range(0, 15)
			_tp(img, x, y, pal[3])
			_tp(img, x + 1, y, Sprites._sh(pal[3], 0.8))
			_tp(img, x, y + 1, dark)
	return img


static func _path_img(v: int) -> Image:
	var base := Color(0.67, 0.56, 0.38)
	var img := Sprites._new(16, 16)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 200 + v
	for i in 4:
		_tdisc(img, rng.randi_range(0, 15), rng.randi_range(0, 15), rng.randi_range(1, 2), Sprites._sh(base, 0.9))
	for i in 3:
		_tdisc(img, rng.randi_range(0, 15), rng.randi_range(0, 15), 1, Sprites._lt(base, 0.1))
	for i in 2: # kamyki
		var x := rng.randi_range(0, 15)
		var y := rng.randi_range(0, 15)
		_tp(img, x, y, Color(0.55, 0.53, 0.5))
		_tp(img, x - 1, y - 1, Color(0.78, 0.76, 0.72))
		_tp(img, x + 1, y + 1, Sprites._sh(base, 0.75))
	return img


## Rysuje płynnie wijącą się ścieżkę wiersz po wierszu (szybkie kopiowanie pasków 1 px).
## Na rzekach i w twierdzy jej nie ma; na rowach tylko w przejściach.
static func _draw_path(img: Image, rows: int, row_kind: PackedInt32Array, trenches: Dictionary,
		rng: RandomNumberGenerator) -> void:
	var pat := Sprites._new(256, 64) # wzór nawierzchni szerszy niż świat
	var variants := [_path_img(0), _path_img(1), _path_img(2), _path_img(3)]
	for by in 4:
		for bx in 16:
			pat.blit_rect(variants[rng.randi() % 4], Rect2i(0, 0, 16, 16), Vector2i(bx * 16, by * 16))
	var edge_dark := Color(0.16, 0.36, 0.16, 0.9)
	for y in rows * 16:
		var ty := int(y / 16.0)
		var kind := row_kind[ty]
		if kind == 20 or (kind >= 0 and kind <= 3):
			continue
		var cx := path_px(y)
		var x0 := clampi(int(cx - path_half(y, true)), 1, img.get_width() - 2)
		var x1 := clampi(int(cx + path_half(y, false)), 1, img.get_width() - 2)
		if kind == 10: # rów: ścieżka tylko w przejściach
			for g in trenches[ty]:
				var sx0 := maxi(x0, g * 16)
				var sx1 := mini(x1, g * 16 + 16)
				if sx1 > sx0:
					img.blit_rect(pat, Rect2i(sx0, y % 64, sx1 - sx0, 1), Vector2i(sx0, y))
			continue
		img.blit_rect(pat, Rect2i(x0, y % 64, x1 - x0, 1), Vector2i(x0, y))
		# brzegi: ciemniejsza trawa na granicy + cień na nawierzchni
		img.set_pixel(x0 - 1, y, img.get_pixel(x0 - 1, y).blend(edge_dark))
		img.set_pixel(x0, y, Sprites._sh(img.get_pixel(x0, y), 0.8))
		img.set_pixel(x0 + 1, y, Sprites._sh(img.get_pixel(x0 + 1, y), 0.9))
		img.set_pixel(x1, y, img.get_pixel(x1, y).blend(edge_dark))
		img.set_pixel(x1 - 1, y, Sprites._sh(img.get_pixel(x1 - 1, y), 0.85))


static func _sand_img(wet: int) -> Image:
	var base := Color(0.86, 0.78, 0.53)
	var img := Sprites._new(16, 16)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + wet
	for i in 8:
		_tp(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Sprites._sh(base, 0.88))
	for i in 4:
		_tp(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Sprites._lt(base, 0.25))
	if wet != 0: # mokry pas przy wodzie
		var shades := [0.9, 0.8, 0.68]
		for k in 3:
			var y := 13 + k if wet == 1 else 2 - k
			for x in 16:
				img.set_pixel(x, y, Sprites._sh(img.get_pixel(x, y), shades[k]))
	return img


static func water(frame: int, edge: int) -> Texture2D:
	return Sprites._tex("water_%d_%d" % [frame, edge], func(): return _water_img(frame, edge))


## Woda: edge 1 = piana u góry (brzeg północny), 2 = piana u dołu (brzeg południowy).
static func _water_img(frame: int, edge: int) -> Image:
	var deep := Color(0.12, 0.34, 0.64)
	var shallow := Color(0.22, 0.5, 0.74)
	var img := Sprites._new(16, 16)
	for y in 16:
		var k := 0.0
		if edge == 1:
			k = clampf(1.0 - y / 7.0, 0.0, 1.0)
		elif edge == 2:
			k = clampf((y - 8) / 7.0, 0.0, 1.0)
		var c := deep.lerp(shallow, k)
		for x in 16:
			img.set_pixel(x, y, c)
	for k in 5: # fale
		var x0 := (k * 7 + frame * 3) % 16
		var y := (k * 5 + 3) % 16
		for i in 3:
			_tp(img, x0 + i, y, Color(0.36, 0.62, 0.88))
		_tp(img, x0 + 1, y - 1, Color(0.3, 0.55, 0.82))
	for k in 2: # odblaski
		_tp(img, (k * 11 + frame * 5) % 16, (k * 7 + 5) % 16, Color(0.88, 0.96, 1.0))
	var foam := Color(0.88, 0.95, 1.0)
	for x in 16:
		var n := (x * 5 + frame * 3) % 7
		if edge == 1:
			img.set_pixel(x, 0, foam)
			if n < 4:
				img.set_pixel(x, 1, foam)
			if n == 0:
				img.set_pixel(x, 2, Color(0.6, 0.8, 0.95))
		elif edge == 2:
			img.set_pixel(x, 15, foam)
			if n < 4:
				img.set_pixel(x, 14, foam)
			if n == 0:
				img.set_pixel(x, 13, Color(0.6, 0.8, 0.95))
	return img


static func _bridge_img(part: int) -> Image:
	var img := Sprites._new(16, 16)
	for y in 16:
		var tone := Color(0.6, 0.42, 0.22) if int(y / 4.0) % 2 == 0 else Color(0.53, 0.36, 0.19)
		for x in 16:
			img.set_pixel(x, y, tone)
		if y % 4 == 3:
			for x in 16:
				img.set_pixel(x, y, Color(0.3, 0.2, 0.1))
		elif y % 4 == 0:
			for x in 16:
				img.set_pixel(x, y, Sprites._lt(tone, 0.12))
	for y in [1, 5, 9, 13]:
		img.set_pixel(3, y, Color(0.7, 0.7, 0.72))
		img.set_pixel(12, y, Color(0.7, 0.7, 0.72))
	var rail := Color(0.36, 0.24, 0.12)
	if part != 1:
		var x0 := 0 if part == 0 else 13
		Sprites._r(img, x0, 0, 3, 16, rail)
		Sprites._r(img, x0, 0, 1, 16, Sprites._lt(rail, 0.2))
		for y in [0, 8]:
			Sprites._r(img, x0, y, 3, 2, Color(0.55, 0.4, 0.22)) # słupki
	return img


static func _floor_img() -> Image:
	var base := Color(0.56, 0.55, 0.5)
	var img := Sprites._new(16, 16)
	img.fill(base)
	var rng := RandomNumberGenerator.new()
	rng.seed = 500
	for row in 2:
		var off := (row % 2) * 4
		for col in 3:
			var x0 := col * 8 - off
			var y0 := row * 8
			var tint := Sprites._sh(base, rng.randf_range(0.92, 1.05))
			for y in 8:
				for x in 8:
					_tp(img, x0 + x, y0 + y, tint)
			for i in 8:
				_tp(img, x0 + i, y0, Sprites._lt(tint, 0.15))
				_tp(img, x0, y0 + i, Sprites._lt(tint, 0.08))
				_tp(img, x0 + i, y0 + 7, Color(0.35, 0.34, 0.31))
				_tp(img, x0 + 7, y0 + i, Color(0.35, 0.34, 0.31))
	for i in 3:
		_tp(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Color(0.35, 0.48, 0.25)) # mech
	return img


static func _wall_img() -> Image:
	var base := Color(0.4, 0.39, 0.43)
	var img := Sprites._new(16, 16)
	img.fill(base)
	for row in 4:
		var y0 := row * 4
		var off := (row % 2) * 4
		for x in 16:
			img.set_pixel(x, y0 + 3, Color(0.24, 0.23, 0.27))
			img.set_pixel(x, y0, Sprites._lt(base, 0.12))
		for x in range(off, 16, 8):
			for y in 4:
				img.set_pixel(x, y0 + y, Color(0.24, 0.23, 0.27))
	return img


## Rów: worki z piaskiem u góry, głęboki ciemny wykop z deskami na dnie, ziemny stok u dołu.
## part: 0 = środek, 1 = lewy koniec, 2 = prawy koniec.
static func _trench_img(part: int) -> Image:
	var img := Sprites._new(16, 16)
	img.fill(Color(0.13, 0.09, 0.06))
	Sprites._r(img, 0, 4, 16, 2, Color(0.07, 0.05, 0.035)) # cień pod workami
	Sprites._r(img, 0, 8, 16, 3, Color(0.25, 0.18, 0.1))   # deski na dnie
	for x in range(1, 16, 4):
		Sprites._r(img, x, 8, 1, 3, Color(0.12, 0.08, 0.05))
	for y in 5: # stok od strony gracza: jaśniejszy ku górze krawędzi
		Sprites._r(img, 0, 11 + y, 16, 1, Color(0.3, 0.22, 0.13).lerp(Color(0.47, 0.36, 0.21), y / 4.0))
	for x in range(0, 16, 3):
		Sprites._p(img, x, 15, Color(0.22, 0.45, 0.2))
		Sprites._p(img, x + 1, 15, Color(0.18, 0.38, 0.17))
	var bag := Color(0.76, 0.66, 0.43)
	for x in range(-3, 16, 6): # worki z piaskiem (zaokrąglone)
		Sprites._r(img, x + 1, 0, 4, 1, Sprites._lt(bag, 0.3))
		Sprites._r(img, x, 1, 6, 2, bag)
		Sprites._p(img, x, 1, Sprites._lt(bag, 0.15))
		Sprites._r(img, x + 1, 3, 4, 1, Sprites._sh(bag, 0.62))
		Sprites._p(img, x + 5, 2, Sprites._sh(bag, 0.75))
	if part != 0: # zaokrąglony koniec rowu: ziemny nasyp
		var x0 := 0 if part == 1 else 11
		for y in 16:
			Sprites._r(img, x0, y, 5, 1, Color(0.4, 0.3, 0.18).lerp(Color(0.5, 0.39, 0.23), y / 15.0))
		Sprites._r(img, x0 + (4 if part == 1 else 0), 3, 1, 9, Color(0.22, 0.15, 0.09))
	return img


## Miękka plama (do łamania powtarzalności kafelków).
static func _blob_img(size: int, c: Color) -> Image:
	var img := Sprites._new(size, size)
	var r := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length() / r
			if d < 1.0:
				img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * (1.0 - d * d)))
	return img


# ---------------------------------------------------------------- małe dekoracje (wtapiane w tło)

static func _tuft_img(zone: int) -> Image:
	var pal: Array = GRASS[zone]
	var img := Sprites._new(7, 6)
	for i: int in [0, 2, 4, 6]:
		var h: int = 3 + (1 if i % 4 == 2 else 0)
		Sprites._r(img, i, 6 - h, 1, h, pal[1])
	Sprites._r(img, 3, 0, 1, 6, pal[2])
	Sprites._r(img, 1, 2, 1, 4, pal[2])
	return img


static func _flowers_img(zone: int) -> Image:
	var pal: Array = GRASS[zone]
	var img := Sprites._new(7, 5)
	for p in [Vector2i(1, 1), Vector2i(4, 0), Vector2i(5, 3)]:
		Sprites._p(img, p.x, p.y + 1, pal[1])
		Sprites._p(img, p.x, p.y, pal[3])
		Sprites._p(img, p.x + 1, p.y, Sprites._sh(pal[3], 0.85))
	return img


static func _pebbles_img() -> Image:
	var img := Sprites._new(6, 4)
	Sprites._r(img, 0, 1, 3, 2, Color(0.55, 0.54, 0.52))
	Sprites._p(img, 0, 1, Color(0.75, 0.74, 0.72))
	Sprites._r(img, 4, 2, 2, 2, Color(0.5, 0.49, 0.47))
	Sprites._r(img, 0, 3, 3, 1, Color(0, 0, 0, 0.25))
	return img


static func _bush_img(zone: int) -> Image:
	var pal: Array = GRASS[zone]
	var img := Sprites._new(16, 13)
	var dk: Color = Sprites._sh(pal[1], 0.85)
	Sprites._ellipse(img, 8, 7, 7, 5, dk)
	Sprites._ellipse(img, 6.5, 6, 5, 4, pal[0])
	Sprites._ellipse(img, 5.5, 4.5, 2.5, 2, pal[2])
	Sprites._p(img, 10, 5, pal[2])
	if zone == 0:
		Sprites._p(img, 9, 8, Color(0.85, 0.2, 0.25)) # jagody
		Sprites._p(img, 5, 9, Color(0.85, 0.2, 0.25))
	Sprites._outline(img)
	Sprites._shadow(img, 9, 11, 7, 1.8, 0.25)
	return img


# ---------------------------------------------------------------- tło poziomu

## Tło poziomu jako węzeł z paskami tekstur po max. 2048 px wysokości
## (część telefonów nie obsługuje tekstur większych niż 4096 px).
## trenches: {wiersz: [kolumny przejść]}, zone_override >= 0 wymusza jedną strefę (ekran tytułowy).
static func level_background_node(cols: int, rows: int, rivers: Array, trenches: Dictionary,
		boss_rows: int, level_len: float, zone_override := -1) -> Node2D:
	var img := _level_image(cols, rows, rivers, trenches, boss_rows, level_len, zone_override)
	var root := Node2D.new()
	var y := 0
	while y < img.get_height():
		var h := mini(2048, img.get_height() - y)
		var s := Sprite2D.new()
		s.texture = ImageTexture.create_from_image(img.get_region(Rect2i(0, y, img.get_width(), h)))
		s.centered = false
		s.position = Vector2(0, y)
		root.add_child(s)
		y += h
	return root


static func _level_image(cols: int, rows: int, rivers: Array, trenches: Dictionary,
		boss_rows: int, level_len: float, zone_override: int) -> Image:
	var img := Sprites._new(cols * 16, rows * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grass := [] # grass[int(t * 4)][wariant], t = 0..2 co 0.25
	for k in 9:
		var arr := []
		for v in 5:
			arr.append(_grass_img(k / 4.0, v))
		grass.append(arr)
	var sand := [_sand_img(0), _sand_img(1), _sand_img(2)]
	var wtiles := [_water_img(0, 1), _water_img(0, 2)]
	var bridge := [_bridge_img(0), _bridge_img(1), _bridge_img(2)]
	var trench := [_trench_img(0), _trench_img(1), _trench_img(2)]
	var floor_t := _floor_img()
	var wall := _wall_img()
	var is_grass := PackedByteArray()
	is_grass.resize(rows * cols)

	var row_kind := PackedInt32Array() # -1 zwykły, 0..3 wiersz rzeki, 10 rów, 20 twierdza
	row_kind.resize(rows)
	for ty in rows:
		var p := clampf((level_len - ty * 16.0) / level_len, 0.0, 1.0)
		var rr := -1
		var bc := 0
		for r in rivers:
			if ty >= r and ty <= r + 3:
				rr = ty - r
				bc = bridge_col(r)
		row_kind[ty] = 20 if ty < boss_rows else (rr if rr >= 0 else (10 if trenches.has(ty) else -1))
		# cały wiersz w jednym odcieniu; między strefami kolor zmienia się co 0.25 strefy
		var zk := zone_override * 4 if zone_override >= 0 else int(zone_t(p) * 4.0)
		for tx in cols:
			var tile: Image
			var g := false
			if ty < boss_rows:
				tile = wall if ty < 3 else floor_t
			elif rr == 0:
				tile = sand[1]
			elif rr == 3:
				tile = sand[2]
			elif rr == 1 or rr == 2:
				tile = bridge[tx - bc] if (tx >= bc and tx <= bc + 2) else wtiles[rr - 1]
			elif trenches.has(ty) and not (tx in trenches[ty]):
				var gaps: Array = trenches[ty]
				var part := 0
				if (tx - 1) in gaps:
					part = 1
				elif (tx + 1) in gaps:
					part = 2
				tile = trench[part]
			else:
				tile = grass[zk][rng.randi() % 5]
				g = true
			img.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(tx * 16, ty * 16))
			is_grass[ty * cols + tx] = 1 if g else 0

	var w := cols * 16
	var h := rows * 16
	_draw_path(img, rows, row_kind, trenches, rng)

	var grass_at := func(x: int, y: int) -> bool:
		var tx := clampi(x / 16, 0, cols - 1)
		var ty := clampi(y / 16, 0, rows - 1)
		if is_grass[ty * cols + tx] != 1:
			return false
		var cx := path_px(y)
		return x < cx - path_half(y, true) - 4.0 or x > cx + path_half(y, false) + 4.0
	var zone_at := func(y: int) -> int:
		if zone_override >= 0:
			return zone_override
		return zone_of(clampf((level_len - y) / level_len, 0.0, 1.0))

	# duże miękkie plamy: łamią powtarzalność kafelków
	var blob_dark := _blob_img(48, Color(0.0, 0.08, 0.0, 0.16))
	var blob_light := _blob_img(40, Color(1.0, 1.0, 0.75, 0.08))
	var blob_dirt := _blob_img(26, Color(0.45, 0.33, 0.18, 0.3))
	for i in int(rows * 1.2):
		var x := rng.randi_range(0, w - 48)
		var y := rng.randi_range(0, h - 48)
		if grass_at.call(x + 24, y + 24):
			img.blend_rect(blob_dark, Rect2i(0, 0, 48, 48), Vector2i(x, y))
		x = rng.randi_range(0, w - 40)
		y = rng.randi_range(0, h - 40)
		if grass_at.call(x + 20, y + 20):
			img.blend_rect(blob_light, Rect2i(0, 0, 40, 40), Vector2i(x, y))
		x = rng.randi_range(0, w - 26)
		y = rng.randi_range(0, h - 26)
		var dirt_chance := 0.6 if zone_at.call(y) == 2 else 0.2
		if grass_at.call(x + 13, y + 13) and rng.randf() < dirt_chance:
			img.blend_rect(blob_dirt, Rect2i(0, 0, 26, 26), Vector2i(x, y))

	# drobne dekoracje: kępki trawy, kwiaty, kamyki, krzaki
	var deco := []
	for z in 3:
		deco.append([_tuft_img(z), _flowers_img(z), _pebbles_img(), _bush_img(z)])
	for i in int(rows * 3.2):
		var x := rng.randi_range(0, w - 16)
		var y := rng.randi_range(0, h - 13)
		if not grass_at.call(x + 6, y + 6):
			continue
		var z: int = zone_at.call(y)
		var r := rng.randf()
		var k := 0
		if r < 0.45:
			k = 0
		elif r < 0.7:
			k = 1 if z != 2 else 0
		elif r < 0.85:
			k = 2
		else:
			k = 3
		var d: Image = deco[z][k]
		img.blend_rect(d, Rect2i(Vector2i.ZERO, d.get_size()), Vector2i(x, y))
	return img


# ---------------------------------------------------------------- drzewa, skały, wzniesienia

static func oak(v: int) -> Texture2D:
	return Sprites._tex("oak_%d" % v, func(): return _oak_img(v))


static func _oak_img(v: int) -> Image:
	var img := Sprites._new(28, 32)
	Sprites._r(img, 12, 19, 4, 10, BARK)
	Sprites._r(img, 12, 19, 1, 10, Sprites._lt(BARK, 0.2))
	Sprites._r(img, 15, 19, 1, 10, Sprites._sh(BARK, 0.7))
	Sprites._r(img, 10, 27, 2, 2, BARK)
	Sprites._r(img, 16, 27, 2, 2, Sprites._sh(BARK, 0.8))
	var dk := Color(0.09, 0.3, 0.13) if v == 0 else Color(0.16, 0.33, 0.1)
	var md := Color(0.15, 0.44, 0.18) if v == 0 else Color(0.27, 0.48, 0.14)
	var lt := Color(0.27, 0.58, 0.25) if v == 0 else Color(0.44, 0.63, 0.2)
	Sprites._disc(img, 14, 13, 10, dk)
	Sprites._disc(img, 11, 11, 7, md)
	Sprites._disc(img, 18, 12, 5, md)
	Sprites._disc(img, 13, 16, 5, md)
	Sprites._disc(img, 10, 8, 4, lt)
	Sprites._disc(img, 17, 8, 3, lt)
	for p in [Vector2i(9, 5), Vector2i(11, 4), Vector2i(16, 6), Vector2i(7, 9), Vector2i(12, 7)]:
		Sprites._p(img, p.x, p.y, Sprites._lt(lt, 0.25))
	for p in [Vector2i(19, 16), Vector2i(14, 20), Vector2i(21, 12), Vector2i(8, 17)]:
		Sprites._p(img, p.x, p.y, Sprites._sh(dk, 0.7))
	Sprites._outline(img)
	Sprites._shadow(img, 17, 28.5, 11, 3.2)
	return img


static func pine() -> Texture2D:
	return Sprites._tex("pine", _pine_img)


static func _pine_img() -> Image:
	var img := Sprites._new(22, 34)
	Sprites._r(img, 10, 26, 3, 6, BARK)
	Sprites._r(img, 10, 26, 1, 6, Sprites._lt(BARK, 0.2))
	var dark := Color(0.07, 0.27, 0.2)
	var light := Color(0.14, 0.41, 0.28)
	for i in 4:
		var y0 := 2 + i * 6
		var hw := 3 + i * 2
		for j in 9:
			var wdt := int(lerpf(1.0, float(hw), j / 8.0))
			var l := light if j < 8 else Sprites._sh(light, 0.8)
			var d := dark if j < 8 else Sprites._sh(dark, 0.8)
			Sprites._r(img, 11 - wdt, y0 + j, wdt, 1, l)
			Sprites._r(img, 11, y0 + j, wdt, 1, d)
		Sprites._p(img, 10 - hw / 2, y0 + 6, Sprites._lt(light, 0.25))
	Sprites._p(img, 10, 2, Sprites._lt(light, 0.4))
	Sprites._outline(img)
	Sprites._shadow(img, 13, 32, 8, 2.2)
	return img


static func palm() -> Texture2D:
	return Sprites._tex("palm", _palm_img)


static func _palm_img() -> Image:
	var img := Sprites._new(34, 40)
	for s in 27: # pień wygięty łukiem
		var t := s / 26.0
		var x := 14.0 + 5.0 * t * t
		var y := 37.0 - 26.0 * t
		var col := Color(0.58, 0.45, 0.27) if s % 3 != 0 else Color(0.43, 0.32, 0.18)
		Sprites._r(img, int(x) - 1, int(y), 3, 1, col)
		Sprites._p(img, int(x) - 1, int(y), Sprites._lt(col, 0.15))
	var top := Vector2(19, 11)
	var leaf_dark := Color(0.1, 0.38, 0.16)
	var leaf := Color(0.2, 0.55, 0.2)
	var leaf_light := Color(0.38, 0.7, 0.28)
	for a in [200.0, 235.0, 270.0, 305.0, 340.0, 15.0, 165.0]:
		var dir := Vector2.from_angle(deg_to_rad(a))
		var length := 9 if a == 270.0 else 14
		var perp := Vector2(-dir.y, dir.x)
		for k in length:
			var pos := top + dir * k + Vector2(0, 0.05 * k * k)
			var c := leaf.lerp(leaf_light, 1.0 - float(k) / length) if dir.y < 0.0 else leaf
			Sprites._r(img, int(pos.x), int(pos.y), 2, 2, c)
			if k > 2 and k % 2 == 0: # listki
				var a1 := pos + perp * 2.0 + Vector2(0, 1)
				var a2 := pos - perp * 2.0 + Vector2(0, 1)
				Sprites._p(img, int(a1.x), int(a1.y), leaf_dark)
				Sprites._p(img, int(a2.x), int(a2.y), leaf_dark)
	Sprites._disc(img, 18, 13, 1, Color(0.4, 0.26, 0.12)) # kokosy
	Sprites._disc(img, 21, 13, 1, Color(0.35, 0.22, 0.1))
	Sprites._outline(img)
	Sprites._shadow(img, 16, 37.5, 9, 2.2)
	return img


static func rock(v: int) -> Texture2D:
	return Sprites._tex("rock_%d" % v, func(): return _rock_img(v))


static func _stone(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	Sprites._ellipse(img, cx, cy, rx, ry, ROCK)
	Sprites._ellipse(img, cx + rx * 0.22, cy + ry * 0.3, rx * 0.8, ry * 0.7, Sprites._sh(ROCK, 0.76))
	Sprites._ellipse(img, cx - rx * 0.3, cy - ry * 0.35, rx * 0.45, ry * 0.4, Sprites._lt(ROCK, 0.3))


static func _rock_img(v: int) -> Image:
	var img: Image
	match v:
		0: # głaz
			img = Sprites._new(24, 20)
			_stone(img, 12, 10, 10, 7.5)
			for p in [Vector2i(13, 6), Vector2i(14, 7), Vector2i(14, 8), Vector2i(15, 9)]:
				Sprites._p(img, p.x, p.y, Sprites._sh(ROCK, 0.55)) # pęknięcie
			for p in [Vector2i(9, 3), Vector2i(10, 3), Vector2i(15, 4)]:
				Sprites._p(img, p.x, p.y, Color(0.32, 0.47, 0.25)) # mech
			Sprites._outline(img)
			Sprites._shadow(img, 14, 17, 10, 2.5)
		1: # grupa kamieni
			img = Sprites._new(24, 16)
			_stone(img, 7, 9, 5, 4)
			_stone(img, 15, 8, 6, 5)
			_stone(img, 20, 11, 3, 2.5)
			Sprites._outline(img)
			Sprites._shadow(img, 14, 13.5, 10, 2)
		_: # płaska skała
			img = Sprites._new(24, 14)
			_stone(img, 12, 7, 10, 4.5)
			Sprites._ellipse(img, 11, 5.5, 7, 2, Sprites._lt(ROCK, 0.15))
			Sprites._outline(img)
			Sprites._shadow(img, 13, 11.5, 10, 2)
	return img


static func hill(zone: int) -> Texture2D:
	return Sprites._tex("hill_%d" % zone, func(): return _hill_img(zone))


## Wzniesienie: trawiasty płaskowyż z klifem skalnym od strony gracza.
static func _hill_img(zone: int) -> Image:
	var img := Sprites._new(60, 46)
	var pal: Array = GRASS[zone]
	var g: Color = Sprites._lt(pal[0], 0.08)
	var rock_c := Color(0.52, 0.43, 0.33)
	for x in 60:
		var dx := (x + 0.5 - 30.0) / 27.0
		if absf(dx) >= 1.0:
			continue
		var s := sqrt(1.0 - dx * dx)
		var y_top := int(18.0 + 12.0 * s) - 1
		var y_bot := int(y_top + 9 + 3 * s)
		for y in range(y_top, y_bot):
			var c := Sprites._sh(rock_c, 1.05 - 0.3 * (dx + 1.0) / 2.0)
			if (y - y_top) % 4 == 0:
				c = Sprites._sh(c, 0.82) # warstwy skalne
			if (x * 7 + y * 3) % 13 == 0:
				c = Sprites._sh(c, 0.65) # pęknięcia
			Sprites._p(img, x, y, c)
	Sprites._ellipse(img, 30, 18, 27, 13, Sprites._sh(g, 0.8))
	Sprites._ellipse(img, 29.5, 17, 26, 12, g)
	Sprites._ellipse(img, 25, 13, 16, 7, Sprites._lt(g, 0.1))
	Sprites._ellipse(img, 21, 10, 7, 3, Sprites._lt(g, 0.2))
	for p in [Vector2i(15, 18), Vector2i(36, 12), Vector2i(42, 20), Vector2i(26, 23), Vector2i(31, 8)]:
		Sprites._p(img, p.x, p.y, pal[1])
		Sprites._p(img, p.x - 1, p.y - 1, pal[1])
	_stone(img, 39, 15, 3, 2)
	Sprites._outline(img)
	Sprites._shadow(img, 34, 40, 27, 5, 0.3)
	return img
