# Commando (Godot 4)

Klon klasycznego Commando (Capcom, 1985): pionowy shooter z widokiem z góry.
Cała grafika (pixel art) i dźwięk są generowane kodem — projekt nie ma żadnych plików z assetami.

## Uruchomienie

Otwórz folder w Godot 4.3+ (Import → `project.godot`) i kliknij Play (Cmd+B).

## Telefon (układ pionowy + sterowanie dotykowe)

Gra ma układ pionowy 224 px szerokości (wysokość dopasowuje się do ekranu telefonu).
Na urządzeniu z ekranem dotykowym pojawia się wirtualny joystick (lewa strona — dotknij gdziekolwiek)
oraz przyciski FIRE i GREN (prawa strona). Na komputerze sterowanie dotykowe wymusisz flagą `-- --touch`.
Budowanie APK: patrz [ANDROID.md](ANDROID.md).

## Język

Gra jest po polsku i po angielsku. Język przełączasz na ekranie tytułowym (PL | EN w lewym górnym rogu), a wybór zapisuje się w `user://settings.cfg`.
Domyślny język zależy od języka systemu. Wszystkie teksty, łącznie z okrzykami jeńców, są w `scripts/lang.gd`.

## Sterowanie (klawiatura)

| Akcja | Klawisze |
|---|---|
| Ruch (8 kierunków) | WASD / strzałki |
| Strzał | Spacja / J |
| Granat | G / K |
| Blokada celu (strafe): chodzisz, a strzelasz dalej w tę samą stronę | trzymaj strzał (Spacja / J; na telefonie FIRE). Shift blokuje kierunek bez strzelania |
| Muzyka wł. / wył. | M (lub ikonka głośniczka) |
| Pełny ekran | F11 / Alt+Enter |
| Restart po końcu gry | Enter / R |

## Rozgrywka

- Przejdź poziom od dołu do góry i pokonaj bossa (czołg-forteca) — pasek jego życia pojawia się u góry.
- **Wrogowie:** piechur, snajper (czerwienieje przed strzałem), granatnik (miejsce lądowania granatu jest zaznaczone), motocyklista, bunkier (8 HP).
- **Teren:** trzy rzeki (tylko mosty) i cztery rowy z workami z piaskiem (przejścia na ścieżce i z boku; za rowami czekają okopani wrogowie). Drzewa, skały i wzniesienia blokują ruch i pociski, rzeki i rowy tylko ruch.
- **Jeńcy** wołają o pomoc w komiksowych dymkach. Gdy jeniec pojawia się na ekranie, krzyczy na głos „HELP!” albo „HEY!”. Głos jest syntezowany formantami w `Sfx._voice`, a każdy jeniec ma trochę inną wysokość głosu. Co 6 s na ekranie bez ratunku robią się bardziej zniecierpliwieni, a na końcu klną znaczkami („#@*!”). Teksty są w `LINES` w `scripts/pickup.gd`, a dymek rysuje `scripts/speech_bubble.gd`.
- **Przedmioty:** jeniec (+500 pkt, +2 granaty), skrzynia (+5 granatów) i apteczka (+2 energii; przy pełnej energii zostaje na mapie).
- Energia gracza: 6 segmentów (pasek w prawym górnym rogu, czerwony przy ≤2). Pocisk zabiera 1, pocisk snajpera, wybuch granatu i taranowanie motocyklem po 2. Po zerowej energii tracisz życie i wracasz z pełną.
- Dodatkowe życie co 10 000 punktów.

## Struktura

- `scenes/title.tscn` — ekran tytułowy (`scripts/title.gd`), start gry: Enter / Spacja
- `scenes/main.tscn` — scena gry; świat buduje `scripts/main.gd`. Po końcu gry: Enter = restart, Esc = tytuł
- `scripts/touch_controls.gd` — wirtualny joystick i przyciski; `scripts/screen_mode.gd` — pełny ekran i dopasowanie proporcji
- `scripts/highscore.gd` — rekord zapisywany w `user://highscore.cfg`
- `scripts/sprites.gd` — generator pixel artu: postacie 20x24, przedmioty, wybuchy, boss
- `scripts/terrain.gd` — teren: 3 strefy (łąka, dżungla, wyżyna), ścieżka, woda, rowy, drzewa, palmy, sosny, skały, wzniesienia
- `scripts/sfx.gd` — syntezator efektów i muzyki; gra odtwarza gotowe pliki `audio/*.wav`.
  Po zmianie dźwięków w `sfx.gd` wygeneruj je ponownie: `godot --headless --path . --script res://tools/generate_audio.gd`
- `scripts/player.gd`, `enemy.gd`, `bunker.gd`, `boss.gd`, `bullet.gd`, `grenade.gd`, `pickup.gd`
- `scripts/boom.gd`, `scorch.gd`, `flash.gd`, `fx.gd` (Puff), `floattext.gd`, `water.gd` — efekty i animacje

## Balans

Stałe trudności (liczba wrogów, bunkrów, żyć, granatów…) są na górze `scripts/main.gd`.
Parametry poszczególnych wrogów — w `scripts/enemy.gd`, bossa — w `scripts/boss.gd`.

## Warstwy kolizji

1 world · 2 player · 3 enemy · 4 player_bullet · 5 enemy_bullet · 6 water
(woda blokuje ruch, ale nie pociski)
