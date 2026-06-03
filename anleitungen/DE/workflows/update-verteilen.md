# Workflow — Update an Gruppe verteilen

Änderung am Golden-Image (Security-Patch, neue Software-Version, Config-Anpassung) → Delta-Capture → wellenweise Rollout an die Client-Flotte.

## Voraussetzungen

- [ ] Eine bestehende Clone-Kette (Baseline + evtl. schon Deltas) existiert
- [ ] Ziel-Gruppe(n) sind definiert ([04](../04-gruppen.md))
- [ ] Pilot-Gruppe mit 1–3 Test-Clients (optional aber dringend empfohlen)

## Schritt 1 — Cloning-VM starten (mit existierender Disk)

Die VM hat die Disk aus dem letzten Capture gespeichert — beim Starten „ohne ISO" wird genau diese Disk weitergenutzt.

1. **Cloning → Cloning-VM**
2. **„VM starten"** → Dialog → **keine ISO** wählen (die existierende Disk wird gebootet)
3. **VNC öffnen**

## Schritt 2 — Änderungen einspielen

In der VM:

- Security-Updates (`apt upgrade`, `pacman -Syu`, Windows Update)
- Software installieren/updaten
- Config anpassen
- Was auch immer

**Getestet im Kiosk-/Produktions-Szenario?** Bevor der Capture rausgeht, probier aus dass nichts Offensichtliches kaputt ist.

## Schritt 3 — VM herunterfahren

Sauberer Shutdown aus der VM. VM-Status geht auf „Inaktiv".

## Schritt 4 — Delta-Capture

1. **Cloning → Captures**
2. **„Save Update"** → Dialog:
   - **Version** — nächste Nummer, z. B. `v1.004` (wird meist automatisch vorgeschlagen)
   - **Kommentar** — knapp, was drin ist. Z. B. „Chromium 126, libssl CVE-Patch"
   - **„Als neue Basis"** — **nicht** aktivieren (wir wollen Delta, nicht Baseline)
3. Starten

Capture läuft 1–5 Minuten. Delta wird gegen die Vorversion gebildet, landet in `/data/deltas` und wird signiert.

## Schritt 5 — Pilot-Rollout

Zuerst auf wenige Test-Clients:

1. **Rollouts → + Neuer Rollout** ([06](../06-rollouts.md))
2. **Name**: `2026-04-15 Pilot — v1.004`
3. **Ziel**: Client-Liste → die 1–3 Pilot-Clients auswählen
4. **Image**: `v1.004`
5. **Methode**: Unicast (einfach, wenige Clients)
6. **Zeitplan**: Sofort starten
7. Speichern

Auf der Rollout-Detailseite verfolgen, bis alle Pilot-Clients `done` sind.

## Schritt 6 — Pilot verifizieren

Minimum-Check-Liste:

- [ ] Clients wurden neu gestartet und sind wieder Online
- [ ] Agent läuft (`systemctl status thinforge-agent` im Terminal)
- [ ] Version-Spalte zeigt `v1.004`
- [ ] Nutzer-seitig keine auffälligen Fehler (Applikationen starten, Netzwerk geht, Drucker geht)
- [ ] Keine Fehlerspuren in Tasks ([08](../08-tasks-logs.md))

**Mindestens 24 h laufen lassen** im Pilot, bevor der Breitband-Rollout geht.

## Schritt 7 — Breiter Rollout

Wenn Pilot sauber läuft:

1. **Rollouts → + Neuer Rollout**
2. **Name**: `2026-04-15 Breitband — v1.004`
3. **Ziel**: Gruppe (z. B. „Filiale Nord", „alle Kassen")
4. **Image**: `v1.004`
5. **Methode**:
   - **Multicast** wenn alle im gleichen LAN → schnell, bandbreiten-freundlich
   - **BitTorrent** wenn über VPN / mehrere Standorte → Clients teilen sich Daten
   - **Unicast** wenn ein paar Dutzend Clients und keine der oberen Voraussetzungen zutreffen
6. **Zeitplan**:
   - Sofort oder
   - Nachts (für Kassen-Szenarien wo Clients aus sind, aber Wake-on-LAN eingeschaltet ist)
7. Speichern

## Schritt 8 — Fortschritt überwachen

Auf der Rollout-Detailseite:

- Client-Liste mit Einzelstatus — auf `failed` achten
- Failed-Clients einzeln anklicken → Fehler-Details
- Zeitstrahl zeigt Geschwindigkeit

**Bei Problemen:**

- Einzelne fehlgeschlagene Clients: manuell nach-rollen, ggf. in Rescue-Modus → Problem lokal beheben
- Gehäufte Fehler (> 10 % failed): **Rollout pausieren**, Ursache klären, bevor weitere Clients betroffen sind

## Schritt 9 — Abschluss

Rollout wechselt auf `completed`. Letzter Check:

- Dashboard-Compliance-Kachel: sollte nahe 100 % der Zielgruppe auf `v1.004` sein
- Abweicher in der Client-Liste filtern (Status + Version-Spalte), individuell nacharbeiten

## Stolperfallen

- **Delta-Capture scheitert** → meist ist die VM nicht wirklich heruntergefahren, oder der vorherige Snapshot wurde manuell gelöscht. Tasks-Details ansehen.
- **Multicast-Rollout kommt bei Clients nicht an** → IGMP-Snooping am Switch muss aktiv sein, oder das Subnetz blockiert Multicast. Fallback auf Unicast.
- **BitTorrent-Rollout hängt** → zweiter parallel laufender BT-Rollout? Nur **einer** gleichzeitig geht.
- **Pilot-Clients melden sich nach Reboot nicht zurück** → Agent-Update selbst hatte einen Bug oder die Signatur passt nicht mehr. Rollback einzeln ausführen ([client-rollback.md](client-rollback.md)).

## Nächste Schritte

- [workflows/client-rollback.md](client-rollback.md) — wenn's schief ging
- [06 — Rollouts](../06-rollouts.md) — Deployment-Methoden detailliert
