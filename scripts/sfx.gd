class_name Sfx
extends Node
## Proceduralne efekty dźwiękowe i muzyka (chiptune) — bez plików audio.

const RATE := 22050
const SETTINGS_PATH := "user://settings.cfg"
const SOUND_NAMES := ["shoot", "enemy_shoot", "throw", "explosion", "die", "hit",
	"boss_hit", "pickup", "rescue", "gameover", "win", "shout_help", "shout_hey"]

static var inst: Sfx
static var sounds := {}
static var music_stream: AudioStreamWAV
static var music_on := true
static var settings_loaded := false

var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music: AudioStreamPlayer
var ended := false # muzyka zatrzymana na koniec gry — nie wznawiaj jej przełącznikiem


func _ready() -> void:
	inst = self
	if not settings_loaded:
		settings_loaded = true
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			music_on = bool(cfg.get_value("audio", "music", true))
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		players.append(p)
	if sounds.is_empty():
		_load_or_build()
	music = AudioStreamPlayer.new()
	music.stream = music_stream
	music.volume_db = -12.0
	add_child(music)
	if music_on:
		music.play()


## Ładuje gotowe pliki res://audio/*.wav (generuje je tools/generate_audio.gd).
## Gdyby ich brakowało, syntezuje dźwięki w locie, jak wcześniej.
static func _load_or_build() -> void:
	for n in SOUND_NAMES:
		var path := "res://audio/%s.wav" % n
		if ResourceLoader.exists(path):
			sounds[n] = load(path)
	if sounds.size() < SOUND_NAMES.size():
		push_warning("Sfx: brak plików audio, generuję dźwięki w locie")
		_build_sounds()
	if ResourceLoader.exists("res://audio/music.wav"):
		music_stream = load("res://audio/music.wav")
	else:
		music_stream = _build_music()
	if music_stream.loop_mode == AudioStreamWAV.LOOP_DISABLED:
		music_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music_stream.loop_begin = 0
		music_stream.loop_end = int(music_stream.get_length() * music_stream.mix_rate)


static func play(sound: String, pitch := 1.0) -> void:
	if not is_instance_valid(inst) or not sounds.has(sound):
		return
	var p := inst.players[inst.next_player]
	inst.next_player = (inst.next_player + 1) % inst.players.size()
	p.stream = sounds[sound]
	p.pitch_scale = pitch # np. każdy jeniec ma trochę inny głos
	p.play()


## Włącza/wyłącza muzykę w tle (efekty dźwiękowe zostają). Wybór jest zapamiętywany.
static func toggle_music() -> void:
	music_on = not music_on
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # zachowaj pozostałe ustawienia (np. język)
	cfg.set_value("audio", "music", music_on)
	cfg.save(SETTINGS_PATH)
	if not is_instance_valid(inst):
		return
	if music_on:
		if not inst.ended and not inst.music.playing:
			inst.music.play()
	else:
		inst.music.stop()


static func stop_music() -> void:
	if is_instance_valid(inst):
		inst.ended = true
		inst.music.stop()


# ---------------------------------------------------------------- synteza

static func _wave(kind: String, ph: float) -> float:
	var f := fposmod(ph, 1.0)
	match kind:
		"square":
			return 1.0 if f < 0.5 else -1.0
		"pulse":
			return 1.0 if f < 0.25 else -1.0
		"saw":
			return 2.0 * f - 1.0
		"tri":
			return 4.0 * absf(f - 0.5) - 1.0
	return sin(f * TAU)


