# Architektur

Iris-Shaderpack im Root-Verzeichnis `shaders/`. GLSL 330 compatibility wird von
Iris auf die tatsächlichen Minecraft-/Sodium-Vertexformate transformiert.
Kein Resourcepack, keine Vanilla-Core-Shader, keine zusätzlichen Mods.

Eine Forward-Pipeline schreibt beleuchtete Geometrie in `colortex0` (lineares
RGBA16F). Ein `final`-Pass liest diesen Buffer und erzeugt das sRGB-Bild mit
sanfter Highlight-Kompression. Damit entfallen Gbuffer-Normalen, temporale
History und Compute-Passes. Iris übernimmt die programmspezifischen Fallbacks.

Gemeinsame Funktionen liegen unter `shaders/lib`, Programme unter
`shaders/program`. Kleine Einstiegspunkte setzen Pass- und Dimensionsdefines.
Absolute Include-Pfade beginnen an `shaders/`, nicht am Dateisystem-Root.

Zunächst werden Texturen, Vertex-/Biomfarben, Vanilla-Lichtmap und Alpha-Test
erhalten. Komplexere Beleuchtung, Wasser und Atmosphäre folgen nach dem ersten
bestandenen Compile- und Ausgabetest.
