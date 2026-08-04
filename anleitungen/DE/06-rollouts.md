# 6 — Rollouts

Ein **Rollout** ist die geplante Verteilung eines Clones ([05](05-cloning.md)) an eine Menge von Clients. Rollouts sind das primäre Werkzeug für:

- Erstinstallation einer Baseline auf neuen Clients
- Updates auf bereits bespielten Clients (Delta)
- Wellenartiges Ausrollen (Pilot-Gruppe erst, Produktion danach)
- Rollbacks (alte Version wiederherstellen — siehe [workflows/client-rollback.md](workflows/client-rollback.md))

## Rollouts-Übersicht

Menü **Rollouts** zeigt alle laufenden, geplanten und abgeschlossenen Rollouts in einer Tabelle:

| Spalte | Inhalt |
|--------|--------|
| Status | draft / scheduled / active / paused / completed / cancelled |
| Name | frei vergeben |
| Ziel | Gruppe oder Client-Liste |
| Image | Clone-Version |
| Methode | unicast / multicast / bittorrent |
| Fortschritt | X / Y Clients fertig |
| Start | Geplant oder tatsächlich |

Klick auf eine Zeile öffnet die Rollout-Detailseite.

## Rollout anlegen

**„+ Neuer Rollout"** oben rechts. Der Dialog hat vier Tabs:

### Tab 1 — Basis

- **Name** — sinnvoll benennen (z. B. `2026-04-15 Security-Patch Filiale Nord`)
- **Beschreibung** — freitext

### Tab 2 — Ziel

- **Modus**: Gruppe oder Client-Liste
- Bei Gruppe: Gruppe wählen — die Aktion trifft nur die direkt zugewiesenen Clients der Gruppe (keine Untergruppen)
- Bei Liste: Clients aus Tabelle markieren (gleiche Filter-Optionen wie Client-Liste)

### Tab 3 — Image + Methode

- **Clone wählen** — aus dem Versionsbaum. Meist die aktuelle Basis oder eine frische Delta-Version
- **Deployment-Methode**:
  - **Unicast** — jeder Client lädt direkt vom Server. Einfach, funktioniert immer, bei > 50 Clients im selben LAN wird Server-Uplink zum Flaschenhals.
  - **Multicast** — Server streamt einmal im UDP-Multicast, alle Clients empfangen parallel. Super für große Rollouts im gleichen Subnetz. Nur LAN, nicht über VPN/geroutete Netze.
  - **BitTorrent** — Clients saugen den Clone als Torrent, teilen sich Bandbreite untereinander. Gut für viele Clients im selben LAN. Nur **eines** gleichzeitig wegen fester Tracker-Ports.

### Tab 4 — Zeitplan

- **Sofort starten** — Rollout beginnt nach Bestätigung
- **Geplant** — Datum/Uhrzeit setzen (z. B. 23:00 Uhr); Rollout wird vom Scheduler zum Zeitpunkt gestartet
- **Manuell starten** — Rollout im Status „draft" speichern, später manuell per Button
- **Wake-on-LAN** — nur bei einem **geplanten** Rollout aktivierbar: die Zielgeräte werden 1–60 Minuten vor dem Start automatisch per Magic-Packet eingeschaltet (PXE-Boot erforderlich). Ohne gesetzten Zeitpunkt ist die WoL-Option nicht verfügbar.

### Speichern

Abhängig von der Zeitplan-Option wird der Rollout direkt aktiv, wartet auf Scheduler, oder bleibt als Entwurf.

## Rollout-Detail

Die Detailseite zeigt:

- **Kopfleiste** — Status, Fortschritt, Aktions-Buttons (Cancel / Rollback)
- **Client-Liste mit Einzelstatus**:
  - `pending` — wartet auf Start
  - `deploying` — Client zieht und installiert gerade
  - `done` — erfolgreich, Client läuft auf neuer Version
  - `failed` — Fehler, Details in Client-Historie
  - `cancelled` — vom Operator abgebrochen
- **Live-Logs** — Backend-Logs zum Rollout (auch in Tasks / Logs sichtbar)
- **Zeitstrahl** — Events (gestartet, abgeschlossen)

## Rollout-Aktionen