static func _tone(f0: float, f1: float, dur: float, wave: String, amp: float, noise := 0.0, decay := 2.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		ph += lerpf(f0, f1, t) / RATE
		var s := _wave(wave, ph) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
		out[i] = s * pow(1.0 - t, decay) * amp
	return out


static func _noise(dur: float, amp: float, decay: float, lp0: float, lp1: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var y := 0.0
	for i in n:
		var t := float(i) / n
		y += lerpf(lp0, lp1, t) * ((randf() * 2.0 - 1.0) - y)
		out[i] = y * pow(1.0 - t, decay) * amp
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(a.size(), b.size()))
	for i in out.size():
		out[i] = (a[i] if i < a.size() else 0.0) + (b[i] if i < b.size() else 0.0)
	return out


static func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	w.data = data
	return w


static func _midi(n: int) -> float:
	return 440.0 * pow(2.0, (n - 69) / 12.0)


static func _build_sounds() -> void:
	sounds["shoot"] = _wav(_tone(1000, 300, 0.09, "square", 0.2, 0.1, 1.5))
	sounds["enemy_shoot"] = _wav(_tone(600, 250, 0.1, "pulse", 0.14, 0.1, 1.5))
	sounds["throw"] = _wav(_tone(200, 500, 0.18, "tri", 0.25, 0.4, 1.0))
	sounds["explosion"] = _wav(_mix(_noise(0.7, 1.2, 2.0, 0.25, 0.02), _tone(70, 30, 0.7, "sine", 0.7, 0.0, 1.5)))
	sounds["die"] = _wav(_tone(500, 80, 0.25, "square", 0.25, 0.3, 1.5))
	sounds["hit"] = _wav(_tone(350, 60, 0.5, "saw", 0.35, 0.2, 1.0))
	sounds["boss_hit"] = _wav(_tone(180, 120, 0.06, "square", 0.25, 0.5, 1.0))
	sounds["pickup"] = _wav(_cat([
		_tone(660, 660, 0.07, "square", 0.2, 0.0, 0.5),
		_tone(880, 880, 0.07, "square", 0.2, 0.0, 0.5),
		_tone(1320, 1320, 0.12, "square", 0.2, 0.0, 1.0)]))
	sounds["rescue"] = _wav(_cat([
		_tone(523, 523, 0.08, "pulse", 0.25, 0.0, 0.5),
		_tone(659, 659, 0.08, "pulse", 0.25, 0.0, 0.5),
		_tone(784, 784, 0.08, "pulse", 0.25, 0.0, 0.5),
		_tone(1047, 1047, 0.25, "pulse", 0.25, 0.0, 1.0)]))
	sounds["gameover"] = _wav(_cat([
		_tone(400, 390, 0.2, "tri", 0.4, 0.0, 0.5),
		_tone(330, 320, 0.2, "tri", 0.4, 0.0, 0.5),
		_tone(260, 250, 0.2, "tri", 0.4, 0.0, 0.5),
		_tone(180, 120, 0.6, "tri", 0.4, 0.0, 1.0)]))
	sounds["win"] = _wav(_cat([
		_tone(523, 523, 0.14, "pulse", 0.25, 0.0, 0.5),
		_tone(523, 523, 0.14, "pulse", 0.25, 0.0, 0.5),
		_tone(523, 523, 0.14, "pulse", 0.25, 0.0, 0.5),
		_tone(698, 698, 0.4, "pulse", 0.25, 0.0, 0.8),
		_tone(659, 659, 0.14, "pulse", 0.25, 0.0, 0.5),
		_tone(784, 784, 0.6, "pulse", 0.25, 0.0, 0.8)]))
	_shouts()


## Prosty syntezator mowy (formanty). keys: [czas, wysokość głosu, F1, F2, F3, głośność, szum]
## — wartości są interpolowane między klatkami kluczowymi. Szum to oddech ("h") i chrypka.
static func _voice(keys: Array, dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var st := [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]] # stany trzech rezonatorów
	var bw := [90.0, 120.0, 180.0]
	var gains := [1.0, 0.55, 0.3]
	var k := 0
	var peak := 0.001
	for i in n:
		var tt := float(i) / RATE
		while k < keys.size() - 2 and tt > keys[k + 1][0]:
			k += 1
		var a: Array = keys[k]
		var b: Array = keys[k + 1]
		var u := clampf((tt - a[0]) / maxf(b[0] - a[0], 0.0001), 0.0, 1.0)
		var v := []
		for j in range(1, 7):
			v.append(lerpf(a[j], b[j], u))
		# wysokość z lekkim vibrato i drżeniem (krzyk nie jest równy)
		var f0: float = v[0] * (1.0 + 0.03 * sin(tt * TAU * 6.0) + randf_range(-0.01, 0.01))
		ph += f0 / RATE
		var glottal := 1.0 - 2.0 * fposmod(ph, 1.0) # piła = źródło głosu
		var src: float = glottal * (1.0 - v[5]) + randf_range(-1.0, 1.0) * v[5]
		var y := 0.0
		for f in 3:
			var r := exp(-PI * bw[f] / RATE)
			var c := 2.0 * r * cos(TAU * v[f + 1] / RATE)
			var o: float = (1.0 - r) * src + c * st[f][0] - r * r * st[f][1]
			st[f][1] = st[f][0]
			st[f][0] = o
			y += o * gains[f]
		y *= v[4]
		out[i] = y
		peak = maxf(peak, absf(y))
	for i in n:
		out[i] = out[i] / peak * 0.6
	return out


## Okrzyki jeńca: "HELP!" (z wybuchowym "p" na końcu) i "HEY!".
static func _shouts() -> void:
	var help := _voice([
		[0.00, 300, 650, 1800, 2600, 0.0, 1.0],  # h — wydech
		[0.06, 300, 650, 1800, 2600, 0.45, 0.85],
		[0.10, 330, 680, 1850, 2600, 1.0, 0.12], # e
		[0.26, 370, 640, 1800, 2550, 1.0, 0.1],
		[0.40, 330, 560, 1700, 2500, 0.9, 0.1],
		[0.47, 290, 380, 1000, 2400, 0.55, 0.05], # l
		[0.53, 270, 360, 900, 2400, 0.0, 0.0],   # zamknięcie ust przed "p"
		[0.64, 270, 360, 900, 2400, 0.0, 0.0]], 0.64)
	var burst := _noise(0.05, 0.35, 2.5, 0.6, 0.2) # "p"
	var at := int(0.57 * RATE)
	for i in burst.size():
		if at + i < help.size():
			help[at + i] += burst[i]
	sounds["shout_help"] = _wav(help)
	sounds["shout_hey"] = _wav(_voice([
		[0.00, 320, 600, 1900, 2600, 0.0, 1.0],  # h
		[0.05, 320, 600, 1900, 2600, 0.5, 0.8],
		[0.09, 350, 620, 1950, 2650, 1.0, 0.1],  # e...
		[0.22, 400, 520, 2050, 2700, 1.0, 0.1],
		[0.36, 360, 300, 2350, 3000, 0.35, 0.08], # ...j (i)
		[0.46, 300, 280, 2350, 3000, 0.0, 0.0],
		[0.50, 300, 280, 2350, 3000, 0.0, 0.0]], 0.5))


static func _build_music() -> AudioStreamWAV:
	var melody := [
		69, -1, 72, -1, 76, -1, 72, 69, 67, -1, 71, -1, 74, -1, 71, 67,
		65, -1, 69, -1, 72, -1, 69, 65, 64, -1, 68, -1, 71, 68, 64, -1,
		76, 76, -1, 72, 76, -1, 79, -1, 74, 74, -1, 71, 74, -1, 77, -1,
		72, 72, -1, 69, 72, -1, 76, -1, 71, -1, 68, -1, 64, -1, -1, -1]
	var roots := [45, 43, 41, 40, 45, 43, 41, 40]
	var step_n := int(0.2 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(step_n * 64)
	var mph := 0.0
	var bph := 0.0
	for s in 64:
		var m: int = melody[s]
		var root: int = roots[int(s / 8.0)]
		var mf := _midi(m) if m >= 0 else 0.0
		var bf := _midi(root + (12 if s % 2 == 1 else 0))
		for i in step_n:
			var t := float(i) / step_n
			var ts := float(i) / RATE
			var v := 0.0
			if m >= 0:
				mph += mf / RATE
				v += _wave("pulse", mph) * 0.10 * pow(1.0 - t, 0.7)
			bph += bf / RATE
			v += _wave("tri", bph) * 0.2 * (1.0 if t < 0.8 else (1.0 - t) * 5.0)
			if s % 4 == 0 and i < 1800:
				var phase := 110.0 / 30.0 * (1.0 - exp(-30.0 * ts)) + 40.0 * ts
				v += sin(TAU * phase) * 0.3 * exp(-ts * 35.0)
			if s % 4 == 2 and i < 1200:
				v += (randf() * 2.0 - 1.0) * 0.12 * (1.0 - i / 1200.0)
			buf[s * step_n + i] = v
	var w := _wav(buf)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = buf.size()
	return w
