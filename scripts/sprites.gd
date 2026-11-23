class_name Sprites
extends RefCounted
## Generator pixel artu: postacie, przedmioty, efekty (teren i roślinność: terrain.gd).
## Wszystko jest rysowane kodem do obrazów i zamieniane na tekstury (z cache'em).
## Światło pada z lewej-góry: lewe/górne krawędzie jaśniejsze, prawe/dolne ciemniejsze.

const OUT := Color(0.06, 0.06, 0.09)

const PAL := {
	"player": {
		"helmet": Color(0.2, 0.46, 0.22), "shirt": Color(0.42, 0.66, 0.3), "pants": Color(0.27, 0.42, 0.24),
		"skin": Color(0.96, 0.76, 0.56), "gun": Color(0.24, 0.24, 0.27), "band": Color(0.92, 0.2, 0.15),
	},
	"grunt": {
		"helmet": Color(0.43, 0.47, 0.6), "shirt": Color(0.38, 0.44, 0.66), "pants": Color(0.27, 0.3, 0.44),
		"skin": Color(0.9, 0.7, 0.5), "gun": Color(0.2, 0.2, 0.22),
	},
	"grenadier": {
		"helmet": Color(0.55, 0.2, 0.18), "shirt": Color(0.78, 0.32, 0.24), "pants": Color(0.32, 0.3, 0.34),
		"skin": Color(0.9, 0.7, 0.5), "gun": Color(0.2, 0.2, 0.22),
	},
	"sniper": {
		"helmet": Color(0.17, 0.19, 0.23), "shirt": Color(0.25, 0.28, 0.33), "pants": Color(0.16, 0.17, 0.21),
		"skin": Color(0.85, 0.65, 0.5), "gun": Color(0.5, 0.5, 0.56),
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
			if (i - cx) * (i - cx) + (j - cy) * (j - cy) <= r * r + r:
				_p(img, i, j, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for j in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for i in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (i + 0.5 - cx) / rx
			var dy := (j + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				_p(img, i, j, c)


## Cień na ziemi: rysowany tylko w pustych pikselach (pod obiektem).
static func _shadow(img: Image, cx: float, cy: float, rx: float, ry: float, alpha := 0.3) -> void:
	for j in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for i in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (i + 0.5 - cx) / rx
			var dy := (j + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0 and i >= 0 and j >= 0 and i < img.get_width() and j < img.get_height():
				if img.get_pixel(i, j).a < 0.05:
					img.set_pixel(i, j, Color(0, 0, 0, alpha))


static func _sh(c: Color, f: float) -> Color:
	return Color(c.r * f, c.g * f, c.b * f, c.a)


static func _lt(c: Color, f: float) -> Color:
	return Color(lerpf(c.r, 1.0, f), lerpf(c.g, 1.0, f), lerpf(c.b, 1.0, f), c.a)


## Kontur selektywny: obrys w kolorze przyciemnionego sąsiada (bardziej miękki niż czarny).
static func _outline(img: Image) -> void:
	var src := Image.new()
	src.copy_from(img)
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.5:
				continue
			for o in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + o.x
				var ny: int = y + o.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h:
					var n := src.get_pixel(nx, ny)
					if n.a > 0.5:
						img.set_pixel(x, y, Color(n.r * 0.25 + 0.02, n.g * 0.25 + 0.02, n.b * 0.25 + 0.04, 1.0))
						break


static func _tex(key: String, builder: Callable) -> Texture2D:
	if not _cache.has(key):
		_cache[key] = ImageTexture.create_from_image(builder.call())
	return _cache[key]


# ---------------------------------------------------------------- żołnierze (20x24)

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


## Cień pod postacią (osobny sprite, rysowany pod nią).
static func add_shadow(parent: Node2D, w: float = 14.0, y: float = 7.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = shadow(int(w), maxi(4, int(w / 3.0)))
	s.position = Vector2(0, y)
	parent.add_child(s)
	return s


static func shadow(w: int, h: int) -> Texture2D:
	return _tex("shadow_%d_%d" % [w, h], func():
		var img := _new(w, h)
		_ellipse(img, w / 2.0, h / 2.0, w / 2.0, h / 2.0, Color(0, 0, 0, 0.32))
		return img)


static func _leg(img: Image, x: int, y: int, h: int, pants: Color, boot: Color) -> void:
	_r(img, x, y, 3, h, pants)
	_r(img, x, y, 1, h, _lt(pants, 0.12))
	_r(img, x, y + h - 2, 3, 2, boot)
	_p(img, x, y + h - 2, _lt(boot, 0.15))


static func _soldier_img(kind: String, dir: String, frame: int) -> Image:
	var pal: Dictionary = PAL[kind]
	var helmet: Color = pal["helmet"]
	var shirt: Color = pal["shirt"]
	var pants: Color = pal["pants"]
	var skin: Color = pal["skin"]
	var gun: Color = pal["gun"]
	var boot := Color(0.22, 0.15, 0.1)
	var belt := Color(0.3, 0.22, 0.12)
	var buckle := Color(0.92, 0.82, 0.42)
	var img := _new(20, 24)
	var lh := 4 if frame == 1 else 5
	var rh := 4 if frame == 2 else 5

	match dir:
		"down":
			_leg(img, 6, 18, lh, pants, boot)
			_leg(img, 11, 18, rh, pants, boot)
			_r(img, 5, 11, 10, 7, shirt)
			_r(img, 5, 11, 2, 7, _lt(shirt, 0.15))
			_r(img, 13, 11, 2, 7, _sh(shirt, 0.8))
			_r(img, 7, 12, 2, 2, _sh(shirt, 0.82)) # kieszenie
			_r(img, 11, 12, 2, 2, _sh(shirt, 0.82))
			_r(img, 5, 16, 10, 1, belt)
			_r(img, 9, 16, 2, 1, buckle)
			_r(img, 3, 11, 2, 5, _sh(shirt, 0.88))
			_r(img, 3, 16, 2, 1, skin)
			_r(img, 15, 11, 2, 3, _sh(shirt, 0.75))
			_r(img, 15, 13, 2, 9, gun)
			_r(img, 15, 13, 1, 9, _lt(gun, 0.3))
			_r(img, 15, 14, 2, 1, skin)
			_r(img, 6, 6, 8, 5, skin)
			_r(img, 12, 6, 2, 5, _sh(skin, 0.86))
			_r(img, 7, 10, 6, 1, _sh(skin, 0.85))
			_p(img, 8, 8, OUT)
			_p(img, 11, 8, OUT)
			_r(img, 6, 1, 8, 1, helmet)
			_r(img, 5, 2, 10, 3, helmet)
			_r(img, 4, 5, 12, 1, _sh(helmet, 0.72))
			_r(img, 7, 2, 3, 1, _lt(helmet, 0.35))
			_p(img, 6, 3, _lt(helmet, 0.2))
			_r(img, 12, 3, 3, 2, _sh(helmet, 0.85))
			if pal.has("band"):
				_r(img, 5, 5, 10, 1, pal["band"])
		"up":
			_leg(img, 6, 18, lh, pants, boot)
			_leg(img, 11, 18, rh, pants, boot)
			_r(img, 5, 10, 10, 8, shirt)
			_r(img, 5, 10, 1, 8, _lt(shirt, 0.15))
			_r(img, 6, 11, 8, 5, _sh(shirt, 0.66)) # plecak
			_r(img, 6, 11, 8, 1, _sh(shirt, 0.5))
			_r(img, 7, 13, 6, 1, _sh(shirt, 0.55))
			_r(img, 5, 17, 10, 1, belt)
			_r(img, 3, 11, 2, 5, _sh(shirt, 0.88))
			_r(img, 15, 11, 2, 5, _sh(shirt, 0.75))
			_r(img, 15, 1, 2, 12, gun)
			_r(img, 15, 1, 1, 12, _lt(gun, 0.3))
			_r(img, 15, 11, 2, 1, skin)
			_r(img, 7, 8, 6, 2, _sh(skin, 0.85))
			_r(img, 6, 1, 8, 1, helmet)
			_r(img, 5, 2, 10, 5, helmet)
			_r(img, 4, 7, 12, 1, _sh(helmet, 0.72))
			_r(img, 7, 2, 3, 2, _lt(helmet, 0.3))
			_r(img, 12, 4, 3, 3, _sh(helmet, 0.85))
			if pal.has("band"):
				_r(img, 5, 6, 10, 1, pal["band"])
		_:
			match frame:
				0:
					_r(img, 8, 18, 5, 5, pants)
					_r(img, 8, 18, 1, 5, _lt(pants, 0.12))
					_r(img, 8, 21, 6, 2, boot)
				1:
					_leg(img, 6, 18, 5, _sh(pants, 0.85), boot)
					_leg(img, 11, 18, 4, pants, boot)
				_:
					_leg(img, 7, 18, 4, _sh(pants, 0.85), boot)
					_leg(img, 10, 18, 5, pants, boot)
			_r(img, 7, 11, 6, 7, shirt)
			_r(img, 7, 11, 6, 1, _lt(shirt, 0.18))
			_r(img, 5, 11, 2, 6, _sh(shirt, 0.6)) # plecak
			_r(img, 7, 16, 6, 1, belt)
			_r(img, 10, 12, 3, 3, _sh(shirt, 0.8))
			_r(img, 7, 14, 3, 2, _sh(gun, 0.85)) # kolba
			_r(img, 9, 13, 10, 2, gun)
			_r(img, 9, 13, 10, 1, _lt(gun, 0.3))
			_r(img, 12, 13, 2, 2, skin)
			_r(img, 9, 6, 5, 5, skin)
			_r(img, 9, 10, 4, 1, _sh(skin, 0.85))
			_r(img, 7, 6, 2, 4, Color(0.3, 0.2, 0.12))
			_p(img, 12, 8, OUT)
			_r(img, 7, 1, 7, 1, helmet)
			_r(img, 6, 2, 9, 3, helmet)
			_r(img, 6, 5, 10, 1, _sh(helmet, 0.72))
			_r(img, 8, 2, 3, 1, _lt(helmet, 0.35))
			if pal.has("band"):
				_r(img, 6, 5, 9, 1, pal["band"])
	_outline(img)
	return img


static func biker(frame: int) -> Texture2D:
	return _tex("biker_%d" % frame, func(): return _biker_img(frame))


static func _biker_img(frame: int) -> Image:
	var img := _new(20, 24)
	var tire := Color(0.12, 0.12, 0.14)
	var chrome := Color(0.75, 0.76, 0.8)
	var jacket := Color(0.78, 0.3, 0.24)
	var skin := Color(0.9, 0.7, 0.5)
	_r(img, 8, 0, 4, 6, tire)
	_r(img, 8, 18, 4, 6, tire)
	for y in [1, 3, 19, 21]:
		_r(img, 8, y + frame, 4, 1, Color(0.25, 0.25, 0.28)) # bieżnik (animowany)
	_r(img, 9, 5, 2, 14, Color(0.5, 0.5, 0.55))
	_r(img, 7, 13, 6, 4, Color(0.25, 0.3, 0.5))      # bak
	_r(img, 7, 13, 2, 3, Color(0.4, 0.46, 0.7))
	_r(img, 3, 17, 14, 1, chrome)                     # kierownica
	_p(img, 9, 23, Color(1, 0.95, 0.6))               # reflektor
	_r(img, 5, 6, 10, 7, jacket)
	_r(img, 5, 6, 2, 7, _lt(jacket, 0.15))
	_r(img, 13, 6, 2, 7, _sh(jacket, 0.8))
	_r(img, 4, 10, 2, 7, _sh(jacket, 0.85))
	_r(img, 14, 10, 2, 7, _sh(jacket, 0.75))
	_r(img, 4, 16, 2, 2, skin)
	_r(img, 14, 16, 2, 2, skin)
	_r(img, 7, 2, 6, 5, Color(0.18, 0.18, 0.22))      # kask
	_r(img, 8, 2, 2, 2, Color(0.45, 0.45, 0.52))
	_r(img, 7, 6, 6, 1, Color(0.4, 0.6, 0.8))         # gogle
	_outline(img)
	return img


static func prisoner(frame: int) -> Texture2D:
	return _tex("pow_%d" % frame, func(): return _prisoner_img(frame))


static func _prisoner_img(frame: int) -> Image:
	var img := _new(20, 24)
	var skin := Color(0.94, 0.74, 0.54)
	var cloth := Color(0.82, 0.76, 0.56)
	var wood := Color(0.45, 0.31, 0.17)
	_r(img, 9, 1, 2, 22, wood)                          # pal
	_r(img, 9, 1, 1, 22, _lt(wood, 0.2))
	_r(img, 7, 18, 2, 5, Color(0.38, 0.32, 0.22))
	_r(img, 11, 18, 2, 5, Color(0.38, 0.32, 0.22))
	_r(img, 6, 11, 8, 7, cloth)
	_r(img, 6, 11, 2, 7, _lt(cloth, 0.2))
	_r(img, 12, 11, 2, 7, _sh(cloth, 0.8))
	_r(img, 8, 13, 2, 2, _sh(cloth, 0.7))              # rozdarcie
	_r(img, 6, 15, 8, 1, Color(0.6, 0.45, 0.25))        # lina
	_r(img, 7, 5, 6, 6, skin)
	_r(img, 11, 5, 2, 6, _sh(skin, 0.86))
	_r(img, 7, 4, 6, 2, Color(0.32, 0.2, 0.1))         # włosy
	_p(img, 8, 7, OUT)
	_p(img, 11, 7, OUT)
	_r(img, 9, 9, 2, 1, Color(0.6, 0.3, 0.25))
	if frame == 0:
		_r(img, 3, 3, 2, 9, skin)
		_r(img, 14, 10, 3, 2, skin)
	else:
		_r(img, 15, 3, 2, 9, skin)
		_r(img, 3, 10, 3, 2, skin)
	_outline(img)
	_shadow(img, 10, 22.5, 7, 1.8)
	return img


static func bunker() -> Texture2D:
	return _tex("bunker", _bunker_img)


static func _bunker_img() -> Image:
	var img := _new(36, 26)
	var conc := Color(0.6, 0.59, 0.53)
	_r(img, 4, 3, 28, 14, conc)                         # betonowy schron
	_r(img, 4, 3, 28, 2, _lt(conc, 0.25))
	_r(img, 4, 3, 2, 14, _lt(conc, 0.12))
	_r(img, 30, 3, 2, 14, _sh(conc, 0.78))
	for p in [Vector2i(9, 7), Vector2i(22, 6), Vector2i(26, 12), Vector2i(7, 13)]:
		_p(img, p.x, p.y, _sh(conc, 0.7))               # rysy
	_r(img, 9, 9, 18, 4, Color(0.07, 0.07, 0.09))      # strzelnica
	_r(img, 9, 9, 18, 1, Color(0.2, 0.2, 0.22))
	_r(img, 15, 8, 6, 3, Color(0.43, 0.47, 0.6))       # hełm strzelca
	_r(img, 17, 11, 2, 8, Color(0.22, 0.22, 0.25))     # lufa
	var bag := Color(0.72, 0.62, 0.4)
	for row in 2:
		var y := 16 + row * 4
		var off := (row % 2) * 3
		for x in range(1 + off, 34, 6):
			_r(img, x, y, 5, 4, bag)
			_r(img, x, y, 5, 1, _lt(bag, 0.25))
			_r(img, x, y + 3, 5, 1, _sh(bag, 0.7))
			_p(img, x + 4, y + 1, _sh(bag, 0.8))
	_outline(img)
	_shadow(img, 20, 22, 17, 4)
	return img


static func crate() -> Texture2D:
	return _tex("crate", _crate_img)


static func _crate_img() -> Image:
	var img := _new(18, 16)
	var wood := Color(0.56, 0.38, 0.18)
	_r(img, 1, 2, 16, 12, wood)
	_r(img, 1, 2, 16, 1, _lt(wood, 0.3))
	_r(img, 1, 2, 1, 12, _lt(wood, 0.15))
	_r(img, 1, 13, 16, 1, _sh(wood, 0.6))
	_r(img, 1, 7, 16, 1, _sh(wood, 0.65))
	_r(img, 16, 2, 1, 12, _sh(wood, 0.7))
	_disc(img, 9, 8, 3, Color(0.22, 0.5, 0.22))
	_r(img, 8, 4, 2, 2, Color(0.78, 0.78, 0.78))
	_p(img, 8, 7, Color(0.45, 0.75, 0.4))
	_outline(img)
	_shadow(img, 10, 15, 8, 1.5)
	return img


static func medkit() -> Texture2D:
	return _tex("medkit", _medkit_img)


static func _medkit_img() -> Image:
	# biała torba 16x13 z wyraźnym, smukłym czerwonym krzyżem i szarą rączką
	var img := _new(18, 18)
	var body := Color(0.97, 0.97, 0.95)
	_r(img, 4, 0, 10, 1, Color(0.45, 0.45, 0.48)) # rączka
	_r(img, 4, 1, 1, 2, Color(0.45, 0.45, 0.48))
	_r(img, 13, 1, 1, 2, Color(0.45, 0.45, 0.48))
	_r(img, 1, 3, 16, 12, body)
	_r(img, 1, 3, 16, 1, Color.WHITE)               # światło u góry
	_r(img, 1, 14, 16, 1, Color(0.68, 0.68, 0.72))  # cień u dołu
	_r(img, 16, 3, 1, 12, Color(0.8, 0.8, 0.83))
	# krzyż: ciemnoczerwona obwódka, a w środku jasna czerwień
	var dark := Color(0.55, 0.02, 0.04)
	var red := Color(1.0, 0.12, 0.12)
	_r(img, 7, 4, 4, 10, dark)
	_r(img, 4, 7, 10, 4, dark)
	_r(img, 8, 5, 2, 8, red)
	_r(img, 5, 8, 8, 2, red)
	_p(img, 8, 5, Color(1.0, 0.55, 0.5)) # błysk
	_outline(img)
	_shadow(img, 9, 16, 8, 1.5)
	return img


static func speaker(on: bool) -> Texture2D:
	return _tex("speaker_%s" % on, func(): return _speaker_img(on))


static func _speaker_img(on: bool) -> Image:
	var img := _new(14, 14)
	var w := Color(0.95, 0.95, 0.95)
	_r(img, 2, 5, 3, 4, w)
	_r(img, 5, 4, 1, 6, w)
	_r(img, 6, 3, 1, 8, w)
	_r(img, 7, 2, 1, 10, w)
	if on:
		_r(img, 9, 5, 1, 4, w)
		_r(img, 11, 3, 1, 8, w)
	else:
		for i in 4:
			_p(img, 9 + i, 5 + i, Color(1.0, 0.3, 0.25))
			_p(img, 12 - i, 5 + i, Color(1.0, 0.3, 0.25))
	_outline(img)
	return img


# ---------------------------------------------------------------- efekty

static func explosion(frame: int) -> Texture2D:
	return _tex("boom_%d" % frame, func(): return _explosion_img(frame))


static func _explosion_img(frame: int) -> Image:
	var img := _new(32, 32)
	var radii := [7.0, 12.0, 15.0, 14.0]
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
			if frame == 3:
				c = Color(0.42, 0.38, 0.36, 0.85) if q > 0.45 else Color(1, 0.6, 0.15)
			elif q < 0.35:
				c = Color(1, 0.98, 0.78)
			elif q < 0.65:
				c = Color(1, 0.68, 0.15)
			else:
				c = Color(0.88, 0.25, 0.1)
			img.set_pixel(x, y, c)
	return img


## Ślad po wybuchu na ziemi.
static func scorch() -> Texture2D:
	return _tex("scorch", func():
		var img := _new(30, 16)
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for y in 16:
			for x in 30:
				var dx := (x - 14.5) / 14.0
				var dy := (y - 7.5) / 7.0
				var d := dx * dx + dy * dy + rng.randf_range(-0.15, 0.15)
				if d < 1.0:
					img.set_pixel(x, y, Color(0.08, 0.06, 0.04, 0.55 * (1.0 - d * 0.7)))
		return img)


# ---------------------------------------------------------------- boss

static func boss() -> Texture2D:
	return _tex("boss", _boss_img)


static func _boss_img() -> Image:
	var img := _new(64, 44)
	var steel := Color(0.5, 0.53, 0.5)
	var dark := Color(0.27, 0.29, 0.28)
	var light := Color(0.7, 0.73, 0.7)
	var red := Color(0.95, 0.22, 0.15)
	_r(img, 2, 4, 12, 32, dark)
	_r(img, 50, 4, 12, 32, dark)
	for y in range(5, 36, 4):
		_r(img, 3, y, 10, 1, Color(0.14, 0.14, 0.17))
		_r(img, 51, y, 10, 1, Color(0.14, 0.14, 0.17))
	_r(img, 12, 6, 40, 28, steel)
	_r(img, 12, 6, 40, 3, light)
	_r(img, 12, 6, 2, 28, _lt(steel, 0.15))
	_r(img, 12, 31, 40, 3, dark)
	_r(img, 49, 6, 3, 28, _sh(steel, 0.8))
	for x in [16, 26, 38, 47]:
		_p(img, x, 12, dark)
		_p(img, x, 28, dark)
	_r(img, 20, 12, 24, 16, light)
	_r(img, 22, 14, 20, 12, steel)
	_disc(img, 32, 20, 5, dark)
	_disc(img, 32, 20, 3, steel)
	_p(img, 31, 18, light)
	_r(img, 22, 28, 5, 9, dark)
	_r(img, 37, 28, 5, 9, dark)
	_r(img, 22, 28, 1, 9, steel)
	_r(img, 37, 28, 1, 9, steel)
	_r(img, 21, 36, 7, 3, Color(0.12, 0.12, 0.15))
	_r(img, 36, 36, 7, 3, Color(0.12, 0.12, 0.15))
	_r(img, 14, 8, 3, 2, red)
	_r(img, 47, 8, 3, 2, red)
	_outline(img)
	_shadow(img, 34, 38, 30, 5, 0.35)
	return img
