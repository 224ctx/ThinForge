# Workflow — Client auf vorherige Version zurücksetzen

Wenn nach einem Update etwas nicht stimmt — einzelne Clients, eine ganze Gruppe oder ein kompletter Rollout — muss zurück auf die letzte gute Version. ThinForge unterstützt drei Rollback-Wege, abhängig vom Umfang.

## Voraussetzungen

- [ ] Der betroffene Client hat einen **Vorgänger-Clone** (wird automatisch lokal vorgehalten für eine Generation)
- [ ] Agent läuft oder Client ist per PXE bootbar

**Wichtig**: Ein Rollback geht immer nur **eine Generation** zurück. Für weiter zurückliegende Versionen → Rollout einer älteren Version statt Rollback-Funktion.

## Weg 1 — Einzelner Client

Schnell, direkt in der Detail-Seite.

1. **Clients → Client-Detail** öffnen ([03](../03-clients.md))
2. Tab **Aktionen** → **„Rollback"**
3. Bestätigungs-Dialog zeigt: *"Dieser Client wird auf `v1.003` zurückgesetzt (aktuell: `v1.004`). Fortfahren?"*
4. Bestätigen

Was passiert:
- Der Agent bekommt Boot-Modus `rollback` beim nächsten Heartbeat
- Client rebootet (automatisch oder nach manueller Einleitung)
- Rollback-Bootmodus aktiviert den vorgehaltenen Vorgänger-Snapshot
- Nach ca. 2–5 Min ist der Client wieder auf der Vorversion, Agent meldet sich

**Status verfolgen:**
- Client-Detail → Tab Historie
- Status in der Liste: Orange („Klont") → Grau („Offline") → Grün („Online")

## Weg 2 — Mehrere Clients (Bulk)

Typischer Fall: eine Handvoll Clients einer Gruppe haben Probleme, aber nicht alle.

1. **Clients-Liste** ([03](../03-clients.md))
2. Filter/Suche → die betroffenen Clients markieren (Checkbox)
3. Aktions-Leiste oben → **„Rollback"**
4. Bestätigungs-Dialog mit Liste der markierten Clients
5. Bestätigen

Führt intern für jeden Client einen Einzel-Rollback aus. Fortschritt in **Tasks** ([08](../08-tasks-logs.md#tasks)).

## Weg 3 — Kompletter Rollout rückgängig

Ein frisch ausgerollter Update hat großflächige Probleme — alle betroffenen Clients sollen gemeinsam zurück.

1. **Rollouts → Rollout-Detail** öffnen ([06](../06-rollouts.md))
2. Button **„Rollback dieses Rollouts"**
3. Bestätigungs-Dialog: *"X Clients werden auf die vor diesem Rollout installierte Version zurückgesetzt."*
4. Bestätigen

ThinForge erzeugt intern einen neuen Rollout, der für jeden betroffenen Client den Rollback durchführt. Methode wird vom ursprünglichen Rollout übernommen (Unicast/Multicast/BitTorrent).

**Vorteil**: Fortschrittsseite wie bei einem normalen Rollout. **Nachteil**: Dauert etwa so lang wie der ursprüngliche Rollout.

## Wenn der Rollback selbst scheitert

Selten, aber möglich — Rollback-Prozess hängt, Client läuft nicht mehr, Disk-Schaden.

### Option A — Rescue-Boot

1. Client-Detail → Aktionen → **„Rescue-Boot beim nächsten Start"**
2. Client neustarten (manuell am Gerät oder per Agent-Befehl)
3. Client bootet in minimale Recovery-Umgebung
4. Per Terminal auf den Client → manuell diagnostizieren (Partitionen, Snapshots, Logs)

### Option B — Neu ausrollen

Wenn Rollback nicht geht, ist der schnellste Weg oft: frischer Deploy der gewünschten Version.

1. Client-Detail → Aktionen → **„Rollout"** mit der älteren Version als Ziel-Image
2. Client rebootet in `deploy`-Modus, installiert die Version wie ein neuer Client

### Option C — Komplett neu provisionieren

Letzter Ausweg, wenn die Disk korrupt ist:

1. Client in der UI **löschen** (DB-Eintrag weg)
2. Client physisch ausschalten, PXE-Reset (im Idealfall Disk komplett wipen)
3. Aufnehmen wie einen neuen Client ([workflows/erster-client.md](erster-client.md))

## Stolperfallen

- **Button „Rollback" ist ausgegraut** → Client hat keinen Vorgänger-Snapshot (frisch installiert, oder lokaler Snapshot wurde aufgeräumt). Option B / C.
- **Nach Rollback kommt Client nicht wieder online** → Prüfen ob Agent in der alten Version korrekt läuft; ggf. neu provisionieren.
- **Rollout-Rollback erzeugt „failed" Clients** → Diese Clients hatten schon vor dem ursprünglichen Rollout ein Problem. Einzeln behandeln (Weg 1 oder Option C).

## Vorbeugung für nächste Male

- **Pilot-Phase einhalten** ([workflows/update-verteilen.md](update-verteilen.md), Schritt 5–6)
- **Nicht direkt in Breitband** — erst 1–3 Clients, 24 h laufen lassen, dann skalieren
- **Monitoring** — Alerts und Compliance-Kachel im Dashboard im Auge behalten

## Nächste Schritte

- [06 — Rollouts](../06-rollouts.md) — Wie Rollouts aufgesetzt werden
- [08 — Tasks & Logs](../08-tasks-logs.md) — Wurzelursache analysieren
