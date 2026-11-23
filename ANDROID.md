# Build APK na Androida

Projekt ma gotowy preset eksportu (`export_presets.cfg`): arm64, układ pionowy,
pakiet `com.gameslab.commando`, ikona `icon.png`.

## Budowanie

```bash
mkdir -p build && godot --headless --path . --export-debug Android build/commando.apk
```

Albo w edytorze: *Project → Export → Android → Export Project*.

## Instalacja na telefonie

Włącz na telefonie opcje programisty i debugowanie USB, podłącz kabel, potem:

```bash
~/Library/Android/sdk/platform-tools/adb install -r build/commando.apk
```

(Albo „One-Click Deploy” — ikona Androida w prawym górnym rogu edytora.)

## Co jest zainstalowane na tym Macu (jednorazowa konfiguracja — już zrobiona)

| Element | Skąd | Gdzie |
|---|---|---|
| JDK 17 | `brew install openjdk@17` | `/opt/homebrew/opt/openjdk@17` |
| Android command-line tools | `brew install --cask android-commandlinetools` | `/opt/homebrew/share/android-commandlinetools` |
| SDK: platform-tools, build-tools 35.0.1, platforma android-35 | `sdkmanager --sdk_root=$HOME/Library/Android/sdk ...` | `~/Library/Android/sdk` |
| Szablony eksportu Godot 4.7.2 | oficjalny `.tpz` z GitHuba Godota | `~/Library/Application Support/Godot/export_templates/4.7.2.stable` |
| Klucz debug (do podpisywania) | `keytool` | `~/Library/Application Support/Godot/keystores/debug.keystore` (hasło `android`) |

Ścieżka JDK jest wpisana w *Editor Settings → Export → Android → Java SDK Path*.
Jeśli edytor ją nadpisze (np. przy zamknięciu), ustaw ją ponownie na `/opt/homebrew/opt/openjdk@17`.

NDK i CMake **nie są** potrzebne — build używa gotowego szablonu APK (bez Gradle).
Przy aktualizacji Godota do nowszej wersji pobierz nowe szablony (*Editor → Manage Export Templates*).

## Wersja release / Google Play

Potrzebny własny keystore (nie używaj klucza debug do publikacji) i dane w presecie
(*Project → Export → Android → Keystore → Release*). Do Google Play wybierz format AAB:
wymaga włączonego *Use Gradle Build*, zainstalowanego szablonu Androida (*Project → Install Android Build Template*)
oraz dodatkowo `sdkmanager "cmake;3.10.2.4988404" "ndk;28.1.13356709"`.
