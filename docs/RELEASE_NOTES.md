Warm Fantasy Vanilla+ 0.1.0-alpha.3 überarbeitet die Darstellung nach dem
Benutzer-Spieltest: deutlich größere Sonne/Mond, stärkeres Sonnenlicht und
schärfere Schatten sowie eine abschaltbare warme Sonnenblendung mit Sichtprüfung.

Wasser ist satter und deckender, mit ruhigeren und schwächeren Reflexen.
Wasserfälle zeigen die native animierte Fließtextur kräftiger und erhalten
keinen Himmels-Spiegelglanz. Tiefen-/flächengeführte Biomglättung läuft im
vorhandenen Final-Pass: Balanced 2 Blöcke, Quality 4, Performance aus.

Nach dem ZIP-Wechsel einmal Balanced anwenden. Die neuen Optionen stehen im
Himmel-/Wassermenü. Bei Bedarf zusätzlich die native Biomvermischung einschalten.

Die RGBA16F-Korrektur aus Alpha 2 bleibt enthalten. Generische GPU-Tests und
synthetische Renderprüfungen bestehen; die visuelle Überarbeitung und die
Metadaten-Blending-Integration benötigen einen neuen Minecraft-Spieltest.
RTX-2080-Werte sind ungemessen. Keine SSR oder farbige Weltlichtausbreitung.
