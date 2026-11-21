class_name HighScore
extends RefCounted
## Rekord zapisywany w user://highscore.cfg.

const PATH := "user://highscore.cfg"


static func get_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


## Zapisuje wynik, jeśli jest rekordem. Zwraca true przy nowym rekordzie.
static func submit(score: int) -> bool:
	if score <= get_best():
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", score)
	cfg.save(PATH)
	return true
