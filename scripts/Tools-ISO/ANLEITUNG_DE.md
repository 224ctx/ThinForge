# ThinForge Install-Scripts — Kurzanleitung

## Voraussetzungen

- Cloning-VM mit Debian- oder Manjaro-ISO als Boot-Medium
- Tools-ISO als zweites CD-ROM eingehaengt (erscheint automatisch im Dateimanager als THINFORGE_TOOLS)

## Workflow: Debian (empfohlen)

```
0. Im ThinForge-UI Cloning-VM-Card -> "Basis HD erstellen" klicken,
   gewuenschte Groessen eingeben, Anwenden. Damit ist die qcow2 mit
   ESP + System (btrfs, noch ohne Subvolumes) + Data (btrfs/@data) vorbereitet.
1. Von Debian Live-ISO (XFCE) booten
2. Im Dateimanager auf THINFORGE_TOOLS navigieren, Terminal oeffnen
3. Vorbereiten:     sudo bash install-debian.sh prepare /dev/vda
4. Debian-Installer starten (Calamares), Manuelle Partitionierung waehlen,
   Partition 2 mit Mount-Option subvol=@root als / zuweisen
5. Ins neue System booten
6. Im Dateimanager auf THINFORGE_TOOLS navigieren, Terminal oeffnen
7. Abschliessen:    sudo bash install-debian.sh finish
```

### prepare

Konfiguriert Calamares fuer das in Schritt 0 ueber das UI angelegte Layout:
- Erstellt/aendert mount.conf: Root-Subvolume auf `@root` (noetig fuer Delta-Updates)
- Erstellt partition.conf: btrfs als Standard-Dateisystem

Disk-Layout selbst wird nicht mehr verifiziert — die UI ist Single Source of
Truth, Calamares meldet sich von selbst, falls die Partitionen nicht passen.

### finish

Richtet das installierte System ein:

