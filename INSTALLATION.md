# Installation und erster Start

1. Ein getrenntes Minecraft-Java-Profil für **26.3** anlegen und eine Testwelt
   verwenden.
2. Fabric sowie tatsächlich für diese Spielversion verfügbare Iris-/Sodium-
   Builds installieren. Die geprüfte Quellenbasis nennt Iris 1.11.6, Fabric
   Loader 0.19.3 und Sodium 0.9.2+mc26.3. Das bestätigt keine Veröffentlichung
   genau dieser Binärpakete. Andere Versionskombinationen sind ungetestet.
3. `Warm-Fantasy-Vanilla-Plus-0.1.0-alpha.2.zip` **unentpackt** in den Ordner
   `shaderpacks` des gewählten Spielprofils kopieren. Standardpfade:
   Windows `%APPDATA%\.minecraft\shaderpacks`, Linux
   `~/.minecraft/shaderpacks`, macOS
   `~/Library/Application Support/minecraft/shaderpacks`.
4. Minecraft starten und das Pack in der Iris-Shaderpack-Verwaltung auswählen.
5. In den Shaderpack-Optionen zuerst **Balanced** verwenden. Untermenüs bieten
   Wasser, Schatten, Himmel, Atmosphäre und Expertenoptionen.
6. Spielstart und erste Szene nach [TESTING.md](TESTING.md) prüfen. Das Pack ist
   eine Alpha ohne hier bestätigten Minecraft-Laufzeittest.

## Custom und gespeicherte Optionen

Das Pack definiert drei Presets. Abweichende Einstellungen kennzeichnet Iris
nativ als **Custom**; es gibt kein viertes festes Preset und keine zusätzliche
Konfigurationsmod. Im geprüften Iris-Quellstand speichert Iris die Optionen als
`shaderpacks/<Packdateiname>.txt`, bei einer ZIP also beispielsweise
`Warm-Fantasy-Vanilla-Plus-0.1.0-alpha.2.zip.txt` neben der ZIP. Ein umbenanntes
Release kann deshalb andere gespeicherte Optionen verwenden.

Alle Optionen gehören zu jedem Preset. Ein Presetwechsel setzt auch individuelle
Helligkeitswerte zurück. Zum Wiederherstellen der Defaults Balanced auswählen
und anwenden. Die tatsächliche Speicherung/Custom-Anzeige ist Teil des offenen
Spieltests, nicht des generischen Konfigurationstests.

## Eigenbau

```sh
python3 scripts/validate.py
python3 scripts/build.py
```

Die ZIP unter `dist/` enthält direkt `shaders/` und die MIT-Lizenz. Kein
zusätzlicher Projektordner darf vor `shaders/` stehen. Integritätsprüfung:

```sh
cd dist
sha256sum -c *.sha256
```

Der Build benötigt keine Minecraft-Dateien und lädt nichts herunter. Um das
Repository als Pack zu verwenden, seinen Ordner mit direkt enthaltenem
`shaders/` nach `shaderpacks` kopieren; die ZIP ist die schlankere Variante.

## Bei Problemen

Bei Kompilierfehlern auf Vanilla zurückschalten und den **ersten** Iris-/Shader-
Fehler aus `logs/latest.log` zusammen mit exakten Versionen, Profil, GPU und
Treiber notieren. Bei Schattenfehlern testweise Schatten deaktivieren; bei
Wasserproblemen andere Ressourcenpacks entfernen und den Wasser-/Glas-Test
durchführen. Fehlendes Handlicht kann bedeuten, dass Iris für den gehaltenen
Gegenstand keinen Emissionswert liefert. Beliebige Items erhalten kein Licht.
