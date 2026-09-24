# ThinForge PXE Boot & Deployment — Sicherheitsarchitektur

## Uebersicht

Dieses Dokument beschreibt die Sicherheitskette vom Netzwerk-Boot bis zur
fertigen Clone-Installation. Jede Schicht schuetzt gegen unterschiedliche
Angriffsvektoren.

## Sicherheitsschichten

```
┌──────────────────────────────────────────────────┐
│ 1. Netzwerk-Isolation (Host-Only Interface)      │
├──────────────────────────────────────────────────┤
│ 2. DHCP-Filterung (nur registrierte MACs)        │
├──────────────────────────────────────────────────┤
│ 3. PXE-Boot pro MAC (Localboot / Deploy)         │
├──────────────────────────────────────────────────┤
│ 4. NFS-Zugriffskontrolle (IP-basiert)            │
├──────────────────────────────────────────────────┤
│ 5. Torrent-Pfad-Secret (SEC-07)                  │
├──────────────────────────────────────────────────┤
│ 6. Callback + PXE-Reset (Anti-Double-Deploy)     │
└──────────────────────────────────────────────────┘
```

---

## 1. Netzwerk-Isolation

Das Rollout-/Client-Netz laeuft auf einem dedizierten Host-Only Interface,
das nicht ins Internet geroutet wird. Einen festen Standardnamen gibt es nicht —
das Interface waehlt der Einrichtungsassistent.

- **Interface**: Konfigurierbar in DHCP-Einstellungen — `interface`-Feld im JSON-`value` der `settings`-Zeile mit `key = 'dhcp_config'`; beim Speichern muss es als physisches Interface auf dem Host existieren
- **Subnetz**: Typisch `192.168.x.0/24` (aus DHCP-Range abgeleitet)
- **Isolation**: Kein Routing zum Internet, nur Client-zu-Server-Kommunikation

DHCP und TFTP (dnsmasq, `interface=`), Multicast (`udp-sender --interface`)
und der BitTorrent-Tracker (`opentracker -i <rollout_ip>`) sind an dieses
Interface bzw. seine Adresse gebunden. Der NFS-Server und der EZIO-Seed-Port
6881 laufen dagegen im Host-Netz und lauschen auf allen Interfaces — dort
schuetzen die Export-IP-Liste (Abschnitt 4) bzw. der Torrent-Pfad (Abschnitt 5).

---

## 2. DHCP-Filterung

**Konfiguration**: `docker/dnsmasq/dnsmasq.conf`

```
dhcp-ignore=tag:!known
dhcp-hostsdir=/etc/dnsmasq.d/clients.d
```

**Verhalten**: Nur Geraete mit einem Eintrag in `clients.d/` (= registrierte
Clients) erhalten eine DHCP-Antwort. Unbekannte MAC-Adressen werden **komplett
ignoriert** — kein DHCP-Offer, keine IP, kein PXE-Boot.

### Client-Registrierung

Pro Client wird eine Datei in `clients.d/` erstellt:

```
# Dateiname: AA-BB-CC-DD-EE-FF
AA:BB:CC:DD:EE:FF,192.168.100.10,set:known,TF-AABBCCDDEEFF
```

**Tags**:
| Tag | Bedeutung |
|-----|-----------|
| `known` | Client ist registriert (DHCP wird beantwortet, PXE-Boot-File wird ausgeliefert) |
| `ipxe` | Client unterstuetzt iPXE (automatisch erkannt) |
| `efi-x86_64` | Client ist UEFI (automatisch erkannt) |

Ohne reservierte Adresse (etwa im Proxy-DHCP-Modus) entfaellt der IP-Teil der
Zeile. Alle registrierten Clients erhalten **immer** ein PXE-Boot-File. Die per-MAC
PXE-Konfiguration bestimmt das Boot-Verhalten (lokale Festplatte oder Deployment).
Dies funktioniert OS-agnostisch fuer Windows und Linux.

---

## 3. PXE-Boot-Kette

### Boot-File-Zuweisung

```
dhcp-boot=tag:known,tag:!localboot,tag:ipxe,boot.ipxe
dhcp-boot=tag:known,tag:!localboot,tag:!ipxe,tag:efi-x86_64,grub/x86_64-efi/core.efi
dhcp-boot=tag:known,tag:!localboot,tag:!ipxe,tag:!efi-x86_64,pxelinux.0
```

**Entscheidungsbaum**:
1. iPXE-Client → `boot.ipxe` per TFTP
2. UEFI-Client → `grub/x86_64-efi/core.efi` per TFTP
3. BIOS-Client → `pxelinux.0` per TFTP

