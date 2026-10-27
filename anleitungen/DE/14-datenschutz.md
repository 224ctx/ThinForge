# 14 — Datenschutz

Dieses Kapitel listet auf, welche personenbezogenen oder personenbeziehbaren Daten ThinForge speichert: wo sie liegen, wie lange sie bleiben, wer sie sieht und wie man sie löscht oder herausgibt. Es soll dir helfen, das Verzeichnis der Verarbeitungstätigkeiten zu führen und Anfragen zu Auskunft oder Löschung zu beantworten.

> **Keine Rechtsberatung.** Das Kapitel beschreibt, wie sich die Software verhält. Ob eine Verarbeitung zulässig ist, welche Fristen angemessen sind und wer im Betrieb zu beteiligen ist, entscheidet der Betrieb selbst.

Die Rollen (Admin, Operator, Betrachter) sind in der [Übersicht](README.md#rollen-im-system) beschrieben. Das **Datenverzeichnis** ist der Ordner, den `STORAGE_DIR` in der `.env` festlegt (Vorgabe `./ThinForgeDaten` im Installationsordner).

## Überblick

| Ort | Was dort liegt |
|-----|----------------|
| Datenbank (PostgreSQL, Ordner `postgres` im Datenverzeichnis) | Konten, Geräte, Audit-Log, Aufträge, SSH-Befehle, Vorfälle, VPN-Zuordnung, Einstellungen |
| Datenverzeichnis | Sicherungen (`backups`), Images (`clones`), Aufnahmen (`captures`), DHCP-Daten (`dnsmasq`), Klon-Exporte (`exports`) |
| Redis | kurzlebige Einträge: Sperrliste abgemeldeter Sitzungen, Fehlversuche beim zweiten Faktor, Links zum Zurücksetzen des Passworts, Auftragswarteschlange. Für Redis ist kein Volume eingerichtet |
| Protokolle der Container | was die Dienste protokollieren, siehe [Protokolle der Container](#protokolle-der-container) |
| Die verwalteten Geräte | Konfiguration und Protokolle des Agenten |
| Browser der Bedienenden | Anmelde-Cookies und Anzeige-Einstellungen |

## Konten der Bedienenden

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen / Export |
|-------|-----|--------------|--------------|------------------|
| Benutzername, E-Mail-Adresse, Rolle, Aktiv-Schalter, Zeitpunkt von Anlage und letzter Änderung | Tabelle `users` | bis das Konto gelöscht wird | Admins (**Einstellungen → Benutzer & Rollen**); jede Person ihr eigenes Konto im Profil | Admins löschen unter **Einstellungen → Benutzer & Rollen**; einen Export gibt es nicht |
| Passwort als Argon2id-Hash, Geheimnis der Zwei-Faktor-Anmeldung (TOTP) | Tabelle `users` | bis das Konto gelöscht wird; das TOTP-Geheimnis bis die 2FA abgeschaltet oder zurückgesetzt wird | in der Oberfläche niemand | mit dem Konto |

- Das TOTP-Geheimnis liegt seit dem Update vom 2026-10-09 verschlüsselt in der Datenbank (AES-256-GCM). Wer nur die Datenbank, einen Abzug davon oder den Ordner `postgres` in die Hand bekommt, kann es nicht lesen. Den Schlüssel dazu enthält aber auch die System-Sicherung: Aus einer Sicherung ohne Passwort lässt sich das Geheimnis weiterhin gewinnen, und ältere Sicherungen enthalten es noch unverschlüsselt (spielt man eine solche zurück, verschlüsselt der Server es beim Neustart). Vergib deshalb ein Passwort für die Sicherung oder schütze die Datei wie den Server selbst ([Sicherungen](#sicherungen)).
- Die E-Mail-Adresse braucht der Server nur für **Passwort vergessen?**: Ist ein Mail-Kanal eingerichtet, geht der Link dorthin. Er gilt 15 Minuten und nur einmal ([10 — Profil & 2FA](10-profil-und-2fa.md)).
- **Deaktivieren** statt Löschen sperrt die Anmeldung, behält aber alle Daten.
- Nach dem Löschen bleiben Verweise auf das Konto bestehen. Einträge im Audit-Log behalten die Kennung des Kontos, Anmeldeeinträge auch den Benutzernamen. Vorfälle, die das Konto quittiert oder gelöst hat, Wartungsfenster, die es angelegt hat, gespeicherte Einstellungen und Aufträge behalten seine Kennung. Bei den SSH-Befehlsprotokollen und den Aufgaben-Vorlagen fällt der Verweis weg; die Einträge selbst bleiben. Das eigene Konto lässt sich nicht löschen.

## Anmeldung und Sitzungen

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen |
|-------|-----|--------------|--------------|---------|
| Anmeldungen und Fehlversuche: Zeit, Konto bzw. versuchter Benutzername, Absenderadresse (IP) | Audit-Log (`audit_log`) | wie das [Audit-Log](#audit-log) | Admins | wie das Audit-Log |
| Anmelde-Cookies `tf_access` und `tf_refresh` | Browser | `tf_access` 15 Minuten; `tf_refresh` für die eingestellte Sitzungsdauer, die mit jeder Nutzung neu beginnt (Vorgabe 7 Tage, in der Oberfläche 1 Stunde bis 30 Tage) | nur der Server (httpOnly) | Abmelden; eine Änderung oder Rücksetzung des Passworts beendet alle Sitzungen des Kontos |
| Sperrliste abgemeldeter Sitzungen, Fehlversuche beim zweiten Faktor, Links zum Zurücksetzen des Passworts | Redis | bis zum Ablauf des jeweiligen Tokens; die Sperre nach Fehlversuchen 15 Minuten; der Rücksetz-Link 15 Minuten | in der Oberfläche niemand | verfallen von selbst |

- Eine Liste angemeldeter Sitzungen führt der Server nicht.
- Die Absenderadresse übernimmt der Server vom Proxy (Caddy), nicht aus Angaben des Browsers. Fehlt sie, bleibt das Feld leer.
- Fehlversuche derselben Quelle fasst das Audit-Log je Minute zu einem Eintrag zusammen. Bei unbekannten Benutzernamen stehen bis zu zehn der eingegebenen Namen darin, so wie sie eingetippt wurden (auf 128 Zeichen gekürzt). Details: [08 — Tasks & Logs](08-tasks-logs.md).
- Die Begrenzung der Anmeldeversuche je Absender hält der Server nur im Arbeitsspeicher.
- Die Sitzungsdauer stellen Admins unter **Einstellungen → General (Allgemein)** ein ([09 — Einstellungen](09-einstellungen.md)).

## Audit-Log

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen / Export |
|-------|-----|--------------|--------------|------------------|
| Wer (Konto) wann was getan hat, mit Absenderadresse und Details (etwa Namen von Geräten, Dateien oder geänderten Werten) | Tabelle `audit_log` | Vorgabe 365 Tage, einstellbar 30 bis 3650 Tage unter **Einstellungen → General (Allgemein)** (nur Admins); der Worker löscht täglich und bei jedem Neustart | Admins (**Logs → Audit-Log**) | Löschen nur über die Aufbewahrung, nicht einzeln. Einen Export gibt es in der Oberfläche nicht; die Liste lässt sich nach Aktion und Pfad filtern, nicht nach Konto |

- Im Audit-Log stehen unter anderem Anmeldungen, Änderungen an Konten und Einstellungen, Sicherungen, das Anlegen, Ändern und Löschen von Geräten (auch per CSV-Import und als Gruppenzuweisung für mehrere Geräte) und von Gruppen sowie Befehle an Geräte (Einschalten, Neustart, Herunterfahren, **MAC übernehmen**, **Token neu ausstellen**, **Reset auf Install Token**). Ebenso stehen dort Aufgaben-Vorlagen, die über die Programmierschnittstelle angelegt, geändert, gelöscht oder ausgeführt wurden; beim Ausführen mit der Zahl der Aufträge und den Zielgeräten. Bei einer Änderung nennt der Eintrag nur die Namen der geänderten Felder, nicht ihre Werte — was etwa im Feld **Benutzer** stand, steht nicht im Audit-Log, ebenso wenig die Beschreibung einer Gruppe oder der Befehl einer Aufgaben-Vorlage (den ausgeführten Befehl halten die SSH-Befehlsprotokolle fest).
- Seit dem Update vom 2026-10-16 stehen dort auch Änderungen unter **Einstellungen → Benachrichtigungen** (**Benachrichtigungskanäle geändert**, **Alarm-Schwellenwerte geändert**), ebenfalls nur mit den Namen der geänderten Felder: welche Adresse, welcher Mailserver, Benutzer oder welches Passwort eingetragen wurde, steht nicht im Audit-Log. Vorher hielt nur die Einstellung selbst fest, wer sie zuletzt gespeichert hatte.
- Terminal- und Fernwartungssitzungen stehen mit Beginn und Ende im Audit-Log: Konto, Absenderadresse, Gerät, Dauer und ob die Verbindung zustande kam. Was in einer Sitzung eingegeben oder angezeigt wird, steht dort nicht ([SSH-Befehle, Terminal und Fernwartung](#ssh-befehle-terminal-und-fernwartung)).
- Das Audit-Log gehört nicht zur System-Sicherung ([Sicherungen](#sicherungen)).

## Geräte und Aufträge

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen / Export |
|-------|-----|--------------|--------------|------------------|
| Stammdaten: Hostname, MAC-Adresse, Inventarnummer, Raum, **Benutzer** (Freitext), Kaufdatum, Garantie, Rechnungsnummer, Lieferant, Gruppe | Tabelle `clients` | bis das Gerät gelöscht wird | alle Rollen (Clients-Liste und Detail) | ändern Admins und Operatoren; das Gerät löschen nur Admins. Export: **CSV exportieren** in der Clients-Liste (alle Rollen) |
| Betriebsdaten: Status, zuletzt gesehen, IP-Adressen, Auslastung, Agent- und Image-Version, VPN-Status, Grund eines abgewiesenen Heartbeats | Tabelle `clients` | wird laufend überschrieben | alle Rollen | mit dem Gerät |
| Hardware-Inventar: Hersteller, Modell, Seriennummern von Gerät und Festplatte, BIOS-Version, CPU, Arbeitsspeicher | Tabelle `clients` | bis zur nächsten Inventur bzw. bis das Gerät gelöscht wird | alle Rollen | mit dem Gerät |
| Aufträge an Geräte: Typ, Status, Zeitpunkte, Fehlermeldung, Parameter, auslösendes Konto | Tabelle `client_tasks` | erledigte, fehlgeschlagene und abgebrochene Aufträge 30 Tage, einstellbar unter **Tasks → Geplante Aufgaben** | alle Rollen (**Tasks**) | automatisch; einzeln unter **Tasks** (Admins und Operatoren); mit dem Gerät |

- Einen Bezug zu einer Person bekommt ein Gerät vor allem über das Feld **Benutzer** und über Raum oder Inventarnummer. Was dort steht, legst du fest, von Hand oder per CSV-Import ([03 — Clients](03-clients.md)).
- Der Agent meldet im Heartbeat nicht, wer am Gerät angemeldet ist. Den Namen der angemeldeten Person liest er nur auf dem Gerät selbst, um dort Hinweise anzuzeigen, etwa während einer Fernwartung.
- Der CSV-Export enthält Hostname, MAC-Adresse, Status, Benutzer, Raum, Gruppe, installierte Version, Inventarnummer, Rechnungsnummer und Lieferant. Er entsteht im Browser aus der geladenen Liste.
- Löscht ein Admin ein Gerät, entfernt der Server auch: VPN-Zuordnung (mit Widerruf des VPN-Zugangs), DHCP-Leases, Vorfälle, Aufträge, SSH-Befehlsprotokolle und die Einträge des Geräts in Deployments, Aufnahmen, Updates und Rollbacks. Einträge im Audit-Log, die das Gerät nennen, bleiben bis zum Ende der Aufbewahrung, ebenso Kopien in älteren Sicherungen.

## Auf den Geräten

- Der Agent hält seine Konfiguration auf der Datenpartition des Geräts (`/data/thinforge/agent.conf`) und schreibt seine Meldungen in das Systemjournal des Geräts. Die Hilfen für Fernwartung und Benachrichtigungen protokollieren nach `/var/log/tf-remote-desktop.log` und `/var/log/tf-notify.log`. Diese Protokolle bleiben auf dem Gerät; der Server holt sie nicht ab.
- Was Personen am Gerät selbst speichern, erfasst ThinForge nicht. Es gerät aber in eine **Aufnahme** dieses Geräts ([Images, Aufnahmen und Exporte](#images-aufnahmen-und-exporte)).

## DHCP und DNS

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen |
|-------|-----|--------------|--------------|---------|
| Aktive Leases: MAC-Adresse, IP-Adresse, Hostname, Ablauf | Datei `dnsmasq.leases` im Ordner `dnsmasq` | bis die Lease abläuft oder freigegeben wird | alle Rollen (**Netzwerk**, Tabelle „Aktive DHCP-Leases") | **Leases zurücksetzen** (Admins) |
| Verlauf der Adressvergaben: MAC-Adresse, IP-Adresse, Hostname, Beginn und Ende | Tabelle `dhcp_leases` | aktive Einträge, solange die Lease gilt; beendete Vorgabe 90 Tage nach ihrem Ende, einstellbar 30 bis 3650 Tage unter **Einstellungen → General (Allgemein)** (nur Admins); der Worker löscht täglich und bei jedem Neustart | keine Liste; **Berichte → DHCP** zählt sie (alle Rollen) | beendete automatisch über die Aufbewahrung; mit dem Gerät. **Leases zurücksetzen** beendet die aktiven Einträge, löscht aber keine |
| Jede DHCP-Vergabe (MAC-Adresse, IP-Adresse, Hostname) | Protokoll des dnsmasq-Containers | siehe [Protokolle der Container](#protokolle-der-container) | Admins (**Logs → Container-Logs**) | — |
| Jede DNS-Anfrage jedes Geräts | Protokoll des dnsmasq-Containers | nur solange **DNS-Anfragen protokollieren** eingeschaltet ist (Vorgabe aus, [07 — Netzwerk](07-netzwerk.md)) | Admins | Schalter ausschalten |

Adressen vergibt ThinForge nur an Geräte, die in der Clients-Liste angelegt sind; unbekannte Geräte im Netz erscheinen deshalb nicht in den Leases.

## SSH-Befehle, Terminal und Fernwartung

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen |
|-------|-----|--------------|--------------|---------|
| Befehle, die der Server per SSH auf einem Gerät ausführt (etwa Neustart, Herunterfahren, Hardware-Inventur, Verteilung des Agenten): Befehl, Ausgabe (je Ausgabekanal höchstens 256 KiB), Exit-Code, Dauer, Zeit, auslösendes Konto | Tabelle `ssh_command_logs` | Vorgabe 90 Tage nach der Ausführung, einstellbar 30 bis 3650 Tage unter **Einstellungen → General (Allgemein)** (nur Admins); der Worker löscht täglich und bei jedem Neustart | die Befehle selbst zeigt keine Ansicht. Unter **Berichte → Aktivität** sehen alle Rollen die Zahl der Befehle insgesamt und je Gerät; eine Aufstellung je Benutzername gibt der Server Admins und Operatoren heraus, Betrachtern nicht (über die Programmierschnittstelle, die Ansicht zeigt sie nicht) | automatisch über die Aufbewahrung; mit dem Gerät |
| Terminal-Sitzungen (Web-SSH) und Fernwartung (Remote Desktop über Guacamole): Beginn und Ende mit Konto, Absenderadresse, Gerät, Dauer und ob die Verbindung zustande kam | Audit-Log (`audit_log`) | wie das [Audit-Log](#audit-log) | Admins (**Logs → Audit-Log**) | wie das Audit-Log |
| Inhalt dieser Sitzungen (Eingaben, Ausgaben, Bildschirm) | — | wird nicht aufgezeichnet | — | — |

- Terminal und Remote Desktop öffnen Admins und Operatoren ([03 — Clients](03-clients.md#remote-zugriff)). Weder Eingaben noch Bildschirminhalte werden gespeichert. Beginn und Ende jeder Sitzung stehen im Audit-Log (**Terminal-Sitzung begonnen/beendet**, **Fernwartung begonnen/beendet**); beide Einträge tragen dieselbe Sitzungskennung, der Endeintrag die Dauer. Fehlt zu einem Beginn das Ende, läuft die Sitzung noch oder endete mit einem Neustart des Backends.
- Während einer Fernwartung zeigt das Gerät der angemeldeten Person den Hinweis **„Remote-Sitzung aktiv"**. Eine Rückfrage, ob sie zustimmt, gibt es nicht. Ist niemand grafisch angemeldet oder lässt sich der Hinweis nicht anzeigen, läuft die Sitzung trotzdem.

## Vorfälle und Benachrichtigungen

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen |
|-------|-----|--------------|--------------|---------|
| Vorfälle: Gerät, Bedingung, Details, Zeitpunkte, quittierendes und lösendes Konto, Hinweis zur Lösung (Freitext) | Tabelle `alert_incidents` | offene und quittierte, bis sie gelöst sind; gelöste Vorgabe 365 Tage nach der Lösung, einstellbar 30 bis 3650 Tage unter **Einstellungen → General (Allgemein)** (nur Admins); der Worker löscht täglich und bei jedem Neustart | alle Rollen (**Einstellungen → Benachrichtigungen**, Dashboard) | gelöste automatisch über die Aufbewahrung; mit dem Gerät |
| Empfängeradressen, Zugangsdaten des Mail-Servers, Webhook-Adresse | Tabelle `settings` | bis zur Änderung | Admins und Operatoren; ändern nur Admins | **Einstellungen → Benachrichtigungen** |

- Das Passwort des Mail-Servers, das Webhook-Secret und die Werte der Webhook-Kopfzeilen liegen seit dem Update vom 2026-10-10 verschlüsselt in der Datenbank (AES-256-GCM, mit demselben Schlüssel wie das TOTP-Geheimnis), die Webhook-Adresse seit dem Update vom 2026-10-14 ebenso. Die Oberfläche zeigt die Geheimnisse niemandem, auch Admins nicht, und von der Webhook-Adresse nur Schema und Host (etwa `https://hooks.slack.com/…`) — Pfad und Query, in denen Slack, Microsoft Teams und ähnliche Dienste das Token tragen, verlassen den Server nicht. Vorher stand die Adresse im Klartext in der Datenbank, und Admins und Operatoren sahen sie vollständig.
- Admins können Passwort, Secret und Webhook-Adresse ersetzen oder entfernen (**Ändern**, **Entfernen**); entfernt steht in der Datenbank kein Wert mehr. Passwort und Secret ließen sich bis zum Update vom 2026-10-16 nur ersetzen — wer sie nicht mehr brauchte, konnte sie nicht löschen. Die Werte der Webhook-Kopfzeilen verschwinden mit ihrer Zeile.
- Die Einstellungen gehören nicht zur System-Sicherung; eine Wiederherstellung lässt die Einstellungen der Zielanlage unverändert. Bringt die Sicherung einen anderen Schlüssel mit (etwa beim Umzug auf eine neue Anlage), verschlüsselt die Wiederherstellung die Zugangsdaten und die Webhook-Adresse auf diesen Schlüssel um. Gelingt das nicht, nennt das Protokoll des Backends die betroffenen Felder; sie sind dann unter **Einstellungen → Benachrichtigungen** neu einzugeben.

Was eine Benachrichtigung enthält, steht unter [Daten, die das System verlassen](#daten-die-das-system-verlassen).

## VPN

| Daten | Ort | Aufbewahrung | Sichtbar für | Löschen |
|-------|-----|--------------|--------------|---------|
| Zuordnung Gerät ↔ VPN-Teilnehmer, Aktivierungszustand, Verbindungsstatus, letzter Handshake, ob das Gerät im LAN oder von außen verbunden ist | Tabelle `vpn_clients` | bis das Gerät gelöscht wird; **VPN deaktivieren** ([13 — VPN](13-vpn.md)) entfernt die Zuordnung zum VPN-Teilnehmer und den Aktivierungsschlüssel aus der Zeile und löscht den Teilnehmer samt unverbrauchtem Schlüssel auf der VPN-Instanz — die Zeile selbst bleibt mit dem Zeitpunkt der Deaktivierung stehen | Admins und Operatoren (**VPN**) | mit dem Gerät |
| Protokoll der Abgleichsläufe mit der VPN-Instanz (Objektnamen, Ergebnis) | Tabelle `vpn_apply_log` | 14 Tage | Admins und Operatoren | automatisch |

- Die VPN-Instanz liegt außerhalb von ThinForge. Für jedes aktivierte Gerät legt ThinForge dort einen Aktivierungsschlüssel mit dem Namen `client-<Hostname>` an, und das Gerät meldet sich dort unter seinem Hostnamen an; beim Verbinden sieht die Instanz die öffentliche IP-Adresse, über die das Gerät ins Internet geht. ThinForge liest von der Instanz je Gerät Namen und Hostnamen, VPN-Adresse, Gruppenzugehörigkeit, Verbindungsstatus und den Zeitpunkt der letzten Verbindung. Welche Angaben die Instanz darüber hinaus speichert, bestimmt, wer sie betreibt. Mit der gebuchten VPN-Option von ThinForge stellt thinforge.org die Instanz bereit ([13 — VPN](13-vpn.md)).

## Protokolle der Container

| Dienst | Was darin stehen kann | Größengrenze |
|--------|-----------------------|--------------|
| Backend, Worker | Geräteangaben (Hostname, MAC- und IP-Adressen), Kennungen und vereinzelt Namen von Konten, Fehlermeldungen. Eine Zeile je Anfrage schreibt das Backend in der vorgegebenen Protokollstufe nicht | je Dienst drei Dateien zu 50 MB |
| dnsmasq | jede DHCP-Vergabe (MAC-Adresse, IP-Adresse, Hostname); bei eingeschaltetem DNS-Protokoll jede DNS-Anfrage | je Dienst drei Dateien zu 50 MB |
| Caddy (Proxy) | kein Zugriffsprotokoll. Laufzeit- und Fehlermeldungen; scheitert eine Weiterleitung (etwa während das Backend neu startet), mit Angaben zur Anfrage, darunter der Absenderadresse | je Dienst drei Dateien zu 50 MB |
| übrige Dienste (etwa Guacd, ThinVPN, PostgreSQL) | technische Meldungen | je Dienst drei Dateien zu 50 MB |

- Lesen dürfen Admins unter **Logs → Container-Logs**, über die Programmierschnittstelle auch Operatoren ([08 — Tasks & Logs](08-tasks-logs.md)).
- Ist die Grenze erreicht, verwirft Docker die ältesten Zeilen; wie weit ein Protokoll zurückreicht, hängt also davon ab, wie viel der Dienst schreibt. Die Grenze gilt für alle Dienste seit dem Update vom 2026-10-09. Vorher hatten nur Backend und Worker eine; die übrigen Dienste, darunter dnsmasq mit jeder Vergabe, schrieben ohne Grenze, sofern der Docker-Dienst auf dem Server (`/etc/docker/daemon.json`) keine vorgab. Container, die ThinForge selbst für einen Auftrag startet (Multicast-Sender, BitTorrent-Seeder, Cloner, Hilfscontainer), haben seit dem Update vom 2026-10-14 dieselbe Grenze; vorher folgten sie dieser Einstellung des Docker-Dienstes. ThinForge entfernt sie nach dem Auftrag samt Protokoll.
- Die Protokolle eines Containers verschwinden mit dem Container, etwa wenn ein Update ihn neu erzeugt. Das Löschen eines Geräts oder der Werksreset entfernen sie nicht.

## Sicherungen

| Art | Inhalt mit Personenbezug | Ort | Aufbewahrung | Sichtbar für |
|-----|--------------------------|-----|--------------|--------------|
| System-Sicherung | die Datenbank **ohne** Audit-Log, DHCP-Leases, Aufträge, Vorfälle und Einstellungen. Enthalten sind also Konten (samt Passwort-Hashes und verschlüsselten TOTP-Geheimnissen), Geräte (samt Benutzer-Feld und Inventar), SSH-Befehlsprotokolle und die VPN-Zuordnung, dazu alle Schlüssel der Anlage | Ordner `backups` | die letzten 3 je Art, einstellbar 0 bis 100 (0 = unbegrenzt) | Admins (**Info & Backup → Backup & Restore**) |
| Daten-Sicherung | Images (Klone) und Delta-Updates, mit allem, was in den Images steckt | Ordner `backups` | wie oben | Admins |

- Ohne Passwort ist eine System-Sicherung ein offenes Archiv; mit Passwort ist sie verschlüsselt. Daten-Sicherungen haben keine Passwortoption ([09 — Einstellungen](09-einstellungen.md#backup--restore)).
- Gelöscht werden Sicherungen einzeln unter **Info & Backup → Backup & Restore** oder durch die Aufbewahrung. Umbenannte Dateien zählen nicht zur Aufbewahrung und bleiben liegen.
- Was im laufenden System gelöscht wurde, etwa ein Konto oder ein Gerät, bleibt in älteren Sicherungen enthalten, bis diese wegfallen. Eine Wiederherstellung bringt es zurück.
- Heruntergeladene Kopien liegen außerhalb von ThinForge und unterliegen keiner Aufbewahrung durch ThinForge.

## Images, Aufnahmen und Exporte

- Eine **Aufnahme** (Capture) sichert den vollständigen Datenträger eines physischen Geräts, mit allem, was darauf liegt: Benutzerprofile, Browserdaten, lokal gespeicherte Dateien. Als Image ausgerollt, landen diese Daten auf allen Zielgeräten. Entferne persönliche Daten deshalb vom Quellgerät, bevor du es aufnimmst ([05 — Cloning](05-cloning.md)).
- Images aus der Cloning-VM enthalten, was in der VM eingerichtet wurde.
- Klone löschen und exportieren dürfen Admins und Operatoren (**Cloning → Clones**). Ein Export entsteht als Archiv, auf Wunsch mit Passwort, und wird nach dem Herunterladen gelöscht; Reste eines abgebrochenen Downloads räumt der nächste Export weg.

## Im Browser

- Die Anmeldung läuft über die Cookies `tf_access` und `tf_refresh`. Sie sind als httpOnly, Secure und SameSite=Strict gesetzt; Skripte im Browser können sie nicht lesen.
- Im lokalen Speicher des Browsers liegen nur Anzeige-Einstellungen: die Anordnung des Dashboards, der ausgeblendete Erststart-Hinweis und der Einrichtungsstatus. Anmeldedaten liegen dort nicht.

## Daten, die das System verlassen

- **E-Mail** über den eingerichteten Mail-Server: Benachrichtigungen zu Vorfällen (Hostname, Bedingung, Details, Zeitpunkt, Zähler) an die eingetragenen Empfänger, und Links zum Zurücksetzen des Passworts an die E-Mail-Adresse des Kontos.
- **Webhook**: dieselben Angaben zu Vorfällen, dazu die Kennung des Vorfalls, an die eingetragene Adresse.
- **VPN-Instanz**: Gerätenamen und Aktivierungsschlüssel, siehe [VPN](#vpn).
- **Downloads** durch Bedienende: CSV-Exporte, Sicherungen, Klon-Exporte.

Alle ausgehenden Verbindungen des Systems mit Ziel, Zweck, Auslöser und Abschaltweg listet [12 — Sicherheit → Ausgehende Verbindungen](12-sicherheit-und-cve-scan.md#ausgehende-verbindungen) auf.

## Auskunft zu einer Person

Eine Funktion, die alle Daten zu einer Person zusammenträgt, gibt es nicht. Diese Stellen kommen in Frage:

- **Konto** — Benutzername, E-Mail-Adresse und Rolle unter **Einstellungen → Benutzer & Rollen**.
- **Geräte, die der Person zugeordnet sind** — Clients-Liste, Feld **Benutzer**; **CSV exportieren** liefert die Stammdaten.
- **Audit-Log** — die Ansicht filtert nicht nach Konto. Die Einträge eines Kontos lassen sich direkt in der Datenbank auswerten (Tabelle `audit_log`, Spalte `user_id`; bei Anmeldungen steht der Name zusätzlich in den Details).
- **SSH-Befehle** und **Vorfälle**, die ein Konto ausgelöst, quittiert oder gelöst hat — nur direkt in der Datenbank (`ssh_command_logs.user_id`, `alert_incidents.acknowledged_by` und `resolved_by`).

## Alles löschen: Werkeinstellungen (Werksreset)

Admins setzen unter **Einstellungen → Werkeinstellungen** (mit dem eigenen Passwort) den gesamten Zustand zurück ([09 — Einstellungen](09-einstellungen.md)). Dabei werden alle Tabellen der Datenbank und Redis geleert, und alles im Datenverzeichnis wird gelöscht, auch die Sicherungen im Ordner `backups`, die Images und die Aufnahmen.

Erhalten bleiben die Protokolle der Container, Dateien außerhalb des Datenverzeichnisses (etwa die `.env` und der Ordner `license`), heruntergeladene Kopien und alles auf den Geräten. Statt eines Eintrags im Audit-Log, das dabei mitgelöscht wird, steht im Protokoll des Backends eine Warnzeile mit dem auslösenden Konto.

## Nächste Schritte

- [08 — Tasks & Logs](08-tasks-logs.md) — Audit-Log und Container-Logs im Detail
- [09 — Einstellungen](09-einstellungen.md) — Benutzer, Aufbewahrung, Sicherungen
- [12 — Sicherheit](12-sicherheit-und-cve-scan.md) — TLS, Schlüssel und ausgehende Verbindungen
