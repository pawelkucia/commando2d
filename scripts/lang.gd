class_name Lang
extends RefCounted
## Teksty gry po angielsku i po polsku. Wybór języka jest zapamiętywany w user://settings.cfg
## (domyślnie: polski, jeśli system jest po polsku, w przeciwnym razie angielski).

const SETTINGS_PATH := "user://settings.cfg"
const LANGS := ["pl", "en"]

const TEXT := {
	"high_score": ["HIGH SCORE", "REKORD"],
	"tap_start": ["TAP TO START", "DOTKNIJ, ABY ZACZĄĆ"],
	"press_enter": ["PRESS ENTER", "NACIŚNIJ ENTER"],
	"title_hint": ["WASD move   SPACE fire   G grenade", "WASD ruch   SPACJA strzał   G granat"],
	"intro_touch": ["Stick - move\nFIRE / GREN buttons\nhold FIRE - aim lock",
		"Gałka - ruch\nprzyciski OGIEŃ / GRANAT\ntrzymaj OGIEŃ - blokada celu"],
	"intro_keys": ["WASD - move   SPACE - fire\nhold SPACE / SHIFT - aim lock\nG - grenade   M - music",
		"WASD - ruch   SPACJA - strzał\ntrzymaj SPACJĘ / SHIFT - blokada\nG - granat   M - muzyka"],
	"hud": ["SCORE %06d\nLIVES %d  GRENADES %d", "PUNKTY %06d\nŻYCIA %d  GRANATY %d"],
	"game_over": ["GAME OVER", "KONIEC GRY"],
	"mission_complete": ["MISSION COMPLETE", "MISJA WYKONANA"],
	"score_line": ["SCORE %06d", "PUNKTY %06d"],
	"new_record": ["NEW RECORD!", "NOWY REKORD!"],
	"tap_restart": ["TAP - restart", "DOTKNIJ - od nowa"],
	"keys_restart": ["ENTER - restart   ESC - title", "ENTER - od nowa   ESC - menu"],
	"one_up": ["1UP", "+1 ŻYCIE"],
	"plus_grenades": ["+%d GREN", "+%d GRAN"],
	"fire_btn": ["FIRE", "OGIEŃ"],
	"gren_btn": ["GREN", "GRANAT"],
}

## Okrzyki jeńca — kolejne poziomy zniecierpliwienia (patrz Pickup).
const POW_LINES := {
	"en": [
		["HELP!", "HEEELP!", "OVER HERE!", "SAVE ME!", "PLEASE!", "HELLO?!", "MEDIC! WAIT, NO..."],
		["WE WILL DIE!", "HURRY UP!", "I'M TOO YOUNG!", "MY MOM IS WAITING!", "THESE ROPES ITCH!",
			"I NEED A TOILET!", "ANYBODY?!", "I HAVE A FAMILY!", "MY LEG IS ASLEEP!"],
		["ARE YOU KIDDING?!", "TODAY, PLEASE!", "SERIOUSLY?!", "I CAN SEE YOU!", "STOP SIGHTSEEING!",
			"MOVE IT, SOLDIER!", "I'LL TELL YOUR SARGE!", "TICK TOCK!"],
		["#@*!", "%&#@!!", "@#$%&!", "*!#@ YOU!", "GRRR... #@!", "$#!*&%!", "!@#$%^&*!", "YOU #@%&!"],
	],
	"pl": [
		["POMOCY!", "RATUNKU!", "TUTAJ!", "RATUJ MNIE!", "PROSZĘ!", "HALO?!", "SANITARIUSZ! A NIE..."],
		["ZGINIEMY!", "POŚPIESZ SIĘ!", "JESTEM ZA MŁODY!", "MAMA NA MNIE CZEKA!", "TE SZNURY GRYZĄ!",
			"MUSZĘ DO TOALETY!", "JEST TU KTOŚ?!", "MAM RODZINĘ!", "ZDRĘTWIAŁA MI NOGA!"],
		["ŻARTUJESZ?!", "DZISIAJ, PROSZĘ!", "SERIO?!", "WIDZĘ CIĘ!", "TO NIE WYCIECZKA!",
			"RUSZAJ SIĘ, ŻOŁNIERZU!", "POSKARŻĘ SIERŻANTOWI!", "TIK-TAK!"],
		["#@*!", "%&#@!!", "@#$%&!", "*!#@ CI!", "GRRR... #@!", "$#!*&%!", "!@#$%^&*!", "TY #@%&!"],
	],
}
const POW_THANKS := {
	"en": ["THANKS!", "MY HERO!", "I OWE YOU!", "FREEDOM!", "YOU ROCK!"],
	"pl": ["DZIĘKI!", "MÓJ BOHATER!", "WISZĘ CI!", "WOLNOŚĆ!", "JESTEŚ WIELKI!"],
}
const POW_THANKS_ANGRY := {
	"en": ["ABOUT TIME!", "FINALLY!", "TOOK YA LONG ENOUGH!", "HMPF. THANKS."],
	"pl": ["NO WRESZCIE!", "NARESZCIE!", "ALEŚ SIĘ GRZEBAŁ!", "HMPF. DZIĘKI."],
}
## Pierwszy okrzyk (dźwięk "HELP!" albo "HEY!") i pasujący do niego dymek.
const POW_SHOUT := {
	"en": {"shout_help": "HELP!", "shout_hey": "HEY! OVER HERE!"},
	"pl": {"shout_help": "HELP! POMOCY!", "shout_hey": "HEJ! TUTAJ!"},
}

static var current := ""


static func get_lang() -> String:
	if current == "":
		var cfg := ConfigFile.new()
		if cfg.load(SETTINGS_PATH) == OK:
			current = str(cfg.get_value("ui", "lang", ""))
		if current not in LANGS:
			current = "pl" if OS.get_locale_language() == "pl" else "en"
	return current


static func set_lang(lang: String) -> void:
	current = lang
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH) # zachowaj pozostałe ustawienia (np. muzykę)
	cfg.set_value("ui", "lang", lang)
	cfg.save(SETTINGS_PATH)


## Tekst interfejsu w bieżącym języku.
static func t(key: String) -> String:
	var pair: Array = TEXT[key]
	return pair[1] if get_lang() == "pl" else pair[0]


static func pick(table: Dictionary) -> Variant:
	return table[get_lang()]