Jeder Bootloader laedt anschliessend die per-MAC-Konfiguration, die entweder
auf Local Boot (`LOCALBOOT 0` / iPXE `exit` / GRUB EFI-Chainload) oder
Clonezilla-Deployment zeigt.

### Per-MAC-Konfiguration

Jeder Boot-Loader laedt eine MAC-spezifische Config:
- **pxelinux**: `pxelinux.cfg/01-aa-bb-cc-dd-ee-ff`
- **iPXE**: `ipxe-cfg/aa:bb:cc:dd:ee:ff.ipxe`
- **GRUB**: `grub/grub.cfg-aa:bb:cc:dd:ee:ff`

Die Config bestimmt ob Clonezilla mit dem Deploy-Script gebootet wird
oder ob lokal gebootet wird.

---

## 4. NFS-Zugriffskontrolle

**Service**: `crates/thinforge-services/src/nfs_service.rs`

Clone-Daten (`/nfs/clones`) werden nur waehrend eines aktiven Deployments
exportiert und auf die IPs der beteiligten Clients beschraenkt:

```
# Waehrend Deployment (pro Client-IP):
/nfs/clones  192.168.100.10(ro,sync,no_subtree_check,no_root_squash)

# Nach Deployment: kein Export
```

**Lifecycle**:
1. `deployment_orchestrator::activate_clients()` → `nfs_service::enable_deploy_share(client_ips)`
2. Jeder `/done`-Rueckruf entfernt die IP genau dieses Clients (`nfs_service::remove_deploy_client_ip`)
3. Deployment abgeschlossen → `deployment_orchestrator::check_and_disable_nfs(docker, config, db)` — der Export faellt weg, wenn kein weiteres Deployment laeuft

Es wird strikt pro Client-IP (`assigned_ip`) exportiert. Sind keine Client-IPs
bekannt, wird die Export-Zeile weggelassen und eine Warnung geloggt — es gibt
keinen Subnetz-weiten Fallback (F-HI-11).

---

## 5. BitTorrent-Pfad-Secret (SEC-07)

**Problem**: Torrent-Dateien werden ueber den Caddy-HTTP-Server (Port 80) unter
`/deploy-scripts/` (root `/srv/tftp`) ausgeliefert. Ein vorhersagbarer Pfad
wuerde jedem im Netzwerk den Download ermoeglichen.

**Loesung**: Pro Deployment wird ein zufaelliges `bt_secret` (128-Bit-Zufallswert,
hexadezimal, bis zu 32 Zeichen) generiert. Der Torrent-Pfad ist:

```
http://{server}/deploy-scripts/bt-{bt_secret}/{partition}.torrent
```

Statt:
```
http://{server}/deploy-scripts/bt-{deployment_id_prefix}/{partition}.torrent
```

Das Secret steht im per-MAC-Deploy-Skript (`deploy-scripts/<mac>.sh`). Dieses
Skript liegt im TFTP-Wurzelverzeichnis und ist dort — wie ueber Caddy:80 — ohne
Zugangspruefung lesbar: wer im Rollout-Netz die MAC eines Geraets mit laufendem
BitTorrent-Deployment kennt, liest auch den Pfad. Der Schutz wirkt also gegen
Erraten, nicht gegen einen Mitleser im Rollout-Netz. Nach dem Deployment werden
die Torrent-Dateien geloescht (`bittorrent_service::cleanup_torrent_files()`).

---

## 6. Callbacks und Anti-Double-Deploy

### /started-Callback

Wird vom Deploy-Script auf dem Client aufgerufen, sobald Clonezilla startet:

```
POST /api/v1/clone-deployments/started?mac={mac}&token={callback_token}
```

Der Callback-Token gilt je Deployment-Client und wird validiert (403 bei
Mismatch — F-CR-02). Im Skript steht er nicht mehr: das Skript holt ihn beim
Start ueber `GET /api/v1/clone-deployments/callback-token?mac={mac}`, und der
Server gibt ihn nur an eine Absenderadresse heraus, die das Geraet sein kann
(reservierte Adresse bzw. Rollout-Netz).

**Sofortige Aktion**: Der Client-Status wird auf `deploying` gesetzt und das
Geraet fuer die Neubespielung zurueckgesetzt. PXE wird
bei `/started` **nicht** auf Local-Boot zurueckgesetzt — das wuerde Deploy-Script
und PXE-Config vorzeitig entfernen. Der Local-Boot-Reset erfolgt erst beim
`/done`-Callback.

