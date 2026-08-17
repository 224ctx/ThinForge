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

Das Management-Netzwerk laeuft auf einem dedizierten Host-Only Interface
(Standard: `ens19`), das nicht ins Internet geroutet wird.

- **Interface**: Konfigurierbar in DHCP-Einstellungen — `interface`-Feld im JSON-`value` der `settings`-Zeile mit `key = 'dhcp_config'`
- **Subnetz**: Typisch `192.168.x.0/24` (aus DHCP-Range abgeleitet)
- **Isolation**: Kein Routing zum Internet, nur Client-zu-Server-Kommunikation

Alle Deployment-Dienste (DHCP, TFTP, NFS, Multicast, BitTorrent) sind an
dieses Interface gebunden.

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
aa:bb:cc:dd:ee:ff,192.168.100.10,set:known,hostname
```

**Tags**:
| Tag | Bedeutung |
|-----|-----------|
| `known` | Client ist registriert (DHCP wird beantwortet, PXE-Boot-File wird ausgeliefert) |
| `ipxe` | Client unterstuetzt iPXE (automatisch erkannt) |
| `efi-x86_64` | Client ist UEFI (automatisch erkannt) |

Alle registrierten Clients erhalten **immer** ein PXE-Boot-File. Die per-MAC
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
2. Deployment abgeschlossen → `deployment_orchestrator::check_and_disable_nfs(docker, config, db)`
3. NFS-Export wird entfernt

Es wird strikt pro Client-IP (`assigned_ip`) exportiert. Sind keine Client-IPs
bekannt, wird die Export-Zeile weggelassen und eine Warnung geloggt — es gibt
keinen Subnetz-weiten Fallback (F-HI-11).

---

## 5. BitTorrent-Pfad-Secret (SEC-07)

**Problem**: Torrent-Dateien werden ueber den Caddy-HTTP-Server (Port 80) unter
`/deploy-scripts/` (root `/srv/tftp`) ausgeliefert. Ein vorhersagbarer Pfad
wuerde jedem im Netzwerk den Download ermoeglichen.

**Loesung**: Pro Deployment wird ein zufaelliges `bt_secret` (32 Hex-Zeichen)
generiert. Der Torrent-Pfad ist:

```
http://{server}/deploy-scripts/bt-{bt_secret}/{partition}.torrent
```

Statt:
```
http://{server}/deploy-scripts/bt-{deployment_id_prefix}/{partition}.torrent
```

Das Secret ist nur im PXE-Boot-Script enthalten, das per TFTP an registrierte
Clients ausgeliefert wird. Nach dem Deployment werden die Torrent-Dateien
geloescht (`bittorrent_service::cleanup_torrent_files()`).

---

## 6. Callbacks und Anti-Double-Deploy

### /started-Callback

Wird vom Deploy-Script auf dem Client aufgerufen, sobald Clonezilla startet:

```
POST /api/v1/clone-deployments/started?mac={mac}&token={callback_token}
```

Der per-Deployment-Callback-Token wird validiert (403 bei Mismatch — F-CR-02).

**Sofortige Aktion**: Der Client-Status wird auf `deploying` gesetzt. PXE wird
bei `/started` **nicht** auf Local-Boot zurueckgesetzt — das wuerde Deploy-Script
und PXE-Config vorzeitig entfernen. Der Local-Boot-Reset erfolgt erst beim
`/done`-Callback.

### /done-Callback

Wird nach Abschluss der Installation aufgerufen:

```
POST /api/v1/clone-deployments/done?mac={mac}&status=success|failed&detail={detail}&token={callback_token}
```

Der per-Deployment-Callback-Token wird validiert (403 bei Mismatch — F-CR-02).

**Aktionen**:
- Client-Status wird aktualisiert (done/failed)
- PXE auf Local-Boot (immer, idempotente Selbstheilung — `/started` fuehrt keinen Reset durch)
- Bei letztem Client: Deployment abgeschlossen, NFS-Export entfernt
- BitTorrent: Seeder gestoppt, Torrent-Dateien geloescht

### Completion-Timeout

Wenn der Multicast-Sender fertig ist, aber ein Client keinen /done-Callback
sendet (z.B. Neustart waehrend Transfer), wird der Client nach konfigurierbarem
Timeout (Standard: 120 Sekunden) automatisch als fehlgeschlagen markiert.

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

- Nur EIN BT-Deployment gleichzeitig
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
| BitTorrent Seeder | Netzwerk-Isolation | Laeuft nur auf Host-Only Interface |
| Torrent-Dateien | Zufaelliger Pfad | `bt_secret` (32 Hex-Zeichen) |
| Callbacks | Per-Deployment-Token | `callback_token`-Validierung (403 bei Mismatch, F-CR-02) |
| Double-Deploy | PXE-Selbstheilung bei /done | Idempotenter Localboot-Reset nach Abschluss |
| Verwaiste Clients | Completion-Timeout | Auto-Fail nach Sender-Ende |
