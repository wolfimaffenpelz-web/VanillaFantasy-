# Testverfahren und Grenzen

## Ausgeführt und offen

Die lokalen Ergebnisse stehen in [docs/VALIDATION.md](docs/VALIDATION.md) und
`docs/validation.json`. Struktur-/Konfigurationstests und generische
Mesa/OpenGL-Compile-/Link-/Renderprüfungen wurden ausgeführt. Ein synthetisches
1440p-Testbild ist **kein Minecraft-Screenshot und kein GPU-Benchmark**.

| Ebene | Prüfung | Aussage |
| --- | --- | --- |
| Struktur/Syntax | Includes, Einstiegspunkte, Guards, Eigenschaften, Menüs, Profile, Sprachen, ZIP | lokale Konsistenz |
| Generisches GLSL | expandierte Includes und Optionen, echte OpenGL-Kompilierung und Linken | GLSL im getesteten Mesa-Treiber gültig |
| Synthetische Ausgabe | echte GLSL-Funktionen, Float-Framebuffer, 1440p-Rampe und Geometrie | begrenzte mathematische/rendertechnische Regression |
| Iris-spezifisch | konkrete Quellrevision gelesen | API-Vertrag recherchiert, AST-Transformation nicht ausgeführt |
| Minecraft-Laufzeit | nicht verfügbar | Spielstart, Bildqualität und Integration offen |

## Automatisch wiederholen

Python 3.12 für alle Skripte. Build/Strukturtests benötigen keine Zusatzpakete.
Die Renderingtests brauchen EGL/OpenGL mit Compatibility-Kontext und die
gepinnten Python-Pakete aus `requirements-test.txt`. Beispiel für Linux:

```sh
python3 scripts/validate.py
python3 -m venv work/venv
work/venv/bin/pip install -r requirements-test.txt
EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 work/venv/bin/python scripts/gl_test.py --report-dir work/test-report
python3 scripts/build.py
```

Mesa-Systempakete: `libegl1`, `libegl-mesa0`, `libgl1-mesa-dri`. Ein fehlender
EGL-Kontext ist ein Testfehler, kein stiller Skip. Die CI installiert diese
Pakete und führt dieselben Prüfungen aus. Nvidia-/andere Treiber müssen separat
im Spiel getestet werden.

`common.py` erweitert Pack-Includes und ersetzt numerische Optionen. Es ergänzt
keine GLSL-Konstanten. Formatnamen wie `RGBA16F` sind Iris-Metadaten innerhalb
von Blockkommentaren, keine eingebauten GLSL-Bezeichner. Ein Regressionstest
prüft, dass diese Direktive für Iris erhalten bleibt und nicht als ausführbarer
GLSL-Code oder künstlich injiziertes Test-Define erscheint. Die GLSL-Präprozessor-
Zweige wertet der echte Compiler aus. Das Skript emuliert weder Iris-Attribute
noch die Iris-AST-Transformation, Blendzustände oder Minecraft-Framebuffer.

Konfigurationen: Default, alle drei Profile, alle optionalen Effekte aus/an,
sämtliche Minimal-/Maximalwerte sowie jeder Effektschalter einzeln umgeschaltet.
Grundlegende Himmelreflexionen gehören auch bei Reflexionsstufe 0 zur Wasserbasis.
Atmosphäre 0 entfernt Zusatzdunst; der Übergang an der Rendergrenze bleibt.

Numerik-/Renderprüfungen verwenden den tatsächlichen GLSL-Code:

- Alle 16 × 16 Block-/Himmelslichtlevel, drei Sonnenstände, drei Dimensionen:
  streng steigendes Blocklicht, erkennbare 0/1-Differenz, endliche Werte.
- Beleuchtete und verdeckte Empfänger für jeden Schattenfilter; bei deaktivierten
  Modulen keine aktiven Schatten-/Handlicht-Uniforms.
- Wasser: steigende Opazität mit Tiefe, unterschiedliche Biomtints.
- Kleine Pflanzen: Spitzenbewegung, feste Basen, feste nicht zugeordnete Blöcke.
- Handlicht: Helligkeitsabnahme, endliche Reichweite, Abschaltung, Seelenfarbe.
- Acht Mondphasen: abnehmend Vollmond bis Neumond, symmetrische Halbmonde.
- Wolken-/Himmelswerte am Horizont und auf Wolkenhöhe, Regen, Unterwasserabsorption.
- Echte Terrain-Einstiegspunkte: Projektion, Texturkoordinaten, Farben, Alpha-Cutout.
- Final-Pass in 2560 × 1440: endliche, begrenzte, monotone HDR-Rampe.
- Sonnengröße und direkter Tageslichtkontrast; tatsächlicher Final-Pass mit
  sichtbarer/verdeckter Sonne, Regen, Blick weg von der Sonne, Abschaltung und
  untergetauchter Kamera. Die Tests prüfen die Blend-Abschattung und den
  Helligkeitsunterschied, nicht das subjektive Blendempfinden im Spiel.
