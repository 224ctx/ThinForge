# 7 — Netzwerk

Das Netzwerk-Menü bündelt alles, was für die Infrastruktur-Seite von ThinForge relevant ist: Server-Interfaces, DHCP, DNS und PXE-Boot.

Die Ansicht hat vier Tabs: **Lokales Netzwerk**, **DHCP / DNSMASQ**, **DNS** und **PXE Boot**. Den Fernzugriff per VPN findest du im eigenen Menüpunkt **VPN** ([13 — VPN](13-vpn.md)).

> **Dieses Kapitel ist Admin-Sache.** Ansehen darf jede Rolle — alle Tabs, Statuskarten, Lease-Tabellen und Boot-Modi lassen sich als Operator oder Betrachter lesen. **Ändern darf seit 2026-08-31 nur ein Admin:** DHCP- und DNS-Einstellungen speichern, Leases zurücksetzen, dnsmasq neu laden, die Netplan-Konfiguration anwenden, Clonezilla herunterladen/hochladen/löschen, PXE-Dateien synchronisieren und Boot-Modi setzen oder löschen.
>
> Ohne Admin-Rolle zeigt die Ansicht oben einen Hinweis, die Formulare sind schreibgeschützt, und die Knöpfe zum Speichern, Neuladen, Zurücksetzen, Synchronisieren, für Clonezilla und für die Boot-Modi fehlen (seit dem Update vom 2026-09-30; vorher waren sie sichtbar und ein Klick endete in einer Fehlermeldung). Die Rechte prüft weiterhin der Server, siehe [Rollenübersicht](README.md#rollen-im-system).

## Tab: Lokales Netzwerk (Server-Interfaces)

Die Karte **Server-Netzwerkkonfiguration** hat zwei Bereiche:

- **Management-Netzwerk (Upstream / Internet)** — Interface mit der Standardroute und seine IP (nur Anzeige) sowie der **Upstream-DNS** für die Namensauflösung des Servers
- **Client-Netzwerk (Rollout / DHCP)** — **Interface** (Auswahl aller physischen Interfaces des Hosts mit MAC, Adresse und Link-Status), **Server-IP** und **CIDR**; daraus leitet die Oberfläche **Gateway**, **Subnetzmaske**, **DHCP Start** und **DHCP Ende** ab (von Hand geänderte Felder bleiben stehen); dazu **Domain** und **Lease-Dauer**

**Typische Nutzung:** nachsehen, über welches Interface der Traffic läuft, vor Rollouts checken, dass das Management-Interface wirklich online ist.

**„Speichern"** legt die Server-IP auf das Client-Interface (per privilegiertem Kurz-Container als Netplan-Datei auf dem Host und sofort als Adresse), schreibt die DHCP-Konfiguration neu, zieht den DNS-Eintrag `thinforge-server` nach und startet dnsmasq neu, damit Interface und DHCP-Bereich sofort gelten — das ist ein Admin-Schritt, normalerweise schon beim Setup gemacht. Scheitert der Neustart, meldet die Oberfläche das als Warnung statt als Erfolg: gespeichert ist dann alles, dnsmasq arbeitet aber bis zu seinem nächsten Neustart mit dem alten Stand.

## Tab: DHCP / DNSMASQ

Der interne `dnsmasq`-Dienst übernimmt DHCP und PXE-Boot für das Client-Netz. Der PXE-Boot selbst wird im eigenen Tab **PXE Boot** behandelt.

Oben steht der Hinweis **MAC-Filter aktiv**: dnsmasq antwortet nur registrierten MAC-Adressen und läuft nicht-autoritativ, kann also neben einem bestehenden DHCP-Server betrieben werden. Meldet ein Client eine andere IP als seine fest zugewiesene, listet eine Warnung **IP-Adress-Konflikt erkannt** ihn mit beiden Adressen.

### Einstellungen

Zuerst den Modus wählen: **DHCP-Server** (dnsmasq vergibt die Adressen) oder **ProxyDHCP (PXE Only)** — dann vergibt ein bestehender DHCP-Server die Adressen, dnsmasq liefert nur die PXE-Boot-Informationen, und statt Pool und Netzwerk-Optionen trägst du das **Subnetz** des bestehenden DHCP-Servers und optional das Interface ein.

> **ProxyDHCP ist seit 2026-09-30 bis zur Klärung nicht wählbar.** Der Knopf ist gesperrt, der Server weist die neue Wahl ab: ThinForge reserviert im Proxy-Betrieb keine Client-Adressen, die NFS-Freigabe eines Deployments bliebe deshalb ohne Client-IP. Eine Installation, die bereits im Proxy-Betrieb läuft, läuft unverändert weiter und kann ihre Einstellungen weiter speichern; wechselt sie auf **DHCP-Server**, gibt es keinen Weg zurück.

| Feld | Bedeutung |
|------|-----------|
| IP-Bereich Start / Ende | Pool, aus dem jeder angelegte Client seine feste IP bekommt. Start und Ende müssen im Netz der Server-IP (Rollout-Netz, Subnetzmaske) liegen, ohne Netz- und Broadcastadresse, und der Start darf nicht hinter dem Ende stehen — sonst weist der Server das Speichern ab |
| Subnetzmaske | z. B. `255.255.255.0` |
| Lease-Zeit | Vorgabe 2h (Format z. B. `12h` oder `1d`) |
| Netzwerk-Interface | leer = dnsmasq lauscht auf allen Interfaces |
| Standard-Gateway | DHCP-Option 3; üblicherweise die ThinForge-Server-IP; hier lässt sich auch eine interne Firewall als Gateway eintragen |
| DNS-Server | DHCP-Option 6 — eine Liste mit **DNS-Server hinzufügen** und Löschen je Zeile, jede Zeile eine IPv4-Adresse; leer = die Gateway-Adresse (dnsmasq selbst). Bis zum Update vom 2026-10-02 gab es zwei feste Felder, und ein dritter gespeicherter Server fiel beim nächsten Speichern weg |
| Domain | optional, DHCP-Option 15, z. B. `thinforge.local` |

Den **Upstream-DNS des Servers** (Internetauflösung des Servers selbst) pflegt der Tab **Lokales Netzwerk**. Bis zum Update vom 2026-09-30 stand er auch hier als Feld — eine Änderung an dieser Stelle verwarf der Server beim Speichern still.

**Speichern & Anwenden** schreibt `/etc/dnsmasq.d/dhcp-settings.conf` und startet dnsmasq neu; scheitert der Neustart, warnt die Oberfläche.

### Leases

Darunter zeigen drei Karten den Dienststatus, die registrierten Clients und die aktiven Leases; **„Konfig neu laden"** erzeugt die Geräte-Konfiguration neu und lädt dnsmasq neu, **„Leases zurücksetzen"** löscht die Leases (Clients bekommen beim nächsten Request ihre reservierte IP), **„Konfiguration anzeigen"** blendet die generierte `clients.conf` ein. Die Tabelle **Aktive DHCP-Leases** listet MAC-Adresse, IP-Adresse, Hostname und Ablauf (eine Lease ohne Ablauf steht als „unbefristet"). **DHCP-Adressen werden nur an bekannte (angelegte) Clients vergeben — unbekannte Geräte werden ignoriert.** Ein Gerät muss also zuerst in der Clients-Liste angelegt sein, bevor es per DHCP/PXE eine IP bekommt; die Lease-Tabelle hilft dann zu prüfen, ob es eine erhalten hat.

