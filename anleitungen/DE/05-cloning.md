# 5 — Cloning

Der Cloning-Bereich ist das Herzstück von ThinForge: hier entstehen, pflegst du und verwaltest die Disk-Images (Clones), die später an die Thin-Clients verteilt werden.

Die Ansicht hat mehrere Tabs. Die wichtigsten für den Image-Lifecycle sind **VM erstellen**, **ISOs**, **Captures** und **Clones**.

## Lifecycle im Überblick

```
1. Basis HD erstellen  (ohne dieses Basis-Layout der Festplatte ist
   die Delta-Update-Funktionalität nicht gewährleistet)
       ↓
2. ISO hochladen/herunterladen, Cloning-VM damit booten
       ↓
3. OS installieren → für den Neustart: VM stoppen, prüfen dass die
   ISO abgewählt ist, VM starten → Agent installieren, anpassen
       ↓
4. Delta-Update erstellen ("Updatedelta speichern & Klon erstellen")
   → Image (v2026.06.22-001)
       ↓
5. Später: VM starten, ändern, erneut "Updatedelta speichern"
   → v2026.06.22-002, v2026.06.22-003, ...
       ↓
6. Rollout → Clients pullen das Image ([06](06-rollouts.md))
```

---

## Tab: VM erstellen

Die Cloning-VM ist eine QEMU/KVM-Instanz, die auf dem Server läuft. Sie hat eine dedizierte qcow2-Disk, die als Vorlage für alle späteren Clones dient.

### VM-Status

Oben auf dem Tab zeigt eine Statusleiste:

- **Aktiv** (grün) — VM läuft, Konsole ist eingeklinkt
- **Inaktiv** (grau) — nicht gestartet
- **Wird gestartet / wird gestoppt** — Übergangszustand

### Starten

