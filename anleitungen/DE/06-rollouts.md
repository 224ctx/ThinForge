# 6 — Rollouts

Ein **Rollout** ist die Verteilung eines Clones ([05](05-cloning.md)) an eine Menge von Clients. ThinForge kennt dafür zwei Wege; beide spielen das vollständige Image per PXE neu auf:

- **Cloning → Deployments** — Erstinstallation oder Neu-Klon einer Gruppe, mehrerer Gruppen oder einzelner Clients, per Unicast, Multicast oder BitTorrent, sofort oder zu einem Termin
- **Gestaffelter Rollout** — wellenartiges Ausrollen eines Images (Pilot-Anteil erst, Produktion danach) mit Fehlerschwelle je Stufe

Delta-Updates für bereits bespielte Clients verteilst du unter **Cloning → Updates** ([workflows/update-verteilen.md](workflows/update-verteilen.md)), Rollbacks unter **Cloning → Rollback** ([workflows/client-rollback.md](workflows/client-rollback.md)).

## Deployments

**Cloning → Deployments** listet alle Clone-Deployments in einer Tabelle:

| Spalte | Inhalt |
|--------|--------|
| Modus | UC (Unicast) / MC (Multicast) / BT (BitTorrent) |
| Clone | Name des Clones |
| Gruppe | Zielgruppe |
| Status | Geplant (mit Uhrzeit) / Aktiv / Pausiert / Abgeschlossen / Mit Fehlern abgeschlossen / Abgebrochen; bei BitTorrent vorab „Vorbereitung…" |
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
  - **Multicast** — Server streamt einmal im UDP-Multicast, alle Clients empfangen parallel. Super für große Rollouts im gleichen Subnetz. Nur LAN, nicht über VPN/geroutete Netze. Es läuft immer nur **ein** aktives Multicast-Deployment; für mehrere Gruppen mit demselben Image **Mehrere Gruppen** wählen. Ein Deployment mit dieser Methode anzulegen und zu starten ist Operator-Arbeit; die globalen **Multicast-Einstellungen** (Zahnrad-Symbol: Wartezeit 30–3600 s, Abschluss-Timeout 30–1800 s) darf seit 2026-08-31 nur ein Admin speichern, weil sie alle künftigen Deployments betreffen.
  - **BT Multi-Deploy** (Vorgabe) — Clients saugen den Clone als Torrent, teilen sich Bandbreite untereinander. Gut für viele Clients im selben LAN. Mehrere BitTorrent-Deployments können parallel laufen, auch mit unterschiedlichen Clones.
- **Nach Deploy** — Neustart (Vorgabe), Herunterfahren oder Nichts

### Zeitpunkt

- **Ohne Termin** — das Deployment startet sofort. **„Online-Geräte jetzt neu starten"** (Vorgabe an) startet online gemeldete Clients per SSH in die Bereitstellung, bei BitTorrent erst, sobald der Seeder die Torrents bereitgestellt hat; ausgeschaltete starten beim nächsten Einschalten hinein.
- **Geplanter Start** — Datum und Uhrzeit setzen (z. B. 23:00 Uhr), gemeint in der Server-Zeitzone ([09](09-einstellungen.md)); der Scheduler startet das Deployment zum Zeitpunkt. Ein Datum ohne Uhrzeit sperrt das Anlegen.
- **Wake-on-LAN beim Start senden** — nur bei einem **geplanten** Deployment aktivierbar: die Zielgeräte bekommen zum geplanten Zeitpunkt ein Magic-Packet, die Aktivierung (PXE, NFS, DHCP) läuft eine Minute vorher, bei BitTorrent startet der Seeder zehn Minuten vorher (PXE-Boot erforderlich). Ohne gesetzten Zeitpunkt ist die WoL-Option nicht verfügbar.

### Deployen

**„Deployen"** legt das Deployment an. Hängt ein Zielclient schon in einem laufenden Deployment, lehnt der Server ab.

In der Liste bricht **Abbrechen** ein aktives oder geplantes Deployment ab. Nach dem Ende startet **Fehlgeschlagene neu starten** die fehlgeschlagenen und abgebrochenen Clients erneut, in der aufgeklappten Zeile **Neu starten** einen einzelnen (nicht bei Multicast); **Löschen** entfernt ein beendetes Deployment.