## Tab: DNS

Der Schalter **DNS aktiviert** steht oben; ausgeschaltet arbeitet dnsmasq nur als DHCP-/TFTP-Server. Eingeschaltet gibt es fünf Bereiche: **Upstream DNS-Server**, **Lokale Domain**, **DNS-Cache** (0–50000 Einträge, 0 = kein Cache), **Protokoll** (Schalter **DNS-Anfragen protokollieren** — schreibt jede Anfrage jedes Clients ins dnsmasq-Container-Protokoll; Vorgabe aus, nur zur Fehlersuche einschalten, wirksam mit dem Neustart beim Speichern) und **Eigene DNS-Einträge** (IP-Adresse und Hostname für Geräte oder Dienste ohne DHCP). Einträge, die zu einer VPN-Freigabe mit DNS-Namen gehören, stehen schreibgeschützt über der Liste und tragen den Hinweis **VPN-Freigabe**: sie gehören der Freigabe, geändert oder gelöscht werden sie dort ([13 — VPN](13-vpn.md)); ein eigener Eintrag mit demselben Namen wird abgewiesen. Ebenso schreibgeschützt, mit dem Hinweis **Verwaltet**, stehen die Einträge, die ThinForge selbst pflegt: `thinforge-server` und die Namen aus dem TLS-Zertifikat zeigen immer auf die Serveradresse im Rollout-Netz und werden bei jedem Speichern neu gesetzt; ein eigener Eintrag mit einem dieser Namen wird abgewiesen (bis zum Update vom 2026-10-02 ließen sie sich bearbeiten, die Änderung war nach dem Speichern aber wieder weg). Die IP-Adresse eines eigenen Eintrags darf IPv4 oder IPv6 sein. Hostnamen folgen denselben Regeln wie beim Server: je Abschnitt 1–63 Zeichen aus Buchstaben, Ziffern, `-` und `_`, keine leeren Abschnitte.

