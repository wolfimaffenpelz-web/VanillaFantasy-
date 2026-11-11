# Changelog

## 0.1.0-alpha.2 — 2026-11-11

- Startfehler `final.fsh: undefined variable RGBA16F` behoben: Die
  `colortex0Format`-Angabe steht nun als Iris-Metadatum im Blockkommentar.
- Künstliche `RGBA16F`-Definition aus dem Compile-Test entfernt. Der gemeldete
  Fehler wurde ohne diese Definition reproduziert; die Regression prüft die
  echte, unveränderte Shaderquelle in allen drei Dimensionen.
- Kein neuer bestätigter Minecraft-Laufzeittest; weitere Integration bleibt offen.

## 0.1.0-alpha.1 — 2026-11-11

- Eigenständige Iris-Forward-Pipeline mit einem Final-Pass und gemeinsamen
  Modulen; konkrete Iris-26.3-Quellrevision dokumentiert.
- Warme Sonne, kühler Mond, lesbare Grundhelligkeit, Vanilla-Blocklichtkurve,
  Material-Eigenemission und skalierbare PCF-Schatten.
- Biomtint-Wasser mit Normalenwellen, Himmel-/Lichtreflexen, Tiefen-Alpha
  und separater Unterwasserabsorption.
- Prozeduraler Himmel, runde Sonne und acht Mondphasen, bewegte 2D-Wolken,
  eigene Lichtstimmungen für Nether und End.
- Drei Profile, native Custom-Einstellungen, deutsche/englische Menüs;
  optionale Pflanzenbewegung, Bloom, Nässeglanz und Handlicht.
- Struktur-, Konfigurations-, generische Compile-/Link- und synthetische
  Rendering-/Numeriktests, deterministischer Build und GitHub CI.
- **Offen:** Minecraft-/Iris-Laufzeittest, RTX-2080-Benchmark, Transparenzmatrix,
  Bildqualitätsabnahme. Keine behauptete Folgeversionskompatibilität.