## Gestaffelter Rollout

Die Ansicht **Gestaffelter Rollout** hat keinen eigenen Menüeintrag. Du erreichst sie über die Dashboard-Kachel **Aktive Rollouts** („Alle anzeigen", nur solange ein Rollout aktiv oder pausiert ist) oder direkt unter `/rollouts`.

### Rollouts-Übersicht

| Spalte | Inhalt |
|--------|--------|
| Name | frei vergeben |
| Image | Name des Images |
| Status | Entwurf / Aktiv / Pausiert / Abgeschlossen / Abgebrochen |
| Fortschritt | aktuelle Stufe (z. B. „Stufe 2 / 3") mit Balken der fertigen Clients dieser Stufe |
| Gestartet | Startzeitpunkt |

Klick auf eine Zeile klappt den **Stufenfortschritt** (fertig / gesamt, Fehler, aktive Clients je Stufe) und die **Clients** mit Hostname, MAC, Stufe, Status und Abschlusszeit auf. Einzelstatus:

- `pending` (Ausstehend) — wartet auf seine Stufe
- `deploying` (Wird deployed) — Stufe scharfgeschaltet, Client zieht und installiert
- `done` (Fertig) — erfolgreich, Client läuft auf neuer Version
- `failed` (Fehler) — Klonen fehlgeschlagen
- `cancelled` (Abgebrochen) — vom Operator abgebrochen

### Rollout anlegen

**„Neuer Rollout"** oben rechts öffnet den Dialog:

- **Rollout-Name** — sinnvoll benennen (z. B. `2026-04-15 Security-Patch Filiale Nord`)
- **Image** — zur Wahl stehen die bereitstehenden Images, also die unter **Cloning → Captures** importierten Captures ([05](05-cloning.md#tab-captures))
- **Stufen (kumulierte %)** — kommagetrennt, streng aufsteigend, der letzte Wert muss 100 sein; Vorgabe `10,50,100`
- **Geltungsbereich** — **Alle Clients** oder **Gruppe** (dann Gruppe wählen; es zählen nur die direkt zugewiesenen Clients, keine Untergruppen)
- **Bei Fehlern stoppen** (Vorgabe an) mit **Fehlerschwelle (%)** (Vorgabe 20)

**„Speichern"** legt den Rollout als **Entwurf** an. Ein Entwurf lässt sich bearbeiten (Name, Stufen, Fehlerregel) oder löschen. Jede Stufe spielt das Image per **Unicast** auf und stößt für ihre Clients einen Neustart an; nach dem Klonen starten die Clients neu.

## Rollout-Aktionen

### Starten und Weiterschalten

- **Starten** (Raketen-Symbol, nur im Entwurf) — prüft, ob der NFS-Server läuft (und bietet sonst an, ihn zu starten), sammelt die Clients im Geltungsbereich ein, verteilt sie zufällig auf die Stufen und schaltet die erste Stufe scharf: PXE-Deploy-Eintrag plus Neustart-Auftrag. Clients ohne zugewiesene IP-Adresse oder in einem anderen laufenden Deployment überspringt die Stufe.
- **Weiter zu Stufe X** — schaltet die nächste Stufe scharf; auf der letzten Stufe heißt der Knopf **Abschließen** und setzt den Rollout auf `completed`. Mit **Bei Fehlern stoppen** verweigert der Server das Weiterschalten, sobald der Anteil fehlgeschlagener an den schon fertigen Clients der laufenden Stufe die Fehlerschwelle erreicht.

### Pausieren und Fortsetzen

**Pausieren** hält den Rollout an zwei Stellen an:

- Es wird **keine weitere Stufe** gestartet. Der Button „Weiter zu Stufe X" ist im pausierten Zustand nicht verfügbar — erst **Fortsetzen** gibt ihn wieder frei.
- Vorbereitete Clients, die **noch nicht angefangen haben**, werden zurückgestellt — auch Nachzügler aus einer früheren Stufe, die diese nie durchlaufen haben: PXE-Eintrag zurück auf lokalen Start, anstehender Neustart-Auftrag verworfen, Einzelstatus zurück auf `pending`. Ohne diesen Schritt würde ein Client, der beim Start der Stufe ausgeschaltet war, beim nächsten Einschalten trotzdem klonen — auch wenn die Stufe längst wegen Fehlern pausiert wurde.

Clients, die **schon klonen**, laufen weiter. Ein laufendes Image mitten im Schreibvorgang abzubrechen würde die Platte in einem unklaren Zustand hinterlassen; ihr Ergebnis wird normal als `done` oder `failed` verbucht. Auch **Abbrechen** stoppt sie nicht.

**Fortsetzen** bereitet alle zurückgestellten Clients erneut vor (inkl. Neustart-Auftrag) und gibt „Weiter zu Stufe X" wieder frei. Clients, die die Stufe bereits abgeschlossen haben, bleiben unberührt.

### Abbrechen

Setzt den Rollout nach Rückfrage auf `cancelled`. Bereits fertig deployte Clients bleiben auf der neuen Version. Vorbereitete Clients, die noch nicht angefangen haben, werden wie beim Pausieren entschärft, ihr Einzelstatus geht auf `cancelled`. Clients, die schon klonen, laufen zu Ende und melden ihr Ergebnis regulär zurück.

Abgeschlossene und abgebrochene Rollouts lassen sich löschen.

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
- **Mehrere Clients bleiben auf `deploying` hängen** → am wahrscheinlichsten Netzwerk: Firewall blockiert Download, NFS-Export nicht erreichbar, oder NFS-Server, Multicast-Sender bzw. BitTorrent-Seeder laufen nicht. Prüfe Services auf dem Dashboard ([02](02-dashboard.md)), Logs ([08](08-tasks-logs.md)).
- **`failed`-Clients** → unter **Cloning → Deployments** zeigt die aufgeklappte Zeile die Fehlermeldung je Client; die Stufen eines gestaffelten Rollouts erscheinen dort als eigene Unicast-Deployments. Häufig: Disk zu klein, falsche Partitionstabelle, fehlgeschlagene Signaturprüfung. Korrigieren und den Client erneut ausrollen.
- **Rollout soll nur einen Teil erreichen** → im Deployment **Einzelne Clients** statt Gruppe wählen und gezielt auswählen. Oder eine temporäre „Wellen"-Gruppe anlegen ([04](04-gruppen.md)).

## Rollouts und VPN

Die drei Verteilmethoden (Unicast, Multicast, BitTorrent) verteilen vollständige Clone-Images und laufen ausschließlich im lokalen Netz (LAN). Über das VPN werden nur **Delta-Updates** unterstützt — Clients in Homeoffice/Außenstellen erhalten Änderungen also als Delta, nicht als vollständigen Neu-Klon.

**Warndialog „Betroffene VPN-Clients":** Sind unter den Zielen eines Deployments oder Rollouts Geräte, die im VPN aktiviert sind, zeigt ThinForge sie vor dem Anlegen in einem Dialog (mit CSV-Export). Das Neu-Klonen löscht die VPN-Konfiguration auf dem Gerät; bei eingerichteter VPN-Verbindung setzt ThinForge die Zuordnung beim Start des Klonvorgangs selbst zurück und stellt einen neuen Aktivierungs-Schlüssel aus — die Geräte melden sich danach von selbst wieder an, der Dialog dient nur der Nachverfolgung. Ist die Verbindung zur VPN-Instanz gelöst, geht das nicht: die Geräte müssen nach dem Wiederverbinden von Hand neu aktiviert werden. Nur in diesem Fall bietet der Dialog an, die verwaisten VPN-Zuordnungen aus der Datenbank zu entfernen (die Geräte geben ihre Lizenzplätze frei und legen ihren VPN-Dienst still; ihre Zugänge auf der VPN-Instanz bleiben dort bestehen). Mehr in [13 — VPN](13-vpn.md).

## Nächste Schritte

- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Komplett-Durchlauf: Delta-Capture → Gruppen-Rollout → Verify
- [workflows/client-rollback.md](workflows/client-rollback.md) — Wenn's schiefgegangen ist
- [08 — Tasks & Logs](08-tasks-logs.md) — Fortschritts- und Fehleranalyse
