# Workflow — Neuen Client aufnehmen

Ein frisch ausgepackter Thin-Client vom Karton bis zur grünen Status-Ampel im Dashboard. Dieser Workflow geht vom **Normalfall** aus: Client ist im Rollout-Netz, DHCP funktioniert, Golden-Image ist schon als Clone vorhanden.

## Voraussetzungen

- [ ] ThinForge-Server läuft, Web-UI erreichbar
- [ ] DHCP/PXE eingerichtet ([07](../07-netzwerk.md#tab-dhcp--dnsmasq))
- [ ] Mindestens ein Clone (Baseline) in der Cloning-Ansicht ([05](../05-cloning.md)), der auf diese Hardware passt
- [ ] Der physische Client hängt im Rollout-Netz (dort, wo ThinForge DHCP/PXE anbietet) und kann PXE-Boot

## Schritt 1 — Tools-ISO (einmalig pro Infrastruktur)

Die Tools-ISO trägt das Provisioning-Script, den Agent-Binary, das Heartbeat-Token und das Server-Zertifikat (VPN-Schlüssel enthält sie keine — die entstehen erst beim Aktivieren eines Geräts im Menü VPN). Ein neuer Client bootet sie nicht selbst: die ISO hängt als zweites Laufwerk in der Cloning-VM, ihr Einrichtungsskript installiert Agent, SSH-Key, Heartbeat-Token und Server-Zertifikat ins Golden-Image ([workflows/golden-image.md](golden-image.md)), und jeder Clone bringt sie auf den Client mit. Der Server baut die ISO bei jedem Start der Cloning-VM neu — nicht schon beim Setup, und einen eigenen „Rebuild"-Knopf gibt es nicht. Nach einer Zertifikats- oder Schlüsselrotation genügt daher ein Neustart der Cloning-VM ([05](../05-cloning.md#tools-iso)).

1. Unter **Clients → Agent** prüfen, dass ein gebautes und signiertes Agent-Binary vorliegt — ohne baut der Server keine ISO, und die Cloning-VM startet nicht.
2. **Cloning** → Cloning-VM starten bzw. neu starten; dabei entsteht die aktuelle ISO.
3. Das Golden-Image mit dieser ISO einrichten und als Clone speichern — ein älterer Clone trägt den Stand, mit dem er eingerichtet wurde.

## Schritt 2 — MAC ermitteln und Client anlegen

DHCP und PXE bedienen **nur angelegte Geräte** — eine unbekannte MAC wird ignoriert und bekommt weder eine IP noch die Boot-Kette. Der Client muss also **zuerst** angelegt werden, damit er anschließend überhaupt booten kann.

1. **MAC-Adresse ermitteln** — vom Geräte-Aufkleber, aus dem BIOS/UEFI-Netzwerk-Screen oder aus deiner Inventarliste. (Nicht aus einem DHCP-Lease — solange das Gerät unbekannt ist, gibt es keins.)
2. **Clients-Liste** ([03](../03-clients.md)) → **„+ Client registrieren"** → MAC eintragen (optional Gruppe, Raum und Inventardaten) → speichern. Für viele Geräte auf einmal: CSV-Import.

ThinForge vergibt dabei den Rechnernamen `TF-<MAC>` (z. B. `TF-D45D64A1B2C3`); ändern lässt er sich nicht.

## Schritt 3 — Clone ausrollen und Client booten

1. **Cloning → Deployments** → **„Neues Deployment"**: als Ziel den neuen Client (oder seine Gruppe, wenn du sie in Schritt 2 gesetzt hast), dazu den Clone und die Methode wählen, z. B. Unicast ([06](../06-rollouts.md))
2. Gerät an Strom + Netzwerk anschließen
3. Im BIOS/UEFI: PXE-Boot für den Netzwerk-Adapter aktivieren (bei den meisten Thin-Clients Default)
4. Booten

Weil die MAC bekannt und das Deployment scharf ist, bekommt der Client per DHCP eine IP, bootet per PXE in Clonezilla und spielt den Clone auf seinen Datenträger.

**Während das läuft:**
- Der DHCP-Lease erscheint unter [07 — Netzwerk → DHCP / DNSMASQ → Leases](../07-netzwerk.md#leases) — praktisch, um zu prüfen, ob das angelegte Gerät eine IP bekommen hat
- Den Fortschritt je Client zeigt das Deployment (Cloning → Deployments, Zeile aufklappen)

Danach startet der Client vom frisch beschriebenen Datenträger (Nachaktion „Neustart"). Der Agent aus dem Image sendet Heartbeats; da der Client bereits angelegt ist, werden sie akzeptiert und das Gerät erscheint mit Status „Online" (Version = ausgerollte Baseline) in der Clients-Liste und im Dashboard. Beim ersten Start stellt der Agent das Betriebssystem auf den Rechnernamen `TF-<MAC>` um.

## Schritt 4 — Zuweisen

- **Clients-Liste** → neuen Client markieren → im Feld **„Gruppe zuweisen"** die Zielgruppe wählen → **Zuweisen** ([04](../04-gruppen.md))
- Optional: Inventarnummer, Raum und Benutzer in der Client-Detailansicht ergänzen → **Speichern**

## Schritt 5 — Verifizieren

- **Terminal** auf dem Client öffnen ([03](../03-clients.md#terminal-web-ssh)): `hostname`, `df -h`, `systemctl status thinforge-agent`
- Wenn VPN-relevant: Menü **VPN → Clients**, die Zeile des Geräts sollte „aktiv" und „verbunden" zeigen, der letzte Handshake sollte < 2 Min sein ([13](../13-vpn.md))

## Stolperfallen

- **Kein DHCP** → Ist das Gerät angelegt? Unbekannte MACs bekommen kein DHCP. Sonst Switch-Konfiguration (IGMP/Helper) und Server-Subnetz-Einstellung prüfen
- **Client bootet in BIOS-Menü statt PXE** → BIOS-Boot-Order checken, Secure-Boot ggf. deaktivieren für Legacy-PXE
- **Deployment bleibt für den Client auf „Ausstehend"** → Das Gerät hat nicht per PXE gebootet: Boot-Reihenfolge und Netzwerkkabel prüfen, dann neu starten.
- **Provisioning-Script bricht beim Einrichten des Golden-Image ab** → TLS-Zertifikat im Tools-ISO alt? → Schritt 1 wiederholen. Meldet es `signature check of the agent binary FAILED` oder `thinforge-agent.minisig is missing`, passt die Agent-Signatur nicht zum Signierschlüssel des Servers → unter **Clients → Agent** signieren, dann Schritt 1. Fehlt in der VM `minisign`, installiert das Script es nach und braucht dafür Zugang zu den Paketquellen.
- **Gerät trägt noch einen anderen Rechnernamen** → Den Namen `TF-<MAC>` setzt der Agent beim ersten Start; bis dahin gilt der Name aus dem Image. Ein paar Minuten warten.

## Nächste Schritte

- [workflows/update-verteilen.md](update-verteilen.md) — Wenn eine neue Version angesagt ist
- [03 — Clients](../03-clients.md) — Tägliche Verwaltung
