extends SceneTree
## Generuje pliki res://audio/*.wav z syntezatora w scripts/sfx.gd.
## Gra ładuje gotowe pliki (szybszy start, pewne działanie na Androidzie).
## Po zmianie dźwięków w sfx.gd uruchom ponownie:
##   godot --headless --path . --script res://tools/generate_audio.gd


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://audio"))
	Sfx._build_sounds()
	for sound in Sfx.sounds:
		var err := (Sfx.sounds[sound] as AudioStreamWAV).save_to_wav("res://audio/%s.wav" % sound)
		print("audio/%s.wav -> %s" % [sound, error_string(err)])
	var err := Sfx._build_music().save_to_wav("res://audio/music.wav")
	print("audio/music.wav -> %s" % error_string(err))
	quit()
