class_name Sprites
extends RefCounted
## Generator pixel artu: wszystkie sprite'y i kafelki są rysowane kodem
## do obrazów, a potem zamieniane na tekstury (z cache'em).

const OUT := Color(0.07, 0.07, 0.1)

const PAL := {
	"player": {
		"helmet": Color(0.18, 0.45, 0.2), "shirt": Color(0.5, 0.75, 0.3), "pants": Color(0.25, 0.45, 0.25),
		"skin": Color(0.95, 0.75, 0.55), "gun": Color(0.25, 0.25, 0.28), "band": Color(0.9, 0.2, 0.15),
	},
	"grunt": {
		"helmet": Color(0.45, 0.48, 0.62), "shirt": Color(0.4, 0.45, 0.68), "pants": Color(0.28, 0.3, 0.45),
		"skin": Color(0.9, 0.7, 0.5), "gun": Color(0.2, 0.2, 0.22),
	},
	"grenadier": {
		"helmet": Color(0.55, 0.2, 0.2), "shirt": Color(0.78, 0.3, 0.25), "pants": Color(0.3, 0.3, 0.35),
		"skin": Color(0.9, 0.7, 0.5), "gun": Color(0.2, 0.2, 0.22),
	},
	"sniper": {
		"helmet": Color(0.15, 0.16, 0.2), "shirt": Color(0.22, 0.24, 0.3), "pants": Color(0.15, 0.15, 0.2),
		"skin": Color(0.85, 0.65, 0.5), "gun": Color(0.5, 0.5, 0.55),
	},
}

static var _cache := {}


# ---------------------------------------------------------------- pomocnicze

