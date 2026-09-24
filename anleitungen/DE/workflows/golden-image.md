# Workflow — Golden-Image erstellen

Von einer frischen ISO bis zur ersten Baseline, die auf Clients ausgerollt werden kann.

## Voraussetzungen

- [ ] ThinForge-Server läuft
- [ ] Genug Arbeitsspeicher und Plattenplatz auf dem Host für die Cloning-VM (RAM, CPUs und Festplattengröße stellst du in der Oberfläche ein)
- [ ] Installations-ISO bereit (entweder auf dem lokalen Rechner oder als URL)

## Schritt 1 — ISO bereitstellen

Zwei Wege in **Cloning → ISOs** ([05](../05-cloning.md#tab-isos)):

- **ISO hochladen** — wenn die ISO auf deinem Rechner liegt
- **ISO von URL herunterladen** — direkt vom Mirror ziehen lassen (funktioniert gut für Debian, Ubuntu, Manjaro; nur öffentliche Adressen)

Nach erfolgreichem Upload/Download erscheint die ISO in der Liste.

## Schritt 2 — Basis-Festplatte anlegen und Cloning-VM starten

1. **Cloning → VM erstellen** ([05](../05-cloning.md#tab-vm-erstellen))
2. **„Basis HD erstellen"** → Größen prüfen (Default 60 GB gesamt) → **Anwenden**. Ohne diese Festplatte startet die VM nicht; eine vorhandene wird dabei überschrieben.
3. Auf der Karte:
   - **ISO** auswählen
   - RAM / CPU bei Bedarf anpassen (Default 2 GB / 2 CPU)
4. **„VM starten"** — der Server baut dabei die Tools-ISO neu und hängt sie als zweites Laufwerk ein
5. Warten bis die VM läuft und die Konsole erscheint (~30 s). Sie ist im Tab eingebettet; **„In neuem Tab öffnen"** zeigt sie in einem eigenen Browser-Tab

## Schritt 3 — OS installieren und anpassen

In der Konsole arbeitest du wie an einem physischen PC. Die Einrichtungs-Skripte liegen auf dem zweiten CD-Laufwerk **THINFORGE_TOOLS**; die Kurzanleitung `ANLEITUNG_DE.md` darauf beschreibt die Schritte je Distribution:

1. **Installation vorbereiten** — bei Live-ISOs mit Calamares (Debian, Manjaro, Arch, CachyOS) im Terminal `sudo bash install-<distribution>.sh prepare` ausführen (bei Debian mit Zielplatte, z. B. `prepare /dev/vda`); bei der Debian-netinst-ISO entfällt dieser Schritt
2. **OS installieren** — Installer mit manueller Partitionierung auf den vorbereiteten Partitionen (Root als Subvolume `@root`), Benutzer anlegen, Netzwerk. Danach VM stoppen, ISO abwählen, VM starten
3. **ThinForge-Agent einrichten** — im installierten System `sudo bash install-<distribution>.sh finish` von THINFORGE_TOOLS ausführen. Das Skript richtet GRUB mit Snapshots, die `/data`-Partition, SSH (nur mit Schlüssel) und den Agenten samt Signaturprüfung ein
4. **Software einrichten** — alles was später auf jedem Client laufen soll (Browser, Office-Suite, Kiosk-Software, …)
5. **Personalisierung entfernen** — User-spezifische Einstellungen löschen, Test-Dateien weg, Bash-History leeren

**Tipp**: Nichts an Hostname oder MAC-spezifischer Config hardcoden — das würde auf allen Clients gleich werden. Der Agent personalisiert diese Dinge pro Gerät beim Deploy.

## Schritt 4 — VM herunterfahren

In der Konsole regulär herunterfahren (z. B. `sudo poweroff`). Die Karte **VM erstellen** zeigt nach spätestens etwa 10 Sekunden **Gestoppt**.

**Wichtig**: VM muss gestoppt sein, bevor du das Image sicherst. „VM stoppen" beendet die VM ohne Herunterfahren des Gastsystems — deshalb vorher selbst herunterfahren.

## Schritt 5 — Baseline sichern

1. **Cloning → VM erstellen** ([05](../05-cloning.md#image-aus-der-vm-erstellen))
2. **„Updatedelta speichern & Klon erstellen"** klicken — beim ersten Mal öffnet sich der Dialog **Basis-Version erstellen**
3. Dialog:
   - **Image-Name** — Pflicht, z. B. „Debian Kiosk"
   - **Version** — wird automatisch vergeben, erstes Release z. B. `v2026.06.22-001`
   - **Kommentar** — „Initial Baseline, Debian 12 mit Kiosk-Software"
4. **Basis erstellen**

Das Sichern läuft (10–30 Min je nach Disk-Größe). Den Fortschritt zeigen die Tabs **VM erstellen** und **Clones**.

## Schritt 6 — Clone erscheint

Nach Abschluss wechselst du zum Tab **Cloning → Clones**. Der neue Eintrag `v2026.06.22-001` steht mit der Markierung **Basis** als Wurzel der Kette. Name, Kommentar, Erstellt am und Größen sind sichtbar.

## Schritt 7 — Test-Rollout

Bevor der Clone in Produktion geht — immer erst auf einem Testgerät verifizieren.

1. Neuer Test-Client aufnehmen ([workflows/erster-client.md](erster-client.md))
2. Deployment auf diesen einen Client: **Cloning → Deployments** → **Neues Deployment** → **Einzelne Clients** ([06 — Rollouts](../06-rollouts.md))
3. Verifizieren: Remote-Desktop, Terminal, ggf. Funktionstests

## Stolperfallen

- **VM startet nicht** → keine Basis-HD angelegt (die Meldung nennt die fehlende Festplatte), zu wenig Arbeitsspeicher auf dem Host (der Container bekommt den gewählten RAM plus 512 MB) oder ISO-Datei defekt. Logs ([08](../08-tasks-logs.md#logs)) → Container-Logs → Cloning-VM (QEMU). Nennt die Meldung beim Start das Agent-Binary oder den Signierschlüssel, fehlt ein gebautes, zum Signierschlüssel passend signiertes Agent-Binary (oder der Schlüssel selbst) — ohne das baut der Server keine Tools-ISO und startet die VM nicht. Die Meldung nennt den Weg: unter **Clients → Agent** bauen bzw. signieren (nach einem Release-Update typisch) oder unter **Einstellungen → Sicherheit** den Schlüssel erzeugen.
- **Sichern bricht ab** → meist Disk-Platz auf dem Host. Kachel **Server-Speicher** im Dashboard.
- **Clone ist viel größer als erwartet** → temporäre Files in der VM nicht gelöscht, Swap-Datei groß. Vor dem Sichern: `sudo sync; sudo fstrim -av` in der VM.

## Nächste Schritte

- [workflows/update-verteilen.md](update-verteilen.md) — die erste Änderung als Delta ausliefern
- [05 — Cloning](../05-cloning.md) — Detail über Version-Tree und Reassign
