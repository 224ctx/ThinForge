# ThinForge — Debian VDI Clients

Ablageort der **VDI-Client-Pakete** + Installer. **Für keinen der drei Clients
gibt es ein öffentliches apt-Repository** — die Pakete sind EULA-gated Downloads
von der jeweiligen Hersteller-Seite. Sie werden einmal in diesen Ordner gelegt,
auf die Tools-ISO gebaut und beim Client-Setup von hier installiert.

## Ablauf

1. **Pakete in diesen Ordner legen** — entweder manuell von der Hersteller-Seite
   herunterladen, oder auf dem Build-Host:
   ```
   cp DebianVDIClients/urls.conf.example DebianVDIClients/urls.conf   # URLs eintragen
   bash DebianVDIClients/install-vdi-clients-debian.sh download
   ```
2. **Tools-ISO bauen** — die Pakete liegen dann unter `DebianVDIClients/` auf der ISO.
3. **Auf dem Client installieren** (als root):
   ```
   sudo bash /media/cdrom0/DebianVDIClients/install-vdi-clients-debian.sh
   ```
   (oder den Aufruf aus `install-debian-minimal.sh finish` heraus ergänzen).

## Erkannte Dateinamen / Bezugsquellen

| Client | Datei(en) im Ordner | Bezug |
|---|---|---|
| **Citrix Workspace App** | `icaclient*.deb` (+ optional `ctxusb*.deb`) | <https://www.citrix.com/downloads/workspace-app/linux/> |
| **Parallels Client (RAS)** | `*parallels*client*.deb` / `parallelsclient*.deb` | <https://www.parallels.com/products/ras/download/client/> |
| **Omnissa Horizon Client** | `*Horizon*Client*.bundle` (oder `*horizon*client*.deb`) | <https://docs.omnissa.com/bundle/HorizonClientLinuxGuideVmulti/page/HorizonClientforLinuxGuide.html> |

## Automatisierbarkeit (Stand 2026-06-03, verifiziert)

| Client | Auto-Download via `download`? | Wie / warum |
|---|---|---|
| **Parallels Client** | ✅ ja, **ohne** Konfiguration | `download` löst die aktuelle 64-bit-`.deb` aus dem Manifest `RASClient.xml` auf (kein EULA/Login). `PARALLELS_URL` nur für Version-Pinning. |
| **Citrix Workspace App** | ✅ ja (Seiten-Scrape), **fragil** | `download` scrapet den `icaclient_*_amd64.deb`-Link inkl. frischem Token aus der Citrix-Linux-Seite (kein Login; der Token läuft am selben Tag ab, wird daher pro Lauf frisch geholt). Bricht, wenn Citrix die Seite/Token-Logik ändert → dann `CITRIX_URL` manuell in `urls.conf` setzen (Link nach EULA-Klick kopieren). |
| **Omnissa Horizon Client** | ❌ nein | Download nur über Customer-Connect-**Login**. Paket manuell mit Account ziehen und als `*Horizon*Client*.bundle` in diesen Ordner legen. |

## Hinweise

- **Citrix / Parallels** liefern `.deb` → Installation per `apt-get install -y ./datei.deb` (zieht Abhängigkeiten automatisch).
- **Omnissa Horizon** liefert i.d.R. ein `.bundle` (self-extracting) → `sh datei.bundle --console --required --eulas-agreed`. Flags sind per Env `HORIZON_BUNDLE_FLAGS` überschreibbar. Liegt stattdessen ein `.deb` vor, wird dieses genutzt.
- Der Installer ist **idempotent** und überspringt fehlende Clients ohne Fehler — es muss nicht jeder der drei vorhanden sein.
- Die eigentlichen Hersteller-Pakete sind **nicht im Git** (lizenziert + groß), siehe `.gitignore`. In den Git eingecheckt sind nur Installer, README und `urls.conf.example`.
- Es gibt **keine apt-Auto-Updates** — bei neuen Client-Versionen das Paket austauschen und die ISO neu bauen.
