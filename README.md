# Commando (Godot 4)

Klon klasycznego Commando (Capcom, 1985): pionowy shooter z widokiem z góry.
Cała grafika (pixel art) i dźwięk są generowane kodem — projekt nie ma żadnych plików z assetami.

## Uruchomienie

Otwórz folder w Godot 4.3+ (Import → `project.godot`) i kliknij Play (Cmd+B).

## Sterowanie

| Akcja | Klawisze |
|---|---|
| Ruch (8 kierunków) | WASD / strzałki |
| Strzał | Spacja / J |
| Granat | G / K |
| Wyciszenie | M |
| Pełny ekran | F11 / Alt+Enter |
| Restart po końcu gry | Enter / R |

## Rozgrywka

- Przejdź poziom od dołu do góry i pokonaj bossa (czołg-forteca) — pasek jego życia pojawia się u góry.
- **Wrogowie:** piechur, snajper (czerwienieje przed strzałem), granatnik (miejsce lądowania granatu jest zaznaczone), motocyklista, bunkier (8 HP).
- **Teren:** trzy rzeki — przejdziesz tylko po mostach. Drzewa i skały blokują ruch i pociski.
- **Przedmioty:** jeniec (+500 pkt, +2 granaty), skrzynia (+5 granatów) i apteczka (+2 energii; przy pełnej energii zostaje na mapie).
- Energia gracza: 6 segmentów (pasek w prawym górnym rogu, czerwony przy ≤2). Pocisk zabiera 1, pocisk snajpera, wybuch granatu i taranowanie motocyklem po 2. Po zerowej energii tracisz życie i wracasz z pełną.
- Dodatkowe życie co 10 000 punktów.

## Struktura

- `scenes/title.tscn` — ekran tytułowy (`scripts/title.gd`), start gry: Enter / Spacja
- `scenes/main.tscn` — scena gry; świat buduje `scripts/main.gd`. Po końcu gry: Enter = restart, Esc = tytuł
- `scripts/highscore.gd` — rekord zapisywany w `user://highscore.cfg`
- `scripts/sprites.gd` — generator pixel artu (postaci, teren, wybuchy, boss)
- `scripts/sfx.gd` — syntezowane efekty dźwiękowe i muzyka
- `scripts/player.gd`, `enemy.gd`, `bunker.gd`, `boss.gd`, `bullet.gd`, `grenade.gd`, `pickup.gd`
- `scripts/boom.gd`, `fx.gd` (Puff), `floattext.gd`, `water.gd` — efekty i animacje

## Balans

Stałe trudności (liczba wrogów, bunkrów, żyć, granatów…) są na górze `scripts/main.gd`.
Parametry poszczególnych wrogów — w `scripts/enemy.gd`, bossa — w `scripts/boss.gd`.

## Warstwy kolizji

1 world · 2 player · 3 enemy · 4 player_bullet · 5 enemy_bullet · 6 water
(woda blokuje ruch, ale nie pociski)
