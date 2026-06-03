# Workflow — Neuen Client aufnehmen

Ein frisch ausgepackter Thin-Client vom Karton bis zur grünen Status-Ampel im Dashboard. Dieser Workflow geht vom **Normalfall** aus: Client ist im Management-Netz, DHCP funktioniert, Golden-Image ist schon als Clone vorhanden.

## Voraussetzungen

- [ ] ThinForge-Server läuft, Web-UI erreichbar
- [ ] DHCP/PXE-Profil aktiv ([07](../07-netzwerk.md#tab-dhcp--pxe))
- [ ] Mindestens ein Clone (Baseline) in der Cloning-Ansicht ([05](../05-cloning.md)), der auf diese Hardware passt
- [ ] Der physische Client hängt im Management-Netz und kann PXE-Boot

## Schritt 1 — Tools-ISO (einmalig pro Infrastruktur)

Die Tools-ISO trägt das Provisioning-Script, den Agent-Binary, die VPN-Keys und das Server-Zertifikat. Sie wird nach dem ersten Setup automatisch gebaut — bei Zertifikats- oder Schlüsselrotation muss sie neu erzeugt werden.

1. **Cloning → ISOs**
2. Eintrag **„thinforge-tools.iso"** suchen
3. **„Rebuild"** klicken (dauert ~1 Minute)

## Schritt 2 — Client einschalten

- Gerät an Strom + Netzwerk anschließen
- Im BIOS/UEFI: PXE-Boot für den Netzwerk-Adapter aktivieren (bei den meisten Thin-Clients Default)
- Booten

Der Client bekommt per DHCP eine IP, lädt die PXE-Boot-Kette, bootet in die Tools-ISO und startet dort automatisch das Provisioning-Script.

**Während das läuft** (ca. 3–5 Minuten):
- DHCP-Lease erscheint unter [07 — Netzwerk → DHCP/PXE → Leases](../07-netzwerk.md#leases)
- Das Provisioning-Script schreibt Partitionstabelle, installiert den Agent, holt die Baseline via Unicast/BitTorrent, konfiguriert VPN

## Schritt 3 — Client meldet sich

Nach dem Neustart ist der Agent aktiv und sendet den ersten Heartbeat. Der Client erscheint:

1. **Clients-Liste** ([03](../03-clients.md)) — neuer Eintrag, Status „Online", Version entspricht der ausgerollten Baseline
2. **Dashboard** — Client-Status-Balken-Segment „Online" um 1 hochgezählt

## Schritt 4 — Zuweisen

- **Clients-Liste** → neuen Client markieren → **„Gruppe zuweisen"** → Zielgruppe wählen ([04](../04-gruppen.md))
- Optional: **Hostname** ändern (Detail-Tab → Übersicht → Bearbeiten); der neue Name wird beim nächsten Agent-Heartbeat übernommen

## Schritt 5 — Verifizieren

- **Terminal** auf dem Client öffnen ([03](../03-clients.md#terminal-web-ssh)): `hostname`, `df -h`, `systemctl status thinforge-agent`
- Wenn VPN-relevant: **VPN-Tab** auf Client-Detail, Last-Handshake sollte < 2 Min sein

## Stolperfallen

- **Kein DHCP** → Switch-Konfiguration (IGMP/Helper), Server-Subnetz-Einstellung prüfen
- **Client bootet in BIOS-Menü statt PXE** → BIOS-Boot-Order checken, Secure-Boot ggf. deaktivieren für Legacy-PXE
- **Provisioning-Script bricht ab** → TLS-Zertifikat im Tools-ISO alt? → Schritt 1 wiederholen
- **Client erscheint mit falschem Hostname** → Das ist der DHCP-Hostname; beim ersten Heartbeat übernimmt der Agent den echten. Ein paar Minuten warten.

## Nächste Schritte

- [workflows/update-verteilen.md](update-verteilen.md) — Wenn eine neue Version angesagt ist
- [03 — Clients](../03-clients.md) — Tägliche Verwaltung
