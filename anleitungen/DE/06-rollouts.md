# 6 — Rollouts

Ein **Rollout** ist die Verteilung eines Clones ([05](05-cloning.md)) an eine Menge von Clients. ThinForge macht das über **Cloning → Deployments**: Erstinstallation oder Neu-Klon einer Gruppe, mehrerer Gruppen oder einzelner Clients, per Unicast, Multicast oder BitTorrent, sofort oder zu einem Termin — das vollständige Image wird per PXE neu aufgespielt. Ein wellenartiges Ausrollen (Pilotgruppe erst, Produktion danach) planst du mit mehreren Deployments, etwa je Gruppe oder zu gestaffelten Terminen. Die frühere eigene Funktion „Gestaffelter Rollout" ist seit 2026-10-01 entfallen.

Delta-Updates für bereits bespielte Clients verteilst du unter **Cloning → Updates** ([workflows/update-verteilen.md](workflows/update-verteilen.md)), Rollbacks unter **Cloning → Rollback** ([workflows/client-rollback.md](workflows/client-rollback.md)).

## Deployments

**Cloning → Deployments** listet alle Clone-Deployments in einer Tabelle:

| Spalte | Inhalt |
|--------|--------|
| Modus | UC (Unicast) / MC (Multicast) / BT (BitTorrent) |
| Clone | Name des Clones |
| Gruppe | Zielgruppe |
| Status | Geplant (mit Uhrzeit) / Aktiv / Abgeschlossen / Mit Fehlern abgeschlossen / Abgebrochen; bei BitTorrent vorab „Vorbereitung…" |
| Fortschritt | X / Y Clients fertig |
| Erstellt am | Anlagezeitpunkt |

Klick auf den Pfeil einer Zeile klappt die Clients mit Einzelstatus (Ausstehend, Wird geklont, Fertig, Fehlgeschlagen, Abgebrochen), BitTorrent-Fortschritt und Fehlermeldung auf.

## Deployment anlegen

**„Neues Deployment"** oben rechts öffnet den Dialog:

### Ziel

- **Gruppe**, **Mehrere Gruppen** oder **Einzelne Clients** — zur Wahl stehen nur Gruppen mit Clients
- Bei Gruppen: die Aktion trifft nur die direkt zugewiesenen Clients der Gruppe (keine Untergruppen)
- Bei einzelnen Clients: erst eine Gruppe wählen, dann Clients daraus markieren

### Clone und Modus

- **Clone auswählen** — vorbelegt mit dem neuesten Clone
- **Modus**:
  - **Unicast** — jeder Client stellt das Image einzeln per NFS vom Server wieder her. Einfach, funktioniert immer, bei > 50 Clients im selben LAN wird Server-Uplink zum Flaschenhals.
  - **Multicast** — Server streamt einmal im UDP-Multicast, alle Clients empfangen parallel. Super für große Rollouts im gleichen Subnetz. Nur LAN, nicht über VPN/geroutete Netze. Es läuft immer nur **ein** aktives Multicast-Deployment; für mehrere Gruppen mit demselben Image **Mehrere Gruppen** wählen. Ein Deployment mit dieser Methode anzulegen und zu starten ist Operator-Arbeit; die globalen **Multicast-Einstellungen** (Zahnrad-Symbol: Wartezeit 30–3600 s, Abschluss-Timeout 30–1800 s — Clients, die sich nach dem Ende der Übertragung nicht innerhalb dieses Timeouts melden, gelten als fehlgeschlagen und starten danach wieder lokal) darf seit 2026-08-31 nur ein Admin speichern, weil sie alle künftigen Deployments betreffen.
  - **BT Multi-Deploy** (Vorgabe) — Clients saugen den Clone als Torrent, teilen sich Bandbreite untereinander. Gut für viele Clients im selben LAN. Mehrere BitTorrent-Deployments können parallel laufen, auch mit unterschiedlichen Clones.
- **Nach Deploy** — Neustart (Vorgabe), Herunterfahren oder Nichts

### Zeitpunkt

- **Ohne Termin** — das Deployment startet sofort. **„Online-Geräte jetzt neu starten"** (Vorgabe an) startet online gemeldete Clients per SSH in die Bereitstellung, bei BitTorrent erst, sobald der Seeder die Torrents bereitgestellt hat; ausgeschaltete starten beim nächsten Einschalten hinein.
- **Geplanter Start** — Datum und Uhrzeit setzen (z. B. 23:00 Uhr), gemeint in der Server-Zeitzone ([09](09-einstellungen.md)); der Scheduler aktiviert das Deployment eine Minute vor dem Termin, bei BitTorrent startet der Seeder schon zehn Minuten vorher. Ein Datum ohne Uhrzeit sperrt das Anlegen. **„Online-Geräte zum Termin neu starten"** (Vorgabe an) startet mit der Aktivierung die dann online gemeldeten Clients per SSH in die Bereitstellung (bei BitTorrent, sobald die Torrents bereitstehen); startet das Deployment mehr als 15 Minuten nach dem Termin — etwa weil der Server aus war —, wird nicht mehr neu gestartet.
- **Wake-on-LAN beim Start senden** — nur bei einem **geplanten** Deployment aktivierbar: die Zielgeräte bekommen zum geplanten Zeitpunkt ein Magic-Packet, die Aktivierung (PXE, NFS, DHCP) läuft eine Minute vorher, bei BitTorrent startet der Seeder zehn Minuten vorher (PXE-Boot erforderlich). Ohne gesetzten Zeitpunkt ist die WoL-Option nicht verfügbar.