### /done-Callback

Wird nach Abschluss der Installation aufgerufen:

```
POST /api/v1/clone-deployments/done?mac={mac}&status=success|failed&detail={detail}&token={callback_token}
```

Der Callback-Token des Deployment-Clients wird validiert (403 bei Mismatch — F-CR-02).

**Aktionen** (nur wenn zur MAC ein offener Deployment-Eintrag existiert; sonst
wird der Aufruf ohne jede Aenderung quittiert):
- Client-Status wird aktualisiert (done/failed)
- PXE auf Local-Boot (idempotente Selbstheilung — `/started` fuehrt keinen Reset durch)
- NFS-Freigabe fuer die IP dieses Clients entfernt
- Bei letztem Client: Deployment abgeschlossen, Sender bzw. Torrent gestoppt
  (Torrent abgemeldet, Torrent-Dateien geloescht), NFS-Export entfernt, wenn
  kein weiteres Deployment laeuft; der BitTorrent-Seeder stoppt, sobald kein
  BT-Deployment mehr aktiv ist

### Completion-Timeout (entfallen)

Einen Zeitablauf, der Clients ohne `/done`-Callback als fehlgeschlagen markiert,
gibt es seit 2026-06-12 nicht mehr: ein Deployment gilt erst als abgeschlossen,
wenn alle Clients fertig sind. Der Worker schliesst nur Deployments ab, deren
Clients bereits alle einen Endstatus haben, deren letzter `/done`-Callback aber
verloren ging (`check_deployment_deadlines`, alle 5 Minuten). Der Wert
`completion_timeout` der Multicast-Einstellungen wird noch gespeichert, aber
nicht ausgewertet.

---

## Deployment-Modi

### Unicast (NFS + Clonezilla)

```
Client ──TFTP──> PXE-Config ──> Clonezilla ──NFS (ro)──> Clone-Daten
                                     │
                                     └── /started → /done Callbacks
```

- Jeder Client liest unabhaengig von NFS
- Mehrere Deployments gleichzeitig moeglich

### Multicast (UDP-Broadcast)

```
Server ──UDP 224.0.0.1──> Alle Clients gleichzeitig
  │
  ├── Clients melden /multicast/ready
  ├── Timeout oder alle bereit → Sender startet
  └── Partitionen werden sequenziell gestreamt
```

- Nur EIN Multicast-Deployment gleichzeitig
- Clients synchronisieren sich vor Start (Clients+Time-to-Wait)
- UDP auf Host-Only Interface beschraenkt

### BitTorrent (P2P + EZIO)

```
Server (Seeder) ──Tracker──> Clients laden .torrent von HTTP
                               │
                               └── P2P-Download zwischen Clients
                                   (EZIO schreibt direkt auf /dev/sdX)
```

- Mehrere BT-Deployments teilen sich einen Seeder-Container (ein Torrent je
  Deployment); der Seeder stoppt, wenn das letzte endet
- Torrent-Pfad durch bt_secret geschuetzt
- EZIO schreibt direkt auf Raw-Device (kein RAM/tmpfs noetig)
- Clients seeden kurz nach Download fuer P2P-Verteilung

---

## Sicherheitsmatrix

| Komponente | Schutzmethode | Durchsetzung |
|------------|---------------|--------------|
| DHCP-Zugang | MAC-Whitelist | `dhcp-ignore=tag:!known` |
| PXE-Boot-Files | MAC-basierte Configs | Per-MAC PXE-Config (local/deploy) |
| NFS Clones | IP-Beschraenkung | `enable_deploy_share(client_ips)` |
| Multicast UDP | Subnetz-lokal | Host-Only Interface, 224.0.0.1 |
| BitTorrent Seeder | Netzwerk-Isolation | Tracker an die Rollout-IP gebunden; der EZIO-Seed-Port 6881 lauscht auf allen Interfaces |
| Torrent-Dateien | Zufaelliger Pfad | `bt_secret` (128 Bit) — steht im ohne Zugangspruefung lesbaren Deploy-Skript |
| Callbacks | Token je Deployment-Client | `callback_token`-Validierung (403 bei Mismatch, F-CR-02); Herausgabe nur an die Geraeteadresse |
| Double-Deploy | PXE-Selbstheilung bei /done | Idempotenter Localboot-Reset nach Abschluss |
| Verwaiste Deployments | Abgleich im Worker | Abschluss, sobald alle Clients einen Endstatus haben (kein Zeitablauf) |
