# Security-Audit: DNS + NFS System

> **Kritikalitaet: HOCH**
> Dieses Dokument beschreibt Sicherheitsluecken und Verbesserungen im DNS/DHCP/NFS-Stack.
> Alle P0-Items muessen vor einem Produktiv-Deployment geprueft und behoben werden.
> Aenderungen an diesem System erfordern besondere Sorgfalt, da fehlerhafte Configs
> den gesamten Netzwerk-Stack (DHCP, DNS, PXE-Boot, NFS-Mounts) lahmlegen koennen.
>
> **Vor Implementierung:** Jeden Fix einzeln testen, nie mehrere P0-Items gleichzeitig
> deployen ohne Zwischenpruefung. Rollback-Plan bereithalten (dnsmasq-Config-Backup,
> NFS-Exports-Backup). Idealerweise in einer Testumgebung validieren.

---

## Audit-Datum: 2026-03-25

## Gepruefte Komponenten

Die Spalte „Dateien zum Audit-Datum" nennt den Stand vom 2026-03-25 (Python-Backend); die Spalte „Heute" den Stand im Rust-Code (Abgleich 2026-10-02).

| Komponente | Container | Netzwerk | Dateien zum Audit-Datum | Heute |
|------------|-----------|----------|-------------------------|-------|
| dnsmasq (DNS/DHCP/TFTP) | `thinforge-dnsmasq-1` | host | `backend/app/services/dnsmasq_service.py`, `backend/app/api/v1/network.py`, `docker/dnsmasq/` | `crates/thinforge-services/src/dnsmasq_service.rs`, `crates/thinforge-api/src/handlers/network.rs`, `docker/dnsmasq/` |
| NFS Server | `thinforge-nfs-server-1` | host, privileged | `backend/app/services/nfs_service.py` | `crates/thinforge-services/src/nfs_service.rs`, eigenes Image `docker/nfs-server/` (siehe P3-2) |
| WireGuard VPN | `thinforge-wireguard-1` | host | `docker/wireguard/entrypoint.sh` | entfallen: seit 2026-05-20 hat der Stack keinen WireGuard-Container mehr (Dienst `netbird` in `docker-compose.yml`); nicht Gegenstand dieses Audits |
| Frontend DNS-Panel | — | — | `frontend/src/components/DnsPanel.vue` | unveraendert `frontend/src/components/DnsPanel.vue` |

---

## Zusammenfassung

**17 Issues gefunden:**
- 6x P0 (Sicherheitskritisch) — Config-Injection, NFS-Zugriffskontrolle
- 5x P1 (Wichtige Bugs) — Race Conditions, Privacy, Logik-Fehler
- 4x P2 (Optimierungen) — Performance, Robustheit
- 3x P3 (Nice-to-have) — Frontend, Supply-Chain, Verschluesselung

### Implementierungs-Status (Stand: 2026-10-04, Abgleich gegen den Rust-Code)

Die Datei- und Zeilenangaben in den Befunden unten beziehen sich auf das fruehere Python-Backend zum Audit-Datum. Die Tabelle nennt den Stand im heutigen Rust-Code (`crates/thinforge-services`, `crates/thinforge-api`).