### Deployen

**„Deployen"** legt das Deployment an. Hängt ein Zielclient schon in einem laufenden Deployment oder ist er für eine Aufnahme vorbereitet ([05 — Captures](05-cloning.md#tab-captures)), lehnt der Server ab.

In der Liste bricht **Abbrechen** ein aktives oder geplantes Deployment ab. Nach dem Ende startet **Fehlgeschlagene/abgebrochene neu starten** die fehlgeschlagenen und abgebrochenen Clients erneut, in der aufgeklappten Zeile **Neu starten** einen einzelnen (nicht bei Multicast) — war beim Anlegen „Online-Geräte jetzt neu starten" an, starten online gemeldete Clients dabei gleich per SSH in die Bereitstellung (bei BitTorrent, sobald die Torrents bereitstehen); **Löschen** entfernt ein beendetes Deployment.

## Deployment-Methoden im Vergleich

| | Unicast | Multicast | BitTorrent |
|---|---------|-----------|------------|
| Netzwerk | nur LAN | nur LAN | nur LAN |
| Skalierung | ~50 Clients | hunderte | hunderte |
| Parallel-Deployments möglich | ja (Server-CPU limitiert) | **nein** (nur ein aktives Multicast-Deployment) | ja (ein Seeder für mehrere Torrents) |
| Wenn einzelne Clients fehlen | unproblematisch | Client muss gleichzeitig booten | Client kann später nachziehen |
| Konfig nötig | keine | IGMP im Switch | Tracker-Port 6969 / Seed-Port 6881 frei |

## Fortschritt und Troubleshooting

- **Start scheitert mit „Die NFS-Freigabe für das Deployment ließ sich nicht aktivieren"** → `exportfs` im `nfs-server`-Container ist gescheitert; es wurde kein Gerät vorbereitet. Den Dienst `nfs-server` auf dem Dashboard prüfen ([02](02-dashboard.md)) und das Deployment neu starten. Ein geplantes Deployment versucht es jede Minute erneut.
- **Geplantes Multicast-Deployment steht auf „Abgebrochen“**, jeder Client mit „Termin nicht gestartet: zur selben Zeit lief das Multicast-Deployment …“ → zum Termin lief schon ein anderes Multicast-Deployment, und es kann nur eines gleichzeitig laufen. Das Deployment neu planen, wenn das andere fertig ist.
- **Mehrere Clients bleiben auf `deploying` hängen** → am wahrscheinlichsten Netzwerk: Firewall blockiert Download, NFS-Export nicht erreichbar, oder NFS-Server, Multicast-Sender bzw. BitTorrent-Seeder laufen nicht. Prüfe Services auf dem Dashboard ([02](02-dashboard.md)), Logs ([08](08-tasks-logs.md)).
- **`failed`-Clients** → unter **Cloning → Deployments** zeigt die aufgeklappte Zeile die Fehlermeldung je Client. Häufig: Disk zu klein, falsche Partitionstabelle, fehlgeschlagene Signaturprüfung. Korrigieren und den Client erneut ausrollen.
- **Rollout soll nur einen Teil erreichen** → im Deployment **Einzelne Clients** statt Gruppe wählen und gezielt auswählen. Oder eine temporäre „Wellen"-Gruppe anlegen ([04](04-gruppen.md)) und die Gruppen nacheinander deployen.

## Rollouts und VPN

Die drei Verteilmethoden (Unicast, Multicast, BitTorrent) verteilen vollständige Clone-Images und laufen ausschließlich im lokalen Netz (LAN). Über das VPN werden nur **Delta-Updates** unterstützt — Clients in Homeoffice/Außenstellen erhalten Änderungen also als Delta, nicht als vollständigen Neu-Klon.

**Warndialog „Betroffene VPN-Clients":** Sind unter den Zielen eines Deployments Geräte, die im VPN aktiviert sind, zeigt ThinForge sie vor dem Anlegen in einem Dialog (mit CSV-Export). Eingelagerte Geräte stehen mit drin — ein Klon-Deployment bespielt auch sie. Das Neu-Klonen löscht die VPN-Konfiguration auf dem Gerät; bei eingerichteter VPN-Verbindung setzt ThinForge die Zuordnung beim Start des Klonvorgangs selbst zurück und stellt einen neuen Aktivierungs-Schlüssel aus — die Geräte melden sich danach von selbst wieder an, der Dialog dient nur der Nachverfolgung. Ist die Verbindung zur VPN-Instanz gelöst, geht das nicht: die Geräte müssen nach dem Wiederverbinden von Hand neu aktiviert werden. Nur in diesem Fall bietet der Dialog an, die verwaisten VPN-Zuordnungen aus der Datenbank zu entfernen (die Geräte geben ihre Plätze im Abonnement frei und legen ihren VPN-Dienst still; ihre Zugänge auf der VPN-Instanz bleiben dort bestehen). Mehr in [13 — VPN](13-vpn.md).

## Nächste Schritte

- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Komplett-Durchlauf: Delta-Capture → Gruppen-Rollout → Verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — Wenn's schiefgegangen ist
- [08 — Tasks & Logs](08-tasks-logs.md) — Fortschritts- und Fehleranalyse
