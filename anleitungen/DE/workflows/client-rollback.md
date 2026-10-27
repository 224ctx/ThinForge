# Workflow — Client auf vorherige Version zurücksetzen

Wenn nach einem Update etwas nicht stimmt — einzelne Clients oder eine ganze Gruppe — muss zurück auf die letzte gute Version. ThinForge macht das über eine **Rollback-Zuweisung** unter **Cloning → Rollback**, wahlweise für eine Gruppe oder für einzelne Clients.

## Voraussetzungen

- [ ] Der betroffene Client hat einen **Vorgänger-Snapshot** (der Agent hält nach einem Update die vorige Generation lokal vor und meldet seine Snapshots per Heartbeat)
- [ ] Agent läuft und meldet sich per Heartbeat

**Wichtig**: Ein Rollback geht immer nur **eine Generation** zurück — der Agent wechselt auf den neuesten Snapshot unterhalb der laufenden Version. Für weiter zurückliegende Versionen → Deployment einer älteren Version (**Cloning → Deployments**, [06](../06-rollouts.md)) statt Rollback-Funktion.

## Rollback anlegen

1. **Cloning → Rollback** → **„Rollback erstellen"**
2. Dialog **Rollback-Zuweisung erstellen**:
   - **Gruppe** — die Clients einer Gruppe, oder **Einzelne Clients** — erst Gruppe wählen, dann die betroffenen Clients markieren
   - **Rollback-Ziel** — zur Wahl steht je Client das Ziel, das ein Rollback tatsächlich erreicht: der neueste Snapshot unterhalb seiner laufenden Version. Snapshots neuerer Versionen (etwa nach einem früheren Rollback liegengeblieben) sind kein Ziel. Laufen die Clients auf verschiedenen Versionen, stehen ihre Ziele nebeneinander zur Wahl; die Zuweisung nimmt nur die Clients auf, die das gewählte Ziel erreichen — der Hinweis unter dem Feld nennt, wie viele es sind
   - **Version als defekt markieren** (Vorgabe an) — siehe unten; abwählen, wenn die aktuelle Version weiter benutzbar bleiben soll (z. B. weil sie nur versehentlich ausgerollt wurde)
3. **„Rollback erstellen"**

### Version als defekt markieren

Mit dem Häkchen gilt die Version, auf der die ausgewählten Clients gerade laufen, als **defekt**:

- laufende und geplante Update-Zuweisungen auf diese Version werden abgebrochen, ihre Downloads gestoppt
- in **Clones** und in der Update-Kette trägt die Version das rote Kennzeichen **Defekt** und lässt sich nicht mehr als Ziel wählen
- ihr Snapshot wird auf den Clients entfernt — auf den zurückgerollten erst, wenn ihr Rollback bestätigt ist

Die Markierung bleibt bestehen, auch wenn die Rollback-Zuweisung später abgebrochen oder gelöscht wird.

## Was passiert