1. **„VM starten"** klicken
2. Dialog: ISO auswählen (oder „ohne ISO" wenn bereits OS installiert ist)
3. Ressourcen (RAM, CPUs, Disk-Größe) bestätigen oder anpassen
4. Starten

Nach 10–30 Sekunden ist die VM bootfähig, die Konsole wird aktiv.

### Konsole

- Die VM-Konsole ist direkt im Tab eingebettet; mit **„In neuem Tab öffnen"** lässt sie sich in einem eigenen Fenster anzeigen
- Die Zwischenablage wird durchgereicht
- Die VM ist damit wie ein normaler PC bedienbar: Installation klicken, Software einrichten, Updates laufen lassen

### Stoppen

- **„VM stoppen"** — fährt die VM herunter

### Ressourcen

Die Standard-Werte (RAM, CPUs, Disk-Größe) reichen für die meisten Linux- und Windows-Versionen. RAM, CPUs und Disk-Größe stellst du pro VM direkt beim Start ein; die serverseitigen Standardwerte werden in der Server-Konfiguration festgelegt, nicht im Einstellungen-Bereich der Oberfläche.

---

## Tab: ISOs

Verwaltet Installations-ISOs, die als Boot-Medium für die Cloning-VM dienen.

### Liste

Tabelle mit: Dateiname, Größe, Upload-Datum. Klick auf ISO zeigt Detail (SHA256, Hinweis ob gerade in Benutzung).

### Upload

Zwei Wege:

1. **„ISO hochladen"** — Datei vom lokalen Rechner. Akzeptiert nur `.iso`. Keine Größenbegrenzung, aber bei > 5 GB ist ein Direkt-Download per URL bequemer.
2. **„Per URL herunterladen"** — Dialog mit URL-Feld, optional Dateiname. ThinForge zieht die Datei im Hintergrund und zeigt Fortschritt live (% und Bytes). Ideal für Debian-, Ubuntu-, Manjaro-Images direkt von deren Mirror.

### Löschen

Nur möglich wenn keine aktive VM die ISO nutzt. Sonst Fehlermeldung mit Hinweis, erst die VM zu stoppen.

### Tools-ISO

Die Tools-ISO wird automatisch vom Server gebaut. Sie enthält das Client-Provisioning-Script und wird für das **erstmalige Aufsetzen eines neuen Thin-Clients** per USB-Stick oder PXE verwendet ([workflows/erster-client.md](workflows/erster-client.md)).

Die Tools-ISO wird bei jedem Start der Cloning-VM automatisch neu gebaut. Nach einer Zertifikats-Erneuerung oder Schlüsselrotation genügt es daher, die VM neu zu starten.

---

## Image aus der VM erstellen

Im Tab **VM erstellen** sicherst du den VM-Stand als ausrollbares Image (die VM muss **gestoppt** sein). Der Dialog wählt automatisch den passenden Modus.

### Basis erstellen

- Legt einen Basis-Snapshot der VM an und startet eine neue Versionskette
- Beim ersten Mal (noch keine Clones) automatisch gewählt; per Option **„Als neue Basis"** jederzeit erzwingbar
- **Wann?** Bei Erstinstallation oder für eine saubere neue Kette (z. B. nach großen OS-Upgrades)

### Updatedelta speichern & Klon erstellen

- Erstellt ein Delta gegen die letzte Version **und** ein vollständiges, ausrollbares Clone-Image
- Schnell und klein (nur geänderte Blöcke im Delta)
- **Wann?** Für laufende Updates — Security-Patches, Konfig-Änderungen, neue Software

### Image erstellen

1. Cloning-VM muss **gestoppt** sein (sonst Fehlermeldung)
2. Im Tab **VM erstellen** auf **„Updatedelta speichern & Klon erstellen"**
3. Im Dialog:
   - **Version** — wird automatisch vergeben im Format `vJJJJ.MM.TT-NNN` (Datum + fortlaufender Tageszähler pro Image-Linie), z. B. `v2026.06.22-001`
   - **Kommentar** — kurze Notiz, was geändert wurde
   - **„Als neue Basis"** — erzwingt eine frische Kette (Basis-Modus)
4. Starten

Der Vorgang läuft als Hintergrundtask. Fortschritt sichtbar hier und in **Tasks** ([08](08-tasks-logs.md)). Je nach Disk-Größe dauert ein vollständiges Image 10–30 Minuten, ein Delta meist 1–5 Minuten.

### Abbrechen

Während der Vorgang läuft, erscheint ein **„Abbrechen"**-Button. Abbruch räumt halb-erzeugte Files auf — die VM bleibt unbeschädigt.

---

## Tab: Captures

Der Tab **Captures** erfasst dagegen die Festplatte eines **physischen Clients**: Das Gerät bootet per PXE in eine Capture-Umgebung (Clonezilla), und sein Plattenstand wird als Image gesichert.

1. Client auswählen
2. Namen für das Capture vergeben
3. Festlegen, ob das Gerät danach **herunterfährt** oder **neu startet**
4. Starten

Der Vorgang läuft als Hintergrundtask; der Fortschritt ist in **Tasks** ([08](08-tasks-logs.md)) sichtbar.

---

## Tab: Clones

Die Liste der fertigen Images, bereit zum Ausrollen.

### Versionsbaum

Clones werden hierarchisch dargestellt — Baselines als Root, Deltas als Kinder:

```
v2026.06.22-001 (Baseline)
├─ v2026.06.22-002
├─ v2026.06.22-003
├─ v2026.06.22-004
└─ v2026.06.22-005    ← aktuelle "stable", letzter Update

v2026.06.23-001 (Baseline)
└─ v2026.06.23-002
```

Innerhalb einer Kette sind die Deltas **flach** — sie hängen als Geschwister direkt an der Basis (verknüpft über `parent_id`, nicht über die Versionsnummer), nicht ineinander verschachtelt. Das macht es einfach, einzelne Updates später zu löschen, ohne die Kette zu zerreißen. Falls ein Clone mit defektem `parent_id` auftaucht (z. B. weil der Ur-Quell-Clone gelöscht wurde), repariert ThinForge den Baum beim nächsten Öffnen des Clones-Tabs automatisch.

Die **Basis** einer Kette wird automatisch bestimmt: Es ist die Wurzel der Versionskette (die niedrigste Version ohne Elternteil). Sie wird als Markierung angezeigt.

### Aktionen pro Clone

- **Details anzeigen** — Metadaten (Größe, Kommentar, Erzeugt am, Agent-Version zum Capture-Zeitpunkt)
- **Reassign / Einsortieren** — hängt den Clone an eine andere Stelle im Baum (siehe unten)
- **Wiederherstellen** — spielt den Clone wieder auf die Cloning-VM zurück. So lässt sich jederzeit zu einer älteren Version zurückwechseln. Achte aber darauf, dass auch die Clients auf der älteren Version landen — entweder über ein neues Deployment oder über den Rollback (der nur die jeweils vorherige Version wiederherstellen kann).
- **Exportieren** — Download als 7z-Archiv
- **Löschen** — nur möglich, wenn keine Clients diese Version aktiv nutzen und keine Deltas davon abhängen

### Reassign / Einsortieren

Manchmal sollen Clones im Baum umgeordnet werden — z. B. wenn ein re-importierter Clone an eine andere Position gehört, oder wenn ein Clone ohne Parent als Fortsetzung einer bestehenden Kette einsortiert werden soll.

- **„Zuordnen als Kind"** — hängt den Clone als nächstes Kind an einen gewählten Parent
- **„Vor Clone einordnen"** — fügt den Clone vor einem bestehenden Clone ein (nur wenn eine Versionsnummer im Namen erkennbar ist und die Zielversion im selben Root-Nummernkreis liegt)
- **„Freistellen"** — nimmt den Clone aus seiner Kette, macht ihn zu einer neuen eigenständigen Baseline

Diese Operationen sind **rein logisch** — sie ändern nur Metadaten, nicht das Image selbst. Die Delta-Erzeugung folgt weiter der physischen Snapshot-Kette aus dem Capture-Moment.

---

## Speicherplatz im Blick behalten

Clones können groß werden (mehrere GB pro Baseline, einige MB bis GB pro Delta). Auf der Dashboard-**Disk-Usage**-Kachel sind die Werte sichtbar. Typisches Aufräumen:

- **Alte, nicht mehr verteilte Baselines löschen** — Achtung: nur wenn keine lebenden Clients sie noch nutzen
- **Alte Deltas zusammenführen** — per „Neue Basis" aus der aktuellen Leaf-Version, dann alte Kette entfernen
- **Nicht benutzte ISOs löschen**

## Nächste Schritte

- [06 — Rollouts](06-rollouts.md) — Clone an Clients verteilen
- [workflows/golden-image.md](workflows/golden-image.md) — Erste Baseline von Grund auf erstellen
- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Delta-Update an eine Gruppe rollen
