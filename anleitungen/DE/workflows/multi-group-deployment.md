# Workflow: Ein Image an mehrere Gruppen gleichzeitig ausrollen

Seit dem 2026-04-22-Release unterstützt ThinForge **Multi-Group-Deployments**: ein einziges Deployment-Objekt kann mehrere Gruppen bedienen, und dank des Service-Mode-BitTorrent-Seeders laufen sogar **mehrere Deployments parallel** — auch an verschiedene Gruppen mit verschiedenen Clones. Dieser Workflow zeigt, wie man das in der Praxis nutzt.

## Wann was?

| Szenario | Empfohlener Modus |
|---|---|
| Gleicher Clone → mehrere Gruppen, gleichzeitig, im lokalen Netz | **Multicast mit Target-Mode „Mehrere Gruppen"** — streamt einmal über die Leitung, alle Clients empfangen parallel. |
| Gleicher Clone → mehrere Gruppen, verschiedene Subnetze im lokalen Netz | **BitTorrent** — Peer-Assist, Cache-Sharing zwischen Deployments. Außenstellen über VPN erreicht kein Clone-Deployment — dort nur Delta-Updates ([06](../06-rollouts.md#rollouts-und-vpn)). |
| Verschiedene Clones → verschiedene Gruppen, alles gleichzeitig | **BitTorrent** pro Deployment. Multicast kann nur **einmal** gleichzeitig laufen (Protokoll-Limit), BitTorrent parallelisiert. |
| Nur wenige Ziele, kein Multicast-fähiges Netz | **Unicast** — direkter Download pro Client. |

## Multi-Group per Multicast

1. Menü **Cloning** → Tab **Deployments** → **Neues Deployment**.
2. Ziel → **Mehrere Gruppen**.
3. Unter **Gruppen auswählen** die gewünschten Gruppen anhaken. Der Hinweis unten nennt, wie viele Clients aus wie vielen Gruppen das Deployment trifft.
4. **Clone auswählen**.
5. **Modus** → `Multicast`.
6. Optional: **Geplanter Start** + **Wake-on-LAN beim Start senden** (das Magic-Packet geht zum geplanten Zeitpunkt raus, die Aktivierung läuft eine Minute vorher).
7. **Deployen**.

Alle Clients aller Gruppen stehen in einer einzigen Deployment-Zeile. Der Server wartet, bis alle Teilnehmer den PXE-Boot abgeschlossen haben — höchstens die **Wartezeit** aus den Multicast-Einstellungen, danach startet er mit den bereiten Clients —, streamt dann das Image **einmal** und versorgt damit sämtliche Gruppen gleichzeitig.

**Gotcha:** Zweites gleichzeitiges Multicast-Deployment geht nicht — Address `224.0.0.1:2232` ist statisch. Der Server lehnt ein zweites aktives Multicast-Deployment ab.

## Parallele Deployments per BitTorrent

BitTorrent läuft seit 2026-04-22 als **Service-Mode**: ein einziger `thinforge-bt-seeder-service`-Container hostet beliebig viele Clone-Torrents parallel und fährt sich automatisch runter, sobald das letzte Deployment fertig ist.

Vorteile aus Operator-Sicht:

- **Kein `Mode-Conflict`** mehr bei BT. Zweites Deployment mit anderem Clone an andere Gruppe einfach anlegen.
- **Slice-Cache pro Clone** — der zweite Rollout desselben Clones spart sich die teure Partclone-Extraktion, die neuen Clients landen im selben Swarm wie die bereits laufenden.
- **Auto-Stop** bei Idle — Tracker-Port 6969 und Seed-Port 6881 sind außerhalb aktiver Rollouts geschlossen.

Workflow:

1. Deployment 1 anlegen: Gruppe Marketing, Clone `marketing-v2026.06.22-006`, Modus BitTorrent.
2. Deployment 2 anlegen: Gruppe Sales, Clone `sales-v2026.06.22-003`, Modus BitTorrent.
3. Beide Deployments starten parallel — Seeder bootet einmal, hostet beide Torrents.
4. Wenn Deployment 1 fertig ist: Torrent 1 wird unregistered, Seeder bleibt für Deployment 2.
5. Wenn auch Deployment 2 fertig: Container wird automatisch entfernt.

## Monitoring während des Rollouts

Tabelle im Deployments-Tab:

- **Multicast** — Chip zeigt „N/M bereit" mit Restzeit (M:SS) während der Bereitschaftsphase, dann die gerade gesendete Partition (bzw. „Sende...") während des Streams, schließlich „Gesendet".
- **BitTorrent** — der Status steht zunächst auf „Vorbereitung…", ein Chip zeigt die Schritte („Seeder startet...", „Extrahiere...", „Erstelle Torrents...", „Starte Tracker..."), dann „Seeding (N Part.)", schließlich „Abgeschlossen". In der aufgeklappten Zeile siehst du pro Client die Partition, die gerade geschrieben wird, plus Prozent-Bar.
- Pro Client-Zeile: Ausstehend / Wird geklont / Fertig / Fehlgeschlagen / Abgebrochen; bei fehlgeschlagenen oder abgebrochenen Clients unter BitTorrent/Unicast auch **Neu starten** (nicht bei Multicast — dort hat ein Restart keinen Sinn, weil der Stream bereits weg ist).

## Fehlerbehandlung

- Ein Client meldet `failed` → Zeile aufklappen, **Neu starten**; Backend versucht den einzelnen Client erneut.
- Gesamt-Deployment hängt → **Abbrechen** setzt Status auf „Abgebrochen"; ggf. mit **Fehlgeschlagene neu starten** (für fehlgeschlagene und abgebrochene Clients) nachfassen.
- Seeder startet nicht → **Einstellungen → Dienste** prüfen (`thinforge-bt-seeder-service`-Container). Logs liefern Hinweis, ob opentracker oder EZIO blockiert wurde.
- Multicast bleibt in der Bereitschaftsphase hängen → Netzwerk-Issue (IGMP-Snooping, Switch-Konfig).

## Nach dem Rollout

- Deployment-Zeile ist „Abgeschlossen" oder „Mit Fehlern abgeschlossen". **Löschen**-Button entfernt nur den Datensatz, nicht die Clones.
- In **Clients** → Spalte **Installierte Version** zeigt die neue Version.
- Mit **Nach Deploy** = Neustart oder Herunterfahren sind die Clients bereits im Zielzustand.

## Nächste Schritte

- [05 — Cloning](../05-cloning.md) für die Grundlagen der Image-Pipeline.
- [06 — Rollouts](../06-rollouts.md) für staged Rollouts mit Fortschrittskontrolle.
- [workflows/update-verteilen.md](update-verteilen.md) für den Fall, dass kein volles Image, sondern nur ein Delta ausgerollt werden soll.
