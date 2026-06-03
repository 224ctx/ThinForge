# Workflow — Golden-Image erstellen

Von einer frischen ISO bis zur ersten Baseline, die auf Clients ausgerollt werden kann.

## Voraussetzungen

- [ ] ThinForge-Server läuft
- [ ] Cloning-VM-Ressourcen reichen (RAM, Disk in `.env` angepasst falls nötig)
- [ ] Installations-ISO bereit (entweder auf dem lokalen Rechner oder als URL)

## Schritt 1 — ISO bereitstellen

Zwei Wege in **Cloning → ISOs** ([05](../05-cloning.md#tab-isos)):

- **Upload** — wenn die ISO auf deinem Rechner liegt
- **Per URL** — direkt vom Mirror ziehen lassen (funktioniert gut für Debian, Ubuntu, Manjaro)

Nach erfolgreichem Upload/Download erscheint die ISO in der Liste.

## Schritt 2 — Cloning-VM starten

1. **Cloning → Cloning-VM** ([05](../05-cloning.md#tab-cloning-vm))
2. **„VM starten"** → Dialog:
   - **ISO** auswählen
   - RAM / CPU / Disk-Größe bei Bedarf anpassen (Default 2 GB / 2 CPU / 60 GB)
   - Starten
3. Warten bis die VM läuft (~30 s)
4. **„Öffnen in VNC"** klicken — neues Browser-Tab mit der laufenden VM

## Schritt 3 — OS installieren und anpassen

Im VNC-Fenster arbeitest du wie an einem physischen PC:

1. **OS installieren** — normaler Installer-Flow (Partitionierung, Benutzer anlegen, Netzwerk)
2. **ThinForge-Agent einrichten** — Das Provisioning-Script erwartet eine bestimmte Struktur. Empfohlene Vorarbeit:
   - `/data`-Partition anlegen (siehe Scripts in Tools-ISO — diese werden später beim Client-Deploy automatisch ausgeführt)
   - SSH-Server aktivieren
   - Agent läuft auf dem späteren echten Client via Provisioning-Script — du musst ihn hier **nicht** manuell installieren
3. **Software einrichten** — alles was später auf jedem Client laufen soll (Browser, Office-Suite, Kiosk-Software, …)
4. **Personalisierung entfernen** — User-spezifische Einstellungen löschen, Test-Dateien weg, Bash-History leeren

**Tipp**: Nichts an Hostname oder MAC-spezifischer Config hardcoden — das würde auf allen Clients gleich werden. Der Agent personalisiert diese Dinge pro Gerät beim Deploy.

## Schritt 4 — VM herunterfahren

Im VNC-Fenster regulär Shut-Down (z. B. `sudo poweroff`). Die Cloning-VM-Ansicht geht nach 1–2 Sekunden auf „Inaktiv".

**Wichtig**: VM muss gestoppt sein, bevor der Capture startet.

## Schritt 5 — Baseline capturen

1. **Cloning → Captures** ([05](../05-cloning.md#tab-captures))
2. **„Save Update"** klicken
3. Dialog:
   - **Version** — erstes Release: `v1.000`
   - **Kommentar** — „Initial Baseline, Debian 12 mit Kiosk-Software"
   - **„Als neue Basis"** — **Checkbox aktivieren** (Baseline-Modus)
4. **Starten**

Der Capture läuft (10–30 Min je nach Disk-Größe). Fortschritt:
- Lokal im Captures-Tab
- In Tasks ([08](../08-tasks-logs.md#tasks))

## Schritt 6 — Clone erscheint

Nach Abschluss wechselst du zum Tab **Cloning → Clones**. Der neue Eintrag `v1.000` steht als **Baseline** (Root der Kette). Metadaten, Größe, Kommentar sind sichtbar.

## Schritt 7 — Test-Rollout

Bevor der Clone in Produktion geht — immer erst auf einem Testgerät verifizieren.

1. Neuer Test-Client aufnehmen ([workflows/erster-client.md](erster-client.md))
2. Rollout auf diesen einen Client ([06 — Rollouts](../06-rollouts.md))
3. Verifizieren: Remote-Desktop, Terminal, ggf. Funktionstests

## Stolperfallen

- **VM startet nicht** → Port/Ressourcen-Konflikt (`.env` `CLONING_VM_MEM_LIMIT`) oder ISO-Datei defekt. Logs ([08](../08-tasks-logs.md#logs)) → Cloning-VM-Quelle.
- **Capture bricht ab** → meist Disk-Platz auf dem Host. Disk-Usage-Kachel im Dashboard.
- **Clone ist viel größer als erwartet** → temporäre Files in der VM nicht gelöscht, Swap-Datei groß. Vor Capture: `sudo sync; sudo fstrim -av` in der VM.

## Nächste Schritte

- [workflows/update-verteilen.md](update-verteilen.md) — die erste Änderung als Delta ausliefern
- [05 — Cloning](../05-cloning.md) — Detail über Version-Tree und Reassign