- Wasser von oben: deutlich höhere Deckkraft und gesättigte Farbe. Wasserfälle:
  stärkere Texturmodulation und keine Himmelsglanzlichter auf Seitenflächen.
- Echte Water-Einstiegspunkte mit drei RGBA16F-Renderzielen und unabhängigen
  Blendzuständen: Farb-/Antwortbuffer korrekt geschrieben; Biomfarbsprung im
  synthetischen Test um mehr als 65% vermindert, konstante Farbfelder unverändert,
  keine Korrektur auf Nicht-Wasser oder Vermischung anderer Tiefenebenen.

Es gibt keine Minecraft-Referenzbilder. Deshalb keine behaupteten visuellen
Vergleichstests und keine aus synthetischen Bildern abgeleitete Spielqualität.

## Manuelle Testmatrix — sämtliche Zeilen noch offen

Neue Creative-Testwelt mit Cheats, Vanilla-Ressourcen, fester Seed nach eigener
Wahl. Seed, genaue Position, Blickrichtung, FOV, Wetter, Uhrzeit, Render-/
Simulationsdistanz, GPU/Treiber und alle Modversionen im Protokoll festhalten.
Für Vergleiche `doDaylightCycle` und `doWeatherCycle` abschalten, sofern die
konkrete Minecraft-Version diese Gamerules unter diesen Namen anbietet. Bei
geänderten Befehlen die native Autovervollständigung benutzen.

| Nr. | Szene / Durchführung | Erwartung / zu kontrollieren |
| --- | --- | --- |
| 1 | offene Landschaft, Mittag, helle Wolle/Schnee daneben | neutrale Farben, Blockkanten scharf, keine ausgebrannten Flächen |
| 2 | gleicher Ort, Sonnenauf-/untergang und langsamer Tageszyklus | goldene, kontinuierliche Übergänge; runde Sonne ohne Flackern |
| 3 | dichter Wald, verschiedene Sonnenwinkel, Kamera gehen/drehen | PCF-Stabilität, Acne/Peter-Panning, Schatten-Fade, Pflanzen-/Schattenabgleich |
| 4 | offene Nacht, keine Lichtquellen, alle acht Mondphasen | Gelände lesbar, kühles Licht, korrekte Phasen; kein heller Tageshimmel |
| 5 | dunkle Höhle mit einzelnen Fackeln; Lichtlevel-Teststreifen 0–15 | Navigation möglich, Level 0 dunkler als 1; keine Spawn-Zusage ableiten |
| 6 | Fackel, Laterne, Seelenlicht, Glowstone und Lava nebeneinander | Eigenfarben erhalten; keine behauptete farbige Lichtausbreitung |
| 7 | Wasser bei Tag: seicht, tief, Fluss/Ozean/Sumpf | Biomtints unterscheidbar, Wellen dezent, Tiefe erhöht Opazität |
| 8 | Wasser bei Nacht und Dämmerung | zurückhaltender Mond-/Sonnenglanz, keine falschen Spiegelobjekte |
| 9 | eintauchen, auftauchen, nach oben/unten sehen, schwimmen | graduelle Absorption, gute Sicht, kein harter Schwarz-/Blauwechsel |
| 10 | Regen/Gewitter, Himmel und Wasser beobachten | mäßiger Dunst, Nässe nur plausibel exponiert, keine Blendspitzen |
| 11 | Nether: Lavasee, dunkler Gang und Bauwerk | warme Stimmung, deutliche Lava, kein Sonnen-/Mondlicht |
| 12 | End: große Distanz, Inselkante und Gebäude | kühle Stimmung, Inseln lesbar, kein Sonnenlicht, keine dichte Nebelwand |
| 13 | alle Profile wechseln, Optionen einzeln ändern, Spiel neu starten | Neukompilierung klappt, Custom erscheint, Einstellungen persistieren |
| 14 | schnelle Kamerafahrt, FOV ändern, Nah-/Fernansicht | kein NaN-Flackern, Schatten springen nicht störend, keine Bewegungsunschärfe |
| 15 | mehrfach durch Nether-/Endportal, zurück in Oberwelt | Buffer/Atmosphäre korrekt zurückgesetzt, keine falschen Dimensionseffekte |
| 16 | Glas vor/hinter Wasser, Partikel, Eis, Wasserfall, fließendes Wasser | Alpha/Sortierung, Blockgrenzen, Wasseroberflächenblick, Regenpartikel prüfen |

