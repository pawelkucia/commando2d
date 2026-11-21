class_name Sfx
extends Node
## Proceduralne efekty dźwiękowe i muzyka (chiptune) — bez plików audio.

const RATE := 22050

static var inst: Sfx
static var sounds := {}
static var music_stream: AudioStreamWAV

var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music: AudioStreamPlayer
var muted := false


func _ready() -> void:
	inst = self
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		players.append(p)
	if sounds.is_empty():
		_build_sounds()
		music_stream = _build_music()
	music = AudioStreamPlayer.new()
	music.stream = music_stream
	music.volume_db = -12.0
	add_child(music)
	music.play()


static func play(sound: String) -> void:
	if not is_instance_valid(inst) or inst.muted or not sounds.has(sound):
		return
	var p := inst.players[inst.next_player]
	inst.next_player = (inst.next_player + 1) % inst.players.size()
	p.stream = sounds[sound]
	p.play()


static func toggle_mute() -> void:
	if not is_instance_valid(inst):
		return
	inst.muted = not inst.muted
	inst.music.stream_paused = inst.muted


static func stop_music() -> void:
	if is_instance_valid(inst):
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