### Upstream-DNS

Welche externen DNS-Server dnsmasq befragt, wenn ein Name nicht lokal bekannt ist — eine Liste mit **Server hinzufügen** und Löschen je Zeile; jede Zeile eine IP-Adresse (IPv4 oder IPv6), optional mit `#Port`. Default: der im Setup-Wizard eingetragene Upstream-DNS des Management-Netzes, sonst die DNS-Server des Hosts; gibt es beides nicht, bleibt die Liste leer und dnsmasq löst nur lokale Namen auf (feste Vorgaben wie `8.8.8.8` gibt es seit 2026-09-30 nicht mehr). Für Außenstellen-Szenarien oft ein zentraler Firmen-DNS.

### Lokale Domain

Die interne Zone, für die dnsmasq als autoritativer Server auftritt (z. B. `thinforge.local`). Clients bekommen beim DHCP-Lease automatisch diese Domain als Such-Suffix. Mit **Hostnamen automatisch erweitern** werden DHCP-Clients als `hostname.domain` auflösbar.

Änderungen hier erfordern einen dnsmasq-Restart (passiert automatisch beim Speichern).

Was dnsmasq nicht tragen kann, weist der Server beim Speichern ab und speichert dann nichts: ein Upstream, der keine IP-Adresse (mit optionalem `#Port`) ist, eine lokale Domain oder ein Hostname mit anderen Zeichen als Buchstaben, Ziffern, Bindestrich und Unterstrich (je Teil höchstens 63 Zeichen), ein Eintrag ohne gültige IP-Adresse oder mit nur einer der beiden Angaben, eine negative Cache-Größe. Bis zum Update vom 2026-09-30 meldete die Seite in diesen Fällen „gespeichert", und der Wert fehlte stillschweigend in der Konfiguration.

Hat inzwischen jemand anderes die DNS-Einstellungen gespeichert (etwa ein zweiter Admin oder der Einrichtungsassistent), speichert der Server ebenfalls nichts: das Formular lädt den gespeicherten Stand neu und meldet es, die eigene Änderung ist dann erneut einzutragen. Bis zum Update vom 2026-10-02 überschrieb ein veraltetes Formular den neueren Stand still.

