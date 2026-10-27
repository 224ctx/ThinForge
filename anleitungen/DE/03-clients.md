# 3 — Clients

Ein **Client** in ThinForge ist ein physischer Thin-PC mit installiertem Agent, der regelmäßig per Heartbeat Kontakt zum Server hält. Alle Verwaltungs-Aktionen — Image-Update, Rollback, Remote-Zugriff, Gruppen-Zuweisung — laufen auf Client-Objekte.

> **Empfohlenes System:** Für die Thin-Clients ist Debian die bevorzugte Wahl — installiert als Minimal-System mit XFCE als grafischer Oberfläche. Grundsätzlich funktioniert aber jede Linux-Distribution.

## Clients-Liste

Menü links **Clients**. Die Tabelle zeigt alle registrierten Geräte und lädt alle 30 Sekunden neu. Die weiteren Tabs der Ansicht beschreibt der Abschnitt [Weitere Tabs](#weitere-tabs).

### Spalten

| Spalte | Inhalt |
|--------|--------|
| Inventarnummer | Eigene Inventarnummer; danach ist die Liste anfangs sortiert |
| Hostname | Rechnername `TF-<MAC>` — vergibt ThinForge beim Anlegen |
| MAC-Adresse | Primäre Netzwerkkarte |
| Status | Online (grün; bei bekanntem Weg „Online (LAN)" bzw. „Online (VPN)" mit Schild-Symbol) / Offline (grau) / Klonen (orange) — einen Status „Fehler" gibt es seit dem Update vom 2026-10-01 nicht mehr |
| Aktuelle IP | Die Adresse, von der der letzte Heartbeat kam (LAN oder VPN-Overlay) |
| Installierte Version | Aktuell installierter Clone (`v2026.06.22-004`, …); ohne Versionsangabe der Image-Name mit Link in die Cloning-Ansicht |
| Benutzer, Raum | Frei gepflegte Angaben |
| VPN | Schild-Symbol, wenn VPN für das Gerät aktiviert ist (Zugang ausgestellt, belegt einen Platz im Abonnement); „–" sonst. Ob der Tunnel gerade steht, zeigt der VPN-Tab |
| Gruppen | Zugewiesene Gruppe ([04](04-gruppen.md)) |

Eingelagerte Geräte (**Lager**) erscheinen abgeblendet mit orangem Chip. Rot wird der Status auch, wenn ein Gerät seit mehr als drei Wochen nicht gesehen wurde oder der Server seinen Heartbeat abweist — dann steht dort **„Install Token erkannt!"**, wenn sich das Gerät mit dem Install-Token gemeldet hat, oder **„Token unbekannt!"**, wenn es ein Token schickt, das der Server gar nicht kennt (seit dem Update vom 2026-10-08; vorher stand auch dann „Install Token erkannt!"). Der Tooltip nennt den Grund in der Sprache der Oberfläche, mit der Adresse, von der das Gerät kam, wo sie eine Rolle spielt. Seit dem Update vom 2026-10-08 öffnet ThinForge für eine solche Abweisung außerdem den Vorfall **„Heartbeat abgewiesen"** und benachrichtigt über die eingerichteten Kanäle ([09 — Einstellungen](09-einstellungen.md#tab-benachrichtigungen)). Ein Klick auf einen Online- oder Offline-Chip prüft per Ping, ob das Gerät gerade erreichbar ist.

Seit dem Update vom 2026-10-21 stehen neben dem Status zwei weitere Chips: **„Integrität!“** (rot), wenn der Agent des Geräts etwas abgewiesen oder repariert hat oder der Server beim Abgleich mit seinem Stand eine Abweichung gefunden hat — der Tooltip nennt das jüngste offene Agent-Ereignis, die Einzelheiten stehen in der Detailansicht ([Agent-Ereignisse](#agent-ereignisse)) —, und **„Agent stumm“** (gelb), wenn das Gerät auf Ping antwortet, aber keinen Heartbeat schickt: der Agent läuft nicht oder erreicht den Server nicht. Der Status bleibt dabei „Offline“, und der Ping per Klick meldet ein stummes Gerät zwar als erreichbar, setzt es aber nicht auf „Online“ — das tut erst der nächste Heartbeat. Beide Chips sehen alle Rollen.

Am Zeilenende: **Bearbeiten** (öffnet die Detailansicht), **Löschen**, **Token neu ausstellen** und **Reset auf Install Token** (nur bei abgewiesenem Heartbeat aktiv, also bei „Install Token erkannt!" oder „Token unbekannt!"; der Client meldet sich danach beim nächsten Heartbeat neu an). Steht dort **„Token unbekannt!"**, meldet sich das Gerät mit einem Token, das der Server nicht kennt (etwa nach einer abgebrochenen Neubespielung) — dann hilft der Reset erst, wenn das Gerät wieder das Install-Token sendet; meist heißt das: Gerät neu bespielen. Löschen und die beiden Token-Aktionen sind Admin-Sache: seit dem Update vom 2026-10-08 zeigt die Oberfläche sie nur Admins — in der Zeile, in den Sammelaktionen der Auswahl und (Löschen) in der Detailansicht.

### Filter und Suche

- **Suchfeld** oben: filtert die angezeigte Liste über die Tabellenspalten (z. B. Hostname, MAC-Adresse, Inventarnummer, Benutzer, Raum, Gruppe); ein Suchbegriff aus dem Dashboard wird übernommen.
- **Status-Filter**: Dropdown in der Filterzeile (Online, Offline, Klonen).
- **Gruppen-Filter**: Dropdown „Gruppen" in der Filterzeile, mit **Ohne Gruppe** an erster Stelle; daneben die Filter „Verbindung" (worüber das Gerät gerade hereinkommt) und „VPN aktiviert" (ja/nein) sowie der Aktualisieren-Knopf. „VPN aktiviert: Ja" zusammen mit „Ohne Gruppe" zeigt die VPN-Geräte, deren Gruppe gelöscht wurde.
- **Spalten-Sortierung**: Spaltenkopf anklicken.

### Bulk-Aktionen

Mehrere Clients per Checkbox markieren → Aktionen oben in der Leiste:

- **Gruppe zuweisen** — Gruppe wählen, dann **Zuweisen**
- Menü **Aktionen**:
  - **Einschalten (WoL)**, **Neustart**, **Herunterfahren** — Neustart und Herunterfahren schickt der Server per SSH
  - **Ping Check** — prüft die Erreichbarkeit der markierten Geräte
  - **Token neu ausstellen** — erneuert die Heartbeat-Tokens; jedes Gerät übernimmt seinen neuen Token beim nächsten Heartbeat (nur Admins). Scheitert es für ein Gerät, nennt eine Warnung seinen Namen
  - **Löschen** — entfernt den Client aus der Verwaltung (der physische PC bleibt bestehen); er taucht nicht von selbst wieder auf und muss zum erneuten Verwalten manuell mit seiner MAC-Adresse neu angelegt werden (nur Admins). Lässt sich ein Gerät nicht löschen, nennt eine Warnung seinen Namen

## Client-Detail

Klick auf eine Zeile öffnet die Detail-Ansicht. Sie hat keine Tabs, sondern drei Bereiche — für Admins und Operatoren seit dem Update vom 2026-10-21 darunter die Karte [Agent-Ereignisse](#agent-ereignisse); im Kopf stehen neben dem Status dieselben Chips „Integrität!“ und „Agent stumm“ wie in der Liste. Die Seite lädt alle 15 Sekunden neu, der Aktualisieren-Knopf oben sofort. Antwortet der Server kurz nicht (etwa beim Neustart), holt das nächste Nachladen die Seite von selbst zurück. Gibt es das Gerät nicht mehr (gelöscht oder alter Link), steht oben „Client nicht gefunden“ mit einem Link zur Liste, und die Seite lädt nicht weiter nach.

### Client-Details

- Hostname und MAC-Adresse (nur lesend; eine neue MAC-Adresse übernimmt ein Admin, siehe [Neue Netzwerkkarte](#neue-netzwerkkarte))
- Inventarnummer (muss eindeutig sein, wird beim Tippen geprüft), Raum, Benutzer, Gruppe
- **Lager** — eingelagertes Gerät: keine Alerts, nicht in Kennzahlen und Berichten
- Installierte Version bzw. Image und „Installiert am" (nur lesend)
- Kaufdatum / Garantie (Monate) mit berechnetem Garantieende / Rechnungsnummer / Lieferant (für Garantiefall-Recherche)
- **Speichern** übernimmt nur die geänderten Felder — was jemand anderes inzwischen an einem anderen Feld geändert hat, bleibt erhalten

### Aktionen

- **Einschalten (WoL)**, **Neustart**, **Herunterfahren** — Neustart und Herunterfahren melden nur dann „gesendet“, wenn das Kommando per SSH angekommen ist. Ist das Gerät nicht erreichbar, weist es die Anmeldung ab, läuft die Frist ab oder scheitert das Kommando, erscheint eine Fehlermeldung mit dem Grund (seit dem Update vom 2026-09-30; vorher stand auch dann „gesendet“ da)
- **Terminal öffnen** und **Remote Desktop** — nur wenn der Client online ist, siehe [Remote-Zugriff](#remote-zugriff)
- **Löschen** (nur Admins)

### Neue Netzwerkkarte

Seit dem Update vom 2026-10-08: Bekommt ein Gerät eine neue Netzwerkkarte, meldet es sich weiter beim Server — aber mit einer anderen MAC-Adresse als der registrierten. Die Detailansicht zeigt dann oben den Hinweis **„Das Gerät meldet eine neue MAC-Adresse …"** mit gemeldeter und registrierter Adresse, und unter **Einstellungen → Benachrichtigungen** steht spätestens nach fünf Minuten der Vorfall **„MAC-Adresse geändert"** mit beiden Adressen — mit Benachrichtigung über die eingerichteten Kanäle ([09 — Einstellungen](09-einstellungen.md#tab-benachrichtigungen)). Das klappt bei Geräten, die sich schon einmal beim Server angemeldet haben; ein Gerät, das sich noch nie gemeldet hat, wird mit einer unbekannten MAC-Adresse weiter abgewiesen.

Ein Admin übernimmt die neue Adresse mit **MAC übernehmen** — am Hinweis oder am Vorfall. Die Rückfrage zeigt beide Adressen und die Folgen:

- die DHCP-Reservierung (dieselbe IP-Adresse) geht auf die neue MAC-Adresse über,
- die PXE-Startdateien gelten für die neue Karte, die der alten werden entfernt,
- Wake-on-LAN weckt künftig die neue Karte,
- der **Hostname bleibt**.

Danach ist der Vorfall gelöst. Nicht übernommen wird, solange das Gerät in einem laufenden Deployment steckt oder für eine Aufnahme vorbereitet ist (erst abwarten oder abbrechen), und wenn die Adresse schon bei einem anderen Gerät registriert ist — die Meldung nennt dann dieses Gerät (etwa, weil die Festplatte des einen im anderen steckt). Konnten DHCP-Reservierung oder PXE-Dateien nicht umgestellt werden, sagt es die Meldung; nachholen unter **Netzwerk → DHCP / DNSMASQ → Konfig neu laden** bzw. **Netzwerk → PXE Boot → Alle synchronisieren**. Hält die alte Karte noch eine gültige DHCP-Lease auf die reservierte Adresse, bekommt die neue Karte sie erst nach deren Ablauf und bis dahin eine Adresse aus dem Bereich.

Steckt wieder die alte Karte, verschwindet der Hinweis von selbst, und der Vorfall löst sich mit der nächsten Prüfung (spätestens nach fünf Minuten).

Meldet das Gerät keine neue Adresse, aber der Agent, dass der auf dem Gerät gespeicherte Hostname von einer anderen Netzwerkkarte stammt (etwa eine Festplatte aus einem anderen Gerät, oder eine Karte, die schon vor dem Anlegen getauscht wurde), zeigt die Detailansicht den Hinweis **„Der Agent meldet, dass der auf dem Gerät gespeicherte Hostname … von einer anderen Netzwerkkarte stammt …"**, und der Vorfall „MAC-Adresse geändert" steht ebenfalls. Ist der Stand so gewollt, bestätigt ein Admin mit **MAC bestätigen** die registrierte Adresse: es wird nichts umgestellt, der Vorfall löst sich, und derselbe Stand öffnet keinen neuen. Meldet das Gerät später eine andere Adresse oder einen anderen gespeicherten Hostnamen, öffnet sich wieder ein Vorfall.

### Systeminformationen

Zuletzt gesehen sowie CPU-, RAM- und Festplattenauslastung mit Balken (CPU und RAM über 60 % orange, über 80 % rot; Festplatte über 75 % orange, über 90 % rot).

Die Aufträge eines Geräts findest du unter **Tasks** mit dem Client-Filter ([08](08-tasks-logs.md)).

### Agent-Ereignisse

Seit dem Update vom 2026-10-21 (Agent 2.27.0) meldet der Agent dem Server, was er auf dem Gerät abgewiesen oder repariert hat: ein Agent-Update, ein Skript, ein Server-Zertifikat, einen Signier- oder SSH-Schlüssel mit ungültiger Signatur, einen fehlenden Vertrauensanker, eine veränderte systemd-Unit, ein Delta, das sich beim Herunterfahren nicht anwenden ließ. Dazu vergleicht der Server bei jedem Heartbeat Agent-Version, Agent-Binary und Signierschlüssel des Geräts mit seinem eigenen Stand. Die Karte **„Agent-Ereignisse“** unter den Bereichen der Detailansicht listet beides (für Admins und Operatoren; Betrachter sehen nur die Chips):

- Spalten **Zeit (Gerät)**, **Empfangen**, **Ereignis** (in der Sprache der Oberfläche; Code und Angaben im Tooltip), **Anzahl** (wie oft gemeldet, im Tooltip „Zuletzt gemeldet“), **Quelle** (Gerät oder Server-Abgleich) und **Geschlossen** (von wem und wann, sonst „offen“).
- Filter **Offen** (Vorgabe) und **Alle**; das Aktualisieren-Symbol lädt neu.
- Eine Zeile mit durchgestrichener Glocke öffnet keinen Vorfall: die Unit wurde direkt nach einer Neubespielung, einem Rollback oder einem Agent-Update repariert — das ist der erwartete Ablauf.

Jede andere offene Zeile hält den Chip „Integrität!“ und den Vorfall **„Agent-Integrität“** offen ([09 — Einstellungen](09-einstellungen.md#tab-benachrichtigungen)). **Quittieren** (je Zeile) und **Alle quittieren** sind Admin-Sache und fragen vorher nach:

- Ein **einmaliges Ereignis** (etwa eine reparierte Unit, ein abgelehntes Skript oder Delta) wird damit geschlossen. Kommt dasselbe später wieder, erscheint es als neue Zeile.
- Ein **anhaltender Zustand** (etwa ein abgelehntes Zertifikat, eine abweichende Agent-Binary oder eine Agent-Version, die 30 Minuten nach einem Agent-Update noch die alte ist) bleibt offen, solange das Gerät ihn meldet; die Quittung stellt nur die Benachrichtigungen dazu ab. Ist die Ursache behoben, schließt der Server die Zeile von selbst („nicht mehr gemeldet“), ebenso, wenn er selbst eine neue Agent-Binary oder einen neuen Signierschlüssel ausliefert („Soll-Stand des Servers gewechselt“).

Die Quittung stellt den Vorfall „Agent-Integrität“ auf bestätigt; ist nichts mehr offen, löst ihn die nächste Prüfung (spätestens nach fünf Minuten). Kommt nach der Quittung eine neue Zeile dazu, meldet sich der Vorfall sofort wieder. Jede Quittung, die ein Ereignis schließt oder den Vorfall bestätigt, steht im Audit-Log („Agent-Ereignisse quittiert“, [08 — Tasks & Logs](08-tasks-logs.md)). Geschlossene Zeilen bleiben so lange stehen wie gelöste Vorfälle ([09 — Einstellungen](09-einstellungen.md#karte-allgemeine-einstellungen)) und werden dann gelöscht.

Was die Meldungen leisten: Sie sind Auskunft des Geräts selbst oder ein Vergleich mit ihr. Sie decken Fehler, halbfertige Updates und Eingriffe auf, die nicht verborgen werden (jemand ändert die Unit, stoppt den Agenten). Ein Angreifer mit vollen Rechten auf dem Gerät kann den Agenten ersetzen und schweigen lassen — das fällt dann nur als „Agent stumm“ auf, wenn das Gerät weiter auf Ping antwortet.

## Neuen Client anlegen

Clients werden **manuell** angelegt — eine automatische Registrierung neuer Geräte gibt es nicht. Über **„+ Client registrieren"** trägst du die **MAC-Adresse** ein (Pflichtfeld) und optional Inventarnummer, Raum, Benutzer, Kauf- und Garantiedaten, Gruppe und Lager. Erst ein angelegtes Gerät wird vom Server akzeptiert; Heartbeats von unbekannten MAC-Adressen werden abgewiesen. Für die Massen-Anlage gibt es den CSV-Import (siehe unten).

Schritt-für-Schritt siehe [workflows/erster-client.md](workflows/erster-client.md).

## CSV-Import / -Export

Für Massen-Anlage oder Backup-Zwecke.

### Export

- **CSV exportieren** in der Aktionsleiste über der Liste
- Datei `clients.csv` mit Hostname, MAC-Adresse, Status, Benutzer, Raum, Gruppe, installierter Version, Inventarnummer, Rechnungsnummer und Lieferant — exportiert werden die gerade geladenen Clients, bei gesetztem Status-, Verbindungs-, „VPN aktiviert"- oder Gruppenfilter (auch „Ohne Gruppe") also nur diese; die Textsuche wirkt nur auf die Anzeige, nicht auf den Export
- UTF-8 mit BOM, kommagetrennt, jedes Feld in Anführungszeichen; Spaltenköpfe in der Sprache der Oberfläche

### Import

- **CSV importieren** → CSV-Inhalt in das Textfeld einfügen (eine Datei wird nicht hochgeladen); ein exportiertes `clients.csv` lässt sich direkt einfügen
- ThinForge erkennt die Kopfzeile (deutsche und englische Spaltennamen, auch die des Exports) und zeigt eine Vorschau; Zeilen mit ungültiger MAC sind markiert und werden übersprungen
- Fehlen Gruppen, fragt ein Dialog, ob sie angelegt werden sollen
- Nach **„N Client(s) importieren"** legt der Server die neuen Clients an. Ist eine MAC schon vorhanden, legt er nichts an — eine angegebene Gruppe übernimmt er für das vorhandene Gerät. Zeilen mit einer schon vergebenen Inventarnummer überspringt er und meldet sie
- Die Rückmeldung nennt, wie viele Clients erstellt, aktualisiert (neue Gruppe) und übersprungen wurden. Gab es Zeilenfehler, bleibt der Dialog offen und listet jede nicht importierte Zeile mit ihrer MAC-Adresse und dem Grund in der Sprache der Oberfläche (seit dem Update vom 2026-09-30; vorher schloss er in jedem Fall, und die Fehler waren nicht zu sehen — und bis zum Update vom 2026-10-01 standen die Gründe teils deutsch, teils englisch da). Ein Gerät, dessen Gruppe schon stimmte, zählt als übersprungen, nicht als aktualisiert

**CSV-Spalten (Mindestumfang):**

```
mac_address,gruppe_name,inventarnummer,raum,benutzer,kaufdatum,garantiezeit_monate,rechnungsnummer,lieferant
```

Nur `mac_address` ist Pflicht; `kaufdatum` im Format `JJJJ-MM-TT`. Andere Spalten (etwa Hostname, Status oder installierte Version aus dem Export) werden ignoriert, ein per Export erzeugtes CSV kann also direkt wieder importiert werden. Ohne erkennbare Kopfzeile gilt die feste Reihenfolge `mac_address, inventarnummer, raum, benutzer, kaufdatum, garantiezeit_monate, rechnungsnummer, lieferant`.

## Boot-Modi

Jeder Client hat einen **Boot-Modus**, der steuert, was er beim nächsten Start per PXE tut. Der Modus liegt als PXE-Konfiguration auf dem Server; nach einem abgeschlossenen Deployment oder Capture steht er automatisch wieder auf Lokal-Boot.

| Modus | Zweck |
|-------|-------|
| Lokal | Normaler Betrieb — der Client bootet vom lokalen Datenträger |
| Deploy | Beim nächsten Start wird ein Image installiert; die Liste nennt das Verfahren: „Klon-Deployment" (Unicast), „Multicast-Deployment" oder „BitTorrent-Deployment" — „Deploy" steht nur noch bei älteren Boot-Konfigurationen |
| Capture | Beim nächsten Start wird der Datenträger des Geräts als Image aufgenommen |
| Keine Config | Es ist keine Boot-Konfiguration hinterlegt — der Client bootet normal weiter |

Einsehen lässt sich der Modus unter **Netzwerk → PXE Boot**, setzen nur als Admin: Lokal oder Capture setzen, Konfiguration löschen ([07](07-netzwerk.md#tab-pxe-boot)). Deploy setzt ThinForge selbst, sobald ein Deployment den Client scharfschaltet.

## VPN-Status

Kommt der Heartbeat eines Clients über das VPN, zeigt die Liste den Status als „Online (VPN)" mit einem Schild-Symbol; über den Filter **Verbindung** lassen sich LAN- und VPN-Clients trennen. Geht ein Gerät offline — kein Lebenszeichen mehr, Ende oder Abbruch eines Klon-Deployments oder einer Aufnahme —, verschwindet der Verbindungsweg mit (seit dem Update vom 2026-10-10): „Offline" steht ohne Schild, und der Filter **Verbindung** findet das Gerät erst wieder, wenn es sich erneut meldet. Mehr steht hier nicht: den eigentlichen VPN-Zustand eines Geräts (aktiviert, verbunden, letzter Handshake, Verbindung über Vermittler) zeigt der Reiter **Clients** im Menü **VPN** ([13 — VPN](13-vpn.md)); eine Traffic-Statistik gibt es nicht.

## Remote-Zugriff

Drei Zugriffsmethoden — je nach Anwendungsfall und Rechteeinstellung:

### Terminal (Web-SSH)

- **Button „Terminal öffnen"** auf der Client-Detail-Seite
- Öffnet eine in-Browser Shell (als `root`) via WebSocket + SSH
- Nutzt den ThinForge-Provisioning-Key (kein Passwort nötig)
- Rechte: Operator oder Admin
- Funktioniert nur wenn Client online und SSH-Port erreichbar (LAN oder VPN)
- Beginn und Ende jeder Sitzung stehen im Audit-Log (Konto, Absender-IP, Gerät, Dauer; seit dem Update vom 2026-10-09). Was im Terminal eingegeben oder ausgegeben wird, zeichnet ThinForge nicht auf

**Typische Aufgaben:** Log-Datei prüfen, Mount-Punkt checken, manuell Agent neustarten.

### Remote-Desktop

- **Button „Remote Desktop"** auf der Client-Detail-Seite
- Der Server baut einen SSH-Tunnel zum Client auf, startet dort `x11vnc` auf dem Bildschirm `:0` und reicht die Sitzung über den Guacamole-Dienst (`guacd`) in den Browser; Maus und Tastatur gehen denselben Weg zurück
- Der Client braucht eine laufende grafische Sitzung auf `:0` (Anmeldebildschirm oder Desktop) — nicht für Headless-Boxen geeignet
- Auf dem Client zeigt ein Hinweisfenster „Remote-Sitzung aktiv", solange die Sitzung läuft; beim Beenden räumt der Server `x11vnc` wieder ab
- Beginn und Ende jeder Sitzung stehen im Audit-Log (Konto, Absender-IP, Gerät, Qualitätsstufe, Dauer; seit dem Update vom 2026-10-09). Den Bildschirm zeichnet ThinForge nicht auf
- Die Qualitätsstufe (DSL, VDSL, LAN) lässt sich im Dialog umschalten; Vorgabe, Leerlauf-Timeout und die Zahl gleichzeitiger Sitzungen je Client stehen unter **Einstellungen → Remote Desktop**. Die Sitzung startet mit dieser Vorgabe; lässt sie sich beim Öffnen nicht abrufen, ist keine Stufe markiert und ein gelber Hinweis nennt den Grund — der Server setzt seine Vorgabe dann trotzdem ein (seit dem Update vom 2026-09-30; vorher startete die Sitzung in diesem Fall still mit VDSL)
- Rechte: Operator oder Admin

**Typische Aufgaben:** Benutzer-Support („Ich sehe einen roten Rahmen"), GUI-Einstellungen prüfen.

### Agent-Befehle

Delta-Updates und Rollbacks laufen nicht über einen Remote-Login: der **Agent** holt sie mit seinem Heartbeat ab und führt sie aus. Dieser Weg funktioniert auch ohne SSH-Erreichbarkeit, z. B. wenn der Client hinter NAT liegt und nur Heartbeats rausgehen. Neustart und Herunterfahren schickt der Server dagegen per SSH — dafür muss das Gerät erreichbar sein.

## Weitere Tabs

- **Garantie** — Kacheln für gültige, bald (innerhalb der eingestellten Garantie-Vorwarnung, Vorgabe 30 Tage, heute eingeschlossen — Einstellungen → Benachrichtigungen; bis zum Update vom 2026-10-03 fest 30 Tage) ablaufende und abgelaufene Garantien — der Tag des Garantieendes zählt noch als gedeckt, wie auf dem Dashboard und in den Berichten (seit dem Update vom 2026-10-01; vorher 90 Tage, und der Endtag galt schon als abgelaufen) —, Filter und Tabelle mit Garantieende; **CSV exportieren** schreibt `inventar.csv`.
- **Agent** — das Agent-Binary des Servers: bauen, hochladen, signieren und per SSH auf die Flotte verteilen. Den Tab sehen Admins und Operatoren; **Neu bauen**, **Binary hochladen**, **Signieren** und das Speichern des Heartbeat-Intervalls sind Admin-Sache (für Operatoren ausgeblendet bzw. schreibgeschützt — Signieren und Intervall seit dem Update vom 2026-10-08, Bauen und Hochladen seit dem Update vom 2026-10-21, weil beide die Binary mit dem Flottenschlüssel signieren und als Soll-Stand für alle Geräte ablegen).
- **Zertifikate** — Vertrauens-Zertifikate, die der Server an alle Clients oder an eine Gruppe verteilt (nur Admins).

## Häufige Probleme

- **Client bleibt nach dem Deployment offline** → Zuerst unter **Netzwerk → DHCP / DNSMASQ → Leases** prüfen, ob das Gerät eine IP bekommen hat (nur angelegte MACs bekommen eine), dann den Status im Deployment. Wurde das Golden-Image mit einer veralteten Tools-ISO eingerichtet, fehlen dem Agent passende Token oder Zertifikate → Image mit aktueller ISO neu einrichten ([05 — Cloning](05-cloning.md)).
- **„Offline" obwohl der Client läuft** → Agent-Service-Status (`systemctl status thinforge-agent` direkt am Gerät — das Terminal der Oberfläche ist bei „Offline" gesperrt). Oft ist die Server-URL falsch konfiguriert oder das TLS-Zertifikat wurde erneuert, ohne dass der Agent das akzeptiert. Steht in der Liste **„Install Token erkannt!"**, weist der Server den Heartbeat ab → **Reset auf Install Token** (Admin). Steht daneben **„Agent stumm“**, antwortet das Gerät auf Ping, aber der Agent schickt keinen Heartbeat: Dienst gestoppt oder hängt (`systemctl status thinforge-agent` und `journalctl -u thinforge-agent -n 30` am Gerät). Auch ein Gerät, dessen Heartbeat der Server abweist, gilt dabei als stumm.
- **Nach dem Tausch der Netzwerkkarte startet das Gerät nicht mehr per PXE oder bekommt nicht seine IP-Adresse** → Die Reservierungen hängen an der MAC-Adresse. In der Detailansicht des Geräts **MAC übernehmen** (Admin), siehe [Neue Netzwerkkarte](#neue-netzwerkkarte).
- **Terminal/Remote-Desktop geht nicht auf** → SSH-Reachability prüfen (Firewall? VPN up?). Den Provisioning-Key unter **Einstellungen → Sicherheit → SSH-Zugang** prüfen bzw. rotieren — online Clients übernehmen einen neuen Schlüssel mit dem nächsten Heartbeat ([12 — Sicherheit](12-sicherheit-und-cve-scan.md)).
- **„Integrität!“ in der Liste** → In der Detailansicht die Karte [Agent-Ereignisse](#agent-ereignisse) lesen: sie nennt, was der Agent abgewiesen oder repariert hat bzw. was beim Abgleich abwich. Ein einmaliges Ereignis quittiert ein Admin; ein anhaltender Zustand verschwindet, wenn die Ursache behoben ist — bei abweichender Agent-Binary, abweichendem Signierschlüssel oder fehlendem Vertrauensanker hilft meist **Reinstall** im Tab **Agent** mit dem Ziel **Einzelne Clients** (legt Binary, `server.crt` und `signing.pub` neu ab).
- **Ein Gerät zeigt die aktuelle Agent-Version, verhält sich aber wie eine alte** → Die Agent-Version in der Liste ist die **Meldung des Geräts**; der Server kann sie nicht nachprüfen. Seit dem Update vom 2026-10-21 meldet ein Agent ab 2.27.0 zusätzlich die Prüfsumme seiner Binary, und der Server vergleicht sie mit der ausgelieferten: weicht sie bei gleicher Version ab, steht „Integrität!“ mit dem Hinweis auf die abweichende Agent-Binary — auch das ist eine Auskunft des Geräts. **Alle aktualisieren** (Tab **Agent**) nimmt bei „Alle Clients“ und „Gruppe“ nur Geräte mit abweichender gemeldeter Version — ein Gerät, das die aktuelle Version bloß meldet, bleibt dabei außen vor. Im Verdachtsfall das Gerät gezielt behandeln: **Reinstall** (installiert unabhängig von der gemeldeten Version neu) oder im Dialog **Einzelne Clients** auswählen.

## Nächste Schritte

- [04 — Gruppen](04-gruppen.md) — Clients organisieren
- [06 — Rollouts](06-rollouts.md) — Updates verteilen
- [workflows/erster-client.md](workflows/erster-client.md) — Neuen Client von Grund auf aufnehmen