static func _new(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			_p(img, i, j, c)


static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for j in range(cy - r, cy + r + 1):
		for i in range(cx - r, cx + r + 1):
			if (i - cx) * (i - cx) + (j - cy) * (j - cy) <= r * r:
				_p(img, i, j, c)


static func _sh(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)


static func _outline(img: Image, c: Color = OUT) -> void:
	var src := Image.new()
	src.copy_from(img)
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.5:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + o.x
				var ny: int = y + o.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and src.get_pixel(nx, ny).a > 0.5:
					img.set_pixel(x, y, c)
					break


static func _tex(key: String, builder: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(builder.call())
	return _cache[key]


# ---------------------------------------------------------------- żołnierze

static func soldier(kind: String, dir: String, frame: int) -> Texture2D:
	return _tex("s_%s_%s_%d" % [kind, dir, frame], func(): return _soldier_img(kind, dir, frame))


## Ustawia sprite żołnierza zależnie od kierunku patrzenia i animacji marszu.
static func set_soldier(sprite: Sprite2D, kind: String, face: Vector2, walk_t: float, moving: bool) -> void:
	var dir := "side"
	if absf(face.x) <= 0.5:
		dir = "down" if face.y > 0.0 else "up"
	var frame := 0
	if moving:
		frame = [1, 0, 2, 0][int(walk_t * 8.0) % 4]
	sprite.texture = soldier(kind, dir, frame)
	sprite.flip_h = dir == "side" and face.x < 0.0


static func _soldier_img(kind: String, dir: String, frame: int) -> Image:
	var pal: Dictionary = PAL[kind]
	var helmet: Color = pal["helmet"]
	var shirt: Color = pal["shirt"]
	var pants: Color = pal["pants"]
	var skin: Color = pal["skin"]
	var gun: Color = pal["gun"]
	var boot := Color(0.2, 0.14, 0.1)
	var img := _new(16, 16)
	var lh := 2 if frame == 1 else 3
	var rh := 2 if frame == 2 else 3

	match dir:
		"down":
			_r(img, 5, 2, 6, 3, helmet)
			_r(img, 4, 4, 8, 1, helmet)
			_r(img, 5, 5, 6, 3, skin)
			_p(img, 6, 6, OUT)
			_p(img, 9, 6, OUT)
			if pal.has("band"):
				_r(img, 5, 4, 6, 1, pal["band"])
			_r(img, 4, 8, 8, 4, shirt)
			_r(img, 3, 8, 1, 4, _sh(shirt, 0.8))
			_r(img, 12, 8, 1, 3, _sh(shirt, 0.8))
			_r(img, 12, 9, 2, 6, gun)
			_r(img, 5, 12, 3, lh, pants)
			_r(img, 8, 12, 3, rh, pants)
			_r(img, 5, 12 + lh - 1, 3, 1, boot)
			_r(img, 8, 12 + rh - 1, 3, 1, boot)
		"up":
			_r(img, 5, 2, 6, 5, helmet)
			_r(img, 4, 4, 8, 1, helmet)
			if pal.has("band"):
				_r(img, 5, 5, 6, 1, pal["band"])
			_r(img, 4, 7, 8, 5, shirt)
			_r(img, 5, 8, 6, 3, _sh(shirt, 0.7))
			_r(img, 3, 8, 1, 3, _sh(shirt, 0.8))
			_r(img, 12, 2, 2, 8, gun)
			_r(img, 5, 12, 3, lh, pants)
			_r(img, 8, 12, 3, rh, pants)
			_r(img, 5, 12 + lh - 1, 3, 1, boot)
			_r(img, 8, 12 + rh - 1, 3, 1, boot)
		_:
			_r(img, 5, 2, 6, 3, helmet)
			_r(img, 5, 4, 7, 1, helmet)
			_r(img, 7, 5, 4, 3, skin)
			_p(img, 9, 6, OUT)
			if pal.has("band"):
				_r(img, 6, 4, 5, 1, pal["band"])
			_r(img, 5, 8, 5, 4, shirt)
			_r(img, 4, 8, 1, 3, _sh(shirt, 0.7))
			_r(img, 7, 8, 3, 3, _sh(shirt, 0.85))
			_r(img, 8, 9, 7, 2, gun)
			_p(img, 9, 9, skin)
			match frame:
				0:
					_r(img, 5, 12, 5, 3, pants)
					_r(img, 5, 14, 5, 1, boot)
				1:
					_r(img, 4, 12, 3, 3, pants)
					_r(img, 8, 12, 3, 2, pants)
					_r(img, 4, 14, 3, 1, boot)
					_r(img, 8, 13, 3, 1, boot)
				_:
					_r(img, 3, 12, 3, 2, pants)
					_r(img, 7, 12, 3, 3, pants)
					_r(img, 3, 13, 3, 1, boot)
					_r(img, 7, 14, 3, 1, boot)
	_outline(img)
	return img


static func biker(frame: int) -> Texture2D:
	return _tex("biker_%d" % frame, func(): return _biker_img(frame))


static func _biker_img(frame: int) -> Image:
	var img := _new(16, 16)
	var dark := Color(0.12, 0.12, 0.14)
	_r(img, 6, 1, 4, 3, dark)
	_r(img, 6, 12, 4, 3, dark)
	_r(img, 7, 3, 2, 10, Color(0.5, 0.5, 0.55))
	_r(img, 4, 3 + frame, 8, 1, Color(0.7, 0.7, 0.75)) # kierownica
	_r(img, 5, 5, 6, 5, Color(0.78, 0.3, 0.25))
	_r(img, 6, 3, 4, 3, Color(0.2, 0.2, 0.25))
	_r(img, 7, 5, 2, 1, Color(0.9, 0.7, 0.5))
	_r(img, 4, 6, 1, 3, Color(0.9, 0.7, 0.5))
	_r(img, 11, 6, 1, 3, Color(0.9, 0.7, 0.5))
	_outline(img)
	return img


# ---------------------------------------------------------------- otoczenie

static func tree() -> Texture2D:
	return _tex("tree", _tree_img)


static func _tree_img() -> Image:
	var img := _new(20, 24)
	_r(img, 9, 16, 3, 6, Color(0.4, 0.26, 0.12))
	_disc(img, 10, 9, 8, Color(0.1, 0.36, 0.14))
	_disc(img, 8, 7, 5, Color(0.17, 0.5, 0.2))
	_disc(img, 7, 6, 2, Color(0.3, 0.65, 0.3))
	_disc(img, 13, 12, 3, Color(0.08, 0.3, 0.12))
	_outline(img)
	return img


static func rock() -> Texture2D:
	return _tex("rock", _rock_img)


static func _rock_img() -> Image:
	var img := _new(16, 14)
	_disc(img, 8, 7, 6, Color(0.5, 0.5, 0.52))
	_disc(img, 6, 5, 3, Color(0.66, 0.66, 0.68))
	_r(img, 8, 10, 5, 2, Color(0.36, 0.36, 0.4))
	_outline(img)
	return img


static func bunker() -> Texture2D:
	return _tex("bunker", _bunker_img)


static func _bunker_img() -> Image:
	var img := _new(30, 20)
	var bag := Color(0.66, 0.55, 0.34)
	var line := Color(0.45, 0.36, 0.2)
	_r(img, 1, 3, 28, 15, bag)
	for row in 5:
		var y := 4 + row * 3
		_r(img, 1, y + 2, 28, 1, line)
		for x in range((row % 2) * 3 + 1, 28, 6):
			_r(img, x, y, 1, 3, line)
	_r(img, 12, 1, 6, 4, Color(0.45, 0.48, 0.62))
	_r(img, 13, 4, 4, 2, Color(0.9, 0.7, 0.5))
	_r(img, 7, 7, 16, 3, Color(0.08, 0.08, 0.1))
	_r(img, 14, 8, 2, 6, Color(0.2, 0.2, 0.22))
	_outline(img)
	return img


static func prisoner(frame: int) -> Texture2D:
	return _tex("pow_%d" % frame, func(): return _prisoner_img(frame))


static func _prisoner_img(frame: int) -> Image:
	var img := _new(16, 16)
	var skin := Color(0.92, 0.72, 0.52)
	var cloth := Color(0.78, 0.72, 0.5)
	_r(img, 6, 3, 4, 4, skin)
	_r(img, 6, 2, 4, 2, Color(0.3, 0.2, 0.1))
	_r(img, 5, 7, 6, 5, cloth)
	_r(img, 5, 12, 2, 3, Color(0.35, 0.3, 0.2))
	_r(img, 9, 12, 2, 3, Color(0.35, 0.3, 0.2))
	if frame == 0:
		_r(img, 3, 2, 2, 6, skin)
		_r(img, 11, 7, 2, 2, skin)
	else:
		_r(img, 11, 2, 2, 6, skin)
		_r(img, 3, 7, 2, 2, skin)
	_r(img, 5, 9, 6, 1, Color(0.55, 0.4, 0.25)) # lina
	_outline(img)
	return img


static func crate() -> Texture2D:
	return _tex("crate", _crate_img)


static func _crate_img() -> Image:
	var img := _new(16, 14)
	var wood := Color(0.55, 0.38, 0.18)
	_r(img, 1, 1, 14, 12, wood)
	_r(img, 1, 1, 14, 1, Color(0.72, 0.52, 0.28))
	_r(img, 1, 12, 14, 1, Color(0.35, 0.22, 0.1))
	_r(img, 1, 6, 14, 1, Color(0.35, 0.22, 0.1))
	_disc(img, 8, 7, 3, Color(0.2, 0.5, 0.2))
	_r(img, 7, 3, 2, 2, Color(0.75, 0.75, 0.75))
	_outline(img)
	return img


static func medkit() -> Texture2D:
	return _tex("medkit", _medkit_img)


static func _medkit_img() -> Image:
	var img := _new(14, 12)
	_r(img, 1, 1, 12, 10, Color(0.95, 0.95, 0.95))
	_r(img, 1, 10, 12, 1, Color(0.7, 0.7, 0.72))
	_r(img, 5, 3, 4, 6, Color(0.9, 0.15, 0.15))
	_r(img, 3, 5, 8, 2, Color(0.9, 0.15, 0.15))
	_r(img, 5, 0, 4, 1, Color(0.6, 0.6, 0.62)) # rączka
	_outline(img)
	return img


static func explosion(frame: int) -> Texture2D:
	return _tex("boom_%d" % frame, func(): return _explosion_img(frame))


static func _explosion_img(frame: int) -> Image:
	var img := _new(32, 32)
	var radii := [7.0, 12.0, 15.0, 13.0]
	var r: float = radii[frame]
	var rng := RandomNumberGenerator.new()
	rng.seed = 50 + frame
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() + rng.randf_range(-2.0, 2.0)
			if d > r:
				continue
			var q := d / r
			var c: Color
			if frame == 3 and q > 0.5:
				c = Color(0.35, 0.3, 0.3)
			elif q < 0.35:
				c = Color(1, 0.97, 0.7)
			elif q < 0.65:
				c = Color(1, 0.65, 0.12)
			else:
				c = Color(0.85, 0.22, 0.1)
			img.set_pixel(x, y, c)
	return img


# ---------------------------------------------------------------- boss

static func boss() -> Texture2D:
	return _tex("boss", _boss_img)


static func _boss_img() -> Image:
	var img := _new(64, 40)
	var steel := Color(0.5, 0.52, 0.56)
	var dark := Color(0.26, 0.27, 0.31)
	var light := Color(0.7, 0.72, 0.76)
	var red := Color(0.9, 0.2, 0.15)
	_r(img, 2, 4, 12, 32, dark)
	_r(img, 50, 4, 12, 32, dark)
	for y in range(5, 36, 4):
		_r(img, 3, y, 10, 1, Color(0.14, 0.14, 0.17))
		_r(img, 51, y, 10, 1, Color(0.14, 0.14, 0.17))
	_r(img, 12, 6, 40, 28, steel)
	_r(img, 12, 6, 40, 3, light)
	_r(img, 12, 31, 40, 3, dark)
	for x in [16, 26, 38, 48]:
		_p(img, x, 12, dark)
		_p(img, x, 28, dark)
	_r(img, 20, 12, 24, 16, light)
	_r(img, 22, 14, 20, 12, steel)
	_disc(img, 32, 20, 5, dark)
	_disc(img, 32, 20, 3, steel)
	_r(img, 22, 28, 5, 9, dark)
	_r(img, 37, 28, 5, 9, dark)
	_r(img, 21, 36, 7, 3, Color(0.12, 0.12, 0.15))
	_r(img, 36, 36, 7, 3, Color(0.12, 0.12, 0.15))
	_r(img, 14, 8, 3, 2, red)
	_r(img, 47, 8, 3, 2, red)
	_outline(img)
	return img


# ---------------------------------------------------------------- teren

static func path_center(ty: int) -> int:
	return 8 + int(round(2.0 * sin(float(ty) * 0.07)))


static func bridge_col(river_row: int) -> int:
	return clampi(path_center(river_row) - 1, 1, 12)


static func water(frame: int) -> Texture2D:
	return _tex("water_%d" % frame, func(): return _water_img(frame))


static func _water_img(frame: int) -> Image:
	var img := _new(16, 16)
	img.fill(Color(0.15, 0.38, 0.78))
	for y in [3, 9, 14]:
		_r(img, (y * 3 + frame * 5) % 12, y, 4, 1, Color(0.45, 0.65, 0.95))
	return img


static func _grass_img(v: int) -> Image:
	var img := _new(16, 16)
	img.fill(Color(0.2, 0.5, 0.2))
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + v
	for i in 7:
		var x := rng.randi_range(1, 13)
		var y := rng.randi_range(1, 14)
		_r(img, x, y, 2, 1, Color(0.14, 0.4, 0.15))
		_p(img, x + 1, y - 1, Color(0.14, 0.4, 0.15))
	for i in 3:
		_p(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Color(0.3, 0.62, 0.28))
	if v == 2:
		_p(img, 8, 8, Color(0.95, 0.9, 0.4))
	return img


static func _path_img(edge: int) -> Image:
	var img := _new(16, 16)
	img.fill(Color(0.68, 0.57, 0.38))
	var rng := RandomNumberGenerator.new()
	rng.seed = 200 + edge
	for i in 8:
		_p(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Color(0.57, 0.47, 0.3))
	if edge == 1:
		_r(img, 0, 0, 2, 16, Color(0.5, 0.42, 0.27))
	elif edge == 2:
		_r(img, 14, 0, 2, 16, Color(0.5, 0.42, 0.27))
	return img


static func _sand_img() -> Image:
	var img := _new(16, 16)
	img.fill(Color(0.86, 0.78, 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 300
	for i in 8:
		_p(img, rng.randi_range(0, 15), rng.randi_range(0, 15), Color(0.75, 0.67, 0.4))
	return img


static func _bridge_img() -> Image:
	var img := _new(16, 16)
	img.fill(Color(0.58, 0.4, 0.2))
	for y in [0, 4, 8, 12]:
		_r(img, 0, y, 16, 1, Color(0.38, 0.25, 0.12))
	_r(img, 0, 0, 2, 16, Color(0.3, 0.2, 0.1))
	_r(img, 14, 0, 2, 16, Color(0.3, 0.2, 0.1))
	return img


static func _stone_img(wall: bool) -> Image:
	var img := _new(16, 16)
	var base := Color(0.33, 0.33, 0.38) if wall else Color(0.52, 0.52, 0.56)
	var line := _sh(base, 0.7)
	img.fill(base)
	for row in 2:
		_r(img, 0, row * 8, 16, 1, line)
		_r(img, (row % 2) * 8, row * 8, 1, 8, line)
	return img


## Buduje całe tło poziomu jako jedną dużą teksturę (kafelki 16x16).
static func level_background(cols: int, rows: int, rivers: Array, boss_rows: int) -> Texture2D:
	var img := _new(cols * 16, rows * 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var grass := [_grass_img(0), _grass_img(0), _grass_img(1), _grass_img(2)]
	var path := [_path_img(0), _path_img(1), _path_img(2)]
	var sand := _sand_img()
	var bridge := _bridge_img()
	var wtile := _water_img(0)
	var stone := _stone_img(false)
	var wall := _stone_img(true)
	for ty in rows:
		var c := path_center(ty)
		var rr := -1
		var bc := 0
		for r in rivers:
			if ty >= r and ty <= r + 3:
				rr = ty - r
				bc = bridge_col(r)
		for tx in cols:
			var tile: Image
			if ty < boss_rows:
				tile = wall if ty < 3 else stone
			elif rr == 0 or rr == 3:
				tile = sand
			elif rr == 1 or rr == 2:
				tile = bridge if (tx >= bc and tx <= bc + 2) else wtile
			elif tx >= c - 2 and tx <= c + 1:
				tile = path[1] if tx == c - 2 else (path[2] if tx == c + 1 else path[0])
			else:
				tile = grass[rng.randi() % grass.size()]
			img.blit_rect(tile, Rect2i(0, 0, 16, 16), Vector2i(tx * 16, ty * 16))
	return ImageTexture.create_from_image(img)
