# Workflow — Update an Gruppe verteilen

Änderung am Golden-Image (Security-Patch, neue Software-Version, Config-Anpassung) → Delta sichern → per Zuweisung erst an Pilot-Clients, dann an die Client-Flotte.

## Voraussetzungen

- [ ] Eine bestehende Clone-Kette (Baseline + evtl. schon Deltas) existiert
- [ ] Ziel-Gruppe(n) sind definiert ([04](../04-gruppen.md))
- [ ] Pilot-Gruppe mit 1–3 Test-Clients (optional aber dringend empfohlen)

## Schritt 1 — Cloning-VM starten (mit existierender Disk)

Die VM hat die Disk aus dem letzten Sichern gespeichert — beim Starten „ohne ISO" wird genau diese Disk weitergenutzt.

1. **Cloning → VM erstellen**
2. ISO auf **„Ohne ISO (von Festplatte booten)"** lassen (ist ein wiederhergestellter Clone aktiv, bootet die VM ohnehin von dessen Festplatte) → **„VM starten"**
3. Konsole im Tab nutzen oder **„In neuem Tab öffnen"**

## Schritt 2 — Änderungen einspielen

In der VM:

- Security-Updates (`apt upgrade`, `pacman -Syu`)
- Software installieren/updaten
- Config anpassen
- Was auch immer

**Getestet im Kiosk-/Produktions-Szenario?** Bevor das Update rausgeht, probier aus dass nichts Offensichtliches kaputt ist.

## Schritt 3 — VM herunterfahren

Sauberer Shutdown aus der VM. Die Karte **VM erstellen** zeigt **Gestoppt**.

## Schritt 4 — Delta sichern

1. **Cloning → VM erstellen**
2. **„Updatedelta speichern & Klon erstellen"** → Dialog:
   - **„Delta-Update (inkrementell)"** — Vorgabe, so lassen (nicht „Neues Basis-Image")
   - **Version** — wird automatisch vergeben, z. B. `v2026.06.22-005`
   - **Kommentar** — knapp, was drin ist. Z. B. „Chromium 126, libssl CVE-Patch"
3. **„Updatedelta speichern & Klon erstellen"**

Das Delta dauert meist 1–5 Minuten (Schritt 1/2), danach entsteht der vollständige Klon (Schritt 2/2). Das Delta wird gegen die Vorversion gebildet, auf dem Server abgelegt und signiert, sofern ein Signing-Key existiert. Es erscheint unter **Cloning → Updates** in der **Update-Kette**.

## Schritt 5 — Pilot-Zuweisung

Zuerst auf wenige Test-Clients:

1. **Cloning → Updates** → Karte **Zuweisungen** → **„Hinzufügen"** ([06](../06-rollouts.md))
2. **Einzelne Clients** → Gruppe wählen → die 1–3 Pilot-Clients auswählen
3. **Ziel-Version**: `v2026.06.22-005`
4. Optional **„Benutzer benachrichtigen (Auto-Neustart nach Update)"** — der Client zeigt einen 15-Minuten-Countdown vor dem automatischen Neustart
5. **„Hinzufügen"** — die Zuweisung entsteht als **Entwurf**
6. In der Zeile **„Freigeben"** (Häkchen) — die Clients holen das Delta ab dem nächsten Heartbeat

Aufgeklappt zeigt die Zuweisung je Client den Status, beim Laden mit Fortschritt, Rate und Bytes. Ein fertig geladenes Update steht auf **Vorbereitet** und wird beim nächsten Herunterfahren oder Neustart des Clients angewendet; ohne Benachrichtigung markierst du die Clients dort und startest sie über **Aktionen → Neustart** neu. Warte, bis alle Pilot-Clients auf **Bestätigt** stehen — der Zusatz „vom Gerät gemeldet“ sagt, woher der Status kommt: Das Gerät meldet die Zielversion als installiert, der Server prüft das Einspielen selbst nicht.

## Schritt 6 — Pilot verifizieren

Minimum-Check-Liste:

- [ ] Clients wurden neu gestartet und sind wieder Online
- [ ] Agent läuft (`systemctl status thinforge-agent` im Terminal)
- [ ] Spalte **Installierte Version** zeigt `v2026.06.22-005`
- [ ] Nutzer-seitig keine auffälligen Fehler (Applikationen starten, Netzwerk geht, Drucker geht)
- [ ] In der Zuweisung kein Client auf **Fehlgeschlagen** oder **Signatur ungültig**

**Mindestens 24 h laufen lassen** im Pilot, bevor der Breitband-Rollout geht.

## Schritt 7 — Breite Zuweisung

Wenn Pilot sauber läuft:

1. **Cloning → Updates** → **Zuweisungen** → **„Hinzufügen"**
2. **Gruppe** wählen (z. B. „Filiale Nord", „alle Kassen")
3. **Ziel-Version**: `v2026.06.22-005`
4. Hängen Clients mehrere Versionen zurück: **„Merged-Deltas erzeugen"** — der Server erzeugt zusammengefasste Deltas im Hintergrund, die Clients warten automatisch darauf
5. Optional **„Benutzer benachrichtigen"** wie im Pilot
6. **„Hinzufügen"**, dann **„Freigeben"**

Ein Client kann nur in einer offenen Zuweisung stehen; wer noch in einer anderen steckt, wird ausgelassen. Wie viele Clients gleichzeitig laden und mit welcher Bandbreite, legen die **Bandbreiten-Einstellungen** (Zahnrad in der Update-Kette) fest.

## Schritt 8 — Fortschritt überwachen

In der Tabelle **Zuweisungen**:

- Spalte **Fortschritt** zählt bestätigte, vorbereitete, ausstehende und fehlgeschlagene Clients
- Aufgeklappte Zeile: Einzelstatus je Client — auf **Fehlgeschlagen** und **Signatur ungültig** achten

**Bei Problemen:**

- Einzelne fehlgeschlagene Clients: Ursache am Gerät prüfen (Terminal, Container-Logs [08](../08-tasks-logs.md)). Bricht ein Download ab, versucht der Server ihn bis zur eingestellten Zahl automatischer Wiederholungen erneut
- Gehäufte Fehler (> 10 % failed): Zuweisung **abbrechen** — laufende Downloads laufen aus, neue beginnen nicht mehr —, Ursache klären, bevor weitere Clients betroffen sind

## Schritt 9 — Abschluss

Sobald alle Clients einen Endstatus haben, wechselt die Zuweisung auf **Abgeschlossen**. Letzter Check:

- Abweicher in der Client-Liste über die Spalte **Installierte Version** finden und individuell nacharbeiten
- Im Tab **Clones** listet die aufgeklappte Zeile einer Version die Clients, die noch darunter liegen

## Stolperfallen

- **Delta-Sichern scheitert** → meist ist die VM nicht wirklich heruntergefahren, oder der vorherige Snapshot wurde manuell gelöscht. Die Fehlermeldung steht im Tab **VM erstellen**, Details in den Container-Logs.
- **Clients bleiben auf Ausstehend** → das Limit gleichzeitiger Downloads ist ausgeschöpft (Bandbreiten-Einstellungen), oder die Merged-Deltas werden noch erzeugt (Merge-Fortschritt in der Status-Spalte).
- **Pilot-Clients melden sich nach Reboot nicht zurück** → das Update selbst hatte einen Bug oder die Signatur passt nicht mehr. Rollback einzeln ausführen ([client-rollback.md](client-rollback.md)).

## Nächste Schritte

- [workflows/client-rollback.md](client-rollback.md) — wenn's schief ging
- [06 — Rollouts](../06-rollouts.md) — Deployment-Methoden detailliert
