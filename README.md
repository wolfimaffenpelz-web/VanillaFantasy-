# Warm Fantasy Vanilla+

Eigenständiges Iris-Shaderpack für eine warme, gut lesbare Vanilla+-Spielwelt.
Ziel: Minecraft Java 26.3, Fabric, Iris und Sodium. Entwicklungsstand: **0.1.0-alpha.1**.

Die Schnittstelle wird gegen Iris **1.11.6**, Zweig `26.3`, Revision
`671a5c87747d33983d7ed659461a64f46dfcb1f0` entwickelt. Eine im Spiel
bestätigte Kompatibilität und RTX-2080-Messwerte liegen noch nicht vor.
Folgeversionen sind nicht als unterstützt freigegeben.

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

Alle Shader wurden eigenständig erstellt. Keine fremden Shaderdateien oder
Texturen werden mitgeliefert. Projektlizenz: MIT.
