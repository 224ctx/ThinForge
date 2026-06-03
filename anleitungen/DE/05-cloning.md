# 5 — Cloning

Der Cloning-Bereich ist das Herzstück von ThinForge: hier entstehen, pflegst du und verwaltest die Disk-Images (Clones), die später an die Thin-Clients verteilt werden.

Die Ansicht hat **vier Tabs**: Cloning-VM, ISOs, Captures, Clones. Jeder Tab deckt einen Schritt im Image-Lifecycle ab.

## Lifecycle im Überblick

```
1. ISO hochladen/herunterladen
       ↓
2. Cloning-VM mit ISO booten
       ↓
3. OS installieren, Agent setzen, anpassen
       ↓
4. Capture → erstes Image = Baseline (v1.000)
       ↓
5. Änderung: VM starten, modifizieren, "Save Update"
       ↓
6. Delta-Capture → v1.001, v1.002, ...
       ↓
7. Rollout → Clients pullen das Image ([06](06-rollouts.md))
```

---

## Tab: Cloning-VM

Die Cloning-VM ist eine QEMU/KVM-Instanz, die auf dem Server läuft. Sie hat eine dedizierte qcow2-Disk, die als Vorlage für alle späteren Clones dient.

### VM-Status

Oben auf dem Tab zeigt eine Statusleiste:

- **Aktiv** (grün) — VM läuft, noVNC ist eingeklinkt
- **Inaktiv** (grau) — nicht gestartet
- **Wird gestartet / wird gestoppt** — Übergangszustand

### Starten

1. **„VM starten"** klicken
2. Dialog: ISO auswählen (oder „ohne ISO" wenn bereits OS installiert ist)
3. Ressourcen (RAM, CPUs, Disk-Größe) bestätigen oder anpassen
4. Starten

Nach 10–30 Sekunden ist die VM bootfähig, der **„Öffnen in VNC"**-Button wird aktiv.

### VNC-Zugriff

- Klick auf **„Öffnen in VNC"** — öffnet in-Browser noVNC
- Vollbild möglich, Zwischenablage wird durchgereicht
- Die VM ist damit wie ein normaler PC bedienbar: Installation klicken, Software einrichten, Updates laufen lassen

### Stoppen

- **„VM stoppen"** — sauberer Shutdown via ACPI
- **„Force Stop"** — hartes Killen (wenn VM hängt)

### Ressourcen

Die Standard-Werte (2 GB RAM, 2 CPUs, 60 GB Disk) reichen für die meisten Linux- und Windows-Versionen. Anpassen über die `.env`-Variablen `CLONING_VM_RAM`, `CLONING_VM_CPUS`, `CLONING_VM_DISK_SIZE` (siehe [09 — Einstellungen](09-einstellungen.md)).

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

Ein spezieller Eintrag, `thinforge-tools.iso`, wird automatisch vom Server gebaut. Enthält das Client-Provisioning-Script und wird für das **erstmalige Aufsetzen eines neuen Thin-Clients** per USB-Stick oder PXE verwendet ([workflows/erster-client.md](workflows/erster-client.md)).

- **„Rebuild"** — Neuaufbau z. B. nach Zertifikats-Erneuerung oder Schlüsselrotation. Dauert ~1 Minute.

---

## Tab: Captures

Der **Capture** ist der Vorgang, den VM-Stand in ein ausrollbares Image zu überführen. Zwei Arten:

### Baseline-Capture

- Erzeugt ein vollständiges Image (keinen Delta-Parent)
- Löscht vorhandene Snapshots in der VM
- Startet eine neue Versionskette: `v1.000`, `v2.000`, …

**Wann?** Bei Erstinstallation oder wenn du eine saubere neue Kette willst (z. B. nach großen OS-Upgrades).

### Delta-Capture („Save Update")

- Erzeugt ein inkrementelles Image gegen die letzte Version
- Schnell und klein (nur geänderte Blöcke)
- Version wird hochgezählt: `v1.003` → `v1.004`

**Wann?** Für laufende Updates — Security-Patches, Konfig-Änderungen, neue Software.

### Capture starten

1. Cloning-VM muss **gestoppt** sein (sonst Fehlermeldung)
2. In Tab **Captures** auf **„Save Update"**
3. Dialog:
   - **Version** — vorausgefüllt (nächste Nummer), kann überschrieben werden
   - **Kommentar** — kurze Notiz was geändert wurde
   - **„Als neue Basis"** — Checkbox für Baseline-Modus (erzeugt `v<nextRoot>.000`)
4. Starten

Der Capture läuft als Hintergrundtask. Fortschritt sichtbar hier im Tab und in **Tasks** ([08](08-tasks-logs.md)). Je nach Disk-Größe dauert ein Full-Capture 10–30 Minuten, ein Delta meist 1–5 Minuten.

### Capture abbrechen

Während der Capture läuft, erscheint ein **„Abbrechen"**-Button. Abbruch räumt halb-erzeugte Files auf — die VM bleibt unbeschädigt.

---

## Tab: Clones

Die Liste der fertigen Images, bereit zum Ausrollen.

### Versionsbaum

Clones werden hierarchisch dargestellt — Baselines als Root, Deltas als Kinder:

```
v1.000 (Baseline)
├─ v1.001
├─ v1.002
├─ v1.003
└─ v1.004    ← aktuelle "stable", letzter Update

v2.000 (Baseline)
└─ v2.001
```

Innerhalb einer Versionskette (z. B. alle `v1.x`) sind die Updates **flach** — `v1.001`, `v1.002`, `v1.003` sind Geschwister unter `v1.000`, nicht ineinander verschachtelt. Das macht es einfach, einzelne Updates später zu löschen, ohne die Kette zu zerreißen. Falls ein Clone mit defektem `parent_id` auftaucht (z. B. weil der Ur-Quell-Clone gelöscht wurde), repariert ThinForge den Baum beim nächsten Öffnen des Clones-Tabs automatisch.

Die **Basis** einer Kette ist der Clone, von dem aus aktuell ausgerollt wird — meist der erste, manchmal ein späterer (wenn ältere Versionen archiviert sind).

### Aktionen pro Clone

- **Details anzeigen** — Metadaten (Größe, Kommentar, Erzeugt am, Agent-Version zum Capture-Zeitpunkt)
- **Als Basis setzen** — markiert diesen Clone als Chain-Start (Ausrollen beginnt hier)
- **Reassign / Einsortieren** — hängt den Clone an eine andere Stelle im Baum (siehe unten)
- **Exportieren** — Download als Tarball
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
