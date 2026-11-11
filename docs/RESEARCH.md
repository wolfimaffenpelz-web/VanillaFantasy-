# Phase 0: geprüfte technische Grundlage

Recherche: 11.11.2026. Quellen dienen ausschließlich als technische Referenz.
Es wurde kein Shadercode aus anderen Packs übernommen.

## Versionsnachweis

- [Iris 26.3 build.gradle.kts](https://github.com/IrisShaders/Iris/blob/671a5c87747d33983d7ed659461a64f46dfcb1f0/build.gradle.kts):
  Minecraft 26.3, Iris 1.11.6, Fabric Loader 0.19.3, Sodium 0.9.2+mc26.3.
- [ShaderDoc](https://github.com/IrisShaders/ShaderDoc/tree/ddf473726710c6504422d192784c1652f8aece98):
  GLSL 330 compatibility, Includes, Welt- und Composite-Programme. Einige Seiten
  sind unvollständig; deshalb ist zusätzlich der konkrete Iris-Quellstand geprüft.

Die Versionsangaben stammen aus einem Entwicklungszweig. Sie belegen weder eine
veröffentlichte Binärversion noch einen erfolgreichen Minecraft-Laufzeittest.
Es gibt hier keinen installierten Minecraft-Testclient und keine RTX 2080.

## Schnittstellen, am genannten Iris-Commit geprüft

Die folgenden Pfade beziehen sich auf `common/src/main/java/net/irisshaders/iris/`:

| Vertrag | Iris-Quelldatei | Verwendung |
| --- | --- | --- |
| Programme und Fallbacks | `shaderpack/loading/ProgramId.java` | gbuffers, shadow, final; keine Vanilla-Core-Shader |
| Dimensionen | `shaderpack/ShaderPack.java` | Root/Oberwelt, world-1/Nether, world1/End |
| Sonnen-/Mondrichtung | `uniforms/CelestialUniforms.java` | view-space sunPosition, moonPosition, shadowLightPosition |
| Matrizen und Lichtdaten | `uniforms/CommonUniforms.java`, `uniforms/MatrixUniforms.java` | Gbuffer-/Schattenmatrizen, cameraPosition, Lichtkoordinaten |
| Gehaltene Leuchtobjekte | `uniforms/IdMapUniforms.java` | heldBlockLightValue, heldBlockLightValue2, heldItemId, heldItemId2 |
| Alpha und Entity-Overlay | `uniforms/IrisInternalUniforms.java`, `pipeline/transform/transformer/EntityPatcher.java` | alphaTestRef, entityColor |
| Schatten-Konstanten | `shaderpack/properties/PackShadowDirectives.java` | shadowMapResolution, shadowDistance, shadowIntervalSize, nearest sampling |
| Menüs/Rendering | `shaderpack/properties/ShaderProperties.java` | screen, profile, sliders, clouds, sun, moon, Blendzustände, custom uniforms |
| Optionen | `shaderpack/option/OptionAnnotatedSource.java` | Zahlen-Defines mit Wertelisten, zulässige const-Optionen |
| Handlichtglättung | `parsing/IrisFunctions.java`, `parsing/SmoothFloat.java` | smooth(id, target, fadeUpTime, fadeDownTime) |
| Material-IDs | `shaderpack/IdMap.java` | block.properties / item.properties, mc_Entity.x |
| Custom-Erkennung | `shaderpack/ShaderPack.java` | getProfileName() liefert Custom, wenn kein Preset passt |

Quelllinks: [Iris-Dateibaum](https://github.com/IrisShaders/Iris/tree/671a5c87747d33983d7ed659461a64f46dfcb1f0/common/src/main/java/net/irisshaders/iris),
[ShaderDoc Uniforms](https://github.com/IrisShaders/ShaderDoc/blob/ddf473726710c6504422d192784c1652f8aece98/uniforms.md),
[Iris-Features](https://github.com/IrisShaders/ShaderDoc/blob/ddf473726710c6504422d192784c1652f8aece98/iris-features.md).

## Grenzen vor der Implementierung

Vanilla-Lichtkoordinaten enthalten Block- und Himmelslicht, keine Liste der
umliegenden Lichtquellen. Eine Oberflächen-ID identifiziert das gezeichnete
Material, nicht den Ursprung des ankommenden Lichts. Deshalb warme Vanilla-
Blockbeleuchtung als Basis und farbige Eigenemission; keine behauptete farbige
Lichtausbreitung. Lichtlevel und Spawnregeln bleiben unverändert. Handlicht ist
eine kameranahe Shaderbeleuchtung ohne Hindernistest, keine Weltlichtsimulation.

Screen-Space-Reflexionen, volumetrische Wolken und indirekte Beleuchtung bleiben
Erweiterungen, solange die Basis nicht im Spiel validiert ist. Die internen
Core-/Postprocessing-Shader von Minecraft 26.3 sind keine Shaderpack-API.

## Phasengates

0: Quellenprüfung und Entwurf. 1: Includes, Struktur, Kompilierung, Ausgabe.
2: Licht/Schatten und Profile kompilieren, numerische Tests. 3: Wasserprogramme
und Transparenzvertrag. 4: alle Dimensionen kompilieren. 5: Menüs, Profile,
Sprachen. 6: nur einzeln geprüfte optionale Effekte. 7: reproduzierbare ZIP,
Gesamtregression. Ein bestandenes lokales Gate ersetzt keinen Spieltest.
