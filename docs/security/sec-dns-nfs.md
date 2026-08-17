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

| Komponente | Container | Netzwerk | Dateien |
|------------|-----------|----------|---------|
| dnsmasq (DNS/DHCP/TFTP) | `thinforge-dnsmasq-1` | host | `backend/app/services/dnsmasq_service.py`, `backend/app/api/v1/network.py`, `docker/dnsmasq/` |
| NFS Server | `thinforge-nfs-server-1` | host, privileged | `backend/app/services/nfs_service.py` |
| WireGuard VPN | `thinforge-wireguard-1` | host | `docker/wireguard/entrypoint.sh` |
| Frontend DNS-Panel | — | — | `frontend/src/components/DnsPanel.vue` |

---

## Zusammenfassung

**17 Issues gefunden:**
- 6x P0 (Sicherheitskritisch) — Config-Injection, NFS-Zugriffskontrolle
- 5x P1 (Wichtige Bugs) — Race Conditions, Privacy, Logik-Fehler
- 4x P2 (Optimierungen) — Performance, Robustheit
- 3x P3 (Nice-to-have) — Frontend, Supply-Chain, Verschluesselung

### Implementierungs-Status (Stand: 2026-04-08)

| Item | Status | Bemerkung |
|------|--------|-----------|
| P0-1 | **OFFEN** | Keine Input-Validierung in `network.py` |
| P0-2 | **OFFEN** | Hosts-File-Injection nicht gefixt |
| P0-3 | **OFFEN** | Defense-in-Depth fehlt |
| P0-4 | **OFFEN** | DHCP-Felder nicht validiert |
| P0-5 | **OFFEN** | `no_root_squash` noch hardcoded (`nfs_service.py:51`) |
| P0-6 | **OFFEN** | `DEFAULT_NETWORK = "192.168.0.0/24"` Fallback existiert noch |
| P1-1 | **OFFEN** | Kein `asyncio.Lock()` |
| P1-2 | **GEGENSTANDSLOS** | Es gibt keine Restart-Logik mehr; NFS-Reload laeuft ausschliesslich ueber `exportfs -ra` |
| P1-3 | **OFFEN** | `log-queries` noch hardcoded |
| P1-4 | **OFFEN** | Google DNS Fallback noch in mehreren Stellen |
| P1-5 | **OFFEN** | Infinite-Lease Edge Case |
| P2-1 | **GEGENSTANDSLOS** | DHCP-Save fasst NFS nicht an; Exports werden nur beim Share-Umschalten neu geladen |
| P2-2 bis P2-4 | **OFFEN** | Optimierungen ausstehend |
| P3-1 bis P3-3 | **OFFEN** | Nice-to-have ausstehend |

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

---

### P2-3: DNS Negative Caching

**Problem:** Fehlgeschlagene DNS-Lookups werden nicht gecacht. Wiederholte Upstream-Queries fuer nicht-existente Domains.

**Fix:** `neg-ttl=300` in `dns-settings.conf` ergaenzen.

**Komplexitaet:** S

---

### P2-4: DNSSEC-Validierung (optional)

**Problem:** Kein Schutz gegen DNS-Spoofing/Poisoning von Upstream-Antworten.

**Fix:** `dnssec` + `trust-anchor` in Config schreiben wenn aktiviert. Frontend-Checkbox.

**Komplexitaet:** M

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

1. **Input-Injection-Tests:** Malicious Payloads via API senden → 422 erwarten
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
