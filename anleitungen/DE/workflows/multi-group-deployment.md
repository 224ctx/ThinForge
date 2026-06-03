# Workflow: Ein Image an mehrere Gruppen gleichzeitig ausrollen

Seit dem 2026-04-22-Release unterstützt ThinForge **Multi-Group-Deployments**: ein einziges Deployment-Objekt kann mehrere Gruppen bedienen, und dank des Service-Mode-BitTorrent-Seeders laufen sogar **mehrere Deployments parallel** — auch an verschiedene Gruppen mit verschiedenen Clones. Dieser Workflow zeigt, wie man das in der Praxis nutzt.

## Wann was?

| Szenario | Empfohlener Modus |
|---|---|
| Gleicher Clone → mehrere Gruppen, gleichzeitig, im lokalen Netz | **Multicast mit Target-Mode „Mehrere Gruppen"** — streamt einmal über die Leitung, alle Clients empfangen parallel. |
| Gleicher Clone → mehrere Gruppen, verschiedene Subnetze / Außenstellen über VPN | **BitTorrent** — Peer-Assist, Cache-Sharing zwischen Deployments. |
| Verschiedene Clones → verschiedene Gruppen, alles gleichzeitig | **BitTorrent** pro Deployment. Multicast kann nur **einmal** gleichzeitig laufen (Protokoll-Limit), BitTorrent parallelisiert. |
| Nur wenige Ziele, kein Multicast-fähiges Netz | **Unicast** — direkter Download pro Client. |

## Multi-Group per Multicast

1. Menü **Cloning** → Tab **Deployments** → **Neu**.
2. **Target-Modus** → `Mehrere Gruppen`.
3. Im Select die gewünschten Gruppen anhaken. Die UI zeigt unten „N Clients insgesamt".
4. **Clone** auswählen.
5. **Modus** → `Multicast`.
6. Optional: Scheduling + Wake-on-LAN setzen (WoL weckt die Clients X Minuten vorher auf).
7. **Anlegen**.

Alle Clients aller Gruppen stehen in einer einzigen Deployment-Zeile. Der Server wartet, bis alle Teilnehmer den PXE-Boot abgeschlossen haben, streamt dann das Image **einmal** und versorgt damit sämtliche Gruppen gleichzeitig.

**Gotcha:** Zweites gleichzeitiges Multicast-Deployment geht nicht — Address `224.0.0.1:2232` ist statisch. Die UI blockiert den Start entsprechend.

## Parallele Deployments per BitTorrent

BitTorrent läuft seit 2026-04-22 als **Service-Mode**: ein einziger `thinforge-bt-seeder-service`-Container hostet beliebig viele Clone-Torrents parallel und fährt sich automatisch runter, sobald das letzte Deployment fertig ist.

Vorteile aus Operator-Sicht:

- **Kein `Mode-Conflict`** mehr bei BT. Zweites Deployment mit anderem Clone an andere Gruppe einfach anlegen.
- **Slice-Cache pro Clone** — der zweite Rollout desselben Clones spart sich die teure Partclone-Extraktion, die neuen Clients landen im selben Swarm wie die bereits laufenden.
- **Auto-Stop** bei Idle — Tracker-Port 6969 und Seed-Port 6881 sind außerhalb aktiver Rollouts geschlossen.

Workflow:

1. Deployment 1 anlegen: Gruppe Marketing, Clone `marketing-v1.005`, Modus BitTorrent.
2. Deployment 2 anlegen: Gruppe Sales, Clone `sales-v1.002`, Modus BitTorrent.
3. Beide Deployments starten parallel — Seeder bootet einmal, hostet beide Torrents.
4. Wenn Deployment 1 fertig ist: Torrent 1 wird unregistered, Seeder bleibt für Deployment 2.
5. Wenn auch Deployment 2 fertig: Container wird automatisch entfernt.

## Monitoring während des Rollouts

Tabelle im Deployments-Tab:

- **Multicast** — Chip zeigt `waiting N/M (MM:SS remaining)` während Bereitschaftsphase, dann `sending` während Stream, schließlich `complete`.
- **BitTorrent** — Chip zeigt `preparing` (Slice-Extract / Torrent-Erzeugung), dann `seeders_ready` (Seeder läuft, Clients peer-assisten sich), dann `complete`. In der aufgeklappten Zeile siehst du pro Client die Partition, die gerade geschrieben wird, plus Prozent-Bar.
- Pro Client-Zeile: `pending / deploying / done / failed / cancelled`, bei BitTorrent/Unicast auch **Neu starten** (nicht bei Multicast — dort hat ein Restart keinen Sinn, weil der Stream bereits weg ist).

## Fehlerbehandlung

- Ein Client meldet `failed` → Zeile aufklappen, **Neu starten**; Backend versucht den einzelnen Client erneut.
- Gesamt-Deployment hängt → **Abbrechen** setzt Status auf `cancelled`; ggf. mit **Neu starten** (für failed/cancelled Clients) nachfassen.
- Seeder startet nicht → Services-Panel prüfen (`thinforge-bt-seeder-service`-Container). Logs liefern Hinweis, ob opentracker oder EZIO blockiert wurde.
- Multicast bleibt auf `waiting` hängen → Netzwerk-Issue (IGMP-Snooping, Switch-Konfig). Check `docs/architecture/cloning-pipeline.md` §5 für Details.

## Nach dem Rollout

- Deployment-Zeile ist `completed` oder `completed_with_errors`. **Löschen**-Button entfernt nur den Datensatz, nicht die Clones.
- In **Clients** → Spalte `installed_image` zeigt die neue Version.
- Bei eingeschalteter Post-Action (`reboot` / `shutdown`) sind die Clients bereits im Zielzustand.

## Nächste Schritte

- [05 — Cloning](05-cloning.md) für die Grundlagen der Image-Pipeline.
- [06 — Rollouts](06-rollouts.md) für staged Rollouts mit Fortschrittskontrolle.
- [workflows/update-verteilen.md](update-verteilen.md) für den Fall, dass kein volles Image, sondern nur ein Delta ausgerollt werden soll.
