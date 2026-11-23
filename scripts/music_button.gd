class_name MusicButton
extends TextureRect
## Ikonka głośniczka: włącza/wyłącza muzykę w tle (działa też z klawisza M).
## Dotyk obsługujemy bezpośrednio: telefon zamienia na "mysz" tylko pierwszy palec,
## więc zwykły przycisk nie reagował, gdy drugi palec trzymał joystick.

var shown := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	size = Vector2(22, 16)
	modulate = Color(1, 1, 1, 0.9)
	_refresh(Sfx.music_on)


## Czy punkt (we współrzędnych widoku) trafia w ikonę — z zapasem dla palca.
func hit(pos: Vector2) -> bool:
	return get_global_rect().grow(6.0).has_point(pos)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and hit(event.position):
		_toggle()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT \
			and hit(event.position):
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			get_viewport().set_input_as_handled() # klik emulowany z dotyku — obsłuży go zdarzenie dotyku
		else:
			_toggle() # prawdziwa mysz (PC)


func _toggle() -> void:
	Sfx.toggle_music()
	_refresh(Sfx.music_on)
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if Sfx.music_on != shown:
		_refresh(Sfx.music_on)


func _refresh(on: bool) -> void:
	shown = on
	texture = Sprites.speaker(on)
