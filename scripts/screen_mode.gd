class_name ScreenMode
extends Node
## F11 (lub Alt+Enter) przełącza pełny ekran.
## Układ jest pionowy (224 px szerokości, wysokość dopasowuje się do ekranu telefonu).
## W oknie szerszym niż wysokim włączamy letterbox, żeby widok nie spłaszczył się.


func _ready() -> void:
	get_window().size_changed.connect(_update_aspect)
	_update_aspect()


func _update_aspect() -> void:
	var s := Vector2(get_window().size)
	var wide := s.y <= 0.0 or s.x / s.y > 0.8
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP if wide else Window.CONTENT_SCALE_ASPECT_KEEP_WIDTH


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
			get_viewport().set_input_as_handled()