**Empfehlung:** Lass den ThinForge-Server als DNS-Server der Clients eingetragen (Standard, DHCP-Option 6). Er beantwortet die lokale Domain selbst und leitet externe Namen an den Upstream-DNS weiter; ein direkt gesetzter externer DNS bricht die lokale und VPN-interne Namensauflösung.

## Tab: PXE Boot

Dieser Tab bündelt die Boot-Infrastruktur und die Boot-Modi aller Clients. ThinForge stellt automatisch einen TFTP-Root und eine GRUB-EFI/BIOS-Boot-Kette bereit; je nach Boot-Modus bootet ein Client per PXE in eine Capture (Image aufnehmen), in einen Deploy-Boot (Image installieren) oder lokal von seiner Platte.

**Statuskarten:** Drei Karten zeigen, ob der TFTP-/dnsmasq-Dienst läuft und ob die PXE-Boot-Dateien sowie das Clonezilla-Abbild (für Capture/Deploy) bereitliegen. Fehlt Clonezilla, lässt es sich direkt herunterladen (Standard-URL oder eigene URL) oder als ISO hochladen.

**Client-Liste:** Darunter sind alle Clients nach Gruppe gruppiert, je mit Hostname, Benutzer, Inventarnummer, Boot-Modus, zugewiesenem Image und Config-Datei. Pro Client lässt sich der Boot-Modus direkt setzen — auf **Lokal** zurücksetzen, eine **Capture** anstoßen (Dialog **Disk-Image aufnehmen** mit Image-Name) oder die Boot-Config löschen. **„Alle synchronisieren"** legt fehlende Boot-Configs an; laufende Deploy-Configs bleiben unangetastet. Die Boot-Modi selbst erklärt [03 — Clients](03-clients.md); den Deploy-Modus setzen die Deployments ([06](06-rollouts.md)) — die Spalte nennt ihn als **Klon-Deployment**, **Multicast-Deployment** oder **BitTorrent-Deployment** (bis zum Update vom 2026-09-30 stand ein solches Gerät dort als „Keine Config“).

**Fehlerbilder:**

- Client zeigt „PXE-E61: Media test failure" → DHCP kommt nicht an. Prüfen, ob der Client angelegt ist (unbekannte MACs bekommen kein DHCP), sowie Subnetz, Gateway oder Switch-IGMP/Helper.
- Client bekommt IP, bootet aber nicht → TFTP blockiert? dnsmasq-Container läuft ([02 — Dashboard](02-dashboard.md))?

## VPN

ThinForge nutzt für den sicheren Zugriff auf Clients außerhalb des lokalen Management-Netzes (Außendienst, Home-Office, Außenstellen) ein VPN. Es hat einen eigenen Menüpunkt — alles dazu steht in [13 — VPN](13-vpn.md).

## Außenstellen

Wenn mehrere Filialen mit je eigenem lokalen Netz existieren, laufen die Clients dort meist via VPN zur Zentrale. Empfohlenes Setup:

- Eine **Gruppe pro Standort** ([04](04-gruppen.md))
- **Clone-Deployments nur vor Ort** — Unicast, Multicast und BitTorrent verteilen vollständige Images ausschließlich im Rollout-LAN des ThinForge-Servers ([06 — Rollouts und VPN](06-rollouts.md#rollouts-und-vpn)); Geräte einer Filiale werden also in der Zentrale bespielt oder mit einem dort erzeugten Klon ausgeliefert
- **Über das VPN laufen Verwaltung und Delta-Updates** — Heartbeat, Fernzugriff und die Update-Kette erreichen die Filiale durch den Tunnel; ein Außenstellen-Relay für Rollouts vor Ort ist nicht vorgesehen

## Nächste Schritte

- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client mit DHCP+PXE aufnehmen
- [09 — Einstellungen](09-einstellungen.md) — NTP, TLS, generelle Server-Config
