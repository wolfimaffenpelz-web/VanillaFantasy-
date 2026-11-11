# Architektur

## Pipeline

`shaders/` liegt im Repository-Root. GLSL 330 compatibility wird von Iris auf
Minecraft-/Sodium-Vertexformate transformiert. Dieser Transformationsschritt ist
in den generischen OpenGL-Tests nicht enthalten. Keine Vanilla-Core-Shader,
keine zusätzliche Beleuchtungsmod.

```text
shadow                         -> Tiefenkarte für Sonne/Mond
gbuffers_skybasic               -> prozeduraler Himmel im Szenenbuffer
gbuffers_*                     -> Forward-Licht, Material und Nebel
gbuffers_water                 -> Alpha-Wasser / Glas-Fallback
final                          -> Bloom, Unterwasserabsorption, Tonemapping, sRGB
```

Ein zusätzlicher Vollbildpass (`final`), kein Compute, keine History, keine
Gbuffer-Normalen oder temporale Rekonstruktion. `colortex0` ist lineares RGBA16F.
`depthtex0` und `depthtex1` liefert Iris; letztere enthält die Tiefe ohne
transparente Geometrie. `shadowtex0` wird manuell mit 1/4/9 Samples verglichen.
Iris verwaltet zusätzliche Schattenziele; die einfache Schattenfarbe wird nicht
für farbige Schatten ausgewertet.

## Programme und Dimensionen

`basic`, `textured`, `textured_lit`, `terrain`, `entities`, `block`, `hand`,
`water`, `lightning`, `skybasic`, `skytextured` erhalten `gbuffers_`-Einstiegspunkte;
hinzu kommen `shadow`, `shadow_water` und `final`. Andere Programme folgen den
geprüften Iris-Fallbacks: Cutout zu Terrain, Partikel zu TexturedLit,
Glint/Beacon/SpiderEyes zu Textured. `entityColor` erhält Entity-Overlays.
Nicht-Wasser im Water-Pass bleibt normale Textur-/Alpha-Geometrie.
Transparente Oberflächen werfen keine opaken Schatten.

`scripts/generate_entrypoints.py` pflegt dünne Einstiegspunkte für Oberwelt
(Root), Nether (`world-1`) und End (`world1`). Strukturtests vergleichen alle
Dateien mit dem Generator. Dimensionsdefines entfernen Sonnen-/Mondbeleuchtung
und Schattenabfragen aus Nether/End. Iris aktiviert Schatten anhand benutzter
Sampler. Deaktivierte Schatten besitzen keinen aktiven Schatten-Sampler.

## Module unter shaders/lib

| Modul | Aufgabe |
| --- | --- |
| options, uniforms, math | Optionen, Iris-Daten, sichere Normalisierung, Lichtkurve |
| color | sRGB/Linear, Highlight-Schulter, finale Ausgabe |
| lighting, shadow | Sonne/Mond, Umgebungs-/Blocklicht, begrenztes PCF |
| material | Eigenemission explizit zugeordneter Oberflächen |
| water | Normalenwellen, Fresnel, Himmel/Glanz und Tiefen-Alpha |
| sky, clouds | Himmelsverlauf, runde Himmelskörper, acht Mondphasen, 2D-Wolken |
| fog | Wetterdunst und Übergang zur Sichtgrenze |
| vegetation | verankerte Bewegung zugeordneter kleiner Pflanzen |
| wet | Nässeglanz nach Himmelslicht und Flächenausrichtung |
| handlight | kameranahes Licht anhand beider Hände |

Includes beginnen an `shaders/` und verwenden eindeutige Guards. Optionen haben
zentrale Definitionen und diskrete Wertelisten. Numerische Compile-Time-Schalter
entfernen optionale Module. Schleifen sind begrenzt: maximal neun Schatten-
und acht Bloom-Samples. Wasser verwendet einen Oberflächentextur- und einen
Tiefensample. Die 2D-Wolken benötigen keinen eigenen Vollbildpass.

## Licht- und Farbverträge

Texturen und Vertexfarben werden gemeinsam nach Linear umgerechnet. Vanilla-AO
bleibt in den Vertexfarben erhalten; `ambientOcclusionLevel` konsumiert Iris.
Lichtkoordinaten werden von den Texelzentren auf Level 0–15 normalisiert. Die
Blocklichtkurve ist bei Null exakt Null und für positive Werte streng steigend.
Die Höhlengrundhelligkeit addiert sich unabhängig davon. Keine Spiellichtlevel
oder Spawnregeln werden verändert.

Material-IDs erkennen gezeichnete Blöcke; die Texturfarbe bestimmt ihre
Eigenemission. Licht auf Nachbarflächen bleibt generisches warmes Vanilla-
Blocklicht. Keine farbige Weltlichtausbreitung, Lichtquellenliste oder
Spawn-Sicherheitsanzeige.

Die Schattenkarte wird nicht radial verzerrt. Normalenversatz, kleiner Tiefenbias,
Iris-Schattenraster und Reichweiten-Fade begrenzen Fehler. Kamerastabilität,
Acne/Peter-Panning und verschiedene Sonnenstände müssen im Spiel abgestimmt
werden; generische Kompilierung belegt diese Bildqualität nicht.

Wasser erhält den Vertex-Biomtint. Skalares tiefenabhängiges Alpha erhält
gewöhnliches sortiertes Blending, ist jedoch keine exakte spektrale Transmission.
Bei untergetauchter Kamera erfolgt einmalig kanalabhängige Absorption anhand von
Tiefe und Spiel-Fogtint. Himmelsreflexionen haben ein definiertes Fallback,
bilden aber keine Umgebungsgeometrie ab. Wasserwellen ändern nur Normalen.

Balanced nutzt 2048er Schatten, 80 Blöcke und vier PCF-Samples. Keine SSR,
Volumetrik, Screen-Space-GI oder zusätzlicher AO-Pass. Bloom ist ein kleiner
Sparse-Filter, keine Blur-Pyramide. Ein GPU-Profiling im Spiel liegt nicht vor;
aus dem Kostenbudget werden keine FPS-Versprechen abgeleitet.