| Item | Status | Bemerkung |
|------|--------|-----------|
| P0-1 | **BEHOBEN** | `dnsmasq_service::render_dns_conf` schreibt nur Upstream-Server, die `dns_upstream_safe` bestehen, und verwirft den Rest mit Warnung (seit 2026-05-30). Seit Runde 5 (2026-09-30, T289) prueft auch die DNS-Seite der API vor dem Speichern und antwortet 400 `errors.network.dnsUpstreamInvalid` — seit F4-01 mit derselben, jetzt oeffentlichen Funktion statt einer Kopie im Handler; `dns_servers` der DHCP-Konfiguration prueft die API (siehe P0-4) |
| P0-2 | **BEHOBEN (Schreib-Schicht)** | `render_dns_hosts` schreibt nur Eintraege mit gueltiger IP und DNS-sicherem Namen (`dns_name_safe`), der Rest wird mit Warnung verworfen |
| P0-3 | **BEHOBEN** | Die Pruefung sitzt in den Render-Funktionen von `dnsmasq_service`, unabhaengig vom Aufrufer |
| P0-4 | **BEHOBEN** | `network::dhcp_konfiguration_pruefen` weist vor dem Speichern ungueltige Werte mit 400 ab (Modus, Range, Netzmaske, Lease-Zeit, Gateway, Rollout-IP, Management-DNS, DNS-Server, Domain; seit 2026-09-06); das Interface muss auf dem Host existieren |
| P0-5 | **BEHOBEN (2026-09-30)** | `/nfs/clones` exportiert mit `root_squash`, `/nfs/captures` behaelt `no_root_squash` (Clonezilla schreibt als Root) — `nfs_service::Freigabe` statt einer gemeinsamen Optionskonstante. Voraussetzung: die Abbilder muessen fuer „andere" lesbar sein; jede Uebernahmestelle (Aufnahme-Umzug, Import, Cloner-Abschluss) ergaenzt die Lesebits (`clones_service::fuer_andere_lesbar_machen`). Bestand auf dem Arbeitsserver am 2026-09-30: alle Abbilddateien 644, alle Verzeichnisse 755 |
| P0-6 | **BEHOBEN** | Kein Subnetz-Fallback: ohne Client-IPs entfaellt die Export-Zeile (`build_client_specs` liefert `None`); `DEFAULT_NETWORK` fuellt nur noch den Kommentarkopf der Datei |
| P1-1 | **BEHOBEN** | Der Freigabe-Zustand liegt hinter einem `Mutex` (`STATE`, Zugriff nur ueber `with_state_restored`; das schlichte `with_state` entfiel am 2026-09-30); seit 2026-09-30 laufen auch Erzeugen und Schreiben der Datei unter dieser Sperre und Schreiben + `exportfs -ra` als Einheit (siehe P2-2) |
| P1-2 | **GEGENSTANDSLOS** | Es gibt keine Restart-Logik mehr; NFS-Reload laeuft ausschliesslich ueber `exportfs -ra` |
| P1-3 | **BEHOBEN (2026-09-30)** | `--log-queries` aus dem Entrypoint entfernt; das Abfrage-Log ist die Einstellung `dns_config.log_queries` (Vorgabe aus, Schalter „DNS-Anfragen protokollieren" im DNS-Panel), die `render_dns_conf` als `log-queries` schreibt — wirksam mit dem Neustart beim Speichern. `log-dhcp` bleibt (Entrypoint und `dnsmasq.conf`). Braucht ein neu gebautes dnsmasq-Image; eine Bestandsinstallation protokolliert nach dem Update keine Anfragen mehr, bis jemand den Schalter setzt |
| P1-4 | **BEHOBEN (2026-09-30)** | Keine festen `8.8.8.8`/`8.8.4.4` mehr — Vorgabe leer in `default_dns_config`, im Setup-Schema (`dns_servers` = DHCP-Option 6, leer = dnsmasq selbst) und in DNS- und DHCP-Panel. Die Upstreams traegt der Einrichtungsassistent ein (Management-DNS, sonst Host-Resolver); ohne beides bleibt die Liste leer und dnsmasq loest nur lokale Namen auf. Gespeicherte Werte bleiben unangetastet. Eine Umgebungsvariable `MANAGEMENT_DNS` gibt es nicht mehr |
| P1-5 | **BEHOBEN (2026-09-30)** | `get_leases` zaehlt `expiry_ts == 0` (dnsmasqs Schreibweise fuer `infinite`) als aktiv; die Lease-Tabelle zeigt dafuer „unbefristet" statt des 1. Januar 1970 |
| P2-1 | **GEGENSTANDSLOS** | DHCP-Save fasst NFS nicht an; Exports werden nur beim Share-Umschalten neu geladen |
| P2-2 | **BEHOBEN (2026-10-02, tmp + rename)** | Seit Runde 6 (T143) haengt `nfs-config` als VERZEICHNIS im NFS-Container (`nfs-config:/etc/thinforge-nfs:ro`, beide Compose-Dateien), der Entrypoint verlinkt `/etc/exports` auf `exports` darin. `nfs_service::write_exports` schreibt eine Nachbardatei, `fsync`, rename auf `exports`, `fsync` des Verzeichnisses — ein Leser (`exportfs -ra`, Containerstart, Zustandswiederherstellung des Backends) sieht immer eine vollstaendige Datei. Erzeugen + Schreiben bleiben unter der Zustandssperre, Schreiben + `exportfs -ra` eine Einheit unter einer async-Sperre (`nfs_service::exports_schreiben_und_neuladen`). Vom 2026-09-30 bis Runde 6 in place (Einzeldatei-Bind-Mount, der am Inode haengt; Restrisiko leere Datei bei Absturz zwischen truncate und write) |
| P2-3 | **BEHOBEN (2026-09-30)** | `neg-ttl=60` in der erzeugten `dns-settings.conf` (`dnsmasq_service::NEG_TTL_SEKUNDEN`): Verneinungen ohne SOA-Eintrag werden eine Minute gecacht — typische Wiederholungen (AAAA zu A-only-Namen, Tippfehler) kommen aus dem Cache, ein frisch angelegter Name ist binnen einer Minute sichtbar; Antworten mit SOA behalten deren TTL. Bestandsinstallationen: der Start-Reconciler sieht die veraltete Datei und startet dnsmasq beim ersten Backend-Start nach dem Update einmal neu |
| P2-4 | **bewusst nicht umgesetzt (Daisy 2026-09-30)** | Kein `dnssec` in der erzeugten Konfiguration — LAN-only-Bedrohungsmodell, Upstream ist in der Regel der Resolver des Verwaltungsnetzes |
| P3-1 | **BEHOBEN (2026-09-30)** | Das DNS-Panel fuehrt die Upstreams als dynamische Liste (Hinzufuegen/Entfernen, beliebig viele); die Eingaberegel spiegelt `dns_upstream_safe` (IP v4/v6, optional `#Port`), und `load()` uebernimmt alle gespeicherten Eintraege statt der ersten zwei. Backend unveraendert (nahm schon eine Liste), alte Zwei-Eintrag-Konfigurationen laden unveraendert |
| P3-2 | **GEGENSTANDSLOS** | Kein Fremd-Image mehr: der NFS-Server ist ein eigenes Image auf `alpine:3.24` mit `nfs-utils` (`docker/nfs-server/Dockerfile`) |
| P3-3 | **bewusst nicht umgesetzt (Daisy 2026-09-30)** | Kein DNS-over-TLS — kein Stubby-Sidecar; der Upstream-Verkehr bleibt im Verwaltungsnetz |

---

## P0 — Sicherheitskritisch (Must-Fix)

### P0-1: Config-Injection via DNS-Server-Feld

**Schweregrad:** Hoch
**Angriffsvektor:** Authentifizierter Admin via API
**Auswirkung:** Beliebige dnsmasq-Direktiven injizierbar (DNS-Hijacking, Cache-Poisoning)

**Problem:** `upstream_servers` und `dns_servers` in den Pydantic-Modellen werden nur gestripped, nicht validiert.
Ein Newline im Wert erzeugt eine neue dnsmasq-Direktive:
```
server=1.2.3.4\naddress=/bank.de/6.6.6.6
```
Ergebnis: Alle Anfragen an `bank.de` werden auf `6.6.6.6` umgeleitet.

**Betroffene Dateien:**
- `backend/app/api/v1/network.py` — `DnsConfigRequest.upstream_servers`, `DhcpConfigRequest.dns_servers`
- `backend/app/services/dnsmasq_service.py` — `write_dns_conf()` Zeile 99-102

**Fix:**
1. Neue Datei `backend/app/utils/validators.py` mit `validate_ip_address()` (via `ipaddress.ip_address()`) und `validate_ip_or_hostname()` (IP oder RFC-1123 Regex `^[a-zA-Z0-9][a-zA-Z0-9.\-]{0,253}$`)
2. `@field_validator` in beiden Pydantic-Modellen — reject bei Newlines, Tabs, Sonderzeichen
3. Defense-in-Depth: Validierung auch in `write_dns_conf()` vor dem Schreiben

**Komplexitaet:** S

---

### P0-2: Hosts-File-Injection via Custom DNS-Eintraege

**Schweregrad:** Hoch
**Angriffsvektor:** Authentifizierter Admin via API
**Auswirkung:** Zusaetzliche A-Records injizierbar

**Problem:** `DnsEntryRequest.ip` und `.hostname` werden nur gestripped. `_write_dns_hosts()` schreibt `{ip}\t{hostname}` direkt.

Payload:
```json
{"ip": "1.2.3.4\n5.6.7.8\tmalicious.example.com", "hostname": "legit"}
```
Erzeugt einen zusaetzlichen A-Record der `malicious.example.com` auf `5.6.7.8` zeigt.

**Betroffene Dateien:**
- `backend/app/api/v1/network.py` — `DnsEntryRequest` (Zeile 255-262)
- `backend/app/services/dnsmasq_service.py` — `_write_dns_hosts()` (Zeile 131-145)

**Fix:**
1. `@field_validator("ip")` mit `ipaddress.ip_address()`
2. `@field_validator("hostname")` mit RFC-1123 Regex, keine Control-Characters
3. Defense-in-Depth in `_write_dns_hosts()`: Newlines/Tabs strippen + re-validieren

**Komplexitaet:** S

---

### P0-3: Defense-in-Depth bei dnsmasq Config-Generierung

**Schweregrad:** Mittel
**Problem:** `write_dns_conf()` schreibt `server={srv}` ohne eigene Pruefung. Auch wenn P0-1 die API absichert, fehlt die zweite Sicherheitsschicht am Write-Layer.

**Betroffene Dateien:**
- `backend/app/services/dnsmasq_service.py` (Zeile 98-102)

**Fix:** `validate_ip_or_hostname(srv)` vor dem Schreiben aufrufen, bei Fehler ueberspringen + loggen.

**Komplexitaet:** S

---

### P0-4: Fehlende Validierung aller DHCP-Config-Felder

**Schweregrad:** Hoch
**Problem:** `range_start`, `range_end`, `netmask`, `gateway`, `interface`, `proxy_subnet`, `domain`, `lease_time` werden nicht validiert. Alle Werte gehen direkt in die dnsmasq-Config-Datei.

**Betroffene Dateien:**
- `backend/app/api/v1/network.py` — `DhcpConfigRequest` (Zeile 144-166)

**Fix:**
1. `range_start`, `range_end`, `netmask`, `gateway` → `ipaddress.ip_address()` (leer erlaubt bei optionalen)
2. `interface` → Regex `^[a-zA-Z0-9._-]{1,15}$` (Linux-Interface-Constraint)
3. `proxy_subnet` → IP-Validierung
4. `domain` → Hostname-Regex, keine Control-Characters
5. `lease_time` → Regex `^\d+[smhd]?$`

**Komplexitaet:** M

---

### P0-5: NFS `no_root_squash` auf allen Shares

**Schweregrad:** Mittel
**Problem:** Alle NFS-Exports nutzen `no_root_squash` (`nfs_service.py` Zeile 51). Client-Root hat volle Server-Root-Rechte auf allen Shares — auch auf Read-Only Shares wo das unnoetig ist.

**Betroffene Dateien:**
- `backend/app/services/nfs_service.py` (Zeile 51, `_build_client_specs`)

**Fix:**
- `/nfs/clones` (RO Deploy) → `root_squash` (Clients lesen nur)
- `/nfs/captures` (RW Capture) → `no_root_squash` bleibt (Clonezilla schreibt als Root, nur temporaer + IP-restricted)
- ~~`/nfs/deltas`~~ — Export retired in T22 (2026-05-07), Delta-Auslieferung läuft jetzt über HTTPS + Bearer-Token
- Implementierung: `_NFS_OPTS_RO` und `_NFS_OPTS_RW` statt einer einzigen Konstante

**Komplexitaet:** S

---

### P0-6: NFS Fail-Open bei fehlendem DHCP-Subnet

**Schweregrad:** Mittel
**Problem:** `DEFAULT_NETWORK = "192.168.0.0/24"` — ohne DHCP-Config bekommt jedes Geraet auf 192.168.0.0/24 NFS-Zugriff. Das System failt open statt closed.

**Betroffene Dateien:**
- `backend/app/services/nfs_service.py` (Zeile 30, `_build_client_specs`)

**Fix:**
1. `DEFAULT_NETWORK = None`
2. `_build_client_specs()`: Ohne IPs und ohne Fallback-Netz → leerer String (kein Export)
3. Warnung loggen: "Kein DHCP-Subnet konfiguriert — NFS-Export uebersprungen"

**Komplexitaet:** S

---

## P1 — Wichtige Bugs

### P1-1: NFS Race Condition (kein Locking)

**Problem:** Modul-Globals (`_deploy_share_active`, `_capture_write_active`, etc.) ohne Locking. Concurrent `enable_deploy_share()` + `enable_capture_write()` koennen inkonsistente Exports erzeugen.

**Betroffene Dateien:** `backend/app/services/nfs_service.py`

**Fix:** `_nfs_lock = asyncio.Lock()` + alle enable/disable-Funktionen wrappen mit `async with _nfs_lock:`

**Komplexitaet:** S

---

### P1-2: NFS Restart-Logik (`docker start` ist No-Op) — GEGENSTANDSLOS

**Stand:** Der NFS-Service kennt keine Restart-Funktion mehr. Jede Export-Aenderung
wird ueber `re_export()` (`exportfs -ra` im laufenden Container) wirksam; schlaegt
das fehl, wird der Fehler geloggt und `false` zurueckgegeben, der Container bleibt
unangetastet. Ein Container-Neustart ist ausschliesslich ein manueller Operator-Schritt
(`docker compose restart nfs-server`).

---

### P1-3: DNS Query-Logging immer aktiv (Privacy)

**Problem:** `--log-queries` hardcoded im dnsmasq-Entrypoint. Loggt jede DNS-Query aller Clients — Privacy-Bedenken in Produktivumgebungen + hohe Log-Volumes.

**Betroffene Dateien:**
- `docker/dnsmasq/entrypoint.sh` (Zeile 67)
- `backend/app/services/dnsmasq_service.py`

**Fix:** `log-queries` als konfigurierbare Option in `dns-settings.conf`. Aus Entrypoint entfernen. Im DNS-Panel als Checkbox anbieten.

**Komplexitaet:** S

---

### P1-4: Hardcoded Google DNS (8.8.8.8) in 6 Stellen

**Problem:** Fallback `8.8.8.8` in `dnsmasq_service.py`, `docker-compose.yml`, WireGuard-Template, Frontend. Die `.env` hat bereits `MANAGEMENT_DNS` — wird aber nicht konsistent genutzt.

**Betroffene Dateien:**
- `backend/app/services/dnsmasq_service.py` (DEFAULT_DHCP_CONFIG, DEFAULT_DNS_CONFIG)
- `ansible/roles/wireguard/templates/wg0.conf.j2`

**Fix:** Defaults aus `os.environ.get("MANAGEMENT_DNS", "8.8.8.8")` lesen.

**Komplexitaet:** S

---

### P1-5: Lease-Expiry Edge Case (Infinite Lease)

**Problem:** `get_leases()` behandelt `expiry_ts == 0` nicht speziell. dnsmasq schreibt `0` fuer infinite Leases. Der Vergleich `0 > now_ts` ist immer `False` — infinite Leases erscheinen als abgelaufen.

**Betroffene Dateien:** `backend/app/services/dnsmasq_service.py` (Zeile 350-373)

**Fix:** `expiry_ts == 0` als "nie ablaufend" behandeln (`is_active: True`).

**Komplexitaet:** S

---

## P2 — Optimierungen

### P2-1: NFS-Restart nur bei Subnet-Aenderung — GEGENSTANDSLOS

**Stand:** Ein DHCP-Save fasst NFS gar nicht mehr an. Die Exports werden nur beim
Umschalten eines Shares neu geschrieben (`enable/disable_capture_write`,
`enable/disable_deploy_share`), jeweils aus der aktuellen DHCP-Config aus der DB,
gefolgt von `exportfs -ra` — ohne Container-Neustart. Aktive NFS-Mounts bleiben
dabei bestehen; die Optimierung ist damit hinfaellig.

---

### P2-2: Atomares Schreiben der NFS-Exports

**Problem:** `write_exports()` ist nicht atomar. Crash/Race kann halbe Datei hinterlassen.

**Fix:** Write-to-temp + `os.rename()`.

**Komplexitaet:** S

**Umsetzung (2026-09-30):** Write-to-temp + rename ist hier NICHT moeglich — die
Datei ist als Einzeldatei in den NFS-Container gemountet und der Mount haengt
am Inode. Umgesetzt wurde deshalb: Erzeugen und Schreiben in einem Stueck unter
der Zustandssperre (das war die reale Race: zwei Uebergaenge ueberholten sich
zwischen Erzeugen und Schreiben), ein Schreibaufruf mit `fsync`, und Schreiben
plus `exportfs -ra` als Einheit unter einer async-Sperre. Siehe Statustabelle.

**Umsetzung (2026-10-02, Runde 6, T143):** die strukturelle Variante. `nfs-config`
haengt als Verzeichnis im NFS-Container (`nfs-config:/etc/thinforge-nfs:ro`, beide
Compose-Dateien), `docker/nfs-server/entrypoint.sh` verlinkt `/etc/exports` auf
`/etc/thinforge-nfs/exports` — ein Symlink trifft bei jedem Lesen die aktuelle
Datei. Damit schreibt `write_exports` per Nachbardatei + `fsync` + rename +
`fsync` des Verzeichnisses; das Restrisiko der leeren Datei ist weg. Fehlt der
Verzeichnis-Mount (veraltete Compose-Datei), bricht der Entrypoint laut ab,
statt still eine feste Datei zu lesen. Betrieb: nfs-server-Image neu bauen und den
Container neu anlegen, nicht waehrend eines Deployments oder einer Aufnahme.

---

### P2-3: DNS Negative Caching

**Problem:** Fehlgeschlagene DNS-Lookups werden nicht gecacht. Wiederholte Upstream-Queries fuer nicht-existente Domains.

**Fix:** `neg-ttl=300` in `dns-settings.conf` ergaenzen.

**Komplexitaet:** S

**Umsetzung (2026-09-30):** `neg-ttl=60` statt 300 — die Option greift nur fuer
Verneinungen OHNE SOA-Eintrag (mit SOA gilt weiter dessen TTL); eine Minute
faengt die Wiederholungen ab, ohne einen frisch angelegten Namen lange zu
verbergen.

---

### P2-4: DNSSEC-Validierung (optional)

**Problem:** Kein Schutz gegen DNS-Spoofing/Poisoning von Upstream-Antworten.

**Fix:** `dnssec` + `trust-anchor` in Config schreiben wenn aktiviert. Frontend-Checkbox.

**Komplexitaet:** M

**Entscheidung (Daisy 2026-09-30):** bewusst nicht umgesetzt — wie P3-3 (DoT).

---

## P3 — Nice-to-have

| Item | Beschreibung | Komplexitaet |
|------|-------------|--------------|
| P3-1 | Frontend: 3+ Upstream DNS Server erlauben (dynamische Liste) | S |
| P3-2 | NFS Container Image pinnen (`erichough/nfs-server:2.2.1` statt `:latest`) | S |
| P3-3 | DNS-over-TLS via Stubby-Sidecar fuer verschluesselte Upstream-Queries | L |

---

## Implementierungsreihenfolge

| Schritt | Items | Commit-Scope |
|---------|-------|------|
| 1 | `validators.py` erstellen | Foundation |
| 2 | P0-1 + P0-2 + P0-3 + P0-4 | Input-Validierung (alle zusammen) |
| 3 | P0-5 + P0-6 | NFS Security Hardening |
| 4 | P1-1 + P2-2 | NFS Race Condition + Atomic Writes |
| 5 | P1-4 | MANAGEMENT_DNS konsolidieren |
| 6 | P1-3 | DNS Query-Logging toggle |
| 7 | P2-3 | Negative Caching |
| 8 | P1-5 | Lease-Expiry Robustheit |
| 9 | P3-1, P3-2 | Frontend, NFS Image Pin |
| 10 | P2-4 | DNSSEC |

---

## Verifikation (End-to-End)

1. **Input-Injection-Tests:** Malicious Payloads via API senden → 400 erwarten (Rust-API: `errors.network.*` aus `dhcp_konfiguration_pruefen` bzw. der DNS-Pruefung; zum Audit-Datum 422 von Pydantic)
2. **Config-Generierung:** Nach Save DNS/DHCP-Settings → generierte Configs inspizieren (keine injizierten Zeilen)
3. **NFS-Exports:** `docker exec thinforge-nfs-server-1 exportfs -v` → korrektes Subnet, `root_squash` bei RO
4. **NFS ohne DHCP:** Frisches System ohne DHCP-Config → leere Exports (kein Zugriff)
5. **DNS-Logging:** Toggle ein/aus → Logs pruefen
6. **Concurrent NFS:** Gleichzeitig Deploy + Capture starten → Exports enthalten beide Shares

---

## Kritische Dateien

| Datei | Betroffene Items |
|-------|-----------------|
| `backend/app/api/v1/network.py` | P0-1, P0-2, P0-4 |
| `backend/app/services/dnsmasq_service.py` | P0-3, P1-3, P1-4, P1-5, P2-3 |
| `backend/app/services/nfs_service.py` | P0-5, P0-6, P1-1, P2-2 |
| `docker/dnsmasq/entrypoint.sh` | P1-3 |
| `frontend/src/components/DnsPanel.vue` | P2-4, P3-1 |
| NEU: `backend/app/utils/validators.py` | P0-1, P0-2, P0-3, P0-4 |