Zusätzlich alle optionalen Effekte vollständig abschalten. Handlicht separat
mit Haupt-/Nebenhand und Wechsel leuchtend/nicht leuchtend testen: weiche
Helligkeitsübergänge, Seelenfarbe, bekannte Lichtlecks hinter Wänden. Statische
Blöcke und Pflanzenbasen dürfen nicht schwanken. Hand, Mob-Schadensblinken,
Glint, Beacons und leuchtende Augen auf korrekte Fallbacks prüfen.

Jeden Fehler mit Screenshot/kurzem Video, erster relevanter Logmeldung, Profil,
Position und Versionen dokumentieren. Vor weiterem Effektaufbau zuerst
Integrationsfehler beheben und die betroffenen Zeilen wiederholen.

## RTX-2080-Benchmark — noch nicht gemessen

Vor der Performance-Messung Alpha 3 im Spiel prüfen: dieselbe Szene gegen Alpha 2
vergleichen, einmal Balanced neu anwenden. Sonne hinter einem Gebäude/Blättern,
am Bildrand, bei Regen und durch Glas betrachten; Größenoptionen und alle
Mondphasen prüfen. Wasser von oben und in flachem Winkel, tiefe/seichte Gewässer,
Wasserfälle, native Biomvermischung aus/an sowie Shader-Biomglättung 0/2/4 prüfen.
Auf Farbflackern bei Kamerabewegung, Ufer, getrennte Wasserhöhen und mehrere
Glas-/Wasserschichten achten. Die neue MRT-/Blend-Konfiguration wurde generisch,
jedoch nicht im hiesigen Minecraft-Renderer geprüft.

Biomglättung kostet zusätzliche Texturzugriffe und zwei HDR-Buffer, verwendet
jedoch den bestehenden Final-Pass. Bei der Messung diese Funktion separat
abschalten, um ihren Anteil einzugrenzen; das Performance-Profil deaktiviert sie.

1. 2560 × 1440, gleiche Versionen, gleicher FOV. 16 und 24 Chunks getrennt;
   Simulationsdistanz dokumentieren. Notebook-/Energiesparmodi ausschließen.
2. FPS-Limit deaktivieren und VSync kontrollieren. Treiberlimit ebenfalls
   kontrollieren. Shaderkompilierung und Chunkgenerierung vor Messstart abwarten.
3. Identische bereits geladene Szenen verwenden: offene Landschaft, Wald,
   Wasser, Höhle, Regen, Nether, End. Standpunkt/Blick oder Kamerapfad speichern.
4. Pro Szene zuerst Sodium ohne Shader messen, danach Performance, Balanced,
   Quality. Jeweils mindestens 60 Sekunden aufwärmen, danach 60 Sekunden
   Frametime-Aufzeichnung; drei Durchläufe pro Einstellung.
5. Mit einem verfügbaren externen Frametime-Capture-Werkzeug aufzeichnen,
   beispielsweise PresentMon unter Windows. Eine F3-Momentaufnahme reicht nicht
   für 1%-Lows. Aufzeichnungen und Ausschluss von Ladephasen aufbewahren.
6. Durchschnitts-FPS = 1000 / mittlere Frametime in ms. Hier verwendete Definition
   der 1%-Low-FPS: 1000 / Mittelwert der langsamsten aufgerundeten 1% der Frames.
   Definition nennen, da andere Werkzeuge abweichen können.
7. GPU-Auslastung/Frametime und CPU-Last betrachten. Gegenprobe mit niedrigerer
   Auflösung hilft, ein GPU-Limit einzugrenzen. Software-Mesa-Zeiten sind hierfür
   ohne Aussagekraft.
8. Werte, Streuung, Bildqualität und Stottern in `docs/BENCHMARK.csv` protokollieren.
   Erst dann das vorläufige Balanced-Ziel von 120 FPS beurteilen.

`scripts/benchmark.py` wertet reale CSV-Dateien mit Spalte `frametime_ms` aus.
Es erfasst selbst keine Frames und erzeugt keine Messdaten.
