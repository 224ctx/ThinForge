# 7 — Netzwerk

Das Netzwerk-Menü bündelt alles, was für die Infrastruktur-Seite von ThinForge relevant ist: Server-Interfaces, DHCP/PXE, DNS und VPN.

Die Ansicht hat vier Tabs:

## Tab: Local Network (Server-Interfaces)

Zeigt alle Netzwerk-Interfaces des Server-Hosts mit aktueller IP, MAC und Link-Status. Für den normalen Betrieb meist nur Lesezugriff — ThinForge greift lesend auf `/proc/net` zu.

**Typische Nutzung:** nachsehen, über welches Interface der Traffic läuft, vor Rollouts checken, dass das Management-Interface wirklich online ist.

**„Aktualisieren"** schreibt per privilegiertem Kurz-Container eine Netplan-Datei auf den Host und appliziert sie — das ist ein Admin-Schritt, normalerweise schon beim Setup gemacht.

## Tab: DHCP / PXE

Der interne `dnsmasq`-Dienst übernimmt DHCP und PXE-Boot für das Management-Subnetz.

### Einstellungen

| Feld | Bedeutung |
|------|-----------|
| Subnetz | CIDR des Management-Netzes, z. B. `192.168.10.0/24` |
| Gateway | üblicherweise die ThinForge-Server-IP |
| DNS | Upstream DNS für Clients (Default: lokaler dnsmasq) |
| Rollout-IP-Range | Start und Ende des Pools, aus dem Clients beim PXE-Boot eine temporäre IP bekommen |
| Lease-Time | typisch 8h |
| Domain-Suffix | optional, z. B. `.thinforge.local` |

**Speichern** schreibt eine neue `dnsmasq.conf` und startet den Dienst neu.

### Leases

Tabelle mit aktuell vergebenen DHCP-Leases (MAC, IP, Hostname, Expires). Nützlich, um zu prüfen, ob ein neuer Client überhaupt DHCP bekommen hat. Ein Client erscheint hier **bevor** er in der Clients-Liste auftaucht (Lease kommt beim PXE-Boot, Client-Objekt erst nach erstem Agent-Heartbeat).

### PXE-Boot

ThinForge stellt automatisch einen TFTP-Root und eine GRUB-EFI/BIOS-Boot-Kette bereit. Neue Clients booten per PXE zur Tools-ISO (Provisioning) oder zu einem Deploy-Boot (Image installieren).

**Fehlerbilder:**

- Client zeigt „PXE-E61: Media test failure" → DHCP kommt nicht an. Subnetz, Gateway oder Switch-IGMP/Helper prüfen.
- Client bekommt IP, bootet aber nicht → TFTP blockiert? dnsmasq-Container läuft ([02 — Dashboard](02-dashboard.md))?

## Tab: DNS

Zwei Bereiche:

### Upstream-DNS

Welche externen DNS-Server dnsmasq befragt, wenn ein Name nicht lokal bekannt ist. Default: Management-Gateway-IP aus Setup-Wizard. Für Außenstellen-Szenarien oft ein zentraler Firmen-DNS.

### Lokale Domain

Die interne Zone, für die dnsmasq als autoritativer Server auftritt (z. B. `thinforge.local`). Clients bekommen beim DHCP-Lease automatisch diese Domain als Such-Suffix.

Änderungen hier erfordern einen dnsmasq-Restart (passiert automatisch beim Speichern).

## Tab: VPN

ThinForge nutzt **WireGuard** für den sicheren Zugriff auf Clients außerhalb des lokalen Management-Netzes (Außendienst, Home-Office, Außenstellen).

### VPN-Status

Oben der Tab-weite Status: **Server aktiv**, **Interface up**, **Port offen** (meist 51820/UDP).

### Client-Liste

Tabelle aller registrierten VPN-Peers:

| Spalte | Bedeutung |
|--------|-----------|
| Name | Client-Hostname |
| Public-Key | WireGuard-Pubkey |
| VPN-IP | interne VPN-Adresse |
| Last Handshake | wann hat der Client sich zuletzt gemeldet |
| Traffic | Bytes sent / received in dieser Session |
| Status | `connected` / `stale` / `error` |

### Provisioning

Ein neuer Client bekommt seine VPN-Konfiguration **automatisch** beim Agent-Setup — die Wireguard-Keys werden auf beiden Seiten generiert und ausgetauscht. Für den Operator meist nichts zu tun; nur in Sonderfällen (Key-Rotation, VPN-Gateway-Umzug) manueller Eingriff nötig:

- **„Deploy"** auf einem Client → generiert neue Keys, schiebt Config an den Agent, restartet WireGuard.
- **„Undeploy"** → entfernt den Peer vom Server, Agent löscht die VPN-Config lokal.

### Traffic-Statistik

Separater Sub-Tab mit historischem Traffic pro Client (monatlich, täglich). Hilfreich für Kapazitätsplanung (welche Außenstellen fressen wieviel) und für die Abrechnung wenn ThinForge-Infrastruktur gemeinsam genutzt wird.

## Außenstellen

Wenn mehrere Filialen mit je eigenem lokalen Netz existieren, laufen die Clients dort meist via VPN zur Zentrale. Empfohlenes Setup:

- Eine **Gruppe pro Standort** ([04](04-gruppen.md))
- **BitTorrent-Rollout** statt Unicast — Clients einer Filiale verteilen die Daten intern über VPN-internes Peering
- **Multicast nicht über VPN** — läuft nur lokal. Für Innerfilial-Rollouts könnte perspektivisch ein Außenstellen-Relay sinnvoll sein, aktuell jedoch nicht vorgesehen

## Nächste Schritte

- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client mit DHCP+PXE aufnehmen
- [09 — Einstellungen](09-einstellungen.md) — NTP, TLS, generelle Server-Config