- Mit dem nächsten Heartbeat erhält der Agent die Rollback-Vormerkung, legt sie lokal ab und meldet **vorbereitet**
- Der eigentliche Wechsel passiert **beim nächsten Herunterfahren oder Neustart** des Clients: der Agent tauscht auf den nächstälteren Snapshot und stellt den Bootloader darauf ein
- Einen automatischen Neustart gibt es nicht. Die Karte **Client-Status** unter den Zuweisungen listet die noch offenen Clients; dort markieren und über **Aktionen → Neustart** (oder **Herunterfahren**) auslösen
- Nach dem Neustart meldet der Agent die ältere Version, der Client steht auf **erledigt**; sind alle Clients erledigt, wechselt die Zuweisung auf **Erledigt**
- Landet ein Client dabei auf einer anderen als der gewählten Version (etwa weil ein Snapshot nach seiner letzten Meldung gelöscht wurde), steht er nicht auf erledigt, sondern auf **Ziel verfehlt** mit dem Zusatz „erreicht … statt …“; die Zuweisung zeigt davor ein Warnsymbol, und das Audit-Log hält es fest (**„Rollback hat das erwartete Ziel verfehlt"**). Auch so ein Client gilt als abgeschlossen — er rollt nicht noch einmal zurück

**Status verfolgen:** Die Tabelle der Rollback-Zuweisungen zeigt **Gruppe / Clients**, **Version** (das Rollback-Ziel), **Status** (Aktiv, Erledigt, Abgebrochen) und **Fortschritt** (erledigt / Ziel verfehlt / vorbereitet / ausstehend); aufgeklappt je Client Hostname, Inventarnummer, MAC-Adresse, Version und Status. Solange eine Zuweisung aktiv ist, aktualisiert sich die Ansicht alle 30 Sekunden.

## Abbrechen und löschen

- **Abbrechen** (nur bei aktiver Zuweisung) — noch nicht zurückgerollte Clients verlieren die Vormerkung; bereits zurückgerollte bleiben auf der älteren Version
- **Löschen** — entfernt die Zuweisung, mit derselben Wirkung auf offene Clients

Die Defekt-Markierung nehmen beide nicht zurück.

Anlegen, Abbrechen und Löschen stehen im Audit-Log (**„Rollback-Zuweisung angelegt"**, **„Rollback-Zuweisung abgebrochen"**, **„Rollback-Zuweisung gelöscht"**) — mit Benutzer, Absender-IP und Rollback-Ziel; beim Anlegen auch mit den aufgenommenen Clients und den als defekt markierten Versionen, beim Abbrechen und Löschen mit der Zahl der Clients, die ihre Vormerkung verloren haben.

## Wenn der Rollback selbst scheitert

Selten, aber möglich — Client bleibt auf „vorbereitet", läuft nicht mehr, Disk-Schaden.

### Option A — Neu ausrollen

Wenn Rollback nicht geht, ist der schnellste Weg oft: frischer Deploy der gewünschten Version.

1. **Cloning → Deployments** → **„Neues Deployment"** → **Einzelne Clients** → den Client wählen, als Clone die ältere Version ([06](../06-rollouts.md))
2. Client bootet per PXE in den Deploy und installiert die Version wie ein neuer Client

### Option B — Komplett neu provisionieren

Letzter Ausweg, wenn die Disk korrupt ist:

1. Client in der UI **löschen** (DB-Eintrag weg)
2. Client physisch ausschalten (im Idealfall Disk komplett wipen)
3. Aufnehmen wie einen neuen Client ([workflows/erster-client.md](erster-client.md))

## Stolperfallen

- **Rollback-Ziel-Liste bleibt leer („Kein Client der Auswahl hat einen älteren Snapshot unterhalb seiner laufenden Version")** → die Clients melden keinen älteren Snapshot (etwa weil lokale Snapshots aufgeräumt wurden) oder noch keine laufende Version. Option A / B.
- **„Kein Client der Auswahl erreicht dieses Rollback-Ziel" bzw. „… würden das Rollback-Ziel … nicht erreichen"** → ein Client hat seit dem Öffnen des Dialogs neue Snapshots gemeldet. Dialog schließen, neu öffnen und das Ziel neu wählen.
- **Client steht auf „Ziel verfehlt"** → er ist zurückgerollt, aber auf eine andere Version als gewählt (der Zusatz nennt beide). Ist die erreichte Version nicht brauchbar: eine neue Rollback-Zuweisung mit dem dann angebotenen Ziel anlegen oder die gewünschte Version neu ausrollen (Option A oben).
- **Client bleibt auf „vorbereitet"** → er wurde noch nicht heruntergefahren oder neu gestartet (Karte **Client-Status** → **Aktionen → Neustart**). Scheitert der Wechsel beim Herunterfahren, bleibt die Vormerkung auf dem Gerät, und der nächste Neustart versucht es erneut.
- **Nach Rollback kommt Client nicht wieder online** → Prüfen ob Agent in der alten Version korrekt läuft; ggf. neu provisionieren.

## Vorbeugung für nächste Male

- **Pilot-Phase einhalten** ([workflows/update-verteilen.md](update-verteilen.md), Schritt 5–6)
- **Nicht direkt in Breitband** — erst 1–3 Clients, 24 h laufen lassen, dann skalieren
- **Monitoring** — Alerts im Dashboard im Auge behalten; die Benachrichtigung **Versions-Abweichung** meldet Clients, deren installierter Clone nicht dem für ihre Gruppe erwarteten entspricht ([09](../09-einstellungen.md))

## Nächste Schritte

- [06 — Rollouts](../06-rollouts.md) — Wie Rollouts aufgesetzt werden
- [08 — Tasks & Logs](../08-tasks-logs.md) — Wurzelursache analysieren