| Schritt | Beschreibung |
|---------|-------------|
| GRUB | 2s Timeout, Snapshot-Menue sichtbar |
| grub-btrfs | Snapshots als Boot-Eintraege |
| Data-Partition | Partition 3 aus Schritt 0 (Label „Daten") als `/data` (Subvolume `@data`) in fstab eintragen und einhaengen; fehlt sie, bricht `finish` vor der Agent-Installation ab |
| Pakete | nfs-common, zstd, curl, jq, python3, x11-utils, minisign, chrony, zenity, yad |
| NetBird-Agent | VPN-Client ueber das offizielle Installationsskript (`pkgs.netbird.io/install.sh`); Dienst auf Relay-Zwang und IPv6-aus umgestellt, danach deaktiviert und gestoppt (aktiviert wird er erst, wenn ThinForge das Geraet fuer das VPN freischaltet); `/etc/netbird` und `/var/lib/netbird` zeigen auf `/data/netbird`, damit die Anmeldung Delta-Updates ueberlebt |
| SSH | Key-only Auth, Root per Key |
| Agent | ThinForge Agent + Delta-Update-Service. Das Agent-Binary wird vorher mit `minisign` gegen seine Signatur und den Signierschluessel des Servers geprueft; passt sie nicht, bricht `finish` ab (siehe unten) |
| Branding | tf-wall.png → `/etc/thinforge/`, gesetzt als Desktop-Hintergrund, GRUB-/Plymouth-Boot-Splash und Login-Hintergrund (nicht-fatal) |
| System-Update | apt-get dist-upgrade + Cache bereinigen |

---

## Workflow: Debian Minimal (netinst, ohne Live-System)

Fuer `debian-13.4.0-amd64-netinst.iso` — kein Live-System, kein Calamares,
nur der klassische Debian-Installer (d-i). Eignet sich fuer schlanke
Installationen ohne Desktop-Aufsatz und fuer Setups, in denen eine
netinst-ISO bereits in der Beschaffung vorhanden ist.

```
0. Im ThinForge-UI Cloning-VM-Card -> "Basis HD erstellen" klicken,
   gewuenschte Groessen eingeben, Anwenden. Damit ist die qcow2 mit
   ESP + System (btrfs, noch ohne Subvolumes) + Data (btrfs/@data) vorbereitet.
1. VM mit netinst-ISO booten, normaler d-i (kein Rescue noetig)
2. Im d-i: "Partitionen manuell aendern":
     Partition 1 -> /boot/efi   (FAT32 erhalten, NICHT formatieren)
     Partition 2 -> /            (btrfs erhalten, NICHT formatieren,
                                  Mount-Option subvol=@root setzen)
     Partition 3 -> NICHT verwenden (bleibt fuer /data)
3. Tasksel: nur "standard system utilities" (minimal)
4. Installation durchlaufen, ins neue System booten
5. Tools-ISO mounten und Abschliessen:
     sudo mkdir -p /mnt/tools && sudo mount /dev/sr1 /mnt/tools
     sudo bash /mnt/tools/install-debian-minimal.sh finish
```

**Tools-ISO-Pfad nach Boot ins installierte System:** die ThinForge-
Cloning-VM haengt die Tools-ISO immer als zweites CD-ROM ein — sie ist
garantiert unter `/dev/sr1` erreichbar (Volume-Label `THINFORGE_TOOLS`).
Im normalen Debian-Desktop wird sie automatisch unter
`/media/thinforge/THINFORGE_TOOLS` (oder aehnlich) gemountet. Aus dem
TTY oder ohne Auto-Mount manuell: `mount /dev/sr1 /mnt/tools`.
`/dev/sr0` ist das Install-Medium und sollte nicht angefasst werden.

### finish

Wie `install-debian.sh finish` — siehe Tabelle oben. Zusaetzlich waehlt man zu
Beginn die lokalen Benutzer aus, die sudo-Rechte bekommen (der erste davon
erhaelt LightDM-Autologin ohne Bildschirmsperre), und nicht benoetigte
vorinstallierte Programme werden entfernt (`DistroTweaks/cleanup-debian.sh`).
Am Ende bietet das Skript die Installation der VDI-Clients an
(`DebianVDIClients/install-vdi-clients-debian.sh`). Per `su` statt `sudo`
gestartet, richtet es sudo fuer das aufrufende Konto ein und startet sich
darueber neu.

`install-debian-minimal.sh` hat keinen `prepare`-Step: Das Layout entsteht
in Schritt 0 ueber das UI, der netinst-d-i nutzt es direkt — kein Calamares-
Zwischenschritt noetig wie bei der Live-ISO-Variante.

---

## Workflow: Manjaro (alternativ)

```
0. Im ThinForge-UI Cloning-VM-Card -> "Basis HD erstellen" klicken,
   gewuenschte Groessen eingeben, Anwenden.
1. Von Manjaro Live-ISO booten
2. Im Dateimanager auf THINFORGE_TOOLS navigieren, Terminal oeffnen
3. Vorbereiten:     sudo bash install-manjaro.sh prepare
4. Calamares starten, Manuelle Partitionierung waehlen, Partition 2
   mit Mount-Option subvol=@root als / zuweisen
5. Ins neue System booten
6. Im Dateimanager auf THINFORGE_TOOLS navigieren, Terminal oeffnen
7. Abschliessen:    sudo bash install-manjaro.sh finish
```

> Analoger Workflow gilt fuer `install-arch.sh` und `install-cachyos.sh`.

### prepare

Passt Calamares an, damit das in Schritt 0 ueber das UI angelegte Layout
nutzbar ist:
- Root-Subvolume von `@` auf `@root` aendern (noetig fuer Delta-Updates)

Disk-Layout selbst wird nicht mehr verifiziert — die UI ist Single Source of
Truth, Calamares meldet sich von selbst, falls die Partitionen nicht passen.

### finish

| Schritt | Beschreibung |
|---------|-------------|
| GRUB | 2s Timeout, Snapshot-Menue sichtbar |
| grub-btrfs | Snapshots als Boot-Eintraege |
| Data-Partition | `advanced/create-data-partition.sh`: Partition 3 aus Schritt 0 als `/data` (Subvolume `@data`) einhaengen und in fstab eintragen, fehlt sie, aus dem freien Platz am Ende der Disk anlegen; ohne `/data` bricht `finish` ab |
| Pakete | nfs-utils, zstd, curl, jq, python, xorg-xdpyinfo, minisign, zenity, yad |
| NetBird-Agent | wie bei Debian: offizielles Installationsskript, Relay-Zwang und IPv6-aus, Dienst deaktiviert und gestoppt, Zustand unter `/data/netbird` |
| SSH | Key-only Auth, Root per Key |
| Agent | ThinForge Agent + Delta-Update-Service. Das Agent-Binary wird vorher mit `minisign` gegen seine Signatur und den Signierschluessel des Servers geprueft; passt sie nicht, bricht `finish` ab (siehe unten) |
| Branding | tf-wall.png → `/etc/thinforge/`, gesetzt als Desktop-Hintergrund, GRUB-/Plymouth-Boot-Splash und Login-Hintergrund (nicht-fatal) |
| System-Update | pacman -Syu + Cache bereinigen |

---

## Branding (Wallpaper + Boot-Splash)

`finish` ruft am Ende automatisch das passende `DistroTweaks/install-branding-<distro>.sh`
auf. Es kopiert `tf-wall.png` (liegt im ISO-Root) nach `/etc/thinforge/tf-wall.png`
und setzt es als:

- **Desktop-Hintergrund** — für aktuelle und künftige Benutzer, via systemweitem
  Login-Autostart (`/etc/xdg/autostart/thinforge-wallpaper.desktop`), der die
  laufende Desktop-Umgebung selbst erkennt (XFCE/KDE/GNOME/Cinnamon/MATE/LXQt).
- **GRUB-Bootmenü-Hintergrund**, **Plymouth-Boot-Splash** und **Login-Screen**
  (LightDM/SDDM).

Der Schritt ist nicht-fatal — schlägt er fehl, läuft `finish` normal weiter.
Eigenständig nachträglich aufrufbar: `sudo bash DistroTweaks/install-branding-<distro>.sh`
(Bild via `TF_WALL_FILE=` überschreibbar).

---

## Option --server

```bash
sudo bash install-debian.sh finish --server=https://thinforge.firma.de
sudo bash install-manjaro.sh finish --server=https://thinforge.firma.de
```

Legt nur den NTP-Server der VM fest (Debian: chrony, Manjaro/Arch/CachyOS:
systemd-timesyncd) und hat dabei Vorrang vor dem Host aus `advanced/server_url`.
Die Server-URL des Agenten kommt immer aus `advanced/server_url` auf der ISO;
fehlt die Datei, bricht die Agent-Installation ab.

## Agent-Signatur

`advanced/1-create-client-management.sh` (von `finish` aufgerufen) installiert
den Agenten nur, wenn `thinforge-agent` zu `thinforge-agent.minisig` und zum
eben installierten Signierschluessel des Servers passt (`minisign -V`). Fehlt
`minisign`, installiert das Skript es per apt/dnf/pacman nach — dafuer braucht
die VM Zugang zu den Paketquellen; die `install-*.sh` bringen es in ihrer
Paketliste ohnehin mit. Meldet das Skript `signature check of the agent binary
FAILED` oder `thinforge-agent.minisig is missing`: auf dem Server unter
Clients → Agent das Binary bauen bzw. signieren („Signieren" oder „Neu
signieren"), die VM neu starten (der Server baut die Tools-ISO dabei neu),
die ISO neu einhaengen und `finish` erneut ausfuehren.

## ISO-Struktur

```
THINFORGE_TOOLS/
├── install-debian.sh
├── install-debian-minimal.sh
├── install-manjaro.sh
├── install-arch.sh
├── install-cachyos.sh
├── ANLEITUNG_DE.md
├── INSTRUCTIONS_EN.md
├── tf-wall.png
├── DistroTweaks/
│   ├── branding-common.sh
│   ├── cleanup-debian.sh
│   ├── install-branding-debian.sh
│   ├── install-branding-debian-minimal.sh
│   ├── install-branding-arch.sh
│   ├── install-branding-cachyos.sh
│   └── install-branding-manjaro.sh
├── DebianVDIClients/
│   ├── install-vdi-clients-debian.sh
│   ├── README.md
│   ├── urls.conf.example
│   └── (hochgeladene VDI-Client-Pakete)
└── advanced/
    ├── 1-create-client-management.sh
    ├── agent-apply-update.service
    ├── Agent-Check.sh
    ├── agent-migrate.sh
    ├── create-data-partition.sh
    ├── enable-ssh.sh
    ├── manual-manage-snapshots.sh
    ├── provision-remote-desktop.sh
    │   (die folgenden Dateien erzeugt der Server beim ISO-Bau)
    ├── thinforge-agent            Agent-Binary aus agent-go/bin/
    ├── thinforge-agent.minisig    seine Signatur (Pflicht)
    ├── thinforge.pub              Signierschluessel des Servers
    ├── agent-version              Versionsangabe, falls bekannt
    ├── server_url
    ├── server.crt
    ├── provisioning_key.pub
    └── heartbeat_token
```

Ohne gebautes, signiertes Agent-Binary baut der Server keine Tools-ISO; die
Cloning-VM startet dann nicht, und die Meldung nennt den fehlenden Schritt.
