# Lokaler Testbericht

Datum: 11.11.2026. Version: 0.1.0-alpha.2. Recherchierte Zielbasis:
Minecraft 26.3 / Iris 1.11.6, Commit
`671a5c87747d33983d7ed659461a64f46dfcb1f0` / Sodium 0.9.2+mc26.3.

## Tatsächlich ausgeführte Prüfungen

- Python 3.12.14; PyOpenGL 3.1.10 und NumPy 2.5.4.
- 12 automatisierte Struktur-/Konfigurations-/Build-Testfälle.
- 672 echte generische Compile-/Link-Prüfungen: 42 Programmpaare in 16
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

## Aussagegrenzen

**Nicht ausgeführt:** Iris-AST-Transformation, Minecraft-Start, Sodium-
Attributbindung im Spiel, Blend-/Framebufferintegration im echten Renderer,
visuelle Referenzvergleiche, Nvidia-Treibertest, RTX-2080-Benchmark sowie
GitHub-Actions-Ausführung. Die recherchierte Versionskombination ist damit
noch nicht als lauffähig bestätigt. Minecraft-Folgeversionen sind ungetestet.

Die Auflösung des synthetischen Tests sagt nichts über die Spielbildrate aus.
Es wurden keine FPS-Werte erfunden oder aus llvmpipe abgeleitet. Alle Zeilen der
manuellen Matrix in TESTING.md bleiben offen.

## Gebautes Artefakt

`Warm-Fantasy-Vanilla-Plus-0.1.0-alpha.2.zip`, 64221 Bytes, 114 ZIP-Einträge.
SHA256: `3198dcac7a2a091771abe0ac3dd999a66133290acdfd2bb0ad1687e7882c7a8f`.