### Pausieren und Fortsetzen

**Pausieren** hält den Rollout an zwei Stellen an:

- Es wird **keine weitere Stufe** gestartet. Der Button „Weiter zu Stufe X" ist im pausierten Zustand nicht verfügbar — erst **Fortsetzen** gibt ihn wieder frei.
- Vorbereitete Clients, die **noch nicht angefangen haben**, werden zurückgestellt — auch Nachzügler aus einer früheren Stufe, die diese nie durchlaufen haben: PXE-Eintrag zurück auf lokalen Start, anstehender Neustart-Auftrag verworfen, Einzelstatus zurück auf `pending`. Ohne diesen Schritt würde ein Client, der beim Start der Stufe ausgeschaltet war, beim nächsten Einschalten trotzdem klonen — auch wenn die Stufe längst wegen Fehlern pausiert wurde.

Clients, die **schon klonen**, laufen weiter. Ein laufendes Image mitten im Schreibvorgang abzubrechen würde die Platte in einem unklaren Zustand hinterlassen; ihr Ergebnis wird normal als `done` oder `failed` verbucht. Wer auch die stoppen will, nutzt **Abbrechen**.

**Fortsetzen** bereitet alle zurückgestellten Clients erneut vor (inkl. Neustart-Auftrag) und gibt „Weiter zu Stufe X" wieder frei. Clients, die die Stufe bereits abgeschlossen haben, bleiben unberührt.

### Abbrechen

Setzt den Rollout auf `cancelled`. Bereits fertig deployed Clients bleiben auf der neuen Version, laufende Installationen werden unterbrochen (Client gehen in Rescue-Modus → manueller Reboot empfohlen).

### Rollback des Rollouts

Auf der Detailseite der Button **„Rollback"** — leitet alle in diesem Rollout bereits upgedateten Clients zurück auf die Vorversion. Erzeugt einen neuen Rollout im umgekehrten Sinn. Details siehe [workflows/client-rollback.md](workflows/client-rollback.md).

## Deployment-Methoden im Vergleich

| | Unicast | Multicast | BitTorrent |
|---|---------|-----------|------------|
| Netzwerk | nur LAN | nur LAN | nur LAN |
| Skalierung | ~50 Clients | hunderte | hunderte |
| Parallel-Rollouts möglich | ja (Server-CPU limitiert) | ja (pro Subnetz) | **nein** (Tracker-Port-Konflikt) |
| Wenn einzelne Clients fehlen | unproblematisch | Client muss gleichzeitig booten | Client kann später nachziehen |
| Konfig nötig | keine | IGMP im Switch | Tracker-Port 6969 / Seed-Port 6881 frei |

## Fortschritt und Troubleshooting

- **Mehrere Clients bleiben auf `deploying` hängen** → am wahrscheinlichsten Netzwerk: Firewall blockiert Download, NFS-Export nicht erreichbar, oder der Cloner-Container ist down. Prüfe Services auf dem Dashboard ([02](02-dashboard.md)), Logs ([08](08-tasks-logs.md)).
- **`failed`-Clients** → Einzelklick auf den Client öffnet die Client-Historie mit der Fehlermeldung. Häufig: Disk zu klein, falsche Partitionstabelle, fehlgeschlagene Signaturprüfung. Korrigieren und Client per Einzel-Rollout neu ausrollen.
- **Rollout soll nur einen Teil erreichen** → auf Client-Liste statt Gruppe gehen, gezielt auswählen. Oder eine temporäre „Wellen"-Gruppe anlegen ([04](04-gruppen.md)).

## Rollouts und VPN

Die drei Verteilmethoden (Unicast, Multicast, BitTorrent) verteilen vollständige Clone-Images und laufen ausschließlich im lokalen Netz (LAN). Über das VPN werden nur **Delta-Updates** unterstützt — Clients in Homeoffice/Außenstellen erhalten Änderungen also als Delta, nicht als vollständigen Neu-Klon.

## Nächste Schritte

- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Komplett-Durchlauf: Delta-Capture → Gruppen-Rollout → Verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — Wenn's schiefgegangen ist
- [08 — Tasks & Logs](08-tasks-logs.md) — Fortschritts- und Fehleranalyse
