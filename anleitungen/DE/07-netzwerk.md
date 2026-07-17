# 7 — Netzwerk

Das Netzwerk-Menü bündelt alles, was für die Infrastruktur-Seite von ThinForge relevant ist: Server-Interfaces, DHCP, DNS und PXE-Boot.

Die Ansicht hat vier Tabs: **Lokales Netzwerk**, **DHCP / DNSMASQ**, **DNS** und **PXE Boot**. Den Fernzugriff per VPN findest du im eigenen Menüpunkt **VPN** ([13 — VPN](13-vpn.md)).

## Tab: Lokales Netzwerk (Server-Interfaces)

Zeigt alle Netzwerk-Interfaces des Server-Hosts mit aktueller IP, MAC und Link-Status. Für den normalen Betrieb meist nur Lesezugriff — ThinForge greift lesend auf `/proc/net` zu.

**Typische Nutzung:** nachsehen, über welches Interface der Traffic läuft, vor Rollouts checken, dass das Management-Interface wirklich online ist.

**„Aktualisieren"** schreibt per privilegiertem Kurz-Container eine Netplan-Datei auf den Host und appliziert sie — das ist ein Admin-Schritt, normalerweise schon beim Setup gemacht.

## Tab: DHCP / DNSMASQ

Der interne `dnsmasq`-Dienst übernimmt DHCP und PXE-Boot für das Management-Subnetz. Der PXE-Boot selbst wird im eigenen Tab **PXE Boot** behandelt.

### Einstellungen

| Feld | Bedeutung |
|------|-----------|
| Subnetz | CIDR des Management-Netzes, z. B. `192.168.10.0/24` |
| Gateway | üblicherweise die ThinForge-Server-IP; hier lässt sich auch eine interne Firewall als Gateway eintragen |
| DNS | Upstream DNS für Clients (Default: lokaler dnsmasq) |
| Rollout-IP-Range | Start und Ende des Pools, aus dem Clients beim PXE-Boot eine temporäre IP bekommen |
| Lease-Time | Standard 12h (Format z. B. `12h` oder `1d`) |
| Domain-Suffix | optional, z. B. `.thinforge.local` |

**Speichern** schreibt eine neue `dnsmasq.conf` und startet den Dienst neu.

### Leases

Tabelle mit aktuell vergebenen DHCP-Leases (MAC, IP, Hostname, Expires). **DHCP-Adressen werden nur an bekannte (angelegte) Clients vergeben — unbekannte Geräte werden ignoriert.** Ein Gerät muss also zuerst in der Clients-Liste angelegt sein, bevor es per DHCP/PXE eine IP bekommt; die Lease-Tabelle hilft dann zu prüfen, ob es eine erhalten hat.

## Tab: DNS

Zwei Bereiche:

### Upstream-DNS

Welche externen DNS-Server dnsmasq befragt, wenn ein Name nicht lokal bekannt ist. Default: Management-Gateway-IP aus Setup-Wizard. Für Außenstellen-Szenarien oft ein zentraler Firmen-DNS.

### Lokale Domain

Die interne Zone, für die dnsmasq als autoritativer Server auftritt (z. B. `thinforge.local`). Clients bekommen beim DHCP-Lease automatisch diese Domain als Such-Suffix.

Änderungen hier erfordern einen dnsmasq-Restart (passiert automatisch beim Speichern).

**Empfehlung:** Lass den ThinForge-Server als DNS-Server der Clients eingetragen (Standard, DHCP-Option 6). Er beantwortet die lokale Domain selbst und leitet externe Namen an den Upstream-DNS weiter; ein direkt gesetzter externer DNS bricht die lokale und VPN-interne Namensauflösung.

## Tab: PXE Boot

Dieser Tab bündelt die Boot-Infrastruktur und die Boot-Modi aller Clients. ThinForge stellt automatisch einen TFTP-Root und eine GRUB-EFI/BIOS-Boot-Kette bereit; neue Clients booten per PXE in die Tools-ISO (Provisioning) oder in einen Deploy-Boot (Image installieren).

**Statuskarten:** Drei Karten zeigen, ob der TFTP-/dnsmasq-Dienst läuft und ob die PXE-Boot-Dateien sowie das Clonezilla-Abbild (für Capture/Deploy) bereitliegen. Fehlt Clonezilla, lässt es sich direkt herunterladen (Standard-URL oder eigene URL) oder als ISO hochladen.

**Client-Liste:** Darunter sind alle Clients nach Gruppe gruppiert, je mit Hostname, Benutzer, Inventarnummer, Boot-Modus, zugewiesenem Image und Config-Datei. Pro Client lässt sich der Boot-Modus direkt setzen — auf **Lokal** zurücksetzen, eine **Capture** anstoßen oder die Boot-Config löschen. Es sind dieselben Boot-Modi wie in der Clients-Detailansicht ([03 — Clients](03-clients.md)), hier zentral für alle Geräte.

**Fehlerbilder:**

- Client zeigt „PXE-E61: Media test failure" → DHCP kommt nicht an. Prüfen, ob der Client angelegt ist (unbekannte MACs bekommen kein DHCP), sowie Subnetz, Gateway oder Switch-IGMP/Helper.
- Client bekommt IP, bootet aber nicht → TFTP blockiert? dnsmasq-Container läuft ([02 — Dashboard](02-dashboard.md))?

## VPN

ThinForge nutzt für den sicheren Zugriff auf Clients außerhalb des lokalen Management-Netzes (Außendienst, Home-Office, Außenstellen) ein VPN. Es hat einen eigenen Menüpunkt — alles dazu steht in [13 — VPN](13-vpn.md).

## Außenstellen

Wenn mehrere Filialen mit je eigenem lokalen Netz existieren, laufen die Clients dort meist via VPN zur Zentrale. Empfohlenes Setup:

- Eine **Gruppe pro Standort** ([04](04-gruppen.md))
- **BitTorrent-Rollout** statt Unicast — Clients einer Filiale verteilen die Daten intern über VPN-internes Peering
- **Multicast nicht über VPN** — läuft nur lokal. Für Innerfilial-Rollouts könnte perspektivisch ein Außenstellen-Relay sinnvoll sein, aktuell jedoch nicht vorgesehen

## Nächste Schritte

- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client mit DHCP+PXE aufnehmen
- [09 — Einstellungen](09-einstellungen.md) — NTP, TLS, generelle Server-Config
