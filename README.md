# Warm Fantasy Vanilla+

Eigenständiges Iris-Shaderpack für eine warme, gut lesbare Vanilla+-Spielwelt.
Ziel: Minecraft Java 26.3, Fabric, Iris und Sodium. Entwicklungsstand: **0.1.0-alpha.2**.

Die Schnittstelle wird gegen Iris **1.11.6**, Zweig `26.3`, Revision
`671a5c87747d33983d7ed659461a64f46dfcb1f0` entwickelt. Eine im Spiel
bestätigte Kompatibilität und RTX-2080-Messwerte liegen noch nicht vor.
Folgeversionen sind nicht als unterstützt freigegeben.

## Funktionsumfang

Warme Sonne, goldene Dämmerung, kühles Mondlicht, lesbare Höhlen,
Vanilla-Blocklicht mit eigener Helligkeitskurve, Material-Eigenemission,
PCF-Schatten, biomgefärbtes Wasser mit Normalenwellen und Himmelsreflexionen,
Unterwasserabsorption, runde Himmelskörper mit acht Mondphasen, 2D-Wolken und
eigene Lichtstimmungen für Nether und End.

Vanilla-AO, sparsames Bloom, kleine Pflanzenbewegungen und Nässeglanz sind
konfigurierbar. Experimentelles Handlicht ist standardmäßig aus und kennt keine
Hindernisse. Keine SSR, volumetrischen Wolken oder farbige Lichtausbreitung.

| Profil | Schatten | Filter | Wasser | AO | Nässe |
| --- | --- | --- | --- | --- | --- |
| Performance | 48 Blöcke / 1024 | 1 Sample | einfache Wellen, Himmel | 0,4 | aus |
| Balanced (Standard) | 80 / 2048 | 4 Samples | zusätzliche Wellen, Glanz | 0,7 | aus |
| Quality | 128 / 4096 | 9 Samples | breiterer Lichtreflex | 1,0 | an |

Alle Profile verwenden 2D-Wolken. Individuelle Änderungen erscheinen nativ als
**Custom**. Profile setzen sämtliche Packoptionen zurück; Balanced entspricht
exakt den Quellcode-Standardwerten.

## Installation

Release-ZIP unentpackt nach `.minecraft/shaderpacks/` kopieren und in Iris
auswählen. Beim Eigenbau erzeugt `python3 scripts/build.py` die Datei unter
`dist/`. Für den ersten Spieltest bitte [INSTALLATION.md](INSTALLATION.md) und
[TESTING.md](TESTING.md) verwenden.

## Verifikationsstatus

Automatisierte Struktur-/Konfigurationstests, generische OpenGL-Kompilierung und
synthetische Render-/Numeriktests sind vorhanden. Diese bestätigen **keinen**
erfolgreichen Iris-Start. Die Abnahmekriterien zur tatsächlichen Kompatibilität,
Bildqualität im Spiel und Performance bleiben offen. 120 FPS auf RTX 2080 bei
1440p und 16–24 Chunks sind ein ungemessenes Ziel.

## Entwicklung

```sh
python3 scripts/validate.py
python3 -m venv work/venv
work/venv/bin/pip install -r requirements-test.txt
work/venv/bin/python scripts/gl_test.py
python3 scripts/build.py
```

Details: [Installation](INSTALLATION.md), [Architektur](ARCHITECTURE.md),
[Tests](TESTING.md), [Quellenprüfung](docs/RESEARCH.md),
[Status](docs/STATUS.md), [Änderungen](CHANGELOG.md).

Linux-Tests benötigen Mesa EGL/OpenGL, beispielsweise die Pakete `libegl1`,
`libegl-mesa0`, `libgl1-mesa-dri`. Build und Strukturtests benötigen nur Python
3.12 und dessen Standardbibliothek. Die GitHub-Workflows prüfen Pushes/PRs und
können Builds bei Versions-Tags als **Prerelease** veröffentlichen.
Die Workflows wurden lokal vorbereitet, noch nicht auf GitHub ausgeführt.

Alle Shader wurden eigenständig erstellt. Keine fremden Shaderdateien oder
Texturen werden mitgeliefert. Projektlizenz: MIT.
