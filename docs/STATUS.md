# Liefer- und Abnahmestatus

Stand: 11.11.2026, Version 0.1.0-alpha.3. Dies ist ein gebautes Alpha-Shaderpack
mit ausgeführten generischen Tests, **kein im Spiel verifiziertes Release**.

| Bereich | Implementiert | Lokal geprüft | Minecraft |
| --- | --- | --- | --- |
| Packstruktur, Includes, reproduzierbare ZIP | ja | Struktur/Build | offen |
| Sonne/Mond, Grundhelligkeit, Blocklicht, Eigenemission | ja | GLSL/Render/Numerik | offen |
| 1/4/9-Sample-PCF und Reichweiten | ja | GLSL/Tiefenvergleich | Bildstabilität offen |
| Biomwasser, Normalenwellen, Himmelreflex, Tiefen-Alpha | ja | GLSL/Render/Numerik | Sonderfälle offen |
| Unterwasserabsorption | ja | GLSL/Render/Numerik | Sicht/Übergänge offen |
| Himmel, runde Sonne, acht Mondphasen, 2D-Wolken | ja | GLSL/Render/Numerik | Darstellung offen |
| Oberwelt, Nether und End | ja | Programme aller Dimensionen | Übergänge offen |
| Profile, Optionen, Deutsch/Englisch | ja | Struktur/Konsistenz | Menü/Speicherung offen |
| Vanilla-AO und dezentes Bloom | ja | GLSL/1440p-Synthesebild | Bildqualität offen |
| kleine Pflanzenbewegung | ja | Spitzen/Basen/Materialgrenzen | Schattenabgleich offen |
| einfacher Nässeglanz | ja | Compile on/off | Wetterdarstellung offen |
| Handlicht, beide Hände | experimentell/aus | GLSL/Abnahme/Farben | Uniforms/Glättung offen |
| GitHub-Prüf-/Prerelease-Workflow | ja | Dateien erstellt | noch nicht auf GitHub ausgeführt |

## Visuelle Überarbeitung Alpha 3

Auf Basis des Benutzer-Spieltests von Alpha 2: größere Sonne/Mond, stärkeres
Sonnenlicht und Schatten, sichtbarkeitsabhängige Sonnenblendung, satteres und
weniger durchsichtiges Wasser, ruhigere Reflexe, kräftigere Wasserfälle sowie
flächen-/tiefengeführte Biomglättung. Neue Renderregressionen sind vorhanden;
der subjektive Eindruck und die MRT-/Blending-Integration von Alpha 3 müssen
noch im Spiel geprüft werden. Die komplette manuelle Matrix gilt weiterhin
nicht als abgenommen.

## Bekannte Einschränkungen

- Minecraft-Start, Iris-Shadertransformation, Sodium-Attributbindung und die
  tatsächlichen Blend-/Framebufferzustände wurden nicht ausgeführt. Quellprüfung
  und generische Kompilierung garantieren diese Integration nicht.
- Keine verfügbare RTX 2080 und kein installierter Minecraft-Testclient.
  120 FPS und 1%-Low-Werte bleiben ungemessen. Software-Mesa ist kein Benchmark.
- Reflexionen zeigen Himmel/Lichtreflexe, keine Umgebungsgeometrie. Keine SSR.
- Oberflächenwasser verwendet skalare Tiefen-Transparenz. Mehrere transparente
  Schichten, Wasser hinter Glas, Wasserfälle, Sortierung und Partikel sind im
  Spiel zu prüfen; es wird kein allgemeiner Transparenzfix behauptet.
- Wasserwellen ändern nur Normalen. Keine Geometriewellen oder
  Wasserstandsänderungen. Wasserfälle bleiben geometrisch unverändert.
- Biomglättung nutzt nur sichtbare Wasser-Nachbarn und kostet zwei zusätzliche
  HDR-Buffer; sie ist im Performance-Profil aus. Verdeckte/außerhalb des Bilds
  liegende Nachbarn und mehrere transparente Schichten bleiben Einschränkungen.
- Biomtint stammt von gezeichneten Wasserflächen; Unterwasser-Fogtint von der
  Kameraposition. Eine separate Liste aller Gewässerbiome fehlt.
- Handlicht kommt näherungsweise von der Kamera und kann durch Wände leuchten.
  Es ändert keine Blocklichtlevel. Nicht leuchtende Items bleiben dunkel.
- Eigenemission betrifft ganze zugeordnete Modelle; Laternenfassungen können
  leicht mit aufhellen. Keine per-Pixel-Emissionsmasken oder PBR.
- Keine farbige Lichtausbreitung und keine Spawn-Sicherheitsanzeige. Die
  Blocklichtdarstellung ist keine Zusage über Mob-Spawnregeln.
- Vegetation ist auf gelistete kleine Pflanzen begrenzt. Blätter, hohe Pflanzen,
  neue Pflanzenarten und fremde Modelle werden nicht bewegt.
- Wolken besitzen kein Volumen und werfen keine Schatten. Vanilla-Sterne sind
  deaktiviert; ein eigenes Sternenfeld ist noch offen.
- Kein getesteter Support für zusätzliche Dimensionen, Distant Horizons, PBR,
  HDR oder Minecraft-Folgeversionen.

## Phasen und Abnahme

Phase 0: Quellstand/Schnittstellen geprüft. Phase 1: minimaler Startpunkt
kompiliert, gerendert und gebaut. Phasen 2–5: jeweils Struktur-/Compile-Gate
bestanden. Phase 6: begrenzte optionale Effekte ergänzt, komplexe Erweiterungen
zurückgestellt. Phase 7: lokale Optimierung, Regression, Dokumentation und ZIP;
echte GPU-Engpassanalyse bleibt offen.

Abnahmekriterium 2 (Minecraft-26.3-Kompatibilität) und die im Spiel zu
bewertenden Teile von 3–8 sind **noch nicht nachgewiesen**. Die Bildratenziele
bedürfen gesonderter Benchmarks.

## Nächste Schritte

1. Konkreten Iris-/Sodium-Binärbuild installieren und die Testmatrix ausführen;
   Integrationsfehler vor weiteren Effekten beheben.
2. Schattenbias, Nacht-/Höhlenhelligkeit und Wasser-/Glas-Sortierung abstimmen.
3. RTX-2080-Baseline und alle Profile messen, danach GPU-Kosten optimieren.
4. Anschließend SSR mit Himmel-Fallback, niedrig aufgelöste volumetrische
   Wolken und Screen-Space-Indirektlicht untersuchen.
