# 15 — Firewall-Regeln

Dieses Kapitel fasst zusammen, welche Verbindungen ThinForge braucht, damit eine Firmenfirewall sie erlauben kann — nach Richtung, Quelle und Ziel, Protokoll und Port, mit Hostnamen, soweit sie fest sind. Verbindungen zwischen den Containern und zum Betriebssystem des Servers (Datenbank, Redis, interne Dienste) stehen nicht darin: sie bleiben auf dem Server und berühren keine Firewall. Welche Verbindungen der Server von sich aus nach außen aufbaut und wie sie sich abschalten lassen, beschreibt [12 — Sicherheit → Ausgehende Verbindungen](12-sicherheit-und-cve-scan.md#ausgehende-verbindungen); hier geht es um die Regeln dafür.

> **Das Wichtigste.** Der Server baut alle Verbindungen ins Internet selbst auf und braucht **keinen eingehenden Port aus dem Internet** — auch nicht für das VPN. Keine Portweiterleitung, keine Telemetrie, keine Prüfung beim Hersteller, keine automatischen Zertifikate. Im Betrieb spricht der Server von sich aus nur mit Zeitserver, DNS und — sobald eingerichtet — der VPN-Instanz; alles andere geschieht nur auf Befehl oder wenn es eingetragen ist.

## Die drei Netze

Der Server hat zwei Adapter ([workflows/setup-wizard.md](workflows/setup-wizard.md)): die **Management-Schnittstelle** im Firmen-LAN, über die die Oberfläche erreichbar ist und der Server ins Internet kommt, und die **Rollout-Schnittstelle** ins Client-Netz, in dem er DHCP-, DNS-, PXE- und Zeitserver der Geräte ist ([07 — Netzwerk](07-netzwerk.md)). Dazu kommt bei aktivem VPN die **VPN-Instanz** im Internet, an der Server und Geräte ihre Tunnel aufbauen ([13 — VPN](13-vpn.md)). Die Tabellen folgen diesen drei Wegen.

## Verwaltungsnetz → Server

| Quelle → Ziel | Protokoll / Port | Zweck | Pflicht |
|---|---|---|---|
| Admin-Arbeitsplätze → Server (Management-Adresse) | TCP 443 | Weboberfläche und API, auch Terminal und Fernwartung im Browser | Pflicht |
| Admin-Arbeitsplätze → Server | TCP 22 | SSH für Installation und Pflege des Betriebssystems — Sache des Servers, nicht von ThinForge | optional |

Auf der Management-Adresse antwortet nur Port 443; Port 80 bedient der Server allein auf der Rollout-Adresse (PXE). PostgreSQL (5432), Redis (6379), Backend (8000) und Frontend (3000) sind nur auf dem Loopback des Servers veröffentlicht und erscheinen auf keiner Schnittstelle.

## Client-Netz ↔ Server

Das Client-Netz hängt direkt an der Rollout-Schnittstelle; DHCP, PXE und Multicast arbeiten mit Broadcast bzw. bleiben im lokalen Segment. Diese Regeln braucht es nur, wenn innerhalb dieses Netzes eine Firewall filtert — etwa zwischen Switch-Segmenten oder wenn nicht der Server selbst das Gateway der Geräte ist (DHCP-Option 3, [07 — Netzwerk](07-netzwerk.md)).

**Geräte → Server (Rollout-Adresse)**

| Dienst | Protokoll / Port | Zweck | Pflicht |
|---|---|---|---|
| DHCP | UDP 67, 68 | Adressvergabe und PXE-Boot der Geräte | Pflicht bei eigenem DHCP-Server |
| TFTP | UDP 69 | erste Boot-Dateien beim PXE-Start (`pxelinux.0`, GRUB, `boot.ipxe`) | Pflicht für Klonen und Aufnehmen |
| DNS | UDP/TCP 53 | Namensauflösung der Geräte, auch `thinforge-server` und die lokale Domain | Pflicht (ab Werk an) |
| Zeitdienst (NTP) | UDP 123 | Uhrzeit der Geräte (per DHCP-Option 42 verteilt) | Pflicht |
| HTTP | TCP 80 | PXE: Kernel, Clonezilla-Abbild, Deploy-Skripte und die Rückmeldungen der Geräte beim Klonen und Aufnehmen | Pflicht für Klonen und Aufnehmen |
| HTTPS | TCP 443 | Agent: Heartbeat, Zertifikate, Agent-Update, Delta-Downloads (`https://thinforge-server`) | Pflicht |
| NFS (Version 3) | TCP 2049, TCP/UDP 111 (rpcbind) und dynamische RPC-Ports (mountd) | Klon-Abbild beim Unicast-Deployment, Ablage beim Aufnehmen | Pflicht für Unicast-Deployment und Aufnehmen |
| BitTorrent | TCP/UDP 6969 (Tracker), TCP/UDP 6881 (Seeder) und Peer-Ports zwischen den Geräten | BitTorrent-Deployment; Tracker und Seeder laufen nur während des Rollouts | optional |
| Multicast | UDP ab 2232, zwei Ports je Partition, an 224.0.0.1 (TTL 1) | Multicast-Deployment; bleibt im Segment | optional |

**Server → Geräte**

| Dienst | Protokoll / Port | Zweck | Pflicht |
|---|---|---|---|
| SSH | TCP 22 | Terminal, Fernwartung (VNC 5900 läuft im SSH-Tunnel), Aufgaben, Steuerung von Klonen und Aufnehmen | Pflicht |
| ICMP | Echo | Erreichbarkeits-Ping aus der Clients-Ansicht | optional |
| Wake-on-LAN | UDP 9, Broadcast | Geräte einschalten; nur im selben Netz | optional |

## Server → Internet

Von sich aus baut der Server im Betrieb nur wenige Verbindungen auf. Die Tabellen nennen alle Ziele und wann sie angesprochen werden; abschalten lassen sie sich wie in [12 — Sicherheit](12-sicherheit-und-cve-scan.md#ausgehende-verbindungen) beschrieben.

**Im Betrieb**

| Ziel | Protokoll / Port | Zweck | Wann |
|---|---|---|---|
| Zeitserver — Vorgabe `0.pool.ntp.org`, `1.pool.ntp.org` | UDP 123 | Uhrzeit des Servers, von dem die Geräte ihre Zeit holen | dauerhaft; eigener Zeitserver unter **Einstellungen → Allgemein** |
| DNS-Server aus dem Einrichtungsassistenten | UDP/TCP 53 | Namen außerhalb des eigenen Netzes für die Geräte auflösen | bei DNS-Anfragen der Geräte; änderbar unter **Netzwerk → DNS** |
| VPN-Instanz — Host aus der URL der VPN-Verwaltung | TCP 443, dazu UDP 3478 (STUN, optional) | Verwaltung, Signal und Relay des VPN | dauerhaft, sobald das VPN eingerichtet ist (siehe unten) |
| Mailserver aus den Einstellungen | TCP 587 (STARTTLS) oder 465 (TLS); ein anderer Port nur ohne Anmeldung oder mit ausdrücklicher Freigabe (`allow_insecure_auth`) | Alarm-Mails, Testmail, Link aus „Passwort vergessen?“ | nur, wenn eingetragen |
| Webhook-Adresse aus den Einstellungen | TCP, Port aus der Adresse (443 oder 80) | Alarme | nur, wenn eingetragen |
| Schwachstellen-Datenbank `grype.anchore.io` | TCP 443 | Grundlage des Schwachstellen-Scans | nur beim Scan auf Knopfdruck |
| `www.cisa.gov` (KEV-Katalog), `git.thinforge.org` (neuere Akzeptanzliste) | TCP 443 | Abgleich der Scan-Bewertung | ab Werk aus |
| SourceForge (Clonezilla Live) bzw. eine frei eingegebene Adresse | TCP 443 oder 80 | ISO-Download im Assistenten oder „ISO von URL herunterladen“ | nur auf Klick |
| OCSP-Dienst der ausstellenden Zertifizierungsstelle | TCP 80 oder 443 | Sperrstatus eines hochgeladenen öffentlichen Zertifikats | abhängig vom Zertifikat; beim mitgelieferten selbstsignierten nicht |

**Installation und Update** — alles nur auf Befehl:

| Ziel | Protokoll / Port | Zweck | Wann |
|---|---|---|---|
| `git.thinforge.org` | TCP 443 | Release-Repository und die Container-Abbilder von ThinForge | `bootstrap-release.sh`, jedes `./deploy.sh` |
| Docker Hub (`registry-1.docker.io` und die Hosts, auf die Docker Hub beim Abruf weiterleitet) | TCP 443 | Abbilder von PostgreSQL, Redis und Caddy, für die Fernwartung (`guacamole/guacd`) und das VPN (`netbirdio/netbird`) | Installation und Update |
| Paketquellen von Ubuntu, `download.docker.com` | TCP 443 und 80 | Docker-Installation durch `install-deps.sh` | Installation |
| Docker Hub (`golang`) und der Go-Modul-Proxy (`proxy.golang.org`, `sum.golang.org`) | TCP 443 | Agent-Bau aus der Oberfläche | nur mit `THINFORGE_AGENT_BUILD_ENABLED=true`; in ThinForge-Release ab Werk aus |

Für eine Installation ohne Internet lassen sich die Abbilder vorab spiegeln (`./deploy.sh --pull-only` auf einem Rechner mit Internet, dann `docker save`/`docker load`) und die Clonezilla-ISO hochladen — Einzelheiten in [12 — Sicherheit](12-sicherheit-und-cve-scan.md#ausgehende-verbindungen).

**Image-Erstellung in der Cloning-VM** — die virtuelle Maschine hat über die Netzwerkumsetzung von QEMU ungefilterten Zugang ins Internet; beschränken lässt er sich nur an der Firewall des Hosts oder des Perimeters. Die Installationsskripte der Tools-ISO holen Pakete aus den Paketquellen der gewählten Distribution, den VPN-Client über das Installationsskript von `pkgs.netbird.io` und — fehlt das Paket in der Distribution — `grub-btrfs` von `github.com`; die optionalen VDI-Clients lädt `install-vdi-clients-debian.sh download` von den Seiten der Hersteller.

## VPN

Server und Geräte bauen die Verbindung zur VPN-Instanz von sich aus auf — von innen nach außen. Nach innen muss nichts geöffnet werden.

| Quelle → Ziel | Protokoll / Port | Zweck | Pflicht |
|---|---|---|---|
| ThinForge-Server → Host aus der URL der VPN-Verwaltung (z. B. `teststellung01.thinforge.org`) | TCP 443 | Verwaltung (Management-API), Signal und Relay: Anmeldung, Abgleich im Minutentakt und der Tunnel des Server-Peers | Pflicht |
| ThinForge-Server → derselbe Host | UDP 3478 | STUN für den Verbindungsaufbau; ohne ihn läuft der Tunnel des Servers über den Relay | optional |
| Geräte im Homeoffice → Host aus der URL der VPN-Verwaltung | TCP 443 | Verwaltung, Signal und Relay — die Geräte erzwingen den Relay-Weg (`NB_FORCE_RELAY=true`) und brauchen keinen weiteren Port | Pflicht |
| Geräte mit Agent bis Version 2.24.0 → `thinforge.org` | TCP 443 | Diagnose-Abruf (nur Kopfzeilen), nur wenn die VPN-Instanz nicht erreichbar ist; darf gesperrt bleiben | optional |

Bei der VPN-Option von ThinForge laufen Verwaltung, Signal, Relay und STUN unter dem einen Hostnamen aus der Buchung — im Beispiel `teststellung01.thinforge.org`: Verwaltung, Signal und Relay unter TCP 443, STUN unter UDP 3478. Bei einer selbst betriebenen Instanz gelten die dort eingerichteten Hostnamen und Ports — erreichbar sein müssen Management-API, Signal und Relay. Was durch den Tunnel läuft, regelt ThinForge über die Regeln der VPN-Instanz und nicht die Firmenfirewall: Geräte → Server auf TCP 443 und UDP 53, Server → Geräte per SSH (TCP 22) und ICMP, dazu die eigenen Freigaben ([13 — VPN](13-vpn.md)).

## Was nicht nötig ist

- **Kein eingehender Port aus dem Internet** zum Server und keine Portweiterleitung — auch nicht für das VPN. Geräte im Homeoffice erreichen den Server nur durch den Tunnel.
- **Keine Verbindung zum Hersteller im Betrieb:** keine Telemetrie, keine Prüfung des Abonnements (die Datei prüft der Server offline), keine Suche nach neuen Versionen, keine automatischen Zertifikate (kein ACME).
- **Kein Port 80** auf der Management-Adresse — den bedient der Server nur im Client-Netz für PXE.
- **Keine Freigaben für Datenbank, Redis, Backend und Frontend** — sie sind nur auf dem Server selbst erreichbar.

## Nächste Schritte

- [07 — Netzwerk](07-netzwerk.md) für DHCP, DNS und PXE im Client-Netz.
- [12 — Sicherheit](12-sicherheit-und-cve-scan.md#ausgehende-verbindungen) für Auslöser, Vorgabe und Abschalten der ausgehenden Verbindungen.
- [13 — VPN](13-vpn.md) für Einrichtung und Betrieb des VPN.
