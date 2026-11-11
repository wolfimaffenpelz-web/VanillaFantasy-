# Lokaler Testbericht

Datum: 11.11.2026. Version: 0.1.0-alpha.3. Recherchierte Zielbasis:
Minecraft 26.3 / Iris 1.11.6, Commit
`671a5c87747d33983d7ed659461a64f46dfcb1f0` / Sodium 0.9.2+mc26.3.

## Tatsächlich ausgeführte Prüfungen

- Python 3.12.14; PyOpenGL 3.1.10 und NumPy 2.5.4.
- 12 automatisierte Struktur-/Konfigurations-/Build-Testfälle.
- 756 echte generische Compile-/Link-Prüfungen: 42 Programmpaare in 18
  Konfigurationen, einschließlich aller Dimensionen und Presets.
- GLSL-Numerik-/Renderprüfungen für Lichtlevel, Schattenvergleich, Wasser,
  Pflanzenverankerung, Handlicht, Mondphasen, Wolken-/Regenrandfälle und
  Unterwasserabsorption.
- Tatsächliche Terrain-Einstiegspunkte mit Projektionsmatrix, farbiger Textur
  und Alpha-Cutout in einen Float-Framebuffer gerendert.
- Final-Pass mit 2560 × 1440 synthetischer HDR-Rampe: endliche, begrenzte und
  monotone Ausgabe, unterscheidbare helle HDR-Werte. Keine NaN-/Infinity-Werte
  in den geprüften Fixtures.
- ZIP zweimal mit identischen Bytes gebaut und CRC/Struktur geprüft.

GL-Kontext: **OpenGL 4.5 Compatibility Profile, Mesa 25.0.7-2+deb13u1**.
Renderer: **llvmpipe (LLVM 19.1.7, 256 bits)**, reine Softwareausführung.
Maschinenlesbarer Bericht: [validation.json](validation.json).

Der Compiler fand während der Implementierung eine Kollision zwischen einem
Material-Include-Guard und einem Passdefine. Diese wurde korrigiert und ist
jetzt durch einen Strukturtest abgedeckt. Der Terrain-Test prüft zusätzlich
Texturausgabe und Alpha-Cutout statt ausschließlich erfolgreiches Linken.

## Regression aus dem Minecraft-Fehlerbericht

Der gemeldete Startfehler `undefined variable RGBA16F` wurde ohne künstliches
Test-Define im generischen Compiler reproduziert. Die ursprüngliche Testhilfe
hatte den fehlenden GLSL-Bezeichner verdeckt. Sie ist entfernt. Die
Formatdirektive steht jetzt im von Iris dokumentierten Blockkommentar; der
Regressionstest prüft ihren Erhalt für Iris und ihre Entfernung aus dem für
GLSL ausführbaren Code in allen drei Dimensionen. Die vollständige Compile-/
Renderprüfung läuft ohne zusätzliche Formatdefinitionen.

## Visuelle Regression Alpha 3

- Sonnendurchmesser im Standard fünffach gegenüber Alpha 2; einstellbare Größe
  anhand gerenderter HDR-Discfläche geprüft. Direkter Tageslichtkontrast ist höher.
- Echte Final-Pass-Prüfung: sichtbare Sonne erzeugt einen deutlichen warmen
  Lichtschleier; Terrain-Verdeckung, Regen, Blick weg, Abschaltung und
  Unterwasserkamera verhindern ihn in den geprüften Fixtures.
- Wasser von oben mit höherer Deckkraft und kräftigerer Farbe. Auf Wasserfall-
  Seiten reagiert die animierte Textur deutlich stärker; keine Spiegelglanzlichter.
- Echte Water-Einstiegspunkte für horizontale Flächen und beide Wasserfall-Achsen in drei RGBA16F-Ziele gerendert, Farbziel mit
  Straight-Alpha und Metadaten ohne Blending. Die diffuse Biomfarbkorrektur
  vermindert den Farbsprung im synthetischen Test um mehr als 65%, erhält
  konstante Tintfelder, lässt Nicht-Wasser unverändert und verwirft andere
  Tiefenebenen. Die Abschaltung entfernt die aktiven Metadaten-Sampler.
- Kein zusätzlicher Vollbildpass. Die zwei zusätzlichen HDR-Buffer und die
  Nachbarsamples kosten dennoch Speicher/Bandbreite; keine daraus abgeleitete
  Aussage über die RTX-2080-Bildrate.

## Aussagegrenzen

**Nicht ausgeführt:** Iris-AST-Transformation, Minecraft-Start, Sodium-
Attributbindung im Spiel, Blend-/Framebufferintegration im echten Renderer,
visuelle Referenzvergleiche, Nvidia-Treibertest, RTX-2080-Benchmark sowie
GitHub-Actions-Ausführung. Benutzerfeedback aus einem Spieltest von Alpha 2 liegt vor. Die neue
MRT-/Blend-Integration, Sonnenblendung und subjektive Darstellung von Alpha 3
wurden hier noch nicht in Minecraft geprüft. Eine vollständige Abnahme der
Versionskombination sowie Minecraft-Folgeversionen bleibt offen.

Die Auflösung des synthetischen Tests sagt nichts über die Spielbildrate aus.
Es wurden keine FPS-Werte erfunden oder aus llvmpipe abgeleitet. Alle Zeilen der
manuellen Matrix in TESTING.md bleiben offen.

## Gebautes Artefakt

`Warm-Fantasy-Vanilla-Plus-0.1.0-alpha.3.zip`, 75275 Bytes, 116 ZIP-Einträge.
SHA256: `d81a898e22a622eb8e9335dc87d95620a847e13203a4216b38ea09848ed31395`.
