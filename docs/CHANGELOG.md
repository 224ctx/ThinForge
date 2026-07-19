# ThinForge Changelog

## 2026-07-19

- **Ausgesperrte Clients per Klick wiederherstellen: „Reset auf Install Token"** — Meldet sich ein Client mit dem generischen Install-Token, obwohl er auf dem Server bereits mit einem eigenen Geräte-Token registriert ist (etwa nach einer Neuinstallation außerhalb eines regulären Rollouts), weist der Server seine Meldungen aus Sicherheitsgründen ab — der Client erschien dann dauerhaft als offline, ohne dass die Ursache erkennbar war. Die Client-Liste zeigt diesen Zustand jetzt ausdrücklich als **„Install Token erkannt!"** an, und in der Aktionsspalte gibt es eine neue Schaltfläche **Reset auf Install Token** (nur in diesem Zustand aktiv): Sie verwirft nach einer Sicherheitsabfrage die veraltete Geräte-Registrierung auf dem Server, der Install-Token wird wieder akzeptiert und der Client registriert sich beim nächsten Lebenszeichen automatisch neu — ohne Neuinstallation und ohne manuellen Eingriff in die Datenbank. Wirkt nach Aktualisierung der Server-Dienste (Backend) und der Verwaltungsoberfläche.

- **Herunterfahren bleibt nicht mehr am Ausschalt-Bildschirm hängen (veralteter Agent)** — Thin Clients konnten beim Herunterfahren bis zu zehn Minuten auf dem Ausschalt-Bildschirm hängen bleiben, wenn ein älterer Agent (ohne den Befehl `apply-update`) mit einer neueren Dienst-Konfiguration kombiniert war: Der beim Herunterfahren vorgesehene Update-Aufruf startete dann versehentlich den Agent-Hintergrunddienst, auf dessen Ende das System vergeblich wartete. Der Agent bricht unbekannte Aufrufe jetzt sofort mit einer Fehlermeldung ab, statt in den Hintergrunddienst zu wechseln — das Herunterfahren läuft damit auch bei einem Versionsunterschied zwischen Agent und Dienst-Konfiguration ohne Verzögerung durch. Wirkt nach Aktualisierung des Agents (v2.16.1) auf den Clients.

## 2026-07-18

- **Ersteinrichtung ohne irreführende Warnung zum Playbook-Dienst** — Beim Abschluss der Ersteinrichtung erschien bisher die Warnung „Playbook-Dienst (Semaphore) konnte nicht eingerichtet werden", obwohl dieser Dienst gar nicht Teil der Installation ist (derzeit deaktiviert). Die Einrichtung erkennt das jetzt und überspringt den Schritt ohne Warnung; auch beim Ändern des Admin-Passworts wird kein entsprechender Fehler mehr protokolliert. Zusätzlich behoben: Bei jedem dieser vergeblichen Einrichtungsversuche blieb bisher eine temporäre Datei mit Zugangsdaten im Klartext im Datenverzeichnis (`semaphore/playbooks/`) liegen — sie wird nicht mehr geschrieben, und eine aus früheren Läufen vorhandene Datei wird beim nächsten Setup bzw. Admin-Passwort-Wechsel automatisch entfernt. Wirkt nach Aktualisierung der Server-Dienste (Backend).

- **Client löschen widerruft jetzt auch den VPN-Zugang** — Wurde ein Client gelöscht, ohne sein VPN vorher zu deaktivieren, blieb der zugehörige VPN-Zugang des Geräts bestehen, war aber in der Verwaltung nicht mehr sichtbar. Das Löschen eines Clients entfernt jetzt automatisch auch dessen VPN-Zugang (wie die Schaltfläche *Deaktivieren*); ist die VPN-Verwaltung gerade nicht erreichbar, wird das Löschen dadurch nicht blockiert und der Vorgang protokolliert. Zusätzlich zeigt die Lizenzanzeige ohne gültige Lizenz keine irreführende Belegungszeile („N von 0 VPN-Clients") mehr. Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

## 2026-07-17

- **Neues Lizenzmodell: Vollversion für alle Clients, Lizenz nur noch für VPN-Clients** — Die bisherige Unterscheidung zwischen Light- und Full-Clients entfällt ersatzlos: Delta-Updates, Snapshots und Rollback stehen ab sofort jedem Client zur Verfügung, und die Anzahl verwalteter Clients ist nicht mehr begrenzt (das Registrierungs-Limit und die zugehörigen Fehlermeldungen sind entfernt). Lizenzpflichtig ist stattdessen die Aktivierung von VPN-Clients: Ohne gültige Lizenz können keine VPN-Clients aktiviert werden, mit Lizenz bestimmt sie die maximale Anzahl gleichzeitig aktivierter VPN-Clients. Das Deaktivieren eines VPN-Clients gibt den Platz wieder frei. Bereits aktivierte VPN-Clients laufen bei Ablauf oder Entfernen der Lizenz unverändert weiter — blockiert werden nur neue Aktivierungen; eine Nachfrist (Grace-Periode) gibt es nicht mehr. Die Lizenzanzeige (Einstellungen, Dashboard, Bericht) zeigt entsprechend die VPN-Client-Belegung. **Wichtig:** Lizenzdateien des alten Formats sind nach dieser Aktualisierung ungültig und werden mit einer klaren Fehlermeldung abgewiesen — für die VPN-Client-Aktivierung ist eine neue Lizenzdatei erforderlich. Wirkt nach Aktualisierung der Server-Dienste (Backend und Worker), der Verwaltungsoberfläche und des Agents (v2.16.0); beim Worker ist zusätzlich das aktualisierte docker-compose (Lizenz-Verzeichnis) nötig.

## 2026-07-13

- **ThinForge ist jetzt Open Source (GPL-3.0-or-later)** — Die gesamte von ThinForge stammende Software — Server-Dienste, Verwaltungsoberfläche, Client-Agent und Werkzeuge — steht ab sofort unter der GNU General Public License, Version 3 (oder, nach Ihrer Wahl, jeder späteren Version). Die Datei `LICENSE` enthält jetzt den vollständigen GPLv3-Text; `NOTICE` erklärt die Lizenzlage inklusive der weiterhin unter GPL v2 stehenden Drittkomponenten (Partclone, EZIO). Am Betrieb, am Funktionsumfang und an den bestehenden Wartungs- und VPN-Angeboten ändert sich nichts — neu ist, dass der Quellcode offen einsehbar, prüfbar und unter den Bedingungen der GPL weiterverwendbar ist.

## 2026-06-23

- **Einheitlicher Grauton für ausgeklappte Detailbereiche** — Ausgeklappte Detailbereiche (etwa die Liste der noch ausstehenden Clients eines Klons im Tab *Klone*) und einige Übersichtsflächen hatten im dunklen Erscheinungsbild einen fast weißen Hintergrund, der sich unschön abhob. Sie verwenden jetzt überall denselben, zum Design passenden Grauton — sowohl im dunklen als auch im hellen Erscheinungsbild. Wirkt nach Aktualisierung der Verwaltungsoberfläche.

- **Sitzungsdauer wirkt jetzt tatsächlich** — Die Einstellung *Einstellungen → Allgemein → Sitzungsdauer* hatte bisher keine Wirkung: Sitzungen liefen unabhängig vom gewählten Wert erst nach sieben Tagen Inaktivität ab, und ein Neustart des Rechners beendete die angemeldete Sitzung nicht. Ab dieser Aktualisierung steuert der eingestellte Wert die Sitzung wirklich, als gleitendes Zeitfenster: Nach der gewählten Dauer **ohne Aktivität** ist eine erneute Anmeldung erforderlich, aktive Nutzung verlängert das Fenster fortlaufend. Die Änderung gilt für neue Anmeldungen und greift bei bestehenden Sitzungen mit der nächsten automatischen Erneuerung (spätestens nach rund 15 Minuten Aktivität). Wirkt nach Aktualisierung der Server-Dienste (Backend) und der Verwaltungsoberfläche.

## 2026-06-22

- **Geräte „Auf Lager" verfälschen keine Alarme, Berichte und Lizenzzählung mehr** — Geräte mit dem Status *Auf Lager* (eingelagerter Bestand, noch keinem Einsatz zugeordnet) werden jetzt überall einheitlich behandelt: Sie lösen keine Dashboard-Warnungen mehr aus (weder ablaufende/abgelaufene Garantie noch Störungs-Alarme), und ein bereits gemeldeter Alarm wird automatisch geschlossen, sobald ein Gerät eingelagert wird. In den Berichten zählen sie nicht mehr in die Flotten-, Auslastungs-, Lebenszyklus-, VPN- und Verfügbarkeitskennzahlen hinein; in den beiden Bestands-Übersichten (Agent-Versionen, Gruppen-/Image-Verteilung) werden sie als eigener Block *Auf Lager* getrennt ausgewiesen, damit ihr Versionsstand weiter sichtbar bleibt, ohne die Einsatzzahlen zu verzerren. Auch die Dashboard-Kacheln (Gesamtzahl und Status-Verteilung online/offline) zeigen jetzt die aktive Geräteflotte ohne Lager und weisen den Lagerbestand separat als „davon N auf Lager" aus — so passen Kacheln, Berichte und Verfügbarkeitsansicht zusammen. Die Lizenzzählung war bereits korrekt; sie wurde an eine gemeinsame, zentrale Filterregel angeschlossen, damit künftig keine einzelne Auswertung die Lager-Ausnahme vergisst. Hinweis: Die Tages-Verlaufskurve der Verfügbarkeit wird ab der Aktualisierung bereinigt erfasst; bereits aufgezeichnete Tage bleiben unverändert. Wirkt nach Aktualisierung der Server-Dienste (Backend und Worker) und der Verwaltungsoberfläche.

## 2026-06-19

- **Dashboard: direkte Verknüpfung zu den passenden Berichten** — Die Metrik-Kacheln auf dem Dashboard erhalten oben rechts ein kleines Diagramm-Symbol, das direkt den passenden Bericht öffnet: *Speicher* → Speicher-Bericht, *Client-Status* → Verfügbarkeit, *Lizenz* → Lizenz, *Aktive Alarme* → Störungen, *Rollouts* → Deployments, *Aktivität* → Tasks, *Compliance* → Compliance. Die bisherigen Verknüpfungen (z. B. zu den Einstellungen, Gruppen oder Rollouts) bleiben daneben erhalten. Wirkt nach Aktualisierung der Verwaltungsoberfläche.

## 2026-06-18

- **Berichte: interne Überarbeitung, Bedienung verbessert** — Die Berichtssektion wurde technisch neu strukturiert (gleiche Inhalte, Tabs und Diagramme wie zuvor). Spürbar: der *Aktualisieren*-Knopf lädt jetzt gezielt den gerade geöffneten Bericht neu; der *Speicher*-Bericht blockiert beim Einlesen der Datenträger den Server nicht mehr; und eine Aktualisierung der Server-Dienste läuft auch dann sauber durch, wenn in der Datenbank Altbestände mit Doppelwerten liegen (keine Neustart-Endlosschleife mehr). Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

- **Berichte: Flotten-Verfügbarkeit als Tagestrend** — Die Berichtssektion erhält einen neuen Tab *Verfügbarkeit* mit Zeitraumwahl (7 / 30 / 90 Tage). Er zeigt die aktuelle Geräteflotte (online, offline, im Fehlerzustand, gesamt), den Verlauf der Online-Quote über die Tage als Diagramm, die Verteilung der Geräte nach letztem Kontakt (unter 5 Minuten bis über 7 Tagen oder nie gesehen) sowie eine Liste chronisch offline gefallener Geräte (nach Anzahl der Offline-Vorfälle). Der Tagestrend baut sich ab dem Tag der Aktualisierung auf — eine tägliche Momentaufnahme der Flotte wird im Hintergrund erfasst; rückwirkende Werte gibt es nicht. Die Übersicht „letzter Kontakt" und die chronisch-offline-Liste stehen sofort zur Verfügung. Wirkt nach Aktualisierung der Server-Dienste (Backend und Worker) und der Verwaltungsoberfläche.

- **Berichte: Speicher-/Kapazitätsübersicht + VPN-/LAN-Konnektivitätsabdeckung** — Die Berichtssektion erhält zwei neue Übersichts-Tabs: *Speicher* zeigt das belegte Image-Volumen mit Anzahl und Aufschlüsselung nach Status, die Auslastung des Datenträgers in Prozent (ab 85 Prozent farblich hervorgehoben) und den freien Platz sowie eine Prognose, in wie vielen Tagen der Speicher voraussichtlich voll ist (hochgerechnet aus dem Image-Zuwachs der letzten 30 Tage), eine grafische Datenträger-Belegung (belegt/frei) sowie die größten Speicher-Verbraucher nach Ordner gruppiert (Klone, Captures, ISOs, Delta-Updates) mit Gesamtgröße und den größten Einträgen je Ordner; *VPN* zeigt eine Momentaufnahme der Konnektivität — aktive Verbindungen, Cloud-Verbindungen, Fehler und versiegelte TPM-Module, die Verteilung nach Aufnahme-Status mit LAN-/Remote-Zählung sowie die Abdeckung je VPN-Gruppe. Beide Übersichten benötigen keine Zeitraumwahl und werden beim ersten Öffnen geladen. Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

- **Berichte: Lizenz-Auslastung + Lebenszyklus/Ablauf (Zertifikate, Garantien) — für alle Rollen sichtbar** — Die Berichtssektion erhält zwei neue Tabs: *Lizenz* zeigt einen Seat-Forecast mit Belegung (aktive Geräte gegenüber dem Limit), Auslastung in Prozent, Lizenz-Status und verbleibenden Tagen bis zum Ablauf, dazu die Verteilung nach Geräte-Stufe und den Verlauf der Geräte-Aufnahmen über die Zeit; *Lebenszyklus* zeigt eine Momentaufnahme der bevorstehenden Abläufe — Zertifikate und Geräte-Garantien gruppiert nach Restlaufzeit (abgelaufen, unter 30/60/90 Tagen, in Ordnung) sowie eine Liste der nächsten Abläufe. Die Lizenz-Auswertung zeigt bewusst nur zusammengefasste Kennzahlen und keine sensiblen Lizenz-Details, daher ist sie auch für Konten mit reiner Leseberechtigung sichtbar. Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

## 2026-06-17

- **Berichte: drei weitere zeitbasierte Auswertungen** — Die Berichtssektion erhält drei zusätzliche, zeitachsenbasierte Tabs (gleiche Zeitraumwahl 7 / 30 / 90 Tage, Gruppierung nach Tag oder Woche): *Updates* zeigt den Erfolg der Delta-Updates mit Erfolgsquote, Signaturfehlern, durchschnittlichen Wiederholungen und Download-Rate sowie der Status-Verteilung; *Tasks* zeigt Durchsatz und Fehlerquote der Geräte-Aufgaben pro Aufgabentyp inklusive durchschnittlicher Laufzeit und hängender Warteschlange; *DHCP* zeigt die Vergabe von Netzwerk-Adressen (aktive Leases, Leases im Zeitraum, unterschiedliche MAC-/IP-Adressen) im Zeitverlauf. Updates und Tasks lassen sich als CSV exportieren. Die Verlaufsdiagramme werden direkt in der Oberfläche gezeichnet. Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

- **Berichte: drei neue zeitbasierte Auswertungen** — Die Berichtssektion erhält drei zusätzliche, zeitachsenbasierte Tabs mit Zeitraumwahl (7 / 30 / 90 Tage, Gruppierung nach Tag oder Woche) und CSV-Export: *Störungen* zeigt den Verlauf neuer Störungen sowie Bestätigungs- und Lösungszeiten (MTTA/MTTR) je Störungsart; *Aktivität* zeigt die SSH-Befehlsaktivität im Zeitverlauf mit Fehlerquote, durchschnittlicher Dauer und den aktivsten Geräten; *Deployments* zeigt die Erfolgsquote von Rollouts mit Abschluss-Verlauf und Dauer-Kennzahlen. Die Verlaufsdiagramme werden direkt in der Oberfläche gezeichnet (keine zusätzliche Software). Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

- **Berichtssektion wieder verfügbar und erweitert** — Der Menüpunkt **Berichte** (Tabs *Compliance* und *Nutzung*) ist wieder in der Navigation erreichbar. Die Compliance-Übersicht zeigt jetzt zusätzlich zwei Auswertungen: die Verteilung der Agent-Versionen über die Geräteflotte inklusive Hinweis auf veraltete oder nie eingecheckte Geräte, sowie den Gesundheitszustand der geplanten Hintergrund-Aufgaben (überfällige oder fehlerhafte Läufe). Die Nutzungs-Übersicht zeigt zusätzlich eine Hardware-Auslastung pro Gruppe (CPU/RAM/Festplatte als Ampel-Tabelle mit Hinweis auf knappe Geräte) sowie die Verteilung der Geräte über Gruppen und installierte Image-Versionen inklusive Versions-Rückstand. Alle Auswertungen lassen sich mitdrucken. Wirkt nach Aktualisierung der Server-Dienste und der Verwaltungsoberfläche.

## 2026-06-12

- **Geräte-Updates passen sich schwankender Bandbreite an (Home-Office/VPN/WLAN)** — Die Download-Drosselung für Betriebssystem-Updates misst die Leitungsqualität jetzt direkt an der laufenden Update-Verbindung statt an einem vorab erhobenen Referenzwert. Das behebt zwei Probleme: Nach einem Standortwechsel (z. B. Büro → Home-Office) konnte ein Update unnötig auf der Minimal-Geschwindigkeit verharren, obwohl die Leitung frei war; und auf schwachen Anschlüssen bremste sich das Update zu spät, was parallele Arbeitssitzungen stören konnte. Updates nutzen die verfügbare Bandbreite jetzt besser aus und nehmen sich automatisch zurück, sobald die Leitung anderweitig gebraucht wird — auch bei WLAN-Schwankungen ohne unnötige Dauer-Drosselung. Wirkt nach Aktualisierung der Client-Agenten.

- **Zuverlässigere Geräte-Aktionen und Rollouts** — Mehrere selten auftretende Fehler wurden behoben: Geräte-Befehle (z. B. Neustart) konnten in ungünstigem Timing doppelt ausgeführt werden; ein gestufter Rollout konnte hängen bleiben, wenn das gewählte Abbild noch nicht fertig gebaut war; das Abbrechen eines Rollouts konnte ein gerade startendes Gerät fälschlich als abgebrochen markieren. Diese Abläufe sind jetzt abgesichert. Wirkt nach Aktualisierung der Server-Dienste.

- **Geräte-Updates lassen kein Rollback-Abbild mehr verlieren** — In seltenen Fällen konnte die automatische Aufräumung alter Systemstände den Stand der aktuell laufenden Version löschen, wodurch das nächste Update fehlschlug und eine vollständige Neuinstallation nötig wurde. Der laufende Stand ist jetzt geschützt, und beim Löschen eines Standes werden auch die zugehörigen Home-Daten mit entfernt (keine verwaisten Reste mehr). Wirkt nach Aktualisierung der Client-Agenten.

- **Abbruch während der ersten Update-Phase wird korrekt angezeigt** — Wurde ein Update-Klon während der ersten Phase abgebrochen, meldete die Oberfläche fälschlich „abgebrochen" und blieb stehen. Der Fortschritt läuft jetzt sichtbar weiter, bis die laufende Phase sauber endet. Wirkt nach Aktualisierung der Server-Dienste.

- **Zertifikats-Austausch hinterlässt nie ein unpassendes Schlüsselpaar** — Beim Hochladen eines eigenen TLS-Zertifikats konnte ein Fehler im letzten Schritt Zertifikat und Schlüssel inkonsistent zurücklassen. Schlägt der Austausch fehl, wird jetzt automatisch auf das vorherige, funktionierende Paar zurückgesetzt. Wirkt nach Aktualisierung der Server-Dienste.

- **Netzwerk-Adresse wird nicht mehr versehentlich entfernt** — Beim erneuten Setzen der Server-Adresse konnte eine ähnliche Bestandsadresse falsch erkannt werden, was die Netzwerkkarte adresslos zurücklassen konnte. Die Adress-Erkennung ist jetzt exakt. Wirkt nach Aktualisierung der Server-Dienste.

- **Aussagekräftige Fehlermeldungen in der Verwaltungsoberfläche** — Bisher zeigte die Oberfläche bei vielen Fehlern nur den allgemeinen Hinweis „An error occurred", auch wenn z. B. die Verbindung zum Server gestört war. Fehlermeldungen nennen jetzt die konkrete Ursache: Server nicht erreichbar, Zeitüberschreitung, fehlende Berechtigung, nicht gefundene Ressource u. a. — in der jeweils eingestellten Sprache. Bei einer Verbindungsstörung wiederholen sich die Hinweise außerdem nicht mehr im Sekundentakt. Zusätzlich wird das Aktivieren eines Lager-Geräts am Lizenz-Limit jetzt mit einer klaren Meldung abgelehnt, statt ohne Rückmeldung zu scheitern. Wirkt nach Aktualisierung der Server-Dienste.

- **Client-Agent: Update-Signatur wird vor dem Einspielen erzwungen** — Beim Anwenden eines Betriebssystem-Updates auf dem Client wurde die Signaturprüfung in einem Sonderfall (fehlende Signaturdatei) stillschweigend übersprungen, statt das Update abzulehnen. Außerdem werden die Update-Beschreibungsdaten jetzt streng auf gültige Form geprüft. Beides verhindert, dass manipulierte Update-Daten eingespielt werden. Wirkt nach Aktualisierung der Client-Agenten.

- **Client-Agent: Update lässt das Gerät nie ohne Agent zurück** — Bei der Agent-Aktualisierung wurde die laufende Agent-Datei entfernt, bevor die neue übertragen war; ein Übertragungsfehler hätte das Gerät ohne Agent zurückgelassen. Die neue Datei wird jetzt erst vollständig übertragen, geprüft und dann ausgetauscht — bei einem Fehler bleibt die funktionierende Version erhalten. Wirkt nach Aktualisierung der Server-Dienste.

- **Image-Wiederherstellung auf NVMe-/eMMC-Geräten** — Auf Geräten mit NVMe- oder eMMC-Speicher schlug das Anlegen der Daten-Partition fehl, weil der Gerätename falsch abgeleitet wurde. Das ist behoben; SATA-, NVMe- und eMMC-Datenträger werden korrekt erkannt. Wirkt bei der nächsten Image-Vorbereitung.

- **Image-Vorbereitung bricht bei fehlender Daten-Partition ab** — Konnte die Daten-Partition nicht eingebunden werden, lief die Installation bisher trotzdem weiter und legte die Agent-Daten am falschen Ort ab (die nach dem ersten Update verloren gingen). Die Installation bricht jetzt mit einer klaren Meldung ab. Wirkt bei der nächsten Image-Vorbereitung.

- **Klon-Fehler werden zuverlässig gemeldet** — Beim Erstellen eines Klons konnte ein Fehler einer Partition den Vorgang stillschweigend abbrechen, ohne ihn als Fehler auszuweisen. Solche Fehler werden jetzt erkannt und mit Angabe der betroffenen Partition gemeldet. Außerdem wurde die Wiederherstellung von Festplatten-Abbildern (dd-Image) korrigiert, die zuvor ihre Dateien nicht fand. Wirkt bei der nächsten Image-Vorbereitung bzw. Verteilung.

- **Agent-Upload kann die Agent-Datei nicht mehr zerstören** — Ein versehentlich leerer oder ungültiger Upload der Agent-Datei überschrieb bisher die funktionierende Version, bevor er geprüft wurde. Uploads werden jetzt erst auf Inhalt und Dateityp geprüft und nur bei Gültigkeit übernommen. Wirkt nach Aktualisierung der Server-Dienste.

- **Agent-Update einzelner Geräte stoppt keine fremden Updates mehr** — Das Starten eines Agent-Updates für ausgewählte Geräte oder eine Gruppe brach bisher alle laufenden Agent-Updates flottenweit ab. Jetzt sind nur noch die tatsächlich angesprochenen Geräte betroffen. Wirkt nach Aktualisierung der Server-Dienste.

- **Stapel-Befehle per SSH berücksichtigen das eingestellte Zeitlimit** — Beim gleichzeitigen Ausführen eines Befehls auf mehreren Geräten wurde das angegebene Zeitlimit ignoriert und stattdessen fest 30 Sekunden verwendet; länger laufende Befehle (z. B. Paket-Updates) brachen vorzeitig ab. Das eingestellte Zeitlimit wird nun verwendet. Wirkt nach Aktualisierung der Server-Dienste.

- **Gleichzeitige Klon-/Wiederherstellungs-Vorgänge stören sich nicht mehr** — Wurden zwei Cloning-Vorgänge fast gleichzeitig gestartet (z. B. Doppelklick), konnten beide starten und sich gegenseitig die Daten beschädigen. Der Einzelvorgang-Schutz greift jetzt zuverlässig. Außerdem wird ein Abbruch während der ersten Phase eines Update-Klons jetzt ehrlich gemeldet und tatsächlich befolgt, statt scheinbar erfolgreich weiterzulaufen. Wirkt nach Aktualisierung der Server-Dienste.

- **Server bleibt nach kurzen Docker-Aussetzern erreichbar** — Bei einem kurzen Aussetzer des Container-Dienstes während des Speicherns der Netzwerk-Konfiguration konnte der Server die korrekt eingestellten Adressen verlieren und für die Clients unerreichbar werden, obwohl „gespeichert" gemeldet wurde. Die Adressermittlung greift in diesem Fall jetzt auf die hinterlegte Konfiguration zurück. Wirkt nach Aktualisierung der Server-Dienste.

- **Netzwerk-Adresse wird vor dem Anwenden geprüft** — Beim Setzen der Rollout-Netzwerkadresse wurden ungültige Adressen erst akzeptiert und die alte Adresse entfernt, was die Netzwerkkarte adresslos zurücklassen konnte. Adressen werden jetzt vorab geprüft, und die neue wird gesetzt, bevor die alte entfernt wird. Wirkt nach Aktualisierung der Server-Dienste.

- **NTP-Zugriffsbeschränkung bleibt nach Bearbeitung erhalten** — Das Bearbeiten der Zeitserver öffnete bisher den Zeitdienst versehentlich für das gesamte Netzwerk, statt ihn auf das Rollout-Subnetz beschränkt zu lassen. Die im Setup gesetzte Beschränkung bleibt nun erhalten. Wirkt nach Aktualisierung der Server-Dienste.

- **Verteilung per BitTorrent meldet Fehler korrekt** — Schlug das Hinzufügen einer Partition beim BitTorrent-Restore fehl, wurde der Vorgang trotzdem als erfolgreich gemeldet, obwohl eine Partition nicht geschrieben war. Solche Fehler werden jetzt erkannt und der Vorgang als fehlgeschlagen gemeldet. Wirkt nach Aktualisierung der Server-Dienste.

- **Aufgaben werden bei Worker-Ausfall nicht mehr mehrfach ausgeführt** — Fiel der Hintergrund-Dienst zeitweise aus, wurde eine wartende Aufgabe bei jedem Geräte-Kontakt erneut eingereiht und später vielfach ausgeführt. Aufgaben werden jetzt nur noch einmal eingereiht. Wirkt nach Aktualisierung der Server-Dienste.

- **ThinVPN: Modul- und Router-Verwaltung robuster** — Doppelte oder mit internen Namen kollidierende VPN-Modulnamen werden jetzt abgewiesen, statt eine dauerhaft instabile Konfiguration zu erzeugen. Bei mehreren Geräten gleichen Namens wird die VPN-Zuordnung nicht mehr falsch geraten. Und ein zweiter, manuell angelegter Netzwerk-Router wird nicht mehr versehentlich überschrieben. Wirkt nach Aktualisierung der Server-Dienste.

- **Fehler werden nicht mehr stillschweigend verschluckt** — An mehreren Stellen wurden interne Fehler ignoriert und Aktionen als erfolgreich gemeldet, obwohl sie es nicht waren. Behoben, u. a.: Speichern von Alarm-Kanälen löscht bei einem kurzen Datenbank-Aussetzer nicht mehr versehentlich das hinterlegte SMTP-Passwort; ein abgebrochener ISO-Upload hinterlässt keine unvollständige, trotzdem auswählbare Datei mehr; die Server-Dienst-Überwachung meldet einen Datenbank-Ausfall jetzt ehrlich als „degraded" statt „ok"; fehlgeschlagene NFS-Freigaben, chrony-Neustarts und Playbook-Importe werden sichtbar gemeldet bzw. brechen sauber ab; der Werksreset meldet, falls einzelne Dateien nicht gelöscht werden konnten. Wirkt nach Aktualisierung der Server-Dienste.

- **NTP-Server-Eingaben werden geprüft** — Beim Speichern der Zeitserver-Einstellungen werden ungültige Einträge (leer oder mit unerlaubten Zeichen) jetzt abgewiesen, statt eine fehlerhafte Zeitdienst-Konfiguration zu schreiben. Wirkt nach Aktualisierung der Server-Dienste.

- **Sicherheitsprotokoll erfasst jetzt An-/Abmeldungen und Verwaltungsaktionen** — Das Audit-Protokoll blieb bisher faktisch leer: An- und Abmeldungen, fehlgeschlagene Anmeldeversuche, Passwort- und 2FA-Änderungen, Benutzerverwaltung sowie Lizenz- und Signaturschlüssel-Aktionen wurden nicht aufgezeichnet. Diese sicherheitsrelevanten Ereignisse landen jetzt im Audit-Protokoll (das Werksreset wird ins Server-Log geschrieben, da es das Protokoll selbst leert). Wirkt nach Aktualisierung der Server-Dienste.

- **Passwort-Zurücksetzen beendet bestehende Sitzungen** — Wurde das Passwort eines Benutzers über die Benutzerverwaltung geändert, blieben dessen bestehende Sitzungen gültig — ein zuvor entwendeter Zugang funktionierte weiter. Jetzt werden bestehende Sitzungen beendet und die Zwei-Faktor-Anmeldung zurückgesetzt. Wirkt nach Aktualisierung der Server-Dienste.

- **Mindestlänge für Passwörter durchgängig erzwungen** — Die Mindestlänge von 8 Zeichen galt bisher nur beim Selbst-Ändern des Passworts; beim Zurücksetzen und beim Anlegen/Bearbeiten von Benutzern konnten leere oder sehr kurze Passwörter gesetzt werden. Das wird nun überall geprüft. Wirkt nach Aktualisierung der Server-Dienste.

- **Härtung der Anmelde-Schnittstelle** — Die Abmelde-Schnittstelle ist jetzt ratenbegrenzt und akzeptiert nur noch gültige Sitzungs-Token; die Anmelde-Schnittstellen weisen übergroße Anfragen ab. Damit kann ein Gerät im Netzwerk den Server nicht mehr durch massenhafte oder überdimensionierte Anfragen belasten. Wirkt nach Aktualisierung der Server-Dienste.

- **Image-Aufnahme: Manipulation eines anstehenden Auftrags verhindert** — Ein Gerät im Netzwerk konnte einen anstehenden Image-Aufnahme-Auftrag eines anderen Geräts stören, indem es dessen Netzwerk-Boot-Konfiguration zurücksetzte, bevor das Zugangs-Token geprüft wurde. Die Prüfung erfolgt jetzt zuerst. Wirkt nach Aktualisierung der Server-Dienste.

- **ThinVPN: Modul-Freigaben wirken nur noch auf den jeweiligen Host** — Bei den optionalen ThinVPN-Host-Modulen galten die freigegebenen Ports versehentlich für die gesamte Zielgruppe (alle Modul-Hosts und den Server) statt nur für den Host des jeweiligen Moduls. Die Freigaben sind jetzt exakt auf den jeweiligen Modul-Host beschränkt. Wirkt nach Aktualisierung der Server-Dienste; bestehende Konfigurationen werden beim nächsten Abgleich automatisch korrigiert.

- **Image-Verteilung: Statusmeldung eines Geräts kann fremde Geräte nicht mehr stören** — Über die öffentliche Abschluss-Meldung einer Image-Verteilung konnte ein Gerät im Netzwerk ein anderes registriertes Gerät auf „offline" setzen und ihm den Dateizugriff entziehen, ohne ein gültiges Zugangs-Token. Diese Aktionen erfordern jetzt einen gültigen, zur laufenden Verteilung gehörenden Token. Wirkt nach Aktualisierung der Server-Dienste.

- **Stufenweise Image-Verteilungen werden vollständig nachverfolgt** — Bei stufenweisen Verteilungen (Rollouts) wurde der Abschluss der einzelnen Rechner intern nicht verbucht: Die Stufen-Statistik blieb dauerhaft auf „wird verteilt" stehen, und die Sicherheitsbremse („bei zu vielen Fehlern anhalten") konnte nie auslösen. Außerdem konnte ein ungünstig getimter Statusbericht eines Rechners dessen anstehende Neuinstallation unbemerkt entschärfen. Rollout-Stufen nutzen jetzt dieselbe bewährte Maschinerie wie einzelne Verteilungen — mit korrekter Statistik, funktionierender Fehlerbremse und verlässlichem Start. Wirkt nach Aktualisierung der Server-Dienste.

- **Benachrichtigungen bei Störungen funktionieren wieder** — Die regelmäßige Prüfung der Alarm-Regeln (z. B. Client offline, Festplatte voll) war durch einen Platzhalter lahmgelegt und lief nie. Sie läuft jetzt alle fünf Minuten. Wirkt nach Aktualisierung der Server-Dienste.

- **Wartungsfenster unterdrücken Alarme jetzt wirklich** — Wartungsfenster mit Geltungsbereich „alle Rechner" (die Voreinstellung) sowie wiederkehrende Fenster (täglich/wöchentlich/monatlich) wurden bei der Alarm-Unterdrückung ignoriert — Benachrichtigungen kamen trotz geplanter Wartung. Beides wird jetzt korrekt ausgewertet, auch in der Aktiv-Anzeige der Fenster-Liste. Wirkt nach Aktualisierung der Server-Dienste.

- **ThinVPN-Protokoll wächst nicht mehr unbegrenzt** — Die VPN-Ereignis-Übernahme speicherte dieselben Ereignisse bei jedem Abruf erneut; die Protokoll-Tabelle wuchs dadurch unbegrenzt. Ereignisse werden jetzt eindeutig erkannt und nur einmal gespeichert. Wirkt nach Aktualisierung der Server-Dienste.

- **TPM-Status der Clients wird gespeichert** — Der vom Client gemeldete TPM-Status (vorhanden/versiegelt) ging beim Speichern still verloren, weil die Datenbankfelder fehlten. Wirkt nach Aktualisierung der Server-Dienste.

- **„Lager"-Markierung beim Anlegen eines Clients wird übernommen** — Der Lager-Schalter im Anlege-Formular wurde beim Speichern verworfen; die Markierung musste nachträglich gesetzt werden. Wirkt nach Aktualisierung der Server-Dienste.

- **Client-Agent: Sicherungsstände werden korrekt verwaltet** — Der Agent behält jetzt zuverlässig genau zwei Sicherungsstände (den aktuellen und den vorherigen) inklusive der zugehörigen Home-Bereiche. Bisher konnten durch eine fehlerhafte Sortierung die falschen Stände gelöscht und im Fehlerfall ein ungeeigneter Stand für die Wiederherstellung gewählt werden. Wirkt nach Aktualisierung der Client-Agenten.

- **Mehrstufige Betriebssystem-Updates bleiben nicht mehr hängen** — Musste ein Client mehrere Update-Schritte nacheinander durchlaufen (z. B. von einer älteren Version über eine Zwischenversion zum Ziel), konnte die Kette nach dem ersten Schritt stehen bleiben: Der nächste Schritt bekam nie eine Download-Freigabe. Betroffen waren nur Ketten ohne zusammengefasste Updates. Wirkt nach Aktualisierung der Server-Dienste.

- **Einrichtungs-Assistent prüft Eingaben und meldet Teilprobleme** — Der Assistent nimmt fehlerhafte Eingaben (z. B. ein zu kurzes Administrator-Passwort, ungültige Netzwerk-Adressen oder eine ungültige Zertifikats-Laufzeit) nicht mehr an, sondern weist sie vor dem Speichern mit einer klaren Fehlermeldung ab. Schlägt beim Abschluss ein Teilschritt fehl (z. B. das Erzeugen des Zertifikats oder der Neustart des Zeitdienstes), wird das jetzt am Ende des Assistenten angezeigt statt hinter einer Erfolgsmeldung zu verschwinden. Wirkt nach Aktualisierung der Server-Dienste.

- **Geplante Verteilungen funktionieren auch im Release-Deployment** — In der Auslieferungs-Variante der Dienste fehlten dem Hintergrund-Dienst einige Verzeichnis-Zuordnungen und Einstellungen, die er zum Aktivieren geplanter Verteilungen braucht; außerdem nutzte die DHCP/PXE-Überwachung dort noch die alte, weniger aussagekräftige Prüfung. Beides ist an die Entwicklungs-Variante angeglichen. Wirkt nach Aktualisierung der Server-Dienste.

- **Werksreset macht den Server nicht mehr unbrauchbar** — Nach einem Zurücksetzen auf Werkseinstellungen konnte der Server beim nächsten Neustart in einer Fehlerschleife hängen bleiben, weil eine interne Verwaltungstabelle mit geleert wurde. Außerdem ließ sich die ThinVPN-Verwaltung nach einem Reset nicht mehr einrichten. Beides ist behoben; der Reset hinterlässt jetzt einen sauberen Zustand für den Einrichtungs-Assistenten. Wirkt nach Aktualisierung der Server-Dienste.

- **Zertifikats-Upload kann die Weboberfläche nicht mehr lahmlegen** — Beim Hochladen eines eigenen TLS-Zertifikats wurde das bisherige Zertifikat ersetzt, bevor die Dateien geprüft wurden; ein unpassender oder defekter Schlüssel machte die Weboberfläche anschließend unerreichbar. Hochgeladene Zertifikate und Schlüssel werden jetzt vollständig geprüft (inklusive Zusammengehörigkeit von Zertifikat und Schlüssel), bevor sie übernommen werden — bei Fehlern bleibt das bisherige Zertifikat einfach aktiv und der Upload wird mit einer klaren Fehlermeldung abgewiesen. Wirkt nach Aktualisierung der Server-Dienste.

- **Abgebrochene Verteilungen starten keine neuen Installationen mehr** — Wurde eine stufenweise Image-Verteilung (Rollout) abgebrochen, blieben die betroffenen Rechner trotzdem für die Neuinstallation vorgemerkt und wurden beim nächsten Start neu bespielt. Ein Abbruch nimmt die noch nicht gestarteten Rechner jetzt zuverlässig aus der Verteilung (inklusive geplanter Neustarts), während bereits laufende Installationen ungestört zu Ende laufen. Wirkt nach Aktualisierung der Server-Dienste.

- **DHCP/PXE-Dienst übersteht Server-Neustarts zuverlässig** — Kam nach einem Neustart des Servers die Rollout-Netzwerkkarte erst nach dem Container-Dienst hoch, startete der DHCP/PXE-Dienst nicht mehr und blieb dauerhaft stehen. Er wartet jetzt automatisch auf die Netzwerkkarte und bindet sich, sobald sie verfügbar ist. Damit ein dauerhaft fehlendes oder falsch konfiguriertes Netzwerk-Interface dabei nicht unbemerkt bleibt, wird es in der Dienst-Überwachung als fehlerhaft angezeigt, und beim Speichern der Netzwerk-Einstellungen wird das Interface jetzt gegen die tatsächlich vorhandenen geprüft. Wirkt nach Aktualisierung der Server-Dienste.

- **Namensauflösung „thinforge-server" zeigt nicht mehr auf eine falsche Adresse** — Wurden Netzwerk- oder DNS-Einstellungen gespeichert, während das Rollout-Interface gerade nicht verfügbar war, konnte der interne DNS-Eintrag „thinforge-server" dauerhaft auf eine falsche Adresse (das Gateway) zeigen — Clients hätten den Server dann nicht erreicht. Das Speichern verwendet jetzt die hinterlegte Rollout-Adresse oder weist die Änderung mit einer klaren Fehlermeldung ab. Wirkt nach Aktualisierung der Server-Dienste.

- **Hinweis-Dialoge auf den Client-Rechnern erscheinen wieder zuverlässig** — Meldungen, die der Client-Agent auf dem Bildschirm des angemeldeten Benutzers anzeigt (z. B. der Neustart-Countdown nach einem Betriebssystem-Update oder die Anzeige einer aktiven Fernwartungs-Sitzung), wurden in bestimmten Anmelde-Situationen nicht mehr angezeigt: Der Agent hatte versehentlich eine bereits abgemeldete Sitzung des Anmeldebildschirms angesprochen und die Meldung dann stillschweigend verworfen. Der Agent wählt jetzt zuverlässig die tatsächlich aktive Sitzung des angemeldeten Benutzers. Wirkt nach Aktualisierung der Client-Agenten.

- **Image-Vorbereitung: sudo-Rechte je Benutzer auswählbar** — Beim Abschließen einer Basis-Installation (Tools-ISO) lässt sich jetzt per Auswahlliste festlegen, welche lokalen Benutzer sudo-Rechte erhalten; die Auswahl wird geprüft und sauber hinterlegt. Der ausgewählte Benutzer wird zugleich als automatische Anmeldung (Autologin) eingerichtet. Wird niemand ausgewählt, wird auch nichts vergeben. Wirkt bei der nächsten Image-Vorbereitung.

- **Desktop-Hintergrund wird zuverlässig gesetzt** — Der ThinForge-Hintergrund wird beim Login jetzt auch auf XFCE-Desktops (Debian 13) korrekt übernommen und sofort angewandt; bisher konnte in manchen Konstellationen der voreingestellte System-Hintergrund bestehen bleiben. Wirkt bei der nächsten Image-Vorbereitung.

- **Image-Vorbereitung: nicht benötigte Programme werden entfernt** — Beim Abschließen einer Basis-Installation werden vorinstallierte Programme, die im Thin-Client-Betrieb nicht gebraucht werden (u. a. LibreOffice, diverse XFCE-Zubehör-Apps, Terminal-Emulatoren), automatisch entfernt und der Paket-Cache geleert — die Desktop-Oberfläche bleibt dabei vollständig erhalten. Das ergibt schlankere Images. Wirkt bei der nächsten Image-Vorbereitung.

- **VDI-Clients (Citrix / Parallels / Omnissa Horizon) integrierbar** — Die VDI-Clients lassen sich jetzt über einen Ordner auf der Tools-ISO bereitstellen; zum Abschluss der Image-Vorbereitung wird ihre Installation optional angeboten. Wirkt bei der nächsten Image-Vorbereitung.

- **Neue Funktion: VDI-Client-Pakete über die Weboberfläche hochladen** — Im Bereich Cloning gibt es einen neuen Tab „VDI-Clients", über den die Installationspakete für Citrix Workspace App, Parallels Client und Omnissa Horizon Client hochgeladen werden können. Die Pakete werden beim nächsten Start der Cloning-VM automatisch in die Tools-ISO übernommen, sodass sie bei der Image-Vorbereitung zur Verfügung stehen. Bisher mussten die Dateien manuell auf dem Server abgelegt werden — das ist vor allem bei Omnissa problematisch, weil der Download eine Anmeldung beim Hersteller erfordert. Wirkt nach Aktualisierung der Server-Dienste.

- **Hardware-Inventar der Geräte wird wieder erfasst** — Die per Inventar-Abfrage ermittelten Hardware-Daten (CPU, Arbeitsspeicher, Hersteller, Modell, Seriennummer, BIOS, Datenträger) wurden zwar abgefragt, aber nicht gespeichert; die entsprechenden Felder blieben leer. Sie werden jetzt ausgewertet und beim Gerät hinterlegt. Wirkt nach Aktualisierung der Server-Dienste.

- **Verteilungen werden zuverlässig als abgeschlossen erkannt** — Ging die abschließende Fertig-Meldung eines Geräts verloren (z. B. durch Neustart kurz vor der Rückmeldung), blieb eine Verteilung dauerhaft als „aktiv" stehen. Ein Abgleich erkennt jetzt Verteilungen, bei denen bereits alle Geräte fertig sind, und schließt sie ab. Wirkt nach Aktualisierung der Server-Dienste.

- **Wiederherstellung prüft alle ausgewählten Sicherungen** — Schlug bei der Auswahl mehrerer Sicherungsdateien die Prüfung einer Datei fehl, konnte die Wiederherstellung trotzdem mit ungeprüften Dateien weiterlaufen. Sie wird jetzt blockiert, bis jede ausgewählte Datei erfolgreich geprüft wurde. Wirkt nach Aktualisierung der Server-Dienste.

- **Speichern eines Updates legt nicht versehentlich eine neue Basis an** — Konnte der Dialog „Klon speichern" den VM-Status beim Öffnen nicht laden, wechselte er stillschweigend in den Basis-Modus — der Bediener hätte unbemerkt eine neue Basis statt eines Updates angelegt. Jetzt erscheint stattdessen ein deutlicher Fehlerhinweis und das Speichern bleibt gesperrt. Wirkt nach Aktualisierung der Server-Dienste.

- **Fortschrittsanzeige hängt nicht mehr bei kurzen Aussetzern** — Ein einzelner kurzer Abfrage-Fehler während eines Klon-/Wiederherstellungs-Vorgangs ließ die Anzeige dauerhaft auf „läuft" stehen. Erst nach mehreren aufeinanderfolgenden Fehlern wird die Aktualisierung gestoppt. Wirkt nach Aktualisierung der Server-Dienste.

- **Anmeldung und Uploads in der Weboberfläche robuster** — Eine fehlgeschlagene Anmeldung zeigt wieder die konkrete Fehlermeldung (statt den Nutzer wortlos zur Anmeldeseite zurückzuwerfen), und ein Datei-Upload beendet eine gültige Sitzung nicht mehr unnötig. Wirkt nach Aktualisierung der Server-Dienste.

- **Englische Beschriftung der Zeitserver-Einstellungen** — Im englischsprachigen Bereich der Zeitserver-Einstellungen wurden interne Platzhalter statt der Texte angezeigt. Die fehlenden Übersetzungen wurden ergänzt. Wirkt nach Aktualisierung der Server-Dienste.

## 2026-06-02

- **OS-Update nach Lizenz-Upgrade wird zuverlässig nachgeholt** — Wird ein Betriebssystem-Update (Delta) angestoßen, während ein Client noch im eingeschränkten Modus (ohne gültige Lizenz) läuft, führt er es korrekt nicht aus. Nach dem Einspielen der Lizenz (Vollausstattung) holt der Client das Update jetzt automatisch nach. Bisher konnte es vorkommen, dass das Update dauerhaft mit dem Hinweis „zu oft fehlgeschlagen" blockiert blieb, weil die erfolglosen Versuche aus der Zeit ohne Lizenz fälschlich mitgezählt wurden. Wirkt nach Aktualisierung der Client-Agenten.

- **Status-Ping erreicht jetzt auch VPN-Clients** — Ein Klick auf den Status in der Clients-Übersicht prüft die Erreichbarkeit per Ping. Für Clients, die über ThinVPN verbunden sind, wurde dieser Ping bisher von der VPN-Firewall blockiert, sodass sie fälschlich als offline erschienen. Eine zusätzliche VPN-Regel erlaubt dem Server nun gezielt den Ping zu den Clients. Wirkt nach Aktualisierung der Server-Dienste (die VPN-Regel wird automatisch eingerichtet).

- **Durchgängige Zweisprachigkeit (Deutsch/Englisch)** — Fehlermeldungen und Oberflächentexte, die bisher fest auf Deutsch waren, sind nun an die gewählte Sprache gekoppelt: Server-Fehlermeldungen werden in der Weboberfläche übersetzt (Deutsch/Englisch), und zuvor fest deutsche Texte in der Oberfläche folgen dem Sprachumschalter. Die Provisionierungs-Skripte (Tools-ISO) geben ihre Meldungen jetzt einheitlich auf Englisch aus. Die Sprache der Hinweis-Dialoge auf den Client-Rechnern (z. B. Neustart-Countdown) lässt sich serverseitig vorgeben. Wirkt nach Aktualisierung der Server-Dienste; die Sprache der Client-Dialoge wirkt nach Aktualisierung der Client-Agenten.

## 2026-06-01

- **Client-Authentifizierung gehärtet (individuelle Token)** — Jeder Client erhält nach dem ersten Kontakt ein eigenes Authentifizierungs-Token statt eines gemeinsamen. Ein einzelner kompromittierter Client kann dadurch nicht mehr im Namen anderer Clients Meldungen senden. Wird ein Client neu verteilt (Deployment), vergibt der Server dessen Token beim nächsten Kontakt automatisch neu. Wirkt nach Aktualisierung der Server-Dienste.

- **Clients-Übersicht: abgewiesene Anmeldungen sichtbar** — Kann sich ein Client nicht mehr mit gültigem Token anmelden, wird er in der Clients-Übersicht rot mit „Token abgelehnt" gekennzeichnet (statt nur als offline), sodass ein solches Problem sofort auffällt. Wirkt nach Aktualisierung der Server-Dienste.

- **Neue Aktion „Token neu ausstellen" je Client** — In der Clients-Übersicht kann für einen einzelnen Client ein neues Authentifizierungs-Token ausgestellt werden; der Client übernimmt es beim nächsten Kontakt, ohne andere Clients zu beeinflussen. Wirkt nach Aktualisierung der Server-Dienste.

- **VPN-Einrichtung: nicht-funktionaler „Anleitung"-Link entfernt** — Auf der VPN-Seite (solange ThinVPN noch nicht eingerichtet ist) wurde der „Anleitung"-Button entfernt; er verwies auf eine noch nicht hinterlegte Dokumentationsseite. Wirkt nach Aktualisierung der Server-Dienste.

- **Sicherheits-Härtung der Update- und Zertifikatsverteilung** — Beim Verteilen von Betriebssystem-Updates (Deltas) ist der Download jetzt fest an genau das Update gebunden, für das ein Client berechtigt wurde — ein Client kann keine fremden Update-Dateien mehr abrufen. Operator-hinterlegte Vertrauens-Zertifikate werden vor dem Einspielen auf den Clients signiert und vom Client kryptografisch geprüft, und die Fernwartungs-Steuerung wurde gegen manipulierte Eingaben abgesichert. Wirkt nach Aktualisierung der Server-Dienste und der Client-Agenten.

## 2026-05-31

- **Schwachstellen-Bericht priorisiert jetzt nach realer Dringlichkeit** — Die im Bericht verbleibenden (erreichbaren) Schwachstellen werden jetzt nach Ausnutzungs-Wahrscheinlichkeit und Behebbarkeit sortiert: bekannt aktiv ausgenutzte Lücken (CISA „Known Exploited") stehen zuoberst und sind markiert, danach folgt der Risiko-Wert; pro Eintrag ist sichtbar, ob bereits ein Fix verfügbar ist. So ist auf einen Blick erkennbar, was zuerst zu behandeln ist. Die Bewertung der einzelnen Schwachstellen ändert sich dadurch nicht. Wirkt nach Aktualisierung der Server-Dienste.

- **Schwachstellen-Bericht: über das VPN erreichbare Dienste werden gesondert als „External" ausgewiesen** — Dienste, die über die VPN-Funktion (ThinVPN) von außerhalb des lokalen Netzes erreichbar sind, werden im Schwachstellen-Bericht jetzt mit einer eigenen, höchsten Erreichbarkeits-Stufe „External" gekennzeichnet (eigenes Symbol, in der Übersicht zuoberst einsortiert) — statt wie bisher pauschal als „LAN". Diese Einstufung greift nur, sofern die VPN-Funktion tatsächlich eingerichtet ist; ohne eingerichtetes VPN bleibt es bei maximal „LAN". Die Bewertung der einzelnen Schwachstellen bleibt unverändert; die neue Stufe macht nur deutlicher, welche Komponenten die größte Angriffsfläche besitzen und vorrangig behandelt werden sollten. Wirkt nach Aktualisierung der Server-Dienste (der Bericht spiegelt den VPN-Zustand zum Zeitpunkt des Scans).

## 2026-05-30

- **Image-/Klon-Löschung während eines laufenden Rollouts blockiert** — Ein Image bzw. Klon kann jetzt nicht mehr gelöscht werden, solange ein Verteilungs-Vorgang (Rollout) ihn noch verwendet; der Löschversuch wird mit einem Hinweis abgewiesen statt den laufenden Vorgang zu stören. Wirkt nach Aktualisierung der Server-Dienste.

- **Zuverlässigeres Anmelden bei kurzzeitigen Netzwerkstörungen** — Anmeldung und Sitzungs-Wiederherstellung gehen robuster mit kurzen Verbindungsabbrüchen um: ein vorübergehender Fehler beim Laden des Profils meldet nicht mehr fälschlich „abgemeldet", und eine erneut gesendete Anfrage löst keine doppelte Token-Erneuerung mehr aus. Wirkt nach Aktualisierung der Server-Dienste (Weboberfläche).

- **Bedienkomfort in der Weboberfläche** — Im Konfigurationsdialog der Cloning-VM werden Eingaben nicht mehr alle 10 Sekunden vom automatischen Status-Abruf überschrieben; ein manuell ausgelöstes Erreichbarkeits-Ergebnis („Ping") überschreibt den echten Gerätestatus nur noch kurz statt dauerhaft; und eine zuvor exportierte Geräteliste lässt sich auch bei englischer Spracheinstellung wieder fehlerfrei importieren. Wirkt nach Aktualisierung der Server-Dienste (Weboberfläche).

- **Korrekte Versionsnummern auch ab der 100. Aufnahme pro Tag** — Werden an einem Tag sehr viele Image-Stände unter demselben Namen erzeugt, wird der Tageszähler ab 100 jetzt korrekt fortgeführt (zuvor konnte er zurückspringen). Betrifft nur Installationen mit sehr häufigen Aufnahmen. Wirkt nach Aktualisierung der Server-Dienste.

- **Wake-on-LAN über die richtige Netzwerkkarte** — Auf Servern mit mehreren Netzwerkkarten wird das Aufweck-Signal jetzt gezielt über die Rollout-Netzwerkkarte gesendet statt über die vom Betriebssystem zufällig gewählte. Wirkt nach Aktualisierung der Server-Dienste.

- **Weitere interne Absicherungen** — Zusätzliche Prüfungen gegen ungültige Eingaben (DNS-Einstellungen, Datei- und Pfadangaben, CSV-Export) sowie kleinere Korrekturen an der internen Aufgabenverarbeitung. Keine sichtbare Änderung im Betriebsablauf. Wirkt nach Aktualisierung der Server-Dienste.

- **Administratoren können Sicherheitsmerkmale anderer Administratoren nicht mehr zurücksetzen** — Das Zurücksetzen der Zwei-Faktor-Anmeldung (TOTP) eines Kontos verhält sich jetzt wie das Zurücksetzen des Passworts: Konten mit der Rolle „Administrator" sind davon ausgenommen, und das eigene Konto wird über die regulären Selbstbedienungs-Wege geändert. Damit kann ein Administrator einem anderen nicht mehr die zweite Sicherheitsstufe entfernen. Wirkt nach Aktualisierung der Server-Dienste.

- **Stabilität und Absicherung (Sammel-Aktualisierung aus einer internen Code-Durchsicht)** — Mehrere selten auftretende Fehlersituationen werden jetzt sauber behandelt, statt unbemerkt zu scheitern: ein Gerät ohne zugewiesene Adresse wird bei einem Rollout sauber übersprungen statt hängenzubleiben, die Abbruch-Schwelle eines Rollouts rechnet nur noch über die bereits abgeschlossenen Geräte, ein Image-Versand kann nicht mehr versehentlich doppelt starten, und die VPN-Einrichtung bricht bei einer kurzzeitigen Störung nicht mehr ab und richtet sich neu ein. Zusätzlich wurden mehrere mögliche Programmabstürze bei ungewöhnlichen Ausgaben abgefangen. Rein absichernde Änderungen ohne veränderten Ablauf; wirkt nach Aktualisierung der Server-Dienste.

- **Geräte-Agent: stabiler bei der Update-Vorbereitung** — Schlägt das Vorbereiten eines Geräte-Updates unerwartet fehl, kann das den laufenden Geräte-Agenten nicht mehr beenden; er meldet sich weiterhin regulär beim Server. Außerdem prüft der Agent die Versionsangabe strenger, bevor alte Sicherungspunkte aufgeräumt werden. Wird nach Aktualisierung der Geräte-Software (Agent) wirksam.

- **Update-Rollout: Starten genügt — kein separater „Freigeben"-Schritt mehr nötig** — Beim Starten (Aktivieren) eines Update-Rollouts wird das zugehörige Delta-Update jetzt automatisch zur Auslieferung freigegeben; die zugewiesenen Geräte ziehen es daraufhin beim nächsten Kontakt. Zuvor konnte ein gestarteter Rollout ohne vorherige manuelle Freigabe des Deltas wirkungslos bleiben (die Geräte bekamen nichts). Wirkt nach Aktualisierung der Server-Dienste.

- **Zusätzliche Absicherung der auf den Geräten ausgeführten Skripte** — Die Wartungs- und Einrichtungsskripte, die der Geräte-Agent mit erhöhten Rechten ausführt, werden jetzt zusätzlich kryptografisch signiert und vor jeder Ausführung gegen den hinterlegten Signaturschlüssel geprüft — dieselbe Absicherung, die bereits für die Agent-Software und die Update-Pakete gilt. Bisher war hier allein die gesicherte (verschlüsselte) Verbindung der Schutz; ein manipuliertes Skript wird nun erkannt und nicht ausgeführt. Wird nach Aktualisierung der Server-Dienste **und** der Geräte-Software (Agent) wirksam.

- **Image-Verteilung: Lese-Zugriff eines Geräts endet sofort nach dessen Abschluss** — Beim Ausrollen eines Images auf mehrere Geräte wurde die Lese-Freigabe auf die Image-Ablage (NFS) bisher für alle beteiligten Geräte offen gehalten, bis der gesamte Vorgang abgeschlossen war. Jetzt wird die Freigabe für jedes Gerät einzeln entzogen, sobald genau dieses Gerät fertig ist — die übrigen, noch laufenden Geräte werden dabei nicht gestört (die Freigabe wird im laufenden Betrieb angepasst, ohne den NFS-Dienst neu zu starten). Engerer Zugriff bei unverändertem Ablauf. Wirkt nach Aktualisierung der Server-Dienste.

- **Aktualisierung sehr alter Datenbestände schlägt klar fehl statt in einer Neustart-Schleife** — Startet der Server gegen ein sehr altes Datenverzeichnis (aus einer Version vor der VPN-Funktion), brach der Datenbank-Schritt bisher mit einem internen Fehler ab und der Dienst lief in eine Neustart-Schleife. Jetzt wird dieser Fall erkannt und der Schritt mit einer eindeutigen Meldung samt Handlungsanweisung beendet (das Datenverzeichnis muss neu initialisiert werden). Ein direktes In-Place-Upgrade solch alter Stände wird bewusst nicht unterstützt — der vorgesehene Weg ist eine frische Initialisierung. Betrifft nur sehr alte Installationen.

- **Lizenz-Plätze werden konsistent und stabil zugewiesen** — Die Zuteilung der „Full"-Lizenzplätze auf die Geräte war in bestimmten Fällen inkonsistent: aktive (online) Geräte konnten fälschlich auf „Light" zurückgestuft werden, während offline/stillgelegte Geräte einen bezahlten Platz blockierten, und einzelne Geräte konnten zwischen „Full" und „Light" hin- und herspringen. Maßgeblich ist jetzt einheitlich: Auf Lager gebuchte Geräte zählen nicht in die Lizenz, alle übrigen teilen sich die Plätze stabil (bei Überbelegung behalten die ältesten ihren Platz). Wirkt nach Aktualisierung der Server-Dienste.

- **Schwachstellen-Bericht: eine echte Schwachstelle in einem erreichbaren Container wird nicht mehr durch einen abgeschotteten Container verdeckt** — War dieselbe Schwachstelle (CVE) in einem abgeschotteten Container als „nicht betroffen" eingestuft, wurde sie bisher auch in einem aus dem LAN erreichbaren Container ausgeblendet — der Bericht konnte fälschlich „bestanden" anzeigen, obwohl dort eine echte, kritische Schwachstelle vorlag. Die Einstufung „nicht betroffen" gilt jetzt nur noch für genau den Container, in dem sie zutrifft; in jedem anderen, erreichbaren Container erscheint die Schwachstelle weiterhin korrekt im Bericht. Wirkt nach Aktualisierung der Server-Dienste.

## 2026-05-29

- **Mehrere Image-Aufnahmen gleichzeitig stören sich nicht mehr** — Wurden zwei oder mehr Geräte gleichzeitig für eine Image-Aufnahme (Capture) gestartet, konnte sich die Schreibfreigabe für die Images gegenseitig verdrängen — und das erste fertige Gerät konnte den übrigen, noch laufenden Aufnahmen die Schreibfreigabe entziehen, sodass diese abbrachen. Die Schreibfreigabe wird jetzt für alle gerade laufenden Aufnahmen zuverlässig offen gehalten und erst geschlossen, wenn die letzte fertig ist. Wirkt nach Aktualisierung der Server-Dienste.

- **Lizenzstufe wird auf den Geräten zuverlässiger durchgesetzt** — Die Geräte prüfen die hinterlegte Lizenz beim Start jetzt kryptografisch und auf das Gültigkeitsdatum. Eine manipulierte oder abgelaufene „Full"-Markierung fällt automatisch auf „Light" zurück — auch ohne Verbindung zum Server. Wirkt nach Aktualisierung der Geräte-Software (Agent).

- **ISO per URL herunterladen: besserer Schutz gegen interne Ziele** — Beim Herunterladen einer ISO über eine angegebene Web-Adresse wird jetzt bei jeder Weiterleitung erneut geprüft, dass das Ziel keine interne/private Adresse ist. Zuvor konnten bestimmte Weiterleitungen und Adress-Schreibweisen diese Prüfung umgehen. Reine server-seitige Absicherung. Wirkt nach Aktualisierung der Server-Dienste.

- **2FA: erneutes Einrichten schaltet bestehendes 2FA nicht mehr versehentlich ab** — Beim erneuten Aufrufen der 2FA-Einrichtung wurde ein bereits aktives 2FA bisher sofort deaktiviert, noch bevor ein neuer Code bestätigt war (ein abgebrochener Vorgang ließ das Konto ohne 2FA zurück). Jetzt bleibt das bestehende 2FA aktiv, bis ein neuer Code erfolgreich bestätigt wurde. Wirkt nach Aktualisierung der Server-Dienste.

- **Passwortänderung meldet bestehende Anmeldungen ab** — Nach einer Passwortänderung oder einem Passwort-Reset werden alle zuvor ausgestellten Anmeldungen des Kontos ungültig — auch auf anderen Geräten oder in anderen Browsern. Man meldet sich anschließend einmal mit dem neuen Passwort neu an. Bisher blieben alte Anmeldungen bis zu ihrem natürlichen Ablauf gültig. Wirkt nach Aktualisierung der Server-Dienste.

- **VPN „Trennen & löschen": ein fehlgeschlagener Entzug wird jetzt gemeldet** — Konnte beim „Trennen & löschen" eines VPN-Geräts die Löschung auf dem VPN-Server nicht durchgeführt werden (z.B. der VPN-Dienst war kurz nicht erreichbar), meldete ThinForge bisher trotzdem „erledigt", obwohl das Gerät noch VPN-Zugriff hatte. Jetzt wird ein solcher Fehlschlag als Fehler angezeigt und der Vorgang kann erneut ausgelöst werden. Wirkt nach Aktualisierung der Server-Dienste.

- **Remote-Desktop: Sitzungs-Limit und Leerlauf-Abschaltung greifen jetzt** — Die Einstellungen „maximale gleichzeitige Sitzungen pro Gerät" und „Leerlauf-Zeitlimit" wurden bisher nicht angewendet. Jetzt werden zu viele parallele Remote-Desktop-Sitzungen auf dasselbe Gerät abgewiesen, und eine Sitzung ohne jede Aktivität wird nach Ablauf des Leerlauf-Zeitlimits automatisch beendet (eine aktiv genutzte Sitzung bleibt bestehen). Wirkt nach Aktualisierung der Server-Dienste.

- **Lizenz-Limit wird zuverlässiger durchgesetzt** — Das Geräte-Limit der Lizenz ließ sich in zwei Sonderfällen umgehen: durch nachträgliches Umstellen eines Geräts von „Lager" auf „aktiv" sowie durch mehrere exakt gleichzeitige VPN-Aktivierungen. Beide Wege werden jetzt korrekt gegen das Limit geprüft. Wirkt nach Aktualisierung der Server-Dienste.

- **Fernzugriff nur noch für Administratoren und Operatoren** — Das eingebaute Geräte-Terminal und die Remote-Desktop-Fernsteuerung lassen sich jetzt nur noch von Konten mit der Rolle Administrator oder Operator öffnen. Konten mit reiner Leserolle (Standard für neu angelegte Benutzer) sowie bereits abgemeldete oder deaktivierte Konten werden zuverlässig abgewiesen. Damit gilt für diese Direktzugänge dieselbe Rechteprüfung wie für die übrigen Geräte-Aktionen. Wirkt nach Aktualisierung der Server-Dienste.

- **Schwachstellen-Bericht zeigt lokale Schwachstellen wieder vollständig** — Schwachstellen, die nur lokal bzw. aus dem direkt benachbarten Netz ausnutzbar sind, konnten unter bestimmten Umständen fälschlich als „nicht betroffen" eingestuft und aus dem Bericht ausgeblendet werden, sodass dieser zu Unrecht „bestanden" anzeigte. Die Einstufung wurde korrigiert — solche Schwachstellen erscheinen wieder korrekt im Bericht. Wirkt nach Aktualisierung der Server-Dienste.

- **System-Wiederherstellung meldet Datenbank-Fehler jetzt als Fehler** — Schlug beim Einspielen eines System-Backups der Datenbank-Teil fehl, meldete die Wiederherstellung bisher trotzdem „erfolgreich". Jetzt wird ein solcher Fehler klar als Fehlschlag gemeldet, und der Datenbank-Teil wird entweder vollständig oder gar nicht eingespielt (kein halb-wiederhergestellter Stand). Wirkt nach Aktualisierung der Server-Dienste.

- **Defekte Klon-Stände können nicht mehr ausgerollt werden** — Ein als defekt markierter Klon (z.B. nach dem Zurückziehen einer fehlerhaften Version) lässt sich nicht mehr für ein neues Ausrollen auswählen, damit sich der Defekt nicht auf weitere Geräte überträgt. Wirkt nach Aktualisierung der Server-Dienste.

- **Mehr Stabilität bei Update-Downloads und Fernbefehlen** — Mehrere interne Absicherungen verhindern, dass ein abgebrochener Update-Download oder ein nicht antwortendes Gerät dauerhaft Server-Ressourcen belegt (Zeitlimit für Fernbefehle, sauberes Beenden unterbrochener Downloads, geringerer Arbeitsspeicher-Bedarf bei großen ISO- und Backup-Vorgängen). Wirkt nach Aktualisierung der Server-Dienste.

- **VPN-Tab: Aktualisieren-Buttons zeigen wieder eine Lade-Animation** — In den Bereichen „Konfiguration", „Ressourcen" und „Gruppen" des VPN-Tabs drehte das Aktualisieren-Symbol beim Klick keinen Ladekreis, obwohl im Hintergrund tatsächlich neu geladen wurde. Das Symbol zeigt den Ladevorgang jetzt einheitlich an (wie die übrigen Aktualisieren-Schaltflächen). Reine Anzeige-Korrektur, die geladenen Daten waren immer aktuell. Wirkt nach Aktualisierung der Weboberfläche.

## 2026-05-28

- **Interne Aufräumarbeiten am Server-Code** — Umfangreiche Vereinfachung und Entfernung von ungenutztem Code im Backend, ohne Änderung am Verhalten oder an den Funktionen. Keine Auswirkung auf den Betrieb; wirkt nach Aktualisierung der Server-Dienste.

- **Zertifikate für Clients hochladen (z.B. für Citrix)** — Im Bereich „Clients" gibt es den neuen Tab **„Zertifikate"**. Dort lassen sich vertrauenswürdige Zertifikate (CA- oder Server-Zertifikat, als PEM- oder DER-Datei) hochladen — wahlweise für **alle Geräte** oder gezielt für eine **Gruppe**. Die Geräte übernehmen die zugeordneten Zertifikate automatisch in ihren System-Zertifikatsspeicher, sodass z.B. die Citrix-Workspace-App einem selbstsignierten Server vertraut, ohne dass man an jedem Gerät von Hand etwas einrichten muss. Wird ein Zertifikat in der Oberfläche wieder gelöscht, entfernen es die Geräte beim nächsten Abgleich auch wieder. Wirkt nach Aktualisierung der Server-Dienste und der Geräte-Software.

- **VPN: Abgleich und „Trennen & löschen" arbeiten zuverlässiger** — Mehrere interne Verbesserungen am automatischen Abgleich der VPN-Konfiguration. Der Server-Eintrag wird auch dann eindeutig dem richtigen Gerät zugeordnet, wenn auf dem VPN-Dienst mehrere Einträge denselben Namen tragen (es zählt der tatsächlich verbundene). Doppelt angelegte Zugriffsregeln, die durch einen abgebrochenen Vorgang entstehen können, werden beim nächsten Abgleich automatisch bereinigt. Beim „Trennen & löschen" werden Ressourcen und Routing jetzt auch dann zuverlässig entfernt, wenn die Zuordnung zum VPN-Netzwerk intern nicht eindeutig vorlag — so bleiben keine Reste zurück, die das Löschen von Gruppen blockieren. Wirkt nach Aktualisierung der Server-Dienste.

- **VPN: Ändern des lokalen Gateways löst keinen falschen Abgleich des Server-Eintrags mehr aus** — Im VPN-Tab „Konfiguration" wollte der Abgleich bisher den Eintrag des ThinForge-Servers (und den zugehörigen DNS-Eintrag) im VPN-Dienst auf die Gateway-Adresse umstellen, sobald man im lokalen Netzwerk das Gateway änderte. Das war falsch: Das Gateway ist der Router des Netzwerks, nicht der ThinForge-Server. Der Server-Eintrag richtet sich jetzt nach der tatsächlichen Adresse des Servers im lokalen Netz (vorrangig die eingestellte „Server-IP", sonst die echte Adresse der Netzwerkschnittstelle) — das Gateway wird dafür bewusst nicht mehr herangezogen. Lässt sich keine Server-Adresse ermitteln, bricht der Vorgang mit einem Hinweis ab, statt zu raten. Wirkt nach Aktualisierung der Server-Dienste.

- **VPN: Zwei Standard-Zugriffsregeln zielen jetzt auf die Gruppe statt direkt auf den Server** — Die beiden Regeln, über die die VPN-Geräte den ThinForge-Server erreichen (Namensauflösung/DNS und Zugriff auf die Weboberfläche), verweisen als Ziel jetzt auf die Gruppe „thinforgeTarget" statt direkt auf den Server-Eintrag. Diese Gruppe umfasst den Server sowohl über seine VPN-Adresse als auch über seine Adresse im lokalen Netz, sodass der Zugriff auf beiden Wegen greift. Damit verschwindet die zuvor im Tab „Konfiguration" angezeigte Abweichung für diese beiden Regeln. Wirkt nach Aktualisierung der Server-Dienste.

## 2026-05-26

- **VPN: „Verbindung trennen" heißt jetzt „Trennen & löschen" und räumt vollständig auf** — Die Schaltfläche im VPN-Konfigurationsbereich wurde umbenannt und entfernt beim Betätigen jetzt zuerst alle Objekte, die der ThinForge-Server auf dem VPN-Dienst angelegt hat (Zugriffsregeln, Ressourcen, Routing, DNS-Eintrag, Server-Zugang, Gruppen), bevor die Verbindung lokal gelöscht wird. Bisher konnten dabei Reste zurückbleiben (z.B. ließen sich Gruppen nicht entfernen, weil noch Zugriffsregeln auf sie verwiesen). Wirkt nach Aktualisierung der Server-Dienste und der Weboberfläche.

- **VPN: drei Standard-Zugriffsregeln werden zentral verwaltet** — Der ThinForge-Server legt jetzt drei Standard-Zugriffsregeln selbst an und hält sie im gewünschten Stand, passend zur tatsächlichen Konfiguration auf dem VPN-Dienst: DNS-Auflösung und Zugriff auf die Weboberfläche der Geräte zum Server sowie Fernwartung (SSH) vom Server zu den Geräten. Damit bleiben diese Regeln auch nach einem erneuten Einrichten konsistent. Wirkt nach Aktualisierung der Server-Dienste.

- **VPN-Bereich vollständig zweisprachig (Deutsch/Englisch)** — Der gesamte VPN-Bereich (Übersicht, Geräte, Konfiguration, Gruppen, Aufgaben sowie alle Dialoge zum Einrichten, Aktivieren und Trennen) folgt jetzt der Sprachumschaltung oben rechts und liegt vollständig auf Deutsch und Englisch vor. Bisher war dieser Bereich fest deutschsprachig. Im Zuge dessen wurden außerdem nicht mehr genutzte Überbleibsel der früheren VPN-Technik entfernt, ohne dass sich am sichtbaren Funktionsumfang etwas ändert. Wirkt nach Aktualisierung der Server-Dienste und der Weboberfläche.

- **VPN: kleinere Bedien-Verbesserungen** — Beim Aktivieren des VPN für ein Gerät (einzeln oder für eine ganze Gruppe) ist die Gruppe „Clients" jetzt vorausgewählt. Im Konfigurations-Bereich heißt die Schaltfläche zum Anwenden des gewünschten Stands jetzt „Konfig anwenden" (vorher „Reconcile jetzt"). Wirkt nach Aktualisierung der Weboberfläche.

- **VPN „Lokale Ressourcen": gezielte Host-Freigaben wirken jetzt sofort** — Der frühere Bereich „Host-Zugriffs-Module" im VPN-Tab „Konfiguration" heißt jetzt **„Lokale Ressourcen"** (Anlegen über **„Neue Ressource"**). Eine solche Ressource bündelt ein Ziel-Gerät plus die erlaubten Dienste/Ports — etwa für die Fernwartung eines bestimmten Geräts. Neu: Beim Anlegen oder Löschen wird die zugehörige Freigabe jetzt unmittelbar in den VPN-Dienst übernommen bzw. wieder entfernt — der frühere separate Schritt „Reconcile jetzt" ist dafür nicht mehr nötig. Die im VPN-Dienst erzeugte Zugriffsregel trägt einen klaren, sprechenden Namen aus Ressourcenname, Protokoll und Port (z.B. „w22 TCP 5900") und gibt den VPN-Geräten den Zugang zum Ziel-Gerät frei. Wirkt nach Aktualisierung der Server-Dienste und der Weboberfläche.

## 2026-05-25

- **VPN-Netzwerkkonfiguration wird zentral verwaltet und automatisch mit dem VPN-Dienst abgeglichen** — Der ThinForge-Server richtet die VPN-Struktur (Netzwerk, Server-Zugang, DNS und die Zugriffsregeln) jetzt selbst ein und hält sie automatisch im gewünschten Stand. Im VPN-Bereich gibt es dafür den neuen Tab **„Konfiguration"**: er zeigt den tatsächlichen Stand, markiert Abweichungen und bietet eine Schaltfläche, um den gewünschten Stand erneut anzuwenden. Zusätzlich lassen sich dort gezielte Host-Zugriffe als wiederverwendbare Module anlegen — ein Ziel-Gerät plus die erlaubten Dienste/Ports (z.B. für Fernwartung) —, die beim Abgleich automatisch in den VPN-Dienst übernommen werden. Der bisherige Bereich „Zielnetze" entfällt; seine Aufgabe übernimmt das neue Modell. Wirkt nach Aktualisierung der Server-Dienste und der Weboberfläche.

- **Korrektur: Geräte mit aktivem VPN werden in der Geräteliste wieder als „VPN" statt „LAN" angezeigt (Agent v2.14.14)** — Bei Geräten, die ihren Status über die VPN-Verbindung an den Server meldeten, stand in der Geräteliste fälschlich „LAN" als Verbindungsweg. Ursache war ein interner Namensunterschied der VPN-Netzwerkschnittstelle, durch den die Erkennung des tatsächlichen Verbindungswegs ins Leere lief und immer auf „LAN" zurückfiel. Das ist behoben — der Verbindungsweg wird wieder korrekt erkannt und angezeigt. Greift, sobald ein Gerät die neue Agent-Version übernommen und sich danach einmal neu am VPN angemeldet hat (am Gerät das VPN einmal aus- und wieder einschalten); neu eingerichtete Geräte sind sofort korrekt.

- **VPN-Geräte halten ihren VPN-Dienst zuverlässig im gewünschten Zustand — und schalten ihn nie mehr selbsttätig ab** — Ob ein Gerät VPN haben soll, wird jetzt dauerhaft auf dem Gerät hinterlegt: Beim Aktivieren merkt sich das Gerät „VPN an" und sorgt fortan bei jedem Start selbst dafür, dass der VPN-Dienst läuft (auch nach Neustart oder System-Update). Beim Deaktivieren merkt es sich „VPN aus" und hält den Dienst gestoppt. Die frühere automatische Abschaltung im lokalen Netz entfällt — ein Gerät schaltet seinen VPN-Dienst nur noch auf ausdrückliche Anweisung ab, nie von sich aus. Wirkt, sobald die Geräte die neue Agent-Version übernommen haben.

- **VPN-Bereich: Ein Gerät zeigt „installiert" erst, wenn es die VPN-Einrichtung tatsächlich bestätigt hat** — Bisher sprang der Status direkt nach dem Aktivieren auf „installiert", obwohl das Gerät die VPN-Einrichtung noch gar nicht durchgeführt hatte (das konnte z.B. passieren, wenn beim VPN-Server noch ein älterer Eintrag desselben Geräts vorhanden war). Jetzt zeigt die Liste zunächst „wird installiert" und wechselt erst dann in einen bestätigten Zustand, wenn das Gerät selbst zurückmeldet, dass der VPN-Dienst eingerichtet ist — danach „pausiert" (eingerichtet, Verbindung gerade aus, etwa im lokalen Netz) bzw. „aktiv" (verbunden). Schlägt die Einrichtung (noch) fehl — etwa weil das Gerät den VPN-Server gerade nicht erreicht —, bleibt der Status „wird installiert"; die Einzelheiten dazu und die Möglichkeit zum erneuten Versuch stehen im Untertab „Tasks". Wirkt nach Aktualisierung der Server-Dienste; die zuverlässige Rückmeldung im lokalen Netz greift zusätzlich, sobald die Geräte die neue Agent-Version übernommen haben.

## 2026-05-24

- **Neu installierte Geräte führen den VPN-Tunnel von Anfang an über den Relay-Server und schalten IPv6 im Tunnel ab** — Bei der Erst-Installation eines Geräts über das Tools-Medium wird der VPN-Dienst jetzt direkt so eingestellt, dass der Tunnel grundsätzlich über den Relay-Server läuft (statt zuerst eine direkte Verbindung auszuhandeln, die hinter manchen Firewalls unzuverlässig ist) und dass IPv6 im Tunnel deaktiviert ist. Bisher wurde der Relay-Zwang erst beim VPN-Anmelden des Geräts gesetzt; jetzt steht die Einstellung schon ab der Installation fest. Am sichtbaren Verhalten ändert sich nichts — die VPN-Verbindung wird damit nur robuster. Wirkt für Geräte, die mit der neuen Version des Tools-Mediums neu installiert werden.

- **VPN-Mesh-Dienst des Servers nutzt jetzt das offizielle NetBird-Abbild und lässt sich einfach aktuell halten** — Der VPN-Mesh-Dienst auf dem ThinForge-Server lief bisher aus einem selbstgebauten Abbild mit fest eingebauter, älterer NetBird-Version; Aktualisieren erforderte einen Neubau. Er bezieht jetzt das offizielle NetBird-Abbild direkt, sodass ein einfaches Aktualisieren der Abbilder immer die neueste Version bringt. Am Verhalten ändert sich nichts — die Einrichtung erfolgt weiterhin über die VPN-Verwaltung in der Oberfläche. Hinweis beim Update einer bestehenden Installation: Der Mesh-Dienst muss anschließend einmalig neu eingebunden werden (im VPN-Bereich die Verbindungs-Konfiguration einmal speichern). Wirkt nach Aktualisierung der Netzwerk-Dienste.

## 2026-05-23

- **Korrektur: VPN kommt nach einem System-Update jetzt wirklich von selbst wieder hoch (Agent v2.14.11)** — Die in der Vorversion eingeführte automatische Wiederherstellung der VPN-Verbindung nach einem Update griff in der Praxis nicht: eine interne Prüfung suchte die VPN-Anmeldedaten am falschen Ort und übersprang dadurch das Wiedereinschalten. Das ist behoben — bereits fürs VPN aktivierte Geräte schalten ihren VPN-Dienst nach einem Update wieder selbst ein. Wirkt, sobald die Geräte die neue Agent-Version übernommen haben.

- **VPN-Bereich: Geräte nach Gruppen sortiert, korrekter Status und Aktivieren im Hintergrund** — Die Geräteliste im VPN-Bereich ist jetzt nach den Gruppen gegliedert, die für VPN freigeschaltet sind: jede Gruppe ist eine zusammenklappbare Überschrift mit der Anzahl der Geräte und wie viele davon aktiviert sind; aufgeklappt sieht man die einzelnen Geräte und kann ihnen das VPN aktivieren — einzeln oder über „Ganze Gruppe aktivieren" für alle noch nicht aktivierten Geräte einer Gruppe auf einmal. Geräte, die noch nie fürs VPN aktiviert wurden, zeigen jetzt korrekt **„nicht aktiviert"** an statt fälschlich „installiert". Die beiden Aktualisieren-Schaltflächen holen den aktuellen Stand jetzt direkt vom VPN-Server ab (oben: alles, bei der Geräteliste: nur die Geräte). Das Aktivieren läuft nun als Hintergrund-Aufgabe: ein neuer Untertab **„Tasks"** zeigt die laufenden Aktivierungen je Gerät mit Status und etwaigen Fehlern (samt Wiederholen). Wirkt nach Aktualisierung der Server-Dienste (Backend, Hintergrund-Verarbeitung) und der Weboberfläche.

## 2026-05-22

- **Geräte verbinden sich nach einem System-Update von selbst wieder mit dem VPN (Agent v2.14.10)** — Nach einem System-Update war der VPN-Dienst auf dem Gerät zunächst abgeschaltet, weil das frische System-Abbild ihn standardmäßig deaktiviert mitbringt. Bisher kam die VPN-Verbindung erst wieder zustande, wenn der Server das Gerät erneut dazu anwies. Jetzt schaltet das Gerät seinen VPN-Dienst beim ersten Hochfahren nach dem Update selbst wieder ein, sofern es zuvor für das VPN angemeldet war — die Anmeldedaten bleiben über das Update hinweg erhalten. Geräte ohne VPN oder mit gezielt abgeschaltetem VPN bleiben unverändert. (Technischer Hintergrund: die bisherige Lösung stellte nur eine interne Verknüpfung wieder her, die ohnehin schon erhalten blieb — das eigentliche Problem war der nach dem Update abgeschaltete Dienst.) Wirkt, sobald die Geräte die neue Agent-Version übernommen haben.

- **Geräte melden ihren Status jetzt alle 10 Sekunden (Agent v2.14.8)** — Das Standard-Melde-Intervall der Geräte wurde von 60 auf 10 Sekunden verkürzt, sodass Online-/Offline-Status und Geräte-Informationen im Dashboard deutlich schneller aktualisiert werden. Auch bei vorübergehenden Verbindungsproblemen melden sich die Geräte weiterhin konstant alle 10 Sekunden — sie verlangsamen ihren Takt nicht mehr automatisch. Das Intervall lässt sich bei Bedarf weiterhin zentral in den Agent-Einstellungen ändern. Wirkt, sobald Geräte und Server die neue Version übernommen haben.

- **Geräte behalten nach einem Update ihren Namen und ihre VPN-Anmeldung — ohne zusätzlichen Neustart (Agent v2.14.7)** — Bei einem System-Update wird der korrekte Gerätename jetzt direkt in das neue Abbild geschrieben, sodass das Gerät schon beim ersten Hochfahren nach dem Update richtig benannt ist (vorher war dafür noch ein zusätzlicher automatischer Neustart nötig). Ebenso bleibt die VPN-Anmeldung des Geräts über das Update hinweg erhalten. Der ausgelöste Befehl wird dabei exakt befolgt: ein Neustart startet neu, ein Herunterfahren fährt das Gerät herunter. Wirkt, sobald die Geräte die neue Agent-Version übernommen haben.

- **Geräte starten nach einer Namensänderung automatisch einmal neu (Agent v2.14.6)** — Setzt oder ändert der Agent den Gerätenamen — beim ersten Start eines frisch ausgerollten Geräts, beim Übergang von der Vorlage-VM auf echte Hardware oder wenn der Name korrigiert werden musste — wird das Gerät jetzt sofort einmal neu gestartet, damit der neue Name überall sauber greift (vorher konnten Dienste und Anmeldesitzungen noch den alten Namen verwenden). Der Neustart erfolgt ohne Rückfrage; eine Sicherung verhindert wiederholte Neustarts, falls etwas den Namen bei jedem Start zurücksetzt. Wirkt, sobald die Geräte die neue Agent-Version übernommen haben.

- **Die Kern-Server-Dienste starten jetzt unabhängig vom VPN- und vom Fernwartungs-Dienst** — Der zentrale Dienst (Steuer-Schnittstelle und Hintergrund-Verarbeitung) wartet beim Hochfahren nicht mehr darauf, dass der VPN-Dienst und der Fernwartungs-Dienst als „betriebsbereit" gemeldet werden. Beide sind optionale Zusatzdienste — ist einer davon gestört oder nicht gestartet, kommt der Kern des Systems jetzt trotzdem normal hoch, statt darauf zu warten. Beim regulären Hochfahren des gesamten Systems werden VPN und Fernwartung weiterhin wie bisher mitgestartet (sie gehören zur Dienstgruppe „Netzwerk"). Ein gezielter Start nur des Kerndienstes startet diese beiden Zusatzdienste allerdings nicht mehr automatisch mit. Wirkt nach Übernahme der aktualisierten Dienst-Konfiguration beim nächsten Deploy.

- **Setup-Assistent: neue Vorgaben für Domain, DHCP-Adressbereich und Weiterleitungs-Timer** — Im Einrichtungs-Assistenten sind drei Standardwerte angepasst. Die voreingestellte Domain heißt jetzt `thinforge.lan` statt `thinforge.org`. Der DHCP-Adressbereich beginnt jetzt bei der zehnten Adresse des Netzes (z.B. `…​.10`) statt bei `…​.100` — wählt man im Assistenten ein Netzwerk-Interface aus, wird der Bereich automatisch ab dieser Adresse vorgeschlagen, sodass die Adressen davor (`…​.2` bis `…​.9`) für feste Zuweisungen frei bleiben. Und die automatische Weiterleitung zur Anmeldeseite am Ende der Einrichtung wartet jetzt 15 statt 10 Sekunden, damit der Webserver sein frisch erstelltes Zertifikat sicher übernommen hat. Bestehende Installationen sind nicht betroffen — die Werte gelten nur für eine Neu-Einrichtung und lassen sich im Assistenten weiterhin frei überschreiben. Wirkt nach Frontend- und Backend-Rebuild.

- **VPN ist jetzt ein eigener Hauptpunkt im Menü, zwischen „Cloning" und „Netzwerk"** — Der VPN-Bereich war bisher ein Unterpunkt innerhalb von „Netzwerk". Er ist jetzt direkt in der Hauptnavigation erreichbar — eine Ebene höher, zwischen „Cloning" und „Netzwerk". Inhaltlich ändert sich nichts: dieselbe VPN-Verwaltung wie zuvor, nur mit einem Klick weniger erreichbar. Der Bereich „Netzwerk" enthält weiterhin die übrigen Tabs (Lokales Netzwerk, DHCP/DNSMASQ, DNS, PXE). Wirkt nach Frontend-Rebuild.

- **VPN-Tab: „Verbindung" und der Zähler aktiver Clients kommen jetzt ausschließlich vom ThinVPN-Mesh-Server, nicht mehr von der Selbsteinschätzung des Geräts** — Der Server fragt den Mesh-Status jede Minute direkt ab (unabhängig vom Gerät). Ein Gerät gilt im VPN-Tab nur dann als „verbunden", wenn diese Abfrage es zuletzt (innerhalb der letzten 3 Minuten) als verbunden gemeldet hat; andernfalls „getrennt". Vorher konnte sich die Anzeige zwischen Server-Sicht und Geräte-Selbstmeldung widersprechen. Diese Statusquelle betrifft ausschließlich den VPN-Tab — der allgemeine Online-/Offline-Status der Geräte bleibt unberührt. Wirkt nach Backend- + Frontend-Rebuild.

- **VPN: Geräte melden jetzt korrekt, ob sie lokal oder über das VPN verbunden sind — und aktivierte Geräte laufen fest über den Relay** — Bisher zeigte die Übersicht bei jedem Gerät „LAN", auch bei tatsächlich über das VPN verbundenen Geräten, weil die dafür nötige Standort-Prüfung serverseitig nie konfiguriert wurde. Jetzt teilt der Server jedem im VPN aktivierten Gerät mit, wie es seinen Standort prüfen soll: Es prüft regelmäßig, ob es den Server direkt im lokalen Netz erreicht, abgesichert über den Fingerabdruck des Server-Zertifikats (damit ein Angreifer im lokalen Netz das Gerät nicht durch einen vorgetäuschten Server zum Abschalten des VPN verleiten kann). Das Gerät meldet daraufhin verlässlich „LAN" oder „VPN" zurück. Daraus folgt das beabsichtigte Verhalten: Ein Gerät im lokalen Netz schaltet seinen VPN-Tunnel selbsttätig ab (dort nicht nötig), ein entferntes Gerät hält ihn an. Zusätzlich wird ein Gerät beim Aktivieren so eingestellt, dass sein VPN-Tunnel immer über den Relay läuft, statt zuerst eine direkte Verbindung auszuhandeln — letztere ist hinter manchen Firewalls unzuverlässig. Wirkt nach Backend-Rebuild und Agent-Update.

## 2026-05-21

- **VPN-Tab: neuer Status „wird installiert" nach dem Aktivieren** — Bisher sprang der Status eines Geräts direkt nach dem Klick auf „Aktivieren" sofort auf „installiert", obwohl das Endgerät die VPN-Konfiguration noch gar nicht durchgeführt hatte. Jetzt zeigt die Tabelle zunächst **„wird installiert"** (blau) an und wechselt erst dann auf „aktiv" (grün), wenn das Endgerät beim nächsten Status-Abgleich die erfolgreiche Anmeldung am VPN zurückgemeldet hat — der Status spiegelt also die tatsächliche Rückmeldung des Geräts wider, nicht mehr den bloßen Klick. Bleibt ein Gerät länger auf „wird installiert", hat es die Anmeldung noch nicht abgeschlossen (z.B. offline oder Status-Abgleich deaktiviert). Zusätzlich ist der Status „installiert" jetzt grün eingefärbt. Wirkt nach Backend- + Frontend-Rebuild.

- **Interne Konsolidierung des Datenbank-Schemas auf eine einzige Initialdatei** — Die bisher getrennten Schema-Bausteine (Grundschema, VPN-Umstellung, Provisioning-Protokoll) sind zu einer einzigen Initialdatei zusammengefasst, die beim ersten Start einer frischen Datenbank eingespielt wird. Reine interne Aufräumarbeit: das resultierende Datenbank-Schema ist nachweislich identisch (per Schema-Vergleich zweier Testdatenbanken geprüft), keine Auswirkung auf den Betrieb oder auf bestehende Installationen. Wirkt nach Backend-Rebuild.

- **Netzwerk-Trennung des Webservers verschärft: Agent-Pfade nur noch vom Client-LAN und VPN-Tunnel erreichbar, Admin-Oberfläche nur noch vom Management-Netz** — Der Webserver auf dem ThinForge-Server bedient drei verschiedene Netze (Client-LAN, VPN-Tunnel, Management-LAN) jetzt mit jeweils einer eigenen, genau abgestimmten Pfadliste statt einer pauschalen Freigabe. Konkret: Aus dem Client-LAN und über den VPN-Tunnel sind nur noch die Pfade erreichbar, die ein Endgerät tatsächlich braucht (Heartbeat, Agent-Selbst-Update, Skripte, Zertifikats- und Token-Recovery, Delta-Downloads) — die komplette Admin-API und die Web-Oberfläche sind aus diesen Netzen unsichtbar (HTTP 404), auch hinter Anmeldung. Umgekehrt sind dieselben Endgeräte-Pfade aus dem Management-Netz mit HTTP 403 gesperrt: ein Angreifer im Management-Netz kann damit keine gefälschten Heartbeats oder Delta-Downloads mehr auslösen, selbst wenn er ein gültiges Heartbeat-Token besäße. Die Admin-Oberfläche selbst bleibt im Management-Netz wie gewohnt erreichbar — sie braucht weiterhin die Admin-API, weil sie als Single-Page-App im Browser läuft und Anfragen an dieselbe Adresse stellt. Begleitend wurde der VPN-Tunnel-Listener aktiviert, sobald der ThinForge-Server-Peer im VPN-Mesh registriert ist (zog seine Konfiguration bisher nicht automatisch). Wirkt nach Backend-Rebuild und einmaligem Speichern der Netzwerk-Konfiguration im Setup-Wizard (oder Backend-Neustart) zum Auslösen eines Webserver-Reloads.

- **VPN-Tab: zwei neue Bereiche „Zielnetze" und „Gruppen", plus Gruppen-Auswahl beim VPN-Aktivieren** — Im VPN-Tab unter „Netzwerk" gibt es jetzt drei Untertabs statt einer langen Tabelle: „Clients" (wie bisher), „Zielnetze" und „Gruppen". Unter **Zielnetze** kann der Admin Subnetze definieren, die ein VPN-Client über den Tunnel erreichen soll (z.B. das Server-LAN 192.168.20.0/24 oder ein Außenstellen-Netz) — CIDR + Beschreibung + Routing-Peer + Zugang für eine oder mehrere Gruppen wählen, fertig. Der ThinForge-Server selbst wird beim ersten Speichern der VPN-Mgmt-Verbindung automatisch als Routing-Peer für sein lokales LAN eingerichtet, kein zusätzlicher Klick nötig. Unter **Gruppen** kann der Admin frei eigene Gruppen anlegen (z.B. „Außendienst", „Buchhaltung") und sieht pro Gruppe die Anzahl zugeordneter Geräte. Beim Klick auf **Aktivieren** in der Clients-Tabelle öffnet sich jetzt ein Dialog mit Gruppen-Auswahl — Standard bleibt die System-Gruppe „remote-default", aber jede freie Gruppe ist wählbar. **Berechtigungen:** Operatoren sehen Gruppen + Zielnetze nur zur Information; Anlegen/Bearbeiten/Löschen ist Admins vorbehalten. Aktive Geräte werden im Statusbalken oben jetzt anhand der tatsächlichen Mesh-Verbindung gezählt (nicht mehr der Agent-Selbsteinschätzung, die bei der aktuellen VPN-Client-Version nicht mehr verlässlich gefüllt wurde). Außerdem unten rechts ein dezenter Hinweis „powered by NetBird" zur Upstream-Komponente. Wirkt nach Backend- + Frontend-Rebuild.

- **VPN-Mesh-Backend (ThinVPN-Container) auf Version 0.71.3 aktualisiert** — Der lokale Server-Peer-Container war noch auf 0.30.0 (über ein Jahr alt), während Endgeräte über das offizielle Install-Skript bereits auf 0.71.2 lagen. Diese Versions-Spreizung führte gelegentlich zu unauffälligen Sync-Wackelfeldern bei Routen-Updates. Beide Seiten laufen jetzt synchron. Wirkt nach Image-Rebuild der Network-Profile-Container.

- **Agent v2.14.2 + v2.14.3: explizite Verarbeitungsreihenfolge der Heartbeat-Antwort und harter Timeout auf den VPN-Beitritt** — Frühere Agent-Versionen hatten zwei zusammenhängende Probleme: erstens war die Reihenfolge organisch gewachsen (License-Tier wurde z.B. nach Delta- und VPN-Schritten geprüft, obwohl die License-Stufe logisch davor gehört); zweitens konnte der Agent in einem VPN-Beitritts-Aufruf endlos hängenbleiben, wenn der VPN-Daemon-Socket noch nicht bereit war oder das Mesh-Management nicht erreichbar war — das Endgerät erschien dem Verwaltungs-Server als „hängend", obwohl es eigentlich nur in einer internen Retry-Schleife stand. v2.14.2 ordnet die Heartbeat-Antwort jetzt in vier klare Phasen (Konfigurations-Sync → Lizenz → Update → VPN); v2.14.3 wartet aktiv bis zu 15 s auf den Daemon-Socket und bricht den eigentlichen Beitritts-Versuch nach 60 s sauber ab, statt zu blockieren. Sichtbar: ein Deaktivieren-Aktivieren-Wechsel auf einem fehlgeschlagenen Aktivierungs-Versuch zeigt jetzt sofort einen klaren Fehlertext statt minutenlanger „grauer Phase". Wirkt automatisch über das Agent-Self-Update.

- **VPN: Remote-Geräte bekommen automatisch den lokalen DNS-Server, und beim Trennen werden alle VPN-Objekte vollständig entfernt** — Sobald die VPN-Mgmt-Verbindung eingerichtet ist, wird Remote-Geräten automatisch der ThinForge-Server als DNS-Server für die lokale Zone zugewiesen (Split-DNS): lokale Namen wie `thinforge-server` und `*.<lokale-Domain>` lösen über den Tunnel auf, der übrige Internet-Verkehr bleibt beim normalen Resolver der Geräte. Voraussetzung ist eine im DNS-Setup gesetzte lokale Domain — ohne sie wird der DNS-Eintrag übersprungen. Umgekehrt werden beim **Trennen der VPN-Verbindung am Server** (VPN-Tab → „Verbindung trennen") jetzt **alle** automatisch in der VPN-Verwaltung angelegten Objekte wieder entfernt: der Server-Peer, die LAN-Route, der DNS-Eintrag, die ThinForge-Gruppen und alle aktivierten Client-Geräte. Es bleiben keine Karteileichen mehr zurück. Wirkt nach Backend- + Frontend-Rebuild.

- **VPN: ThinForge-Server-DNS-Name `thinforge-server` ist jetzt vom DHCP-Gateway entkoppelt** — Bisher zeigte der DNS-Eintrag, über den Endgeräte den ThinForge-Server finden, fest auf die im DHCP konfigurierte Gateway-Adresse. Wer das Gateway abweichend von der echten Server-IP setzt (z.B. weil ein vorgeschalteter Router der eigentliche Default-Gateway sein soll), hatte den Effekt, dass `thinforge-server` ins Leere zeigte und Endgeräte den Server nicht mehr erreichen konnten. Der DNS-Eintrag wird jetzt aus der tatsächlich auf dem Roll-Out-Interface gebundenen IP des Servers abgeleitet — die DHCP-Gateway-Wahl ist davon unabhängig. Gleiches gilt für den Webserver-Listener, der jetzt automatisch auf die richtige IP gebunden wird, sobald die Netzwerk-Konfiguration des Servers im Setup-Wizard gespeichert wird. Wirkt nach Backend-Rebuild und einer Wiederholung des Speichern-Klicks in **Setup → Netzwerk**.

## 2026-05-20

- **VPN-Funktion grundlegend überarbeitet — sicherer, einfacher zu bedienen** — Die bisherige VPN-Anbindung wurde durch eine neue Lösung ersetzt, die Datenverkehr durchgängig Ende-zu-Ende verschlüsselt — auch der Verwaltungs-Server kann ab sofort den Inhalt der VPN-Pakete nicht mehr einsehen. Sichtbar wird das vor allem im VPN-Tab unter „Netzwerk": Anstelle der bisherigen Sub-Tabs (Tunnel, Clients, Firewall, …) sieht der Operator jetzt einen klaren Setup-Assistenten beim ersten Aufruf (ThinVPN-URL + Zugangs-Token eintragen, Verbindung testen, fertig) und danach eine einzige Tabelle aller verwalteten Geräte mit „Aktivieren"/„Deaktivieren"-Buttons. Pro Gerät wird der Status angezeigt (installiert / aktiv / pausiert / Fehler) sowie der letzte erfolgreiche Verbindungs-Handshake. Aktivierungs-Schlüssel haben jetzt **kein Ablaufdatum** mehr — ein Gerät kann beliebig lange im Vorrat liegen, bevor es ins Homeoffice geht. Geräte, die ins Büro zurückkehren, schalten den VPN-Tunnel automatisch ab; verlassen sie das Büro wieder, geht der Tunnel automatisch hoch — kein Login, kein Klick für den Mitarbeiter. Lizenzlimits werden weiterhin beim Aktivieren geprüft (Klick auf „Aktivieren" zeigt sofort an, wenn das Tier-Limit erreicht ist). Wirkt nach Backend- + Frontend-Rebuild und Image-Update der Klon-Endgeräte. Detaillierte Anleitung: Menü **Netzwerk → VPN → Anleitung**.

## 2026-05-19

- **Agent-Lizenz-Status zieht nach Lizenz-Ablauf jetzt automatisch nach (vorher: erst beim Neustart des Servers)** — Lief der Server-Prozess über das Ablaufdatum der Lizenz hinweg, blieb der intern gespeicherte Lizenz-Status auf dem Stand vom Start hängen und neu zugewiesene Geräte wurden weiterhin als Voll-Lizenz markiert, obwohl die Lizenz tatsächlich abgelaufen war. Sichtbar wurde das u.a. so: am Ablauftag rief der Operator die Geräteübersicht auf und sah dort alle Geräte weiterhin als „Full Agent". Mit der heutigen Backend-Anpassung prüft der Server jetzt jede Stunde im Hintergrund den Lizenz-Status neu (liest die Datei frisch von Platte, klassifiziert anhand des aktuellen Datums) und gleicht die Geräte-Tier-Zuteilung danach an — Übergänge Lizenziert → Gnadenfrist → Free-Tier wirken jetzt also auch ohne Server-Neustart innerhalb einer Stunde. Das 60-Tage-Verhalten (Gnadenfrist behält Voll-Lizenz, erst danach Rückfall auf Free) bleibt unverändert. Wirkt nach dem Backend-Rebuild.

- **Neue Dashboard-Karte „Lizenz" — Lizenz-Status auf einen Blick** — Das Dashboard zeigt ab sofort eine neue Karte mit dem aktuellen Lizenz-Zustand: farbiges Status-Chip (Lizenziert grün / Gnadenfrist orange / Abgelaufen rot / Free-Tier grau), Lizenzinhaber-Name, verbleibende Tage bis Ablauf (bzw. Tage in der Gnadenfrist), sowie die Geräte-Auslastung als Balken (aktive Geräte von zulässigem Maximum). Bei mehr als 90 % Auslastung wechselt der Balken auf Gelb, bei 100 % auf Rot — soll als frühe Warnung dienen, bevor neue Geräte-Registrierungen am Limit blockiert werden. Klick auf den Pfeil führt direkt zu **Einstellungen → Lizenz**. Die Karte ist standardmäßig sichtbar und lässt sich wie alle anderen Karten über die Dashboard-Einstellungen ausblenden oder in der Breite anpassen. Wirkt nach Frontend-Rebuild.

## 2026-05-18

- **Clients-Übersicht zeigt jetzt eine Spalte „Aktuelle IP"** — In der Geräteliste erscheint zwischen Status und installierter Version eine neue Spalte, die für jedes Gerät die IP-Adresse anzeigt, unter der es aktuell erreichbar ist. Ein kleines Icon links daneben zeigt, ob die Verbindung über das lokale Netz (LAN-Symbol) oder über den VPN-Tunnel (Schloss-Symbol) läuft. Bei reinen VPN-Geräten (z.B. im Außendienst) wird die WireGuard-Adresse (10.10.10.x) angezeigt, bei LAN-Geräten die lokale IP — wechselt ein Gerät die Verbindung, aktualisiert sich die Spalte automatisch beim nächsten Heartbeat. Geräte ohne aktuelle Verbindung werden ausgegraut dargestellt. Hilfreich vor allem für die Diagnose und für SSH-Verbindungen direkt aus der Übersicht. Wirkt nach Frontend-Neubau.

- **VPN-Geräte werden zuverlässig als „online" markiert, auch wenn der reguläre Heartbeat fehlt** — Wenn ein Gerät ausschließlich über den VPN-Tunnel erreichbar war (also keinen regulären Heartbeat zum Server senden konnte), sollte ein Hintergrund-Abgleich alle 60 Sekunden den Online-Status automatisch nachziehen — anhand des frischen WireGuard-Handshakes. Tatsächlich brach dieser Abgleich beim Schreiben der VPN-IP in den Geräte-Datensatz mit einem Datenbank-Fehler ab, weil das Spaltenformat („Netzwerk-Adresse") und das übergebene Format („Text") nicht zusammenpassten und die Datenbank den Eintrag verwarf. Sichtbar war das u.a. so: VPN-only-Geräte blieben in der Übersicht auf „offline", obwohl der WireGuard-Tunnel nachweislich stand; in der gleichen Lauf-Runde nachfolgend zu prüfende Geräte wurden ebenfalls nicht mehr aktualisiert, weil der Fehler die Schleife abbrach. Mit der heutigen Backend-Anpassung wird der Wert explizit als Netzwerk-Adresse übergeben, der Schreibvorgang läuft sauber durch, der Online-Status wird korrekt gesetzt und der Abgleichs-Lauf zieht alle betroffenen Geräte in einem Durchgang nach. Wirkt nach dem Backend-Rebuild.

- **Signatur-Fehler bei Delta-Update wird im Update-Tab jetzt rot angezeigt** — Wenn ein Client beim Anwenden eines Delta-Updates meldet, dass die Signatur ungültig ist (Delta wurde nicht oder mit falschem Schlüssel signiert), markierte das Backend den Vorgang intern korrekt als endgültig fehlgeschlagen und schloss den Rollout sauber ab — die Übersicht im Update-Tab zeigte den betroffenen Client aber nur als graues Chip ohne Text, sodass der Operator den eigentlichen Fehler nicht direkt erkennen konnte. Mit der heutigen Frontend-Anpassung erscheint der Status nun in Rot mit dem Klartext „Signatur ungültig". Wirkt nach Frontend-Neubau.

- **Agent wendet Delta-Updates wieder an** — Der Client-Agent verweigerte das Herunterladen von Delta-Updates mit der Log-Meldung „agent-apply-delta.sh fehlt — kann Update nicht anwenden". Hintergrund: Die komplette Anwende-Logik für Delta-Updates wurde vor einigen Versionen aus dem alten Shell-Skript in das Agent-Programm selbst übernommen, und der ausführende Dienst beim Herunterfahren ruft das Agent-Programm direkt auf — das alte Shell-Skript wird gar nicht mehr ausgeliefert und sogar aktiv von bestehenden Clients gelöscht. Im Agent war aber noch eine alte Vorab-Prüfung stehengeblieben, die das nicht mehr existierende Skript suchte und beim Nicht-Finden den ganzen Download blockierte. Mit der heutigen Agent-Anpassung ist die Vorab-Prüfung entfernt; der Agent lädt das Delta jetzt herunter und das Anwenden beim Herunterfahren läuft wie vorgesehen direkt durch das Agent-Programm. Wirkt nach dem nächsten Agent-Update (Selbst-Update zieht die neue Version automatisch).

- **Lizenz-Limit wird jetzt verlässlich eingehalten, auch wenn alle Clients gleichzeitig anrufen** — Bei einer Lizenz für z.B. 3 Clients und 5 gleichzeitig erstmals meldenden Geräten konnte es bisher passieren, dass alle 5 Geräte fälschlich als Voll-Lizenz markiert wurden statt nur 3. Hintergrund: Die Zuteilung „bekommt dieser Client einen vollen Lizenz-Platz?" prüfte den aktuellen Stand und schrieb das Ergebnis in zwei nacheinander folgenden Datenbank-Schritten — wenn fünf Geräte das gleichzeitig taten, sahen alle fünf „noch keiner hat einen Platz, also kriege ich einen", und am Ende waren statt 3 Plätzen 5 vergeben. Mit der heutigen Backend-Anpassung läuft die Zuteilung jetzt unter einer kurzen exklusiven Sperre, sodass nur ein Gerät zur gleichen Zeit den Platz bekommen kann — Limit wird damit verlässlich eingehalten. Zusätzlich räumt das Backend ab sofort beim Start, beim Lizenz-Einspielen und beim Lizenz-Löschen die Tier-Verteilung einmal auf: zu viele Voll-Plätze werden auf Light heruntergestuft, wobei die jeweils ältesten (zuerst registrierten) Geräte ihren Voll-Status behalten. Damit ist auch der Lizenz-Downgrade abgedeckt — wer von einer 50er- auf eine 3er-Lizenz wechselt, sieht das Limit sofort, nicht erst nach 50 Heartbeats. Wirkt nach dem Backend-Rebuild.

- **Schwachstellen-Ausnahmenliste nach dem heutigen Sammel-Update aufgeräumt** — Im Anschluss an die Bibliotheks-Updates (siehe gleicher Tag, vorheriger Eintrag) wurde die kuratierte Liste der akzeptierten Schwachstellen aktualisiert: 24 Einträge sind komplett entfallen (die zugrundeliegenden Schwachstellen werden vom neuen Stand gar nicht mehr gefunden, vor allem viele Reste aus der vor Wochen abgeschlossenen Debian-zu-Alpine-Umstellung sowie alle Caddy-Go-Bibliotheks-Ausnahmen, die jetzt durch Caddy 2.11.3 / Go 1.26.3 erledigt sind), 12 Einträge sind zusammengeschrumpft (einzelne CVEs darin wurden gefixt, der Rest bleibt), und ein neuer Block ist hinzugekommen für 11 Schwachstellen-Fundstellen im Remote-Desktop-Container `guacamole/guacd:1.6.0` (Drittanbieter, basiert auf Alpine 3.18 EOL — siehe vorheriger Eintrag). Die Liste ist im Backend per Bind-Mount eingebunden — der Operator muss nur die aktualisierte Datei auf den Server bringen und das Backend neu starten, kein Image-Rebuild nötig.

- **Sammel-Update aller Container-Bibliotheken — viele bekannte Schwachstellen verschwinden auf einen Schlag** — Im Zuge des aktuellen Schwachstellen-Audits wurden drei Klassen von Aktualisierungen in einem Block ausgerollt: (a) die fertigen Drittanbieter-Container Reverse-Proxy (Caddy 2.11.2→2.11.3) und Datenbank (PostgreSQL 18.3→18.4) wurden auf die jeweils neueste Stable-Version gezogen — dadurch verschwinden 14 bisher als „akzeptierte Restschwäche" geführte CVEs aus dem Reverse-Proxy (Go-Standardbibliothek-Cluster, der bisher auf einen Caddy-Upstream-Rebuild wartete) sowie sechs neue PostgreSQL-CVEs, die mit dem 18.4-Patch direkt geschlossen sind; (b) die selbst gebauten Container-Images (Backend, Worker, NFS-Server, DNS-Server, Klon-Toolkette, Mehrfachverteilung, Zeitsynchronisation, VPN-Endpunkt) wurden alle vom Basis-Linux Alpine 3.22 auf Alpine 3.23 gehoben — bringt frische Bibliotheks-Stände für SQLite (drei Versionen aktueller, fixt eine Schwäche im NFS-Server), QEMU/OVMF (Klon-Toolkette, mehrere alte Befunde verschwinden), GLib und OpenSSL; und (c) die in Backend und Worker eingebaute Docker-Befehlszeile bekommt durch den Image-Neubau die aktuelle Version 29.5 mit der reparierten Go-Laufzeit — räumt elf bisher akzeptierte CVEs aus den Docker-Hilfsprogrammen auf. Insgesamt sinkt damit die Liste der manuell zu verfolgenden Schwachstellen-Ausnahmen deutlich. **Was nicht aufgeräumt werden konnte:** der Remote-Desktop-Container `guacamole/guacd` (Drittanbieter) hängt seit Juni 2025 ohne Upstream-Update auf einem alten Alpine 3.18 — die elf Befunde dort (libpng/tiff/cups-libs) bleiben bis Apache Guacamole ein neues Image released; betrifft aber nur den internen Container-Verbund, kein LAN-Zugang. Wirkt nach Backend-/Frontend-Rebuild + `docker compose pull` auf der Zielmaschine.

- **Schwachstellen-Bewertung erkennt Container mit „Hersteller/Name"-Image-Bezeichnung jetzt korrekt** — In der Sicherheits-Scan-Übersicht landeten alle 84 Befunde des Remote-Desktop-Containers `guacamole/guacd` in der Kategorie „Bedarf manueller Prüfung" — als hätte das System keine Erreichbarkeits-Information über diesen Container und müsse jeden Befund zur Sicherheit als „möglicherweise ausnutzbar" einstufen. Hintergrund: Die automatische Filterstufe, die jeden CVE gegen die Erreichbarkeit des Containers im Netzwerk abgleicht (interner Docker-Verbund vs. LAN-Listener), hat den Container-Namen aus der Bild-Bezeichnung herzuleiten versucht — bei den eigenen ThinForge-Images (`thinforge-backend` etc.) und bei reinen Einzelnamen (`postgres`, `caddy`) klappt das problemlos, bei der Form „Hersteller/Name:Version" (`guacamole/guacd:1.6.0`) lieferte die Heuristik aber `guacamole/guacd` statt `guacd` und fand keinen passenden Eintrag in der Container-Liste. Mit der heutigen Backend-Anpassung wird zusätzlich eine direkte Zuordnung aus den explizit deklarierten Container-Bildern der Compose-Datei aufgebaut und vorrangig befragt — die Heuristik bleibt nur noch Notnagel für selbst gebaute Images. Konkrete Folge des Fixes: die 84 guacd-Befunde fließen ab dem nächsten Scan wieder durch den normalen Erreichbarkeits-Filter; Befunde mit „Netzwerk-Vektor" werden korrekt als „nicht ausnutzbar" markiert (guacd ist nur intern über das Backend erreichbar, kein LAN-Listener), und zwei dadurch fälschlich rot-markierte Critical-Befunde (in den Bibliotheken glib und openjpeg) verschwinden aus der Warn-Liste. Wirkt nach dem Backend-Rebuild.

- **Sicherheits-Scan-Übersicht zeigt Container nicht mehr doppelt** — Im Sicherheits-Scan tauchten dieselben ThinForge-Container zweimal nebeneinander auf — einmal unter ihrem kurzen Namen (z.B. `thinforge-backend:latest`) und einmal unter dem vollständigen Registry-Pfad (`git.thinforge.org/thinforge/thinforge-backend:latest`). Hintergrund: Nach einem `docker compose pull` existieren auf dem System dieselben Container-Images unter beiden Namen (identische technische ID), und der Scan-Lauf hat beide Namen separat geprüft — die Ergebnisse waren also identisch, nur in der Übersicht doppelt aufgeführt. Mit der heutigen Backend-Anpassung wird vor dem Scan-Lauf nach interner Image-ID dedupliziert: jeder Container kommt nur noch einmal in den Report, der kürzere (lokale) Name gewinnt. Sicherheitsbewertung und Akzeptanz-Status bleiben identisch — nur die Übersicht wird halbiert und übersichtlicher. Wirkt nach dem Backend-Rebuild.

## 2026-05-17

- **Wiederherstellung großer Daten-Backups belastet die Festplatte nur noch einmal statt dreimal** — Beim Wiederherstellen eines mehrere Gigabyte (perspektivisch dreistellige GB) großen Daten-Backups lag die Datei während der Wiederherstellung kurzzeitig bis zu dreimal auf der Festplatte des Servers: einmal als Datei beim Hochladen, einmal als entpackter Zwischenstand, einmal an der finalen Position. Bei einem 50-GB-Backup mussten so zeitweise 150 GB frei sein. Mit der heutigen Backend-Anpassung wird das Archiv jetzt direkt während des Hochladens stückweise durch den Entpacker geschickt und die Inhalte landen unmittelbar an ihrer Zielposition (innerhalb eines Zwischenordners auf derselben Platte, der am Ende per Umbenennen instant aktiv geschaltet wird — atomar, kein zweites Kopieren). Speicherplatz-Bedarf für die Wiederherstellung sinkt damit von dreifacher auf einfache Backup-Größe, und die Wiederherstellung läuft sichtbar schneller, weil die zweite und dritte Daten-Kopie wegfallen. Wirkt nach dem Backend-Rebuild.

- **Daten-Backup-Wiederherstellung trägt die wiederhergestellten Deltas jetzt auch in die Übersicht ein** — Beim Einspielen eines Daten-Backups (mit Clones und Deltas) wurden die Delta-Dateien zwar korrekt auf die Festplatte zurückgeschrieben, in der Delta-Übersicht im Backend tauchten sie aber nicht auf — als wären keine Deltas im Backup gewesen. Hintergrund: Die Clone-Liste in der Oberfläche wird direkt aus dem Datei-Ordner gelesen, die Delta-Liste dagegen aus der Datenbank. Wenn man nur das Daten-Backup wiederherstellte (ohne dazu auch das System-Backup, oder wenn das System-Backup älter als die Delta-Erzeugung war), enthielt die Datenbank die zu den Delta-Dateien gehörenden Einträge nicht — die Dateien waren technisch da, aber für das System „unsichtbar". Mit der heutigen Backend-Anpassung scannt die Wiederherstellung am Ende den Delta-Ordner, liest die Beschreibungs-Dateien jedes Deltas und trägt fehlende Einträge nach. Bereits vorhandene Datenbank-Einträge werden nicht überschrieben (sichere Wiederholbarkeit). Damit ist das Daten-Backup auch ohne mitgespielten System-Backup eigenständig verwendbar. Wirkt nach dem Backend-Rebuild.

- **Maximale Backup-Dateigröße beim Wiederherstellen von 60 GB auf 120 GB angehoben** — Der Reverse-Proxy und das Backend erlauben jetzt Backup-Uploads bis 120 GB statt bisher 60 GB. Vorbereitung für Daten-Backups mit umfangreicheren Clone-Beständen.

- **Hochladen großer Backup-Dateien beim Wiederherstellen läuft jetzt durch, ohne dass das Backend mitten im Upload abbricht** — Beim Wiederherstellen eines mehrere Gigabyte großen Daten-Backups (auf der Test-Maschine reproduziert mit 7,2 GB Clones-Archiv) wurde der Upload nach gut anderthalb Minuten still abgebrochen — die Verwaltungs-Oberfläche zeigte nur „An Error occurred", weder der Reverse-Proxy noch das Backend hatten eine aussagekräftige Fehlermeldung im Log. Hintergrund: das Backend hat das hochgeladene Datei-Feld komplett im Arbeitsspeicher gesammelt, bevor es daraus eine Datei auf der Festplatte gemacht hat. Eine 7-GB-Datei in einer 8-GB-Maschine reicht aus, um die Verbindung still platzen zu lassen, und zusätzlich hat die zugrundeliegende Multipart-Bibliothek noch ein eigenes (kleineres) Größenlimit pro Feld, das den Upload auch ohne Speichermangel verworfen hat. Mit der heutigen Backend-Anpassung wird der Datei-Inhalt jetzt direkt während des Hochladens stückweise auf die Festplatte geschrieben — das Backend braucht nur Bruchteile davon kurz im Speicher und beide Größenlimits sind damit umgangen. Backups in zweistelliger Gigabyte-Größe lassen sich damit zuverlässig wiederherstellen. Wirkt nach dem Backend-Rebuild.

- **Backup-Wiederherstellung kann jetzt mehrere Dateien gleichzeitig annehmen und zeigt Fortschritt während des Uploads** — Der Wiederherstellungs-Bereich akzeptiert ab heute *eine oder zwei* Backup-Dateien in einem Schritt: typischerweise das System-Backup (klein, im Megabyte-Bereich) und das Daten-Backup mit Clones/Deltas (groß, mehrere bis zig Gigabyte) zusammen. Pro Datei erscheint sofort eine Karte mit dem Upload-Fortschritt — erst während der Validierung (der Server muss die ganze Datei lesen, um das Inhaltsverzeichnis zu prüfen), dann mit den Validierungs-Details und beim eigentlichen Wiederherstellen erneut mit Fortschritts-Balken. Die Reihenfolge der eigentlichen Wiederherstellung ist erzwungen: Daten zuerst, System danach, weil das System-Backup das Backend neu startet und ein laufender Daten-Upload dabei abreißen würde. Nach Auswahl beider Dateien also: einmal Bestätigen + Passwort eingeben + auf „Wiederherstellen" klicken, und das System fährt die ganze Sequenz selbständig durch. Zusätzlich wurde die Server-seitige Hochlade-Größengrenze von 10 MiB (Standard) auf 60 GB angehoben, damit Daten-Backups mit zweistelligen Gigabyte überhaupt durchkommen — bisher schlug der Upload schon vor dem ersten Byte mit „An Error occurred" fehl. Wirkt nach dem Backend- und Frontend-Rebuild.

- **VPN-Konfiguration ist nach einer Wiederherstellung wieder in der Oberfläche sichtbar** — Beim Einspielen eines System-Backups blieb der VPN-Einstellungs-Bereich der Oberfläche leer, obwohl die WireGuard-Tunnel-Datei selbst korrekt zurückgeschrieben wurde: der WireGuard-Container lief mit der richtigen Konfiguration, aber die Oberfläche zeigte keine Tunnel-Konfiguration, kein Sync-Intervall, keine geschützten Netze, keinen Firewall-Schalter mehr — als wäre nie etwas konfiguriert gewesen. Hintergrund: die zur Oberfläche gehörenden VPN-Einstellungen (alles, was unter „Einstellungen → VPN" sichtbar ist) leben in der ThinForge-Einstellungstabelle, und diese Tabelle ist absichtlich nicht Teil des System-Backups — sie enthält auch host-spezifische Werte wie die DHCP-Server-IP, die auf einer neuen Maschine nicht eingespielt werden dürfen. Die VPN-Einstellungen sind aber gerade nicht host-spezifisch, sondern Operator-Konfiguration, und gehören nach einer Wiederherstellung mitgenommen. Mit der heutigen Backend-Anpassung legt das System-Backup eine separate kleine Datei mit genau diesen VPN-Einstellungen ins Archiv und die Wiederherstellung schreibt sie auf der Zielbox wieder in die Einstellungstabelle zurück, bevor der WireGuard-Container startet — Tunnel-Konfiguration, Sync-Intervall, geschützte Netze und Firewall-Schalter sind danach in der Oberfläche wie auf der Ursprungsbox sichtbar. Wirkt nach dem Backend-Rebuild auf *beiden* Seiten (Ursprungsbox muss das neue Backup-Format schreiben, Zielbox muss es lesen können).

- **System-Backup-Wiederherstellung setzt private Schlüssel jetzt mit den korrekten Berechtigungen wieder zurück** — Beim Einspielen eines System-Backups landeten mehrere sensitive Schlüsseldateien (SSH-Provisioning-Privatekey, Minisign-Signing-Privatekey, Krypto-Salt, Heartbeat-Token) mit weltlesbaren Berechtigungen auf der Zielmaschine, weil die Wiederherstellung die Mode-Bits aus dem Archiv übernahm und der Archiv-Default „für jeden lesbar" ist. Konkrete Folge: SSH-Verbindungen vom Backend zu den verwalteten Clients (Terminal-Funktion, Remote-Desktop, Ansible-Playbooks, Klon-Provisioning) schlugen alle mit „Permissions for SSH key too open" fehl — wer einen Server umgezogen und das Backup eingespielt hatte, konnte seine Clients vom neuen Server aus nicht mehr per SSH erreichen. Mit der heutigen Backend-Anpassung erzwingt die Wiederherstellung für jede einzelne Datei in den Schlüsselverzeichnissen explizit den richtigen restriktiven Modus (nur für den Besitzer lesbar). Bei einem normalen Restore-Lauf ist alles damit out-of-the-box korrekt; auf bereits eingespielten Boxen genügt ein Restore-Wiederholungslauf oder ein einmaliger manueller chmod-Befehl. Wirkt nach dem Backend-Rebuild.

- **Backup merkt sich den DNS-Namen des Quell-Servers, Restore hängt ihn am neuen Server zusätzlich ein** — Beim Umzug eines ThinForge-Servers auf einen neuen Host (z.B. von „thinossrv.thinforge.org" auf „thinosrelease.thinforge.org") bekamen die bereits ausgerollten Clients ein Auflösungsproblem: ihr Agent ist mit dem ursprünglichen Server-Hostnamen konfiguriert, aber der DNS-Service des neuen Servers kannte diesen alten Namen nicht — die Clients konnten den Server schlicht nicht mehr erreichen und der Operator hätte auf jedem Client die Agent-Konfiguration anpassen müssen. Mit der heutigen Backend-Anpassung packt das System-Backup eine kleine Datei mit den selbst-referenzierenden Hostnamen der Quell-Box (also die Einträge, die der Server im eigenen DNS auf seine eigene Adresse zeigte: der kanonische Name „thinforge-server" plus alle TLS-Zertifikats-Namen). Beim Einspielen auf einer neuen Box werden diese Hostnamen *zusätzlich* zu den eigenen Einträgen des neuen Servers ins DNS aufgenommen — mit der neuen Server-IP. Damit löst der neue Server den alten Hostnamen genauso wie seinen eigenen auf, Bestands-Agents brauchen keine Anpassung. Existierende DNS-Einträge der neuen Box bleiben dabei unangetastet. Wirkt nach dem Backend-Rebuild auf *beiden* Seiten (Quell-Server muss das neue Backup-Format schreiben, Ziel-Server muss es lesen können).

- **Client-Anlage schreibt jetzt auch die PXE-Boot-Konfiguration** — Beim Anlegen eines neuen Clients (sowohl einzeln über den „Client anlegen"-Dialog im Clients-Tab als auch über den CSV-Import) wurde bisher nur die DHCP-Reservierung geschrieben — die per-Gerät Boot-Konfigurations-Dateien für PXE (also die Dateien, die der Client beim Netzwerk-Boot abruft, um zu entscheiden „Installation starten / von Festplatte booten") wurden dagegen *nicht* angelegt. Folge beim ersten Boot des Geräts: das DHCP funktionierte, der PXE-Chainloader lud, beim Versuch die per-Gerät-Konfiguration zu fetchen kam ein 404, der Chainloader brach ab — und das Gerät fiel ins BIOS/UEFI-Firmware-Menü zurück statt von der Festplatte zu starten. Sichtbar war das vor allem nach einem Backup-Restore, wenn alle Clients der wiederhergestellten Datenbank diese Lücke hatten. Ab heute schreibt sowohl die Einzel-Anlage als auch der CSV-Import die per-Gerät PXE-Konfiguration mit dem korrekten „von Festplatte booten"-Default direkt mit. Wirkt nach dem Backend-Rebuild.

- **System-Backup-Wiederherstellung räumt jetzt alte DHCP- und PXE-Reservierungen sauber auf und vergibt für jeden Client frische Werte** — Beim Einspielen eines System-Backups auf einem Server mit einer *anderen* Netzwerk-Topologie als der Ursprungs-Server blieben bisher zwei Klassen alter Werte unverändert stehen: die DHCP-Reservierungen in der Datenbank (alte IP-Adressen aus dem alten Netz) und die per-Gerät PXE-Konfigurations-Dateien auf der Festplatte (alte Server-IP/TFTP-Pfade). Folgen: der DHCP-Server verwarf jede Anfrage der wiederhergestellten Clients still als „ignored" (reservierte IP außerhalb des aktuell konfigurierten Netzes), und selbst nachdem das behoben war, fielen die Geräte beim PXE-Boot ins Firmware-Menü zurück, weil ihre Boot-Konfigurations-Dateien fehlten oder veraltet waren. Mit der heutigen Backend-Anpassung läuft am Ende der Wiederherstellung pro Client *derselbe* Provisionierungspfad wie bei der manuellen Client-Anlage: alte Reservierungen + PXE-Dateien werden weggeräumt, jeder Client bekommt eine frische IP aus dem aktuellen Netz zugewiesen, und die per-Gerät PXE-Konfiguration wird neu geschrieben — der Operator muss nichts nachklicken. Die Zuordnung MAC → IP bleibt also weiterhin sticky, nur eben jetzt im richtigen Netz und mit funktionierendem Boot. Zusätzlich: der DHCP-Bereich-Knopf **„Leases zurücksetzen"** räumt jetzt ebenfalls die alten Reservierungen mit auf (vorher wurde nur der flüchtige Lease-Speicher geleert, die alten Reservierungen blieben bestehen und derselbe Server-Stand kam sofort wieder zurück). Wirkt nach dem Backend-Rebuild.

- **„Schlüssel exportieren"-Knopf aus dem Backup-Tab entfernt** — Der separate ZIP-Export der Sicherheits-Schlüssel war ein Notfall-Werkzeug für die alte Backup-Architektur, in der das System-Backup nicht alle Schlüssel enthielt. Mit dem neuen v4.0-System-Backup (Encryption-Key, JWT-Signing-Key, Minisign, SSH-Hostkeys, WireGuard, TLS-Zertifikat, Lizenz alle drin) ist der separate Export redundant — entsprechend wurde die Kachel entfernt und der Backend-Endpoint abgeschaltet. Wirkt nach dem Frontend- und Backend-Rebuild.

- **Setup-Wizard-Abschluss ist jetzt idempotent — kein Lockout mehr nach abgebrochenem Vor-Versuch** — Wenn ein vorheriger Setup-Wizard-Durchlauf zwischen dem Anlegen des Admin-Benutzers und dem finalen Speichern abbrach (z.B. durch einen Netzwerk-Fehler oder einen Backend-Restart mitten im Prozess), schlug ein erneuter Wizard-Abschluss mit demselben Admin-Konto am Eindeutigkeits-Index der `users`-Tabelle fehl: „duplicate key value violates unique constraint". Der Operator musste die `users`-Tabelle manuell leeren, um neu beginnen zu können. Mit der heutigen Backend-Anpassung löscht der Wizard-Abschluss die Tabelle jetzt selbst, *bevor* der Admin-Benutzer angelegt wird — sicher, weil der Wizard ohnehin nur erreichbar ist, solange das System noch nicht eingerichtet ist (und alles in der Tabelle dann aus einem abgebrochenen Vor-Versuch stammt). Wirkt nach dem Backend-Rebuild.

- **System-Backup-Format neu (v4.0): nur portable Daten, keine host-bound Configs mehr** — Das System-Backup enthält ab heute nur noch das, was beim Umzug auf eine neue Server-Box wirklich Sinn ergibt: die kryptografischen Schlüssel (Encryption, JWT-Signing, Minisign, SSH-Hostkeys), die WireGuard-Tunnel-Konfiguration, das TLS-Zertifikat, die Lizenzdatei und eine bereinigte Datenbank-Tabellen-Liste (Clients, Benutzer, Gruppen, VPN-Bindungen, geplante Tasks, Images usw.). **Nicht** mehr drin: Caddy-Listener-Konfiguration, dnsmasq-Konfig, NFS/Chrony-Settings, die `settings`-Tabelle (inkl. `setup_completed`-Flag und Netzwerk-IPs des Quell-Servers). Damit verschwindet die ganze Klasse von Folge-Problemen, bei denen das Wiederherstellen einer Konfiguration vom alten Server den neuen Server lahmlegte (Caddy versuchte auf nicht-existente IPs zu binden, Setup-Wizard ließ sich nicht abschließen). **Konsequenz für den Operator:** auf einem neuen Server zuerst den Setup-Wizard normal durchlaufen (Netzwerk, TLS-Zertifikat, Admin-Account), dann einloggen und über **Einstellungen → Backup & Restore → Wiederherstellen** das v4.0-Backup einspielen. Im Setup-Wizard selbst gibt es keinen Restore-Schritt mehr. Alte v2.0/v3.0-Backups werden mit einer klaren Fehlermeldung abgewiesen — im Quell-System muss vor dem Umzug ein frisches v4.0-Backup erzeugt werden. Wirkt nach dem Backend- und Frontend-Rebuild.

- **Backend kann die Host-`.env` nicht mehr überschreiben (Sicherheit) und der Encryption-Key wandert in ein eigenes Backend-Volume** — Der Backend-Container hatte bisher Schreibrechte auf die `.env`-Datei auf dem Host-System, weil die Backup-Wiederherstellung den darin abgelegten Encryption-Key aktualisieren musste. Damit hätte ein kompromittierter Backend-Container auch die anderen darin liegenden Passwörter (Postgres, Grafana, Semaphore) verändern können, und der Versuch der Aktualisierung schlug außerdem auf vielen Linux-Konfigurationen mit „Resource busy" fehl. Mit der heutigen Backend- und Compose-Anpassung: der Encryption-Key lebt jetzt in einer separaten Datei innerhalb der ThinForge-Daten (`.encryption_key`), die der Container ohnehin schreiben darf; die Host-`.env` ist nur noch read-only in den Backend-Container eingehängt. Bestehende Systeme migrieren beim ersten Backend-Start automatisch (der alte ENV-Wert wird einmalig in die neue Datei übernommen). Wirkt nach dem Backend-Rebuild und einem Compose-Up — kein Operator-Eingriff nötig.

- **Setup-Wizard nach System-Backup-Restore lässt sich wieder bis zum Ende durchlaufen** — Beim Einspielen eines System-Backups im Setup-Wizard wurde aus dem Backup auch das Flag „Setup ist abgeschlossen" mit zurückgespielt. Folge: ab dem nächsten Wizard-Schritt (Netzwerk-Auswahl) lehnte das Backend alle weiteren Aktionen mit „Setup wurde bereits abgeschlossen" ab — gerade in dem Moment, in dem der Operator die Netzwerk-Werte für den neuen Server (andere IP, anderes Interface) anpassen will. Das Flag wird nach dem Restore jetzt explizit wieder zurückgesetzt und am Ende des Wizards regulär neu gesetzt; der Operator kann die Wizard-Schritte 2 bis 7 wie vorgesehen durchlaufen. Wirkt nach dem Backend-Rebuild.

- **Caddy verträgt jetzt IP-Wechsel durch Backup-Restore, ohne dass die Oberfläche unerreichbar wird** — Der Reverse-Proxy (Caddy) hat seine Listener-Adressen aus den aus dem Backup wiederhergestellten Werten generiert. Wenn der neue Server eine andere Netzwerk-Topologie hatte (z.B. die alte Client-Netz-IP existiert dort nicht), versuchte Caddy auf eine nicht-vorhandene IP zu binden, das schlug fehl, und weil der Bind atomar ist, war damit der gesamte Caddy unten — die Verwaltungsoberfläche war von außen nicht mehr erreichbar, Lock-out. Mit dem heutigen Backend-Rebuild prüft Caddy beim Generieren seiner Listener-Konfiguration jede IP gegen die tatsächlich auf dem Host gebundenen Adressen: nicht vorhandene Bindings werden mit einer Warnung im Log übersprungen, der Rest läuft normal weiter. Verwaltungs-IP fällt im Notfall auf „auf allen Interfaces lauschen" zurück, damit der Setup-Wizard im IP-Drift-Fall immer erreichbar bleibt. **Zusatz:** das Backend rendert die Caddy-Listener-Datei jetzt direkt nach dem Restore neu, *bevor* Caddy in der zweiten Restore-Phase neugestartet wird — sonst würde der Restore-Vorgang die frisch generierte Datei mit der aus dem Backup kopierten Variante (mit den IPs des Quell-Servers) überschreiben und Caddy beim folgenden Restart trotzdem in die alten falschen Binds rennen.

- **System-Backup-Wiederherstellung schlägt nicht mehr mit „Resource busy" auf der .env-Datei fehl** — Beim Einspielen eines System-Backups (sowohl im Setup-Wizard als auch im Backup & Restore-Tab) brach der Vorgang am Ende mit einem internen Fehler ab, sobald sich der Encryption-Key zwischen Backup und aktuellem Server unterschied. Hintergrund: der Backend-Container nutzt eine in den Container hineingeblendete Konfigurations-Datei (`.env`), die den Encryption-Key enthält. Beim Restore wurde die Datei nach dem alten Muster „Temp-Datei schreiben, dann an die Stelle der Original-Datei umbenennen" aktualisiert — Linux verbietet aber das Umbenennen über eine solche eingehängte Datei und meldet „Resource busy". Mit dem heutigen Backend-Rebuild schreibt das Backup-Service den neuen Inhalt jetzt direkt in die `.env` hinein, ohne Umbenennen. Der Restore läuft damit wieder bis zum Ende durch. Wirkt nach dem Backend-Rebuild.

- **Backup-Wiederherstellung im Setup-Wizard und im Backup-Tab nimmt die ausgewählte Datei wieder an** — Im Setup-Wizard bei „System-Backup einspielen" und im Backup & Restore-Tab beim „Wiederherstellen"-Bereich konnte man die Datei zwar auswählen, danach erschien aber keine Validierungs-Anzeige und kein Knopf zum tatsächlichen Einspielen — die Datei wurde intern verworfen und der Restore-Pfad blieb stumm. Ursache war eine Verhaltens-Änderung der zugrundeliegenden Frontend-Bibliothek bei Datei-Auswahl-Feldern, die zwei Stellen im Code noch nicht mit umgesetzt hatten. Mit dem heutigen Frontend-Rebuild greift in beiden Pfaden wieder die Validierung mit Anzeige von Version, Erstellungsdatum, enthaltenen Bereichen und Größe, und der „Wiederherstellen"-Knopf erscheint wie vorgesehen. Wirkt nach dem Frontend-Rebuild.

- **Setup-Wizard nach abgeschlossenem Setup leitet zur Backup-Wiederherstellung weiter** — Beim direkten Aufrufen der Setup-Wizard-Adresse (`/setup`) nach einem bereits abgeschlossenen Setup konnte man im Wizard zwar in den „System-Backup einspielen"-Bereich klicken und eine Datei auswählen, danach erschien aber kein Knopf zum tatsächlichen Importieren — das Backend lehnt in diesem Zustand alle Wizard-Aktionen ab, das Frontend zeigte das aber nicht klar an. Mit dem heutigen Frontend-Rebuild wird die Wizard-Seite in diesem Fall sofort aufs Dashboard umgeleitet und ein Hinweis eingeblendet: „Setup ist bereits abgeschlossen. System-Backups werden unter Einstellungen → Backup & Restore eingespielt." Dort liegt der reguläre Wiederherstellungs-Pfad mit Datei-Upload, Admin-Passwort-Bestätigung und Restore-Knopf, der für System- und Daten-Backups gleichermaßen funktioniert. Werkseinstellungen → Werkseinstellungen-Zurücksetzen bleibt unverändert: nach einem Factory-Reset landet man weiterhin korrekt im frischen Wizard.

- **Daten-Backup (Clones + Deltas) lässt sich wieder herunterladen** — Beim Versuch, ein Daten-Backup über den Download-Knopf im Backup-Tab herunterzuladen, drehte der Spinner ewig oder die Browser-Seite hing, ohne dass am Ende eine Datei beim Operator ankam. Hintergrund: das Frontend lud die komplette Archiv-Datei zunächst in den Tab-Speicher des Browsers, bevor sie als Datei gespeichert wurde — für System-Backups (im Hundert-Megabyte-Bereich) ging das, für Daten-Backups (mehrere bis zig Gigabyte) sprengte das die Tab-Speicher-Grenze des Browsers. Mit dem heutigen Frontend-Rebuild stößt der Download-Knopf jetzt direkt einen normalen Browser-Download an: der native „Speichern unter"-Dialog erscheint sofort und die Datei wird direkt auf die Platte geschrieben, ohne dass der Browser sie komplett im Speicher halten muss. Auch der Download von System-Backups läuft jetzt über denselben Pfad. Wirkt nach dem Frontend-Rebuild, kein Eingriff nötig.

- **BitTorrent-Cache räumt sich nach gelöschten Clones jetzt selbst auf** — Beim Löschen eines Clones wird der zugehörige BitTorrent-Slice-Cache (Verzeichnis `bittorrent/clone-*` unter den ThinForge-Daten) im Normalfall mit aufgeräumt. Bisher konnten in zwei Fällen Reste zurückbleiben: wenn das Backend zwischen den beiden Lösch-Schritten neu startete, oder wenn ein Clone nicht über die Oberfläche, sondern direkt auf dem Dateisystem entfernt wurde. Solche Reste sammelten sich über die Zeit unbemerkt an und konnten zweistellige Gigabytes belegen. Mit dem heutigen Backend-Rebuild greifen zwei Korrekturen: die Lösch-Reihenfolge wurde gedreht, sodass der Cache zuerst entfernt wird, und beim Backend-Start läuft einmalig ein Abgleich, der verwaiste Cache-Verzeichnisse erkennt und löscht. Auf dem Dev-System wurden dabei vier verwaiste Verzeichnisse mit zusammen ~20 GB entfernt. Wirkt nach dem Backend-Rebuild und -Neustart, kein Eingriff nötig.


## 2026-05-16

- **Agent v2.9.0: Remote-Sitzungs-Anzeige wird jetzt vom Agent selbst verwaltet** — Die kleine „● Remote-Sitzung aktiv"-Box am Client-Bildschirm wird ab Agent v2.9.0 vom Agent-Binary selbst angezeigt statt aus einem Shell-Skript heraus. Funktional ändert sich nichts (Position, Größe, Verschiebbarkeit, automatisches Verschwinden beim Sitzungsende — alles wie gewohnt). Hintergrund: kleine Verbesserungen am Indikator (z. B. Aussehen, Sprache, Tastenkürzel) lassen sich jetzt per normalem Agent-Selbst-Update auf alle Clients ausrollen, statt jeden Client erneut zu provisionieren. Wirkt automatisch nach dem nächsten Selbst-Update der Agents.

- **Cloning-VM-Start funktioniert wieder (Hotfix zur Dienste-Panel-Umsortierung von heute)** — Nach dem heutigen Refactor, bei dem Caddy, thinVPN und Guacamole im Dienste-Panel in die Gruppe „Netzwerk" gewandert sind, konnte die Cloning-VM nicht mehr gestartet werden — der Versuch endete im Backend-Log mit „invalid compose project". Ursache war eine Validierungsregel in Docker Compose 2.x, die in der ursprünglichen Änderung von heute übersehen wurde. Behoben durch eine kleine Backend-Anpassung; nach dem Backend-Rebuild lassen sich Cloning-VM-Start, -Stop und das Bauen des Cloner-Images wieder normal anstoßen.

- **Remote Desktop: Sitzungs-Anzeige am Client wird jetzt verlässlich angezeigt** — Beim Verbinden per Remote Desktop auf einen Thin-Client erschien am Client-Bildschirm bisher oft gar keine Meldung, dass eine Fernsitzung läuft — die bisherige System-Benachrichtigung war je nach Desktop-Konfiguration nur für wenige Sekunden sichtbar oder erschien gar nicht. Stattdessen erscheint jetzt eine kleine Box oben rechts mit dem Text „● Remote-Sitzung aktiv", die für die gesamte Sitzungsdauer sichtbar bleibt, vom Benutzer per Maus an die gewünschte Stelle verschoben werden kann und beim Sitzungsende automatisch verschwindet. Damit ist die Anforderung an die Sichtbarkeit für Beschäftigte am Client wieder erfüllt. Wirkt nach einem Image-Rebuild auf neu provisionierten Clients; bestehende Clients müssen `provision-remote-desktop.sh` einmal erneut ausführen.

- **Dienste-Panel: Caddy, thinVPN und Guacamole sortieren sich jetzt unter „Netzwerk"** — Im Einstellungen → Dienste-Panel werden die drei Container `Caddy (Proxy)`, `thinVPN` und `Guacd (Remote-Desktop)` jetzt in der Sektion „Netzwerk" angezeigt, gemeinsam mit dnsmasq und NFS — vorher standen sie zwischen den Datenbank- und App-Services. Reine Anzeige-Sortierung, am Laufzeitverhalten ändert sich nichts. Nach einem Backend-Neustart ist die neue Gruppierung sichtbar.

- **Dienste-Panel: Guacamole-Karte zeigt jetzt korrekten Status** — Im Dienste-Panel wurde der Guacamole-Container fälschlich als „nicht gefunden" mit grauem Rand und generischem Docker-Icon angezeigt, obwohl er normal lief. Ursache war ein interner Namensabgleich; jetzt erscheint die Karte korrekt als „Guacd (Remote-Desktop)" mit Status, Uptime und Bedienknöpfen. Nach einem Backend-Neustart ist die Anzeige korrekt — kein Image-Rebuild nötig.

- **Agent v2.8.1: Folge-Fix zum Self-Heal-Mechanismus** — Hotfix nach Live-Test des zuvor ausgerollten Self-Heal-Mechanismus (siehe Eintrag „VPN-Self-Heal" weiter unten): bei einem automatischen TPM-Reset wurde versehentlich die frisch ausgespielte Tunnel-Konfiguration gelöscht, der Agent landete dadurch in einer Endlos-Retry-Schleife. Mit v2.8.1 läuft der Self-Heal-Zyklus sauber durch.

  Verhalten: Clients mit v2.8.0 werden vom Backend ohne dauerhaften Schaden so lange retried, bis sie per Selbst-Update auf v2.8.1 gehoben sind. Manuelles Eingreifen ist nicht nötig.

- **VPN-Self-Heal: Tunnel reparieren sich automatisch nach Schlüssel-Drift** — Der Server kann einem Client jetzt per Heartbeat sagen, dass er den TPM-versiegelten VPN-Schlüssel verwerfen und sich neu enrollen soll. Damit lösen sich zwei real beobachtete Probleme von selbst:

  - Ein Client, der deaktiviert und wieder aktiviert wurde, behielt vorher den alten Schlüssel im TPM und blieb tunnel-tot. Jetzt zieht der Server das alte Material sauber zurück und der Tunnel kommt nach dem nächsten Heartbeat wieder.
  - Wenn nach interner Server-Wartung Server- und Client-Schlüssel auseinanderlaufen (sogenannter Drift), erkennt der Server das beim nächsten Heartbeat und triggert die Reparatur automatisch. Die Ausfallzeit ist auf das Heartbeat-Intervall (Default 60 Sekunden) begrenzt.

  Operator-Sicht: Activate-, Deactivate- und Regenerate-Knöpfe im VPN-Tab nutzen denselben Kanal. Manuelles Reset-Skript auf dem Client ist nur noch Notfall-Werkzeug. Voraussetzung ist Agent v2.8.0 oder neuer auf den Clients (siehe Eintrag oben).


## 2026-05-15

- **Agent v2.7.2: VPN-Selbstheilung wirkt jetzt auf mehr Linux-Varianten** — Zwei Kleinigkeiten am VPN-Subsystem des Agents:
  - Der TPM-Tunnel funktioniert jetzt auch auf neueren Distributionen mit anderen Programm-Pfaden (Ubuntu 24.04+, Arch mit `/usr`-Merge) — vorher konnte der Tunnel auf solchen Clients nicht starten.
  - Stehengebliebene Tunnel-Konfigurationen im System werden beim Agent-Start jetzt zuverlässig aufgeräumt; ein bisher seltener Drift-Zustand nach Enrollment ist damit behoben.

  Wirkt automatisch beim nächsten Selbst-Update der Clients, kein Eingriff nötig.

- **Agent: VPN-Routen-Updates kommen auf TPM-Clients zuverlässig an** — Auf Clients mit TPM-versiegeltem VPN-Schlüssel wurden Änderungen der „gerouteten Netze" im VPN-Tab vom Agent in die falsche Konfigurationsdatei geschrieben — die Änderungen landeten am laufenden Tunnel nicht. Außerdem konnte ein Neustart des Tunnels in einer Restart-Schleife hängenbleiben, wenn das Interface aus einem vorherigen Lauf liegengeblieben war.

  Beide Probleme sind behoben: der Agent erkennt jetzt sicher, welche Konfiguration aktiv ist, räumt liegengebliebene Interfaces zuverlässig ab, und repariert beim Start typische Drift-Zustände automatisch. Für Clients, die im stuck-Restart hängen, gibt es als Notfall-Recovery: `sudo ip link del thinvpn 2>/dev/null; sudo systemctl start wg-quick@thinvpn`.

  Rollout: neuer Agent läuft 24 h auf einem Test-Client, dann breit per Selbst-Update.

- **VPN: Fehler beim Synchronisieren der Routen werden sichtbar** — Wenn beim Speichern der VPN-Einstellungen die Routen-Liste an die VPS-API geschickt wird und der VPS gerade nicht erreichbar ist, wurde das früher nur im Log vermerkt — die lokal gespeicherten Werte und der Stand auf dem VPS liefen unbemerkt auseinander. Jetzt erscheint stattdessen ein gelber Warn-Hinweis: „Netzwerk-Routen lokal gespeichert, aber VPS-Sync fehlgeschlagen". Ein erneutes Speichern oder ein Klick auf „VPS Sync" im Netzwerke-Tab holt das nach.

  Außerdem: Der „VPS Sync"-Button war dauerhaft ausgegraut, wenn der VPS beim Seitenaufruf nicht erreichbar war. Jetzt erscheint stattdessen ein roter Alert mit Refresh-Button, sodass man den Status ohne Seitenwechsel neu prüfen kann.

- **Remote Desktop: Guacamole auf Version 1.6.0 angehoben** — Der Guacamole-Daemon, der die Remote-Desktop-Sitzungen vermittelt, läuft jetzt in Version 1.6.0 statt 1.5.5. Die Browser-Seite bleibt kompatibel, es ändert sich nichts an der Bedienung. Bei Installationen ohne Internetzugang muss das neue Image einmal mit Internet bezogen werden (`docker pull guacamole/guacd:1.6.0`) bzw. manuell auf den Server kopiert werden.

- **System-Backup: TLS-Zertifikate werden jetzt vollständig mitgesichert** — Das System-Backup hat Konfigurationsverzeichnisse bisher nicht rekursiv eingepackt — Unterordner fehlten im Archiv. Dadurch waren nach einem Restore z.B. die TLS-Zertifikate des Reverse-Proxys nicht enthalten und mussten neu ausgestellt werden, explizit hinterlegte Server-Zertifikate wären verloren gegangen. Jetzt steigt das Backup rekursiv in Unterordner ab, das Restore zieht ebenfalls rekursiv.

  **Achtung:** System-Backups, die vor diesem Update erstellt wurden, enthalten die Zertifikats-Unterordner nicht. Wer sich auf ein älteres Backup verlassen muss, sollte direkt nach diesem Update ein frisches Backup ziehen.

- **Sicherheits-Scan-Panel: überflüssiger Hinweistext entfernt** — Im Vulnerability-Scan-Panel stand unter den Schweregrad-Chips ein technischer Hinweis auf das interne Skript und den Rebuild-Trigger. Wurde im Betrieb nicht gebraucht und ist jetzt entfernt — das Panel wirkt aufgeräumter.

- **Updates-Tab: Fortschrittsbalken für Merge-Vorgänge wieder lesbar** — Beim Erstellen eines Merged-Deltas zeigte die Status-Spalte einen Fortschrittsbalken mit eingeschriebenem Text. Bei langen Bezeichnungen wurde der Text auf zwei Zeilen umgebrochen und oben/unten abgeschnitten — der Status war praktisch unlesbar. Layout korrigiert: der Balken passt sich jetzt dynamisch der Spaltenbreite an, der Text bleibt in einer Zeile und wird bei Bedarf mit „…" abgekürzt.

- **Reboot-Aufforderung auf Clients: „Jetzt neustarten"-Button erscheint** — Wenn der Agent dem angemeldeten Nutzer eines Clients einen Reboot ankündigt, fehlte im Standard-Dialog der „Jetzt neustarten"-Button — nur „Abbrechen" war sichtbar. Ursache war ein Verhaltensunterschied zwischen den zwei Dialog-Werkzeugen, die ThinForge nutzt; auf bestehenden Clients lief immer der eingeschränkte Pfad.

  Jetzt: Beide Schaltflächen sind im Standard-Dialog sichtbar (statischer Text „in 15 Minuten"). Auf neu installierten Clients wird zusätzlich das komfortablere Werkzeug mit Live-Countdown vorinstalliert. Bestehende Clients bekommen das korrigierte Skript automatisch per Heartbeat-Sync — kein Agent-Rebuild nötig.


## 2026-05-14

- **Remote Desktop neu auf Apache-Guacamole-Basis** — Die Remote-Desktop-Funktion (Admin verbindet sich live auf den Bildschirm eines Clients) war seit Anfang Mai deaktiviert und wurde jetzt grundsätzlich neu aufgesetzt — auf Basis von Apache Guacamole, einem etablierten Open-Source-Stack für Remote-Sitzungen im Browser. Der bisherige eigenständige Stream-Mechanismus ist abgelöst.

  Was sich für den Betrieb ändert:
  - Drei Qualitäts-Voreinstellungen (DSL / VDSL / LAN) stehen in den System-Settings zur Auswahl, im Sitzungs-Dialog auch live umschaltbar.
  - Der angemeldete Nutzer am Client sieht ein Tray-Icon mit Hinweis, dass eine Fernsteuerungs-Sitzung läuft.
  - Zwei Admins können gleichzeitig zuschauen (Multi-Viewer).
  - Wayland-Sitzungen werden noch nicht unterstützt und mit einer klaren Fehlermeldung abgelehnt (kommt in einer späteren Ausbaustufe).

  Voraussetzungen:
  - **Ohne Internetzugang:** Das Guacamole-Image muss einmalig mit Internet bezogen werden (`docker pull guacamole/guacd:1.5.5`) oder per Datei auf den Server kommen — es kommt vom Docker Hub, nicht aus der internen Registry.
  - **Bestehende Clients** müssen einmal neu provisioniert werden, damit die nötigen Werkzeuge für die neue Sitzungs-Mechanik installiert sind. Ohne Re-Provisioning zeigt das System eine deutliche Fehlermeldung an. Alte Pakete der bisherigen Lösung dürfen liegenbleiben — sie werden nicht mehr aufgerufen.


## 2026-05-13

- **Klon-Import: Fehler „Linienname bereits vergeben" auf sauberen Systemen behoben** — Beim Importieren eines Klons schlug jeder Versuch mit der Meldung „Linienname bereits vergeben" fehl — selbst auf einem System ohne andere Klone und mit leerer Datenbank. Das System verglich sich versehentlich mit seinem eigenen, temporären Arbeitsverzeichnis und meldete dort eine Namens-Kollision. Behoben — der Import läuft wieder durch.


## 2026-05-12

- **Datenbank: Migrationen wieder zu einer Datei zusammengeführt** — Zwei kürzlich eingeführte Datenbank-Migrationen wurden in die Ausgangs-Migration eingearbeitet, das Migrations-Verzeichnis enthält wieder eine einzige Datei. Fresh-Installationen laufen damit in einer einzigen Datenbank-Transaktion durch und können dabei nicht in einen halb-migrierten Zustand geraten.

  **Achtung bei laufenden Installationen mit der alten Migrationsreihe:** Das Backend wird beim nächsten Start die Migrations-Prüfung mit einem Mismatch ablehnen. Recovery erfordert manuellen Eingriff am `_sqlx_migrations`-Eintrag in der Datenbank oder ein Wipe (Dev-Setups). Bei betroffener Installation vorher Bescheid geben, damit wir die Umstellung gemeinsam durchführen.

- **Agent: TLS-Verbindung repariert sich nach Zertifikatsfehlern in einer Runde** — Wenn auf einem Client die TLS-Verifikation zum Server scheiterte, blieb der intern zwischengespeicherte Zertifikats-Pool unter bestimmten Bedingungen veraltet und der Agent landete in einer Endlos-Schleife bis zum manuellen Neustart. Der Agent verwirft jetzt den zwischengespeicherten Pool unbedingt nach jeder Recovery-Runde — der nächste Heartbeat baut den Pool aus der aktuellen Zertifikatsdatei neu auf.

- **Signing-Schlüssel-Rotation: korrekt formatierter Pubkey wird signiert** — Nach einer Rotation des Signing-Schlüssels lehnten die Clients den neuen Schlüssel als „signature INVALID" ab, obwohl alles formal korrekt war. Ursache war eine unsichtbare Differenz im Zeilenende der signierten Schlüsseldatei (überflüssiger Zeilenumbruch am Ende). Das Generierungs- und das Rotationsskript normalisieren die Datei jetzt vor dem Signieren — neue Rotationen werden von den Clients sauber akzeptiert.

- **Signing-Schlüssel-Rotation: bestehende Deltas werden direkt mit-signiert** — Bisher signierte die Rotation des Signing-Schlüssels nur das Agent-Binary und die Sidecar-Caches direkt mit; die bereits vorhandenen Update-Deltas blieben mit dem alten Schlüssel signiert und wurden von den Agents nach der Rotation als ungültig verworfen — Updates kamen nicht mehr durch. Die Rotation signiert ab jetzt automatisch alle vorhandenen Deltas mit dem neuen Schlüssel nach. Bei sehr großen Delta-Beständen kann das einige Sekunden bis Minuten dauern; das Ergebnis enthält die Anzahl der nachsignierten Deltas.

- **TLS-Zertifikat-Rotation: Reverse-Proxy wird zuverlässig neu geladen** — Nach dem Erzeugen oder Hochladen eines neuen Server-TLS-Zertifikats wurde Caddy nur „reloaded" — weil sich die Konfigurationsdatei selbst nicht ändert (Pfade bleiben gleich), las Caddy das neue Zertifikat aber nicht von der Festplatte. Folge: Der HTTPS-Endpoint antwortete noch mit dem alten Zertifikat, während die Agents bereits umgeswitcht hatten. Die Rotation startet den Caddy-Container jetzt sauber neu, damit das neue Zertifikat sofort wirksam ist.


## 2026-05-11

- **SSH-Schlüssel-Rotation läuft jetzt live über die Clients** — Das Rotieren des SSH-Schlüssels, mit dem das System die Clients verwaltet, war bisher ein erheblicher Eingriff: Master-Image neu bauen, alle Clients neu provisionieren. Jetzt wird der neue Schlüssel beim nächsten Heartbeat (Standard alle 60 s) signiert an alle Online-Clients ausgespielt — die Rotation läuft im laufenden Betrieb durch, ohne Eingriff am einzelnen Client.

  Sicherheits-Begleitfix: Ein latenter, ungenutzter Codepfad im Agent, der einen vom Server gelieferten SSH-Pubkey ohne Prüfung übernommen hätte, ist hart entfernt — auch wenn er aktuell nicht aufgerufen wurde.

  Außerdem: Nach einer Rotation des Signing-Schlüssels wurde der zwischengespeicherte Zertifikats-Begleiteintrag nicht erneuert, sodass jeder Agent, der den neuen Signing-Schlüssel zog, alle Zertifikats-Updates ablehnte und manuell repariert werden musste. Das ist jetzt automatisch aufgeräumt.


## 2026-05-10

- **Update-Ketten: zusammengeführte Deltas werden korrekt der richtigen Linie zugeordnet** — Wenn das System automatisch ein zusammengeführtes Delta (z.B. v001→v003 statt v001→v002→v003) erzeugt, wurde dieses fälschlich unter „Ohne Linie" angezeigt statt unter dem Image-Namen (z.B. Manjaro). Fix: Das zusammengeführte Delta erbt die Zuordnung jetzt vom Ausgangs-Delta. Bestehende Einträge wurden per einmaligem Datenbank-Update nachgezogen.

- **Cloning-Bereich: interne Aufräumarbeiten** — Strukturelle Bereinigung in den Cloning-Tabs (VM erstellen / Captures / Klone / Deployments / Updates / Rollback). Gemeinsame Logik wurde an zentrale Stellen verschoben, Anzeige-Formate vereinheitlicht. Keine sichtbare Änderung an der Bedienung, keine neuen Funktionen, kein Handlungsbedarf. Lediglich kosmetisch fällt auf, dass Größenangaben in Gigabyte jetzt mit zwei Nachkommastellen statt einer angezeigt werden.

- **Defekt-Markierung für Update-Versionen wirkt jetzt zuverlässig** — Versionen, die nur als Update (Delta) existieren — also keine eigene Baseline — wurden bei der „als defekt markieren"-Funktion nicht überall korrekt erfasst:
  - Im Update-Zuweisungs-Dialog ließen sie sich noch als Ziel auswählen.
  - Ein Rollout über eine defekte Zwischenversion hat das automatische Zusammenführen (Skipping) nicht erzwungen.

  Beide Probleme sind behoben — defekte Update-Versionen werden jetzt im Assignment-Dialog ausgeblendet, und Roll-outs über sie hinweg führen die nötigen Deltas automatisch zusammen. Die Datenbank-Schema-Erweiterung läuft beim nächsten Backend-Start automatisch durch.

- **Rollback / Defekt-Markierung: Folgekorrekturen aus Lab-Test** — Beim ersten Live-Test der „defekte Version markieren"-Funktion in einem Gruppen-Rollback fielen vier Probleme auf, alle behoben:

  - Der Rollback-Endpoint warf einen 500-Fehler durch einen falschen Datenbank-Spaltennamen.
  - Es wurde versehentlich die **Rollback-Ziel-Version** als defekt markiert (statt der Version, von der weggerollt wird). Auf einem Test-Client wurde dadurch der benötigte Snapshot gelöscht, der Rollback brach mit „Nicht genug Snapshots" ab. Jetzt wird korrekt die aktuell installierte Version markiert.
  - Ein Rollback nur für eine Gruppe wirkte auf Clients aller Gruppen. Jetzt strikt auf die ausgewählten Clients begrenzt.
  - Die Defekt-Markierung floss nur in die Datenbank, nicht in die Klon-Metadaten auf der Festplatte — der Klone-Tab zeigte den Klon noch als regulär. Jetzt werden beide Stellen synchron aktualisiert.

- **Update-Klone: Linien-Name wird zuverlässig vererbt** — Ein neu erzeugter Update-Klon (z.B. v003) wurde im Klone-Tab fälschlich als „Basis" angezeigt, obwohl er korrekt unter der zugehörigen Linie (z.B. Manjaro) eingeordnet war — sein interner Linien-Name lautete generisch „Update v…". Jetzt wird der Name des Linien-Wurzelklons sauber bis zum jüngsten Update vererbt; doppelte Absicherung im Hintergrund.

- **Klon löschen räumt zugehörige Markierungen mit auf** — Beim Löschen eines als defekt markierten Klons und sofortigem Neu-Anlegen mit gleicher Version blieb die Defekt-Markierung in der Datenbank hängen — der neue Klon erbte sie fälschlich. Außerdem konnten geplante Snapshot-Löschungen für die Version weiter ausgeliefert werden und bei einem späteren Neuaufbau einen Snapshot löschen, der gar nicht mehr „obsolet" war. Beide Aufräumarbeiten laufen jetzt mit beim Klon-Löschen.

- **Updates-Tab: Deltas nach Linien gruppiert** — Update-Kette und zusammengeführte Deltas waren bisher in einer flachen Liste, der Linien-Name stand nur als kleiner Chip. Bei mehreren parallelen Linien (z.B. Manjaro + Debian) war schwer erkennbar, welches Delta zu welcher Linie gehört. Jetzt: Eine Überschrift pro Linie, darunter die zugehörigen Deltas; legacy-Einträge ohne Linien-Namen landen unter „Ohne Linie" am Ende.

- **Agent: Bestätigungen gehen bei Heartbeat-Ausfall nicht mehr verloren** — Wenn der Heartbeat eines Clients fehlschlug, wurden bereits erledigte Bestätigungen (z.B. „diesen Snapshot habe ich gelöscht") trotzdem aus dem Puffer entfernt — das funktionierte bisher nur „aus Versehen", weil die Operationen mehrfach laufen können. Jetzt sauber: Puffer wird erst nach erfolgreichem Heartbeat geleert, sonst werden die Bestätigungen im nächsten Versuch erneut mitgeschickt.

- **Neue Funktion: Defekte Versionen beim Rollback sauber rausnehmen** — Wer eine defekte Version per Rollback rausnimmt, kann jetzt im Rollback-Dialog die Checkbox „Version als defekt markieren" anhaken (Default an). Wenn aktiv:

  - Die Version wird systemweit als defekt markiert und verschwindet aus der Versions-Auswahl für neue Rollouts.
  - Laufende oder geplante Rollouts mit dieser Version als Ziel werden abgebrochen, laufende Downloads gestoppt.
  - Pro Client wird der zugehörige Snapshot der defekten Version nach erfolgreichem Rollback automatisch gelöscht. Clients, die gerade noch auf der defekten Version laufen, werden geschont (sonst würde sich das laufende System wegnehmen).
  - In der Deltas-Liste erscheint die Version mit einem roten „Defekt"-Badge.
  - Wenn ein neuer Rollout-Pfad eine defekte Zwischenversion überspringen müsste, erzwingt das System automatisch das Zusammenführen der Deltas.

  Damit ist ein sauberer „Version raus, alle Spuren weg"-Pfad da, der vorher von Hand auf jeder einzelnen Maschine erledigt werden musste.

- **Backend: Absturz nach Rollout-Abbruch behoben („An error occurred")** — Beim Klick auf „Abbrechen" während eines laufenden Rollouts erschien im UI gelegentlich ein generischer Toast „An error occurred" — gleichzeitig stürzte intern ein Backend-Worker-Thread ab, andere parallele API-Aufrufe brachen ab. Ursache war eine Race-Condition im Datenstrom des Delta-Downloads und im Live-Fortschritt der Delta-Zusammenführung. Beide Datenströme sind jetzt robust gegen Doppel-Polling — Abbrechen funktioniert sauber, parallele Anfragen laufen weiter.


## 2026-05-09

- **Rollout abbrechen stoppt jetzt auch den laufenden Download am Client** — „Abbrechen" auf einem Rollout setzte zwar den Status im Backend, aber der Agent lud den Delta-Block trotzdem bis zum letzten Byte herunter. Die Übertragung lässt sich jetzt direkt im laufenden Stream stoppen — der Klick wirkt innerhalb von Sekundenbruchteilen, der Agent erkennt den Abbruch sauber und probiert ihn nicht erneut.

  Zusätzlich: Der „Löschen"-Button für eine Zuweisung ist gesperrt, solange mindestens ein Client gerade lädt. Tooltip: „Löschen nicht möglich — mindestens ein Client lädt gerade. Erst die Zuweisung abbrechen."

- **Updates-Tab: alle Client-Aktionen direkt in der Zuweisungs-Zeile** — Im Updates-Tab gab es zwei sich überschneidende Bereiche: die „Zuweisungen"-Tabelle (mit ausklappbaren Client-Listen) und eine separate „Client-Status"-Sektion. Die zweite filterte bereits bestätigte Clients heraus, sodass z.B. „alle markierten Clients neustarten" für die Hauptzielgruppe nicht funktionierte.

  Die separate Sektion ist entfernt. Stattdessen findet alles in der ausgeklappten Zuweisungs-Zeile statt — sortierbare Spalten, Auswahl-Checkboxen, Download-Fortschritt mit Prozent / Mbit/s / Bytes pro Client. Eine Aktionsleiste „Neustarten / Herunterfahren" erscheint, sobald in einer ausgeklappten Zuweisung mindestens ein Client markiert ist, und wirkt zuweisungs-übergreifend.

- **Image-Linien: Doppelte Namen werden früh abgefangen** — Bisher konnten zwei verschiedene Image-Linien denselben Namen tragen, was im Hintergrund Versions-Kollisionen verursachen konnte. Beim Speichern eines neuen Updates und beim Klon-Import wird der Name jetzt vorher gegen alle bestehenden Linien geprüft (Groß-/Kleinschreibung egal, führende/schließende Leerzeichen werden weggekürzt). Bei einer Kollision bleibt der Dialog offen, ein roter Hinweis zeigt die kollidierende Linie an, man kann einen anderen Namen wählen.

  Beim Import gibt es zusätzlich ein Feld „Umbenennen", um den im Archiv enthaltenen Namen direkt zu überschreiben. Bestehende Duplikate (z.B. „Manjaro × 2") bleiben unangetastet — sie behindern weitere Arbeit nicht, müssen aber bei Bedarf manuell aufgelöst werden.

- **Update speichern: sichtbarer Fortschritt in zwei klar benannten Schritten** — Beim „Update-Delta speichern & Klon erstellen" hing der Dialog vorher minutenlang ohne erkennbares Feedback, bis das Backend fertig war. Ablauf jetzt:

  1. Klick auf „Speichern": Dialog zeigt einen Spinner und „Layout der Cloning-VM wird geprüft…" (10–15 s).
  2. Sobald die Vorabprüfung durch ist, schließt der Dialog automatisch und im Tab „VM erstellen" erscheint ein Fortschrittsbalken mit klar benannten Phasen — „Schritt 1/2: Delta wird erstellt" und anschließend „Schritt 2/2: VM-Klon wird erstellt".

  Während Schritt 1 ist „Abbrechen" deaktiviert (eine laufende Delta-Erzeugung kann nicht sauber unterbrochen werden), in Schritt 2 verfügbar.

- **Klon-Löschung räumt nur noch das eigene Linien-Delta** — Beim Löschen eines Klons konnte unter bestimmten Umständen versehentlich auch ein Delta einer **anderen** Image-Linie weggeräumt werden, wenn beide am selben Tag dieselbe Versionsnummer trugen (z.B. „Manjaro v2026.05.09-001" und „ManjaroTEST v2026.05.09-001"). Jetzt ist die Linien-Zuordnung des Klons der maßgebliche Identifikator — fremde Deltas werden nicht mehr mit-gelöscht.

  **Hinweis:** Bereits gelöschte Deltas können byte-genau nicht rekonstruiert werden. Wer betroffen war, kann den zugehörigen Klon wiederherstellen und ein neues Update auf den nächsten Snapshot als Baseline-Marker erzeugen.


## 2026-05-08

- **Update-Deltas: Folge-Korrekturen rund um die neue Versions-Logik** — Nach Einführung der Datumsversionen (siehe 2026-05-07) fielen zwei Folgefehler auf, beide behoben:
  - Ein per Delta erzeugter Klon landete im Katalog mit einer abwegigen Versionsnummer (z.B. „2027.0") und tauchte beim Löschen des Klons nicht in der Bestätigungsliste auf — er blieb als Waise zurück. Die Versions-Erkennung greift jetzt sauber.
  - Die Deltas-Liste im Updates-Tab zeigt jetzt den Image-Linien-Namen (z.B. „Manjaro") fett vor dem Versions-Pfeil, sodass bei mehreren parallelen Linien sofort sichtbar ist, welches Delta zu welcher Linie gehört.

- **VPN-Tab vorne in der Netzwerk-Sektion, Auto-Refresh, NTP-Server zuverlässiger gefunden** — Mehrere kleine Verbesserungen, vor allem rund um VPN und Client-Provisionierung:

  - Im Netzwerk-Bereich steht der VPN-Tab jetzt an erster Stelle.
  - Der VPN-Tab aktualisiert sich automatisch alle 10 Sekunden: TPM-Enrollment-Hinweise verschwinden ohne Klick, Handshake und Traffic-Werte sind ohne manuelles Aktualisieren aktuell.
  - Der „Remote Desktop öffnen"-Button im Client-Detail ist temporär ausgeblendet (Funktion zu diesem Zeitpunkt überarbeitet, siehe spätere Einträge).
  - Neue Clients bekommen die Remote-Desktop-Abhängigkeiten nicht mehr automatisch beim Setup installiert (kommen je nach Bedarf später dazu).
  - Bei der Client-Installation wird der NTP-Server jetzt zuverlässig vom ThinForge-Server bezogen (kommt mit dem Tools-ISO) — vorher konnten Clients in einer NAT-Umgebung versehentlich auf eine ungültige NAT-Adresse zeigen.

- **Image-Linien können selbst benannt werden, Versionszähler pro Linie** — Beim Speichern eines neuen Image-Stands (Baseline / „neue Basis") gibt es jetzt ein Pflichtfeld „Image-Name". Damit lassen sich mehrere parallele Image-Linien unterscheiden (z.B. „Manjaro Sales" und „Debian Workforce") — jede Linie hat einen unabhängigen Tages-Zähler, am selben Tag entstehen also nicht zwei kollidierende „v…-001".

  Im Delta-Modus (kein neuer Wurzel-Klon) wird der Linien-Name automatisch vom Basis-Klon übernommen.

- **Cloning-VM: Snapshot-Namen jetzt im Datumsformat** — Der interne Snapshot der Cloning-VM hieß bisher noch nach dem alten Versionsschema (z.B. „@snap_v2.000"). Er folgt jetzt dem neuen Datumsformat („vYYYY.MM.DD-NNN") — konsistent zur Versions-Umstellung von 2026-05-07. Für die Bedienung ändert sich nichts.

- **Hotfix: Heartbeats vom Rollout-Netz kamen nicht mehr durch** — Die Caddy-Umbauten am Vortag hatten den HTTPS-Listener vom Rollout-Netz versehentlich abgehängt — Clients ohne VPN-Tunnel im Rollout-Netz erschienen alle als offline, obwohl sie liefen und einen DHCP-Lease hatten. Behoben: Caddy hat jetzt einen vierten Block speziell für das Rollout-Netz, der nur die API beantwortet (UI bleibt dort weiter unsichtbar). Heartbeats kommen wieder an.

- **Agent v2.6.6: interne Effizienz-Aufräumarbeiten** — Reines Aufräumen ohne Verhaltensänderung — bestehende Agents holen v2.6.6 automatisch per Selbst-Update. Spürbar nur in der Hintergrund-Effizienz: weniger CPU-Last und weniger Netzwerk-Aktivität während eines laufenden Update-Downloads. Kein Eingriff nötig.


## 2026-05-07

- **Admin-Oberfläche nicht mehr über VPN erreichbar (Sicherheit)** — Bisher horchte der HTTPS-Listener auf allen Interfaces — die Admin-Oberfläche war damit auch über das VPN-Overlay aufrufbar, obwohl das nicht vorgesehen ist (VPN ist ausschließlich für Agent-Heartbeats gedacht). Der Reverse-Proxy wird jetzt explizit gebunden: Voller Admin-Zugriff nur über die Management-IP des LAN, über das VPN ist ausschließlich die API erreichbar (alles andere antwortet mit 404).

  **Hinweis für bestehende Installationen:** Beim nächsten Backend-Neustart wird die Listener-Konfiguration automatisch neu geschrieben. Wer den Stack manuell anders konfiguriert hat, sollte alte Listener-Reste entfernen, damit es keinen Port-Konflikt gibt.

- **Image-Versionierung: Wechsel auf Datumsformat („vYYYY.MM.DD-NNN")** — Image-Versionen werden jetzt vom System im Format „vYYYY.MM.DD-NNN" vergeben (z.B. „v2026.05.07-001"). Das NNN ist ein Tageszähler pro Image-Linie, der jeden Tag bei 001 neu startet. Versionen werden **vom System** erzeugt — keine manuelle Eingabe mehr.

  Im Capture-Import-Dialog gibt es jetzt ein „Image-Name"-Feld (1–80 Zeichen, optional eine Beschreibung). Damit lassen sich mehrere parallele Image-Linien sauber trennen.

  **Achtung:** Bestehende Versionen im alten Format werden auf „veraltet" gesetzt und nicht mehr als Update-Ziel angeboten — sie bleiben aber für die Versionshistorie sichtbar. Die Schema-Umstellung ist nicht reversibel; vor dem Apply sollte ein DB-Backup gezogen werden.

- **Agent v2.6.4: erkennt das neue Datums-Versions-Format** — Das neue Versionsformat (siehe Eintrag oben) wäre für ältere Agents nicht erkennbar gewesen — der Client hätte sich vom Update-Mechanismus „verloren". Mit v2.6.4 versteht der Agent beide Formate und sortiert korrekt zwischen ihnen.

  **Wichtig:** Vor dem ersten Rollout im neuen Format müssen alle Ziel-Clients mindestens auf v2.6.4 sein. Selbst-Update bringt sie automatisch hoch — bei langer Offline-Zeit ggf. Heartbeat-Status im Dashboard prüfen.

- **Agent v2.6.3: Hotfix — Update kommt am Client an** — Beim ersten End-to-End-Test des neuen Download-Pfads (siehe Eintrag „Bandbreiten-Steuerung" weiter unten) lief der Download zwar sauber durch, aber das Update wurde beim nächsten Reboot nicht angewendet. Ursache: eine zugehörige Metadaten-Datei wurde nicht mit-heruntergeladen. Der Agent zieht sie jetzt automatisch mit — Updates werden beim Reboot korrekt eingespielt.

- **Agent v2.6.2: schlankerer Heartbeat während Download + Crash-Erkennung** — Beim ersten Live-Test fielen drei Probleme auf:
  - Während eines laufenden Update-Downloads sendete der Agent jeden Heartbeat „vollständig" — unnötige CPU-/IO-Last genau dann, wenn der Client schon mit dem Download beschäftigt ist.
  - Heartbeats stockten während des minutenlangen Downloads — der Fortschrittsbalken im UI blieb leer.
  - Wenn der Client während des Downloads neustartete oder abstürzte, blieb der Download-Slot 15 Minuten blockiert.

  Behoben: Während des Downloads sendet der Agent jetzt schlanke Heartbeats mit nur den nötigsten Werten + Fortschritt. Bricht der Download durch Crash/Reboot ab, erkennt das Backend das im nächsten Heartbeat, gibt den Slot frei und startet einen Wiederholungsversuch (Anzahl der Wiederholungen im Throttle-Dialog einstellbar, Default 3). Der Wiederholungsversuch setzt am letzten heruntergeladenen Byte fort, nicht von vorne.

- **Bandbreiten-Steuerung für Delta-Updates** — Bei 350 Clients, die gleichzeitig ein 1 GB-Update ziehen, lief der Internet-Uplink voll und Homeoffice-Clients verloren ihre Videocall-Bandbreite. Es gab kein Limit und keine Drosselung. Neu:

  - Die Auslieferung läuft jetzt über HTTPS (Caddy/Backend) statt über NFS — saubere Authentisierung, Download lässt sich nahtlos fortsetzen.
  - **Globales Limit:** Standardmäßig 10 parallele Downloads. Im Updates-Tab über das Zahnrad-Icon einstellbar (`max_concurrent_downloads`).
  - **Client-Drosselung:** Jeder Client misst die Latenz zum Server während des Downloads und drosselt automatisch, wenn die Leitung voll wird (BBR-ähnliche Logik). Drei weitere Einstellungen: maximale Rate pro Client (Default 10 Mbit/s, 0 = unbegrenzt), Reserve-Bandbreite, Mindest-Rate.

  Der Wechsel ist „hart" — Agents ziehen das nötige Selbst-Update beim nächsten Heartbeat automatisch.

- **Backend kann VPN-Clients direkt pingen / per Terminal erreichen** — Nach einer Reihe von Anläufen mit Workarounds erreicht das Backend jetzt auch reine VPN-Clients (Homeoffice ohne LAN-Pfad) direkt für Ping und Terminal — ohne Umweg über den VPN-Container. Im Hintergrund wurde die Firewall-Logik so erweitert, dass Antwort-Pakete auf Backend-initiierten Verbindungen sauber durchkommen, und der VPN-Container hat zwei zusätzliche Weiterleitungs-Regeln bekommen. **Sicherheitsmodell:** Neue Verbindungen werden weiterhin gefiltert; nur Antworten auf bereits akzeptierte Verbindungen passieren. Kein Filter-Downgrade.

- **Datenbank-Migrationen laufen automatisch beim Container-Start** — Bisher musste eine neue Schema-Migration im Hintergrund manuell mit `psql` eingespielt werden — bei Installationen vor Ort untragbar. Der Backend-Container ruft jetzt vor jedem Start die Migrationsprüfung selbst auf. Bestehende Schemas werden automatisch erkannt und sauber weiterentwickelt; im Fehlerfall startet das Backend nicht (Schutz vor inkonsistentem Zustand).

  Effekt: Updates spielen sich künftig durch ein normales `docker compose pull && up -d` ein, ohne Handarbeit an der Datenbank.

- **VPN-Routen: sichere Live-Anwendung mit Rollback und Status-Rückmeldung** — Wenn die Liste der über das VPN gerouteten Netze im UI geändert wird, wendet der Agent das jetzt mit drei zusätzlichen Sicherheitsnetzen an:

  1. **Heimnetz-Schutz:** Bevor er die neuen Routen scharf schaltet, prüft der Agent, ob eine der Routen das lokal angeschlossene Heimnetz des Geräts überdeckt. Treffer? Dann lehnt er ab und meldet das zurück — keine Änderung, kein Selbst-Aussperren. Der angemeldete Benutzer am Gerät bekommt einen Hinweisdialog.
  2. **Rollback:** Geht der Tunnel nach dem Apply nicht wieder hoch (Handshake bleibt aus), spielt der Agent die alte Konfiguration zurück und versucht es erneut. Status „rolled_back" wird gemeldet.
  3. **Rückmeldung:** Jedes Apply meldet das Ergebnis im nächsten Heartbeat zurück. Im VPN-Tab erscheint dann pro Client ein farbiges Symbol mit Tooltip — rot bei Heimnetz-Konflikt, orange bei Rollback oder Apply-Fehler. So sieht man, ob die Änderung auf der gesamten Flotte angekommen ist.

- **VPN-Clients-Tab: „letzter Handshake" wird wieder gefüllt** — Die Spalte „letzter Handshake" im VPN-Clients-Tab zeigte für alle Einträge nur „—". Ursache war ein Format-Unterschied im Datum, das von der zentralen VPN-API kommt — die Werte wurden nie geparst und blieben leer. Behoben — beim nächsten Sync-Lauf (jede Minute) füllen sich die Werte korrekt.


## 2026-05-06

- **Terminal-Button erreicht auch reine VPN-Clients (Zwischenlösung)** — Der Terminal-Knopf in der Client-Detail-Ansicht blieb beim Connect hängen oder schlug fehl, vor allem bei reinen VPN-Clients (Homeoffice). Zwei Ursachen — beide behoben:
  - Die VPN-IP wurde mit Präfix-Länge an SSH übergeben (z.B. „10.10.10.3/32"), was als Hostname nicht auflöste.
  - Die Verbindung wurde aus dem Backend-Container heraus aufgebaut, der keinen Weg in das VPN-Netz hat. SSH läuft jetzt — als Zwischenlösung bis zur sauberen Lösung am Folgetag — über den VPN-Container, der direkten Zugriff auf alle Netze hat.

  Stand der Folgetage: Die Sauberlösung über Bridge-Weiterleitung kam einen Tag später (siehe 2026-05-07).

- **Ping-Button erreicht VPN-Clients wieder** — Analog zum Terminal-Problem oben war der Ping-Button im Clients-Tab für reine VPN-Clients ohne Reaktion (Timeout). Das ICMP-Paket entstand im Backend-Container, der kein Forwarding zum VPN-Interface hat. Pings laufen jetzt über den VPN-Container und treffen sowohl LAN- als auch VPN-Clients zuverlässig — ~1 ms RTT im LAN, ~50 ms über VPN.

- **Agent v2.5.21: „VPN verbunden"-Anzeige im Dashboard wieder korrekt** — Roaming-Clients zeigten im Dashboard fälschlich „verbunden (LAN)" statt „verbunden (VPN)", obwohl der Heartbeat durch den Tunnel ging. Ursache war eine separate Route-Abfrage, die mit mehreren Server-Adressen (LAN + VPN) nicht zuverlässig zur richtigen Antwort kam. Der Agent ermittelt den Verbindungsweg jetzt direkt aus der tatsächlich genutzten Verbindung — die Anzeige ist konsistent mit der echten Verbindungsroute.

- **Agent v2.5.20: angezeigte Client-IP stimmt mit dem tatsächlichen Heartbeat-Pfad überein** — Wenn ein Client zwei Wege zum Server hatte (LAN und VPN) und einer davon kurzfristig ausfiel, konnte die im Dashboard angezeigte IP-Adresse von der tatsächlich genutzten Verbindung abweichen. Der Agent ermittelt seine IP-Adresse jetzt durch denselben Probiervorgang wie die Heartbeat-Verbindung selbst — angezeigte IP und Verbindungsweg stimmen wieder überein.


## 2026-05-05

- **Agent erreicht den Server jetzt automatisch über LAN ODER VPN** — In Umgebungen mit LAN-Tunnel an der Maschine und gleichzeitiger Tunnel-Verbindung kam der Tunnel zwar sauber hoch, der Agent erreichte den Server aber nur über die LAN-Adresse — Roaming-Clients (außerhalb des LANs) hatten dafür keinen Pfad. Der Server liefert dem Agent jetzt **beide** Adressen (LAN bevorzugt, VPN als Reserve). Der Agent versucht die erste mit 3 s Timeout und schwenkt automatisch auf die zweite, wenn nötig — innerhalb des 10-Sekunden-Heartbeat-Budgets.

  Bestehende Clients werden beim nächsten VPN-Re-Deploy automatisch migriert. Wer ohne Re-Deploy nachhelfen muss, kann die Datei `/data/wireguard/dns-override` und den `/etc/hosts`-Eintrag von Hand um eine zweite Zeile mit der VPN-IP ergänzen.

- **Agent v2.5.18: Sicherheits- und Robustheits-Sammelrelease** — Umfangreicher Code-Review des Agents (über 4000 Zeilen Code, die mit Root-Rechten laufen). Vier Sicherheitslücken geschlossen, mehrere Korrektheits- und Stabilitäts-Verbesserungen, erstmals automatisierte Tests.

  **Sicherheitslücken (allesamt nur über lokalen Einbruch oder LAN-Angreifer im sehr engen Recovery-Zeitfenster ausnutzbar; auf LAN-only-Deployments mit vertrauenswürdiger Netzwerk-Topologie unkritisch — als Vorsorge dennoch geschlossen):**
  - Eine manipulierte Agent-Binary mit ungültiger Signatur wäre vom Selbst-Update akzeptiert worden — Exit-Code des Signatur-Checks wurde nicht korrekt geprüft.
  - Im Recovery-Pfad nach einem Zertifikatsfehler wurden auch ungeschützte Server-Felder ausgewertet (SSH-Schlüssel, Token, VPN-Routen). Im engen Zeitfenster hätte ein LAN-Angreifer Werte einschleusen können. Jetzt wird im Recovery-Pfad strikt nur das signierte Zertifikats-Update verarbeitet.
  - Der Username des angemeldeten Nutzers konnte über speziell gewählte Zeichen zur Befehlsausführung als Root genutzt werden. Username wird jetzt streng validiert.
  - Vom Server gelieferte Werte (Dateinamen, SSH-Schlüssel, VPN-Routen) flossen ungeprüft in Root-Operationen ein. Alle drei sind jetzt eingegrenzt und validiert.

  **Stabilität:**
  - Beim Selbst-Update / Zertifikatsschreiben / Token-Speichern werden Dateien jetzt durchgängig „atomar" geschrieben (auf die Platte gespült, erst dann umbenannt). Ein Stromausfall mitten in einer Schreiboperation kann keine halbe Datei mehr hinterlassen.
  - Das TPM-Enrollment wurde so umgestellt, dass es bei einem Abbruch entweder im sauberen Klartext-Modus oder im TPM-Modus bleibt — ein nicht-wiederherstellbarer Hybridzustand kann nicht mehr entstehen.
  - Das Hostnamen-Skript läuft jetzt nur noch einmal beim Start (statt bei jedem Heartbeat) — verhindert Schreib-Schleifen mit anderen System-Werkzeugen.
  - Heartbeats nutzen jetzt eine schrittweise Verlängerung bei Server-Fehlern (60 → 120 → 240 → max. 300 Sekunden) und etwas Zufalls-Streuung im Normalbetrieb. Eine Flotte von 60 Geräten nach einem Stromausfall hämmert dadurch nicht mehr synchron auf den Server.
  - Provisionierungs-Skripte werden beim Start automatisch aktualisiert (war zuvor zwar definiert, aber nicht verdrahtet — Skripte wurden nur über die Tools-ISO initial verteilt).

  **Interna:** Code-Doppelungen aufgeräumt, erste Test-Suite (vorher null Tests im Root-Privileg-Code).


## 2026-05-04

- **Dashboard: neue Kachel „Garantie bereits abgelaufen"** — Auf dem Dashboard gibt es jetzt eine fünfte Kachel mit der Anzahl der Geräte, deren Garantie bereits abgelaufen ist (rot bei > 0, sonst grau). Sie ergänzt die bestehende „Garantie läuft bald ab"-Kachel.

- **Agent v2.5.17: Versions-Hochzählung, damit das Selbst-Update wirklich ausrollt** — Der Selbst-Update-Mechanismus vergleicht die Versionsnummer als Text. Nach einem Hotfix-Tag-Wechsel trugen Server- und Client-Binary kurzzeitig dieselbe Versionsnummer trotz unterschiedlichen Inhalts — das Selbst-Update wurde übersprungen. Mit v2.5.17 ist die Version sauber hochgezählt, das Update läuft auf den Clients durch.

- **Dashboard: „Alle anzeigen" im Meldungen-Bereich öffnet den richtigen Tab** — Der „Alle anzeigen"-Link unter aktiven Meldungen landete bisher auf dem Default-Tab der Einstellungen (Benutzer-Verwaltung) statt auf dem Meldungen-Tab. Behoben — der Klick öffnet jetzt direkt den Meldungen-Tab.

- **Agent-Hostname: Cloning-Artefakt wird beim Erststart auf der Maschine stillschweigend ersetzt** — Auf jedem neu installierten Gerät feuerte alle 24 Stunden ein „MAC geändert"-Alarm, weil der von der Cloning-VM mitgebrachte Hostname-Marker (basierend auf der QEMU-Standard-MAC) nicht zur echten Hardware-MAC passte. Es war jedes Mal manuelle Auflösung im Dashboard nötig — bei jedem Gerät.

  Der Agent erkennt jetzt diesen einmaligen Übergang vom Cloning-Artefakt zur echten Hardware und ersetzt den Hostnamen still, ohne Alarm. Der eigentliche Identitäts-Schutz (Hostnamen-Wechsel auf bereits in Betrieb genommener Hardware löst weiterhin einen Alarm aus) bleibt vollständig erhalten.


## 2026-05-03

- **Remote-Desktop: Codec-Wechsel auf H.264, mit Hardware-Beschleunigung, wenn vorhanden** — Der Codec für die Remote-Desktop-Übertragung wurde wieder auf H.264 umgestellt — für Homeoffice-Verbindungen über VPN (~2 Mbit/s) liefert er bei 1080p deutlich saubere Bilder als der vorherige Codec. Der Agent wählt pro Sitzung automatisch den besten verfügbaren Encoder: zuerst Intel-/AMD-Hardware (VAAPI), dann NVIDIA-Hardware (NVENC), als Rückfall die Software-Variante (libx264). Tooling und Treiber werden bei der Client-Provisionierung passend zur Distribution mit-installiert.

  Wirkung: weniger CPU-Last auf dem Client während einer Fernsteuerung, deutlich flüssigere Übertragung. Hinweis: H.264 ist patentpflichtig; auf Hardware-Pfaden ist die Lizenz über den Hersteller abgedeckt, beim Software-Fallback gilt der übliche Lizenzrahmen.

- **Info-Bereich: neuer Tab „Lizenz"** — Im Info-Bereich gibt es jetzt einen dritten Tab „Lizenz" mit den hinterlegten Lizenz-Texten (LICENSE, NOTICE, Drittanbieter-Lizenzen, schriftliches Angebot zur Quellcode-Bereitstellung). Aufklappbar pro Eintrag, ohne Internet.

- **Info-Bereich: Link zur Webseite ergänzt** — Im Info-Tab erscheint neben der E-Mail-Adresse jetzt ein Webseiten-Link auf https://thinforge.org (öffnet in neuem Tab).

- **Agent: Server-TLS-Zertifikat wird auch im System-Vertrauensspeicher des Clients aktualisiert** — Nach einer Rotation des Server-TLS-Zertifikats hat der Agent bisher nur seinen eigenen Vertrauensanker aktualisiert. System-Werkzeuge auf dem Client (z.B. `curl` ohne Sonderparameter, Browser) misstrauten dem neuen Zertifikat aber weiterhin, bis ein separater Pflege-Lauf nachzog. Der Agent aktualisiert jetzt nach jeder Zertifikats-Rotation auch den System-Vertrauensspeicher (auf Arch/Manjaro, RHEL, Debian — je nach Distribution) — Browser und System-Tools vertrauen dem neuen Zertifikat sofort.


## 2026-05-02

- **Backup & Restore neu strukturiert (System-Backup + Daten-Backup)** — Das Backup-System ist neu aufgesetzt und in zwei getrennte Backup-Typen aufgeteilt:

  - **System-Backup** (klein, schnell, synchron): enthält Datenbank, Konfigurationen, VPN-Server-Daten und Schlüssel. Wird vom Backup-Panel sowie vom Setup-Wizard genutzt.
  - **Daten-Backup** (groß, läuft als Hintergrund-Job): enthält die Klone und Update-Deltas — also alle Image-Daten.

  Beide Archive landen in einem zentralen Verzeichnis und können im Backup-Tab erzeugt, heruntergeladen und gelöscht werden. Der Setup-Wizard akzeptiert nur System-Backups; Daten-Backups muss man nach dem Login im Backup-Tab einspielen.

  Restore-Ablauf ist sauber gesplittet: zuerst Dateien und Datenbank atomar zurückgespielt (laufende Daten werden nie gelöscht, bevor die Wiederherstellung vollständig ist), dann die betroffenen Container in fester Reihenfolge neu gestartet. Im Setup-Wizard wird der Backend-Selbst-Neustart bis zum Wizard-Ende verzögert.

  Wichtig: Das WireGuard-Server-Verzeichnis liegt jetzt einheitlich unter `config/wireguard/` (alte Bezeichnung wird beim Restore weiterhin akzeptiert). Das Deltas-Verzeichnis wird erstmals mit-gesichert (war bisher nicht im Backup enthalten).

  Die zuvor deaktivierten Karten „Backup erstellen" und „Aus Backup wiederherstellen" sind wieder aktiv.


## 2026-05-01

- **Speichern von Updates: Mehr-Subvolume-Layout wird automatisch konsolidiert** — Bei einer Cloning-VM, die ohne den vorbereitenden Schritt installiert wurde, lagen Home-Verzeichnis, Cache und Log in separaten Btrfs-Subvolumes — Updates enthielten dadurch nur das Hauptverzeichnis. Konkrete Folge: Auf den Clients fehlten beispielsweise vom Operator angelegte Desktop-Verknüpfungen, obwohl das Update sonst funktionierte.

  Das System erkennt das jetzt vor dem Snapshot und meldet einen Konsolidierungs-Bedarf zurück. Im Dialog erscheint die Liste der Subvolumes und eine Bestätigungs-Abfrage — wer „Konsolidieren" wählt, lässt das System die Inhalte sauber zusammenführen und die separaten Subvolumes entfernen. Anschließend läuft das Update normal weiter; folgende Updates sind dann vollständig.

- **Agent: VPN-Adresse zählt nicht mehr als „Hardware-MAC-Änderung"** — Auf manchen Geräten meldete der Agent fälschlicherweise „MAC geändert"-Alarm, sobald der VPN-Tunnel aktiv wurde — er hatte den VPN-Adapter versehentlich als physische Netzwerkkarte interpretiert. Die Erkennung physischer Netzwerkkarten ist jetzt deutlich robuster: Der Agent fragt direkt beim Kernel an, ob ein Interface Hardware ist, und sortiert die Hardware-Karten in fester Reihenfolge (kabelgebunden vor WLAN). Ergebnis: Stabile Identität, keine falschen Alarme mehr.

  **Migration:** Geräte mit mehreren Kabel-Netzwerkkarten, deren bisheriger Identitäts-Marker von einer „nicht alphabetisch ersten" Karte stammte, melden nach dem Update einmalig einen „MAC geändert"-Alarm. Diesen einmal im Dashboard auflösen — danach ist die Identität stabil. Bestehende Alarme aus der alten Fehlerklasse müssen ebenfalls manuell auf „resolved" gesetzt werden.

- **Dashboard: Interner Fehler beim Anzeigen von MAC-Änderungs-Alarmen behoben** — Sobald ein Client einen MAC-Wechsel meldete, schlug der Dashboard-Aufruf intern mit einem 500-Fehler fehl, weil der Server die Alarm-Kategorie nicht kannte. Behoben — MAC-Änderungen werden jetzt korrekt im Dashboard angezeigt, ebenso „Versions-Abweichung", die das gleiche Problem hatte.


## 2026-04-29

- **Cloning-VM: nur ein gemeinsames Wurzel-Subvolume, sonst fehlen Update-Inhalte** — Bei neu installierten Cloning-VMs lagen Home-Verzeichnis, Cache und Log in jeweils eigenen Btrfs-Subvolumes — Updates enthielten dadurch nur das Hauptverzeichnis, alles in `/home` fehlte beim Client. Der Installations-Vorbereitungsschritt schreibt jetzt einen Single-Wurzel-Block in die Installer-Konfiguration; `/home`, Cache und Log liegen damit als normale Verzeichnisse im Wurzel-Subvolume und werden bei jedem Update mit erfasst.

  **Migration:** Cloning-VMs, die mit dem alten Layout installiert wurden, müssen einmal neu installiert oder die Subvolumes manuell zusammengeführt werden. Auf End-Clients greift das automatisch beim nächsten Update.

- **Cloning-VM-Setup: Agent-Binary wird zuverlässig aktualisiert (kein „Text file busy"-Stillschweigen mehr)** — Beim erneuten Ausführen des Cloning-Vorbereitungs-Skripts auf einer VM mit bereits laufendem Agent blieb der alte Agent-Binary stehen, obwohl die Meldung „Agent von ISO installiert" erschien. Ursache: die Datei lässt sich nicht überschreiben, solange sie ausgeführt wird; der Fehler wurde verschluckt. Jetzt wird die neue Binary daneben gelegt und atomar getauscht; der Agent-Dienst wird bei Bedarf neu gestartet.

- **Cloning-VM-Tools-ISO: Agent-Binary kommt immer aus dem Build-Verzeichnis** — Beim Neuerstellen der Tools-ISO wurde versehentlich die alte, eingecheckte Agent-Binary mitgenommen statt der frisch gebauten — neu installierte Clients liefen damit teils mit deutlich älteren Versionen. Die ISO-Erstellung nutzt jetzt verbindlich die zuletzt gebaute Binary inklusive Signatur und Versions-Datei.

- **Client-Installation: Größe der Daten-Partition kommt komplett aus dem UI** — Die Installations-Skripte fragten den Operator vor Ort separat nach der Größe der Daten-Partition. Diese Größe wird inzwischen schon im UI bei „Basis HD erstellen" festgelegt; die Doppel-Abfrage ist entfernt. Das Daten-Partitions-Skript erkennt den Zustand der Festplatte selbst und legt nur an, was fehlt — schon vorhandene Daten-Partitionen werden nicht angefasst.

- **„Basis HD erstellen": kein Distributions-Dropdown mehr** — Im Wizard „Basis HD erstellen" gab es bisher ein Distributions-Auswahlfeld, dessen Wert nach der Installation oft nicht zur tatsächlichen Btrfs-Layout-Wahl des Installers passte — Snapshot-Erstellung schlug dann fehl. Das Feld ist entfernt; das System erkennt nach der OS-Installation automatisch das vom Installer angelegte Wurzel-Subvolume aus der Datei-Struktur und merkt sich das. Wenn sich der Stand auf der Festplatte ändert, wird die Erkennung erneut ausgeführt — bestehende stuck-Installationen heilen sich beim nächsten Versuch.

- **Frontend-Versionsanzeige: „vdev" durch echte Datums-Version ersetzt** — In der Kopfleiste rechts oben stand auf frisch deployten Servern „vdev" statt einer Datums-Version. Ursache: dem Frontend-Build-Container fehlte das Changelog-File, aus dem die Version gezogen wird. Behoben — die Versionsanzeige stimmt nach dem nächsten Frontend-Rebuild wieder.

- **Release-Server: Compose-Mounts korrigiert (Restart-Loops behoben)** — Auf frisch ausgerollten Release-Servern liefen Backend und Worker im Restart-Loop, die Datenbank blieb ohne Schema, der Setup-Wizard hing. Ursache waren drei Pfad-Fehler in der Compose-Datei, die beim Synchronisieren aus dem Entwickler-Setup nicht angepasst wurden. Beide betroffenen Compose-Varianten sind korrigiert.

  **Hinweis für betroffene Installationen:** Vor dem nächsten Deploy muss eventuell ein versehentlich angelegter Phantom-Ordner entfernt und die Datenbank einmal initial neu angelegt werden.

- **Sicherheits-Audit der Container-Images, Basis-Images angehoben** — Großes Sicherheits-Audit aller Container-Images mit `grype`. Die kritischen Funde stammten aus älteren Versionen von Docker-Werkzeugen und Python-Paketen. Behoben durch:
  - Backend-Basis-Image: neuere Rust-Toolchain, System-Pakete beim Build aktualisiert, Docker-Werkzeuge aus aktuelleren Quellen — Anzahl behebbarer Schwachstellen von 43 auf 3 reduziert, alle kritischen Treffer weg.
  - Cloning-VM- und BT-Seeder-Images: Pin-Versionen für `pip`, `wheel`, `jaraco.context`, `requests` angehoben.
  - Externe Basis-Images (Postgres, Redis, Caddy, Node, Alpine, Go) neu gezogen.

  Verbleibende Treffer in Python-Toolchain-Komponenten sind Build-only und werden zur Laufzeit nicht genutzt — als bekannt und akzeptabel dokumentiert.

- **Debian-Clients: Rollback-Menü-Einträge im Bootloader funktionieren wieder** — Auf Debian-Clients fehlten die Snapshot-Einträge im GRUB-Menü; Rollbacks auf einen früheren Snapshot waren über den Bootloader nicht auswählbar. Ursache war ein Format-Unterschied im Standard-AWK auf Debian gegenüber Arch/Manjaro. Behoben — beim nächsten Update läuft das Skript korrekt, Snapshot-Einträge erscheinen wieder im GRUB-Menü.

- **Agent-Selbst-Update zieht Updates wieder zuverlässig** — Seit kurz vorher war das Agent-Selbst-Update blockiert — Anfragen wurden ohne Authentifizierungs-Token gesendet, der Server lehnte mit 403 ab; im Log war es nur auf Debug-Ebene sichtbar. Folge: Clients hingen auf der zur Installation eingespielten Agent-Version. Selbst-Update und das Nachladen der Helfer-Skripte schicken jetzt den Heartbeat-Token korrekt mit.

  **Migration:** Geräte mit Agent v2.5.13 oder älter brauchen einmal einen manuellen Push der neuen Binary (oder ein Re-Provisioning); danach läuft Selbst-Update wieder eigenständig.

- **Terminal und Remote-Desktop: Login-Cookie wird erkannt** — Nach der vor Kurzem erfolgten Umstellung auf cookie-basierte Anmeldung öffneten sich die Terminal- und Remote-Desktop-Dialoge nicht mehr („Not authenticated"). Beide Dialoge erkennen den Login-Cookie jetzt zuverlässig.

- **Klon-Export: Btrfs-Layout-Infos reisen mit** — Beim Export eines Klons werden die Btrfs-Layout-Informationen (Distributionsname, Wurzel-Subvolume) jetzt mit ins Archiv geschrieben. Beim späteren Restore findet das System sofort das richtige Wurzel-Subvolume — der erste Update-Speichern-Vorgang nach dem Restore läuft ohne manuelles Eingreifen. Ältere Klone ohne diese Infos fallen auf die automatische Erkennung zurück.

- **Single-Root-Layout: Folgekorrekturen aus dem Code-Review** — Mehrere Aufräumarbeiten rund um die Single-Wurzel-Subvolume-Umstellung:
  - Alte System-Hilfsdateien für die getrennten Subvolumes werden beim Agent-Update automatisch entfernt.
  - Das Skript zum Nachsignieren bestehender Deltas räumt versehentlich liegengebliebene `_home`-Delta-Dateien mit weg.
  - Das manuelle Snapshot-Verwaltungs-Skript schützt jetzt zusätzlich vor versehentlichem Löschen des aktiven Wurzel-Subvolumes auf Debian-Clients.
  - Veraltete Kommentare und Konfigurationsreste in den Installations-Skripten aufgeräumt.


## 2026-04-28

- **Cloning-VM: pro Distribution korrektes Layout, Updates wieder mit Inhalt** — Bei einer Debian-basierten Cloning-VM erzeugte das System praktisch leere Update-Dateien (~120 Byte), obwohl in der VM mehrere Hundert MB neu installiert waren. Ursache war ein Layout-Mismatch zwischen der vorbereiteten Festplatte (mit „Mint-Konvention") und dem, was der Debian-Installer tatsächlich anlegte — das System speicherte Snapshots vom leeren Vorab-Subvolume.

  Behoben über zwei Schritte:
  1. **Distributions-Wahl im „Basis HD erstellen"-Wizard:** Auswahl Debian / Ubuntu / Mint / Sonstige; die Vorbereitung legt das passende Wurzel-Subvolume an und merkt sich das in einer Begleit-Datei.
  2. **Single-Wurzel überall:** Backend und Agent erkennen das Wurzel-Subvolume einheitlich. Home-Verzeichnis liegt direkt im Wurzel-Subvolume und wird automatisch mit erfasst — die frühere Sonderbehandlung für ein separates Home-Delta entfällt vollständig.

  Nebenbei: Festplatten-Größenangaben sind jetzt durchgängig auf 1024-Basis vereinheitlicht — eine im Wizard mit 60 GB angelegte Festplatte erscheint anschließend auch als 60 GB statt 54 GB im Klon-Katalog. (Der OS-Installer in der VM zeigt die Eingabe von 60 GB allerdings als 64,4 GB an, weil er dezimal rechnet.)

- **VPN-Firewall: Peer-Isolation funktioniert jetzt verlässlich** — Die „Peer-Isolation"-Regel (Geräte hinter dem VPN sehen sich gegenseitig nicht) wurde vom System mit einer Negations-Form geschrieben, die der iptables-Backend des Servers ablehnt. Der Fehler wurde dabei verschluckt — im UI stand „Peer-Isolation: an", real konnten sich die VPN-Peers aber gegenseitig erreichen. Die Regel ist jetzt sauber aus zwei einzelnen Einträgen gebaut, der Schutz wirkt wie angegeben.

  Außerdem werden Firewall-Befehle strikt nacheinander ausgeführt — ein Fehler bricht jetzt sofort ab, statt durch Verkettung still verschluckt zu werden. Das Backend wendet die Firewall-Regeln nach jedem Container-Neustart automatisch wieder an.

- **VPN-Firewall: Live-Log im UI** — Im VPN-Tab gibt es jetzt unter den Firewall-Regeln einen zweiten Bereich „Firewall Live-Log". Tabelle mit Zeit, Aktion (Akzeptiert / Verworfen / Peer-Isolation), Regel-Name, Quelle, Ziel, Protokoll und Port. Aktualisiert alle 5 Sekunden, mit Pause-Knopf und manuellem Refresh. Vor jeder Firewall-Regel wird intern ein Log-Eintrag im Kernel-Ringpuffer erzeugt, ein Hintergrund-Prozess im VPN-Container schreibt das gefiltert in eine Log-Datei und rotiert sie ab 50 MiB. Damit lässt sich live nachvollziehen, welche Pakete welche Regel treffen.

- **Firewall-Log: keine doppelten Einträge mehr nach Tunnel-Neustart** — Nach einem Neustart des VPN-Containers tauchte der gesamte alte Kernel-Ringpuffer noch einmal im Firewall-Log auf — jedes Event war nach mehreren Neustarts mehrfach vorhanden. Behoben: Der Mitschnitt liest jetzt nur neue Kernel-Meldungen nach dem Start, alte bleiben unberücksichtigt. Jedes Firewall-Event erscheint genau einmal.

- **VPN-Einstellungen: Peer-Isolation nicht mehr abschaltbar** — Der Schalter „Peer-Isolation" in den VPN-Einstellungen ist entfernt. Der Schutz ist als feste Betriebsregel verdrahtet und kann nicht versehentlich deaktiviert werden — der Standard ist immer „an".

- **VPN: Firewall wird beim Tunnel-Import automatisch eingeschaltet** — Nach dem Importieren einer Tunnel-Konfiguration musste die Firewall bisher zusätzlich im UI eingeschaltet werden — sonst lief der Tunnel ohne Regelwerk und das Live-Log zeigte nichts an. Das passiert jetzt automatisch, Peer-Isolation und Live-Log sind ab dem ersten Tunnel-Import direkt aktiv.

- **Heartbeat-Token: kontrolliertes Rotations- und Recovery-Verhalten** — Der Heartbeat-Token (mit dem ein Agent sich beim Server ausweist) wird jetzt zentral validiert; nach einer Rotation werden auch ältere Token noch eine Karenzzeit lang akzeptiert (Standard 96 Stunden, per Umgebungsvariable einstellbar). Der Server schickt im Heartbeat den nächsten gültigen Token mit, der Agent persistiert ihn atomar. Zusätzlich gibt es einen Recovery-Endpunkt, um einen neuen Token gezielt nachzuholen. Die internen Agent-Endpunkte hängen jetzt durchgängig hinter der Token-Prüfung; einzig der Endpunkt zur TLS-Zertifikats-Wiederherstellung bleibt bewusst offen.


## 2026-04-27

- **Geplante Deployments mit BitTorrent: Status-Updates kommen an** — Beim neuen Vorlauf-Mechanismus für geplante Deployments (Seeder läuft schon 10 Minuten vor dem geplanten Start hoch) wurden die Status-Meldungen vom Seeder-Container vom Server verworfen, weil das Deployment noch nicht „aktiv" war. Folge im UI: „Vorbereiten / Seeder starten", obwohl der Seeder bereits saubere Daten verteilte. Behoben — Status-Meldungen werden auch während der Vorlauf-Phase angenommen.

- **Geplante Deployments: dreistufiger Ablauf mit Vorlauf und Wake-on-LAN** — Geplante Deployments laufen jetzt automatisch in drei Phasen ab:

  - **10 Minuten vor dem Start:** Seeder und Torrent werden im Hintergrund vorbereitet (die Hash-Berechnung kann mehr als eine Minute dauern; ohne Vorlauf würde der Client in eine leere Torrent-Datei booten).
  - **1 Minute vor dem Start:** PXE-, NFS-, dnsmasq- und Multicast-Vorbereitungen werden scharfgeschaltet. Wenn der BT-Vorlauf schon gelaufen ist, wird nichts doppelt gestartet.
  - **Zum geplanten Startzeitpunkt:** Wake-on-LAN-Pakete werden an alle Ziel-Geräte gesendet (dreifach mit kurzem Abstand, weil manche Switches/NICs einzelne Magic-Pakete verschlucken). Das passiert bewusst **nach** der Aktivierung — sonst würde ein aufwachender Client in das alte Boot-Ziel laufen, weil die PXE-Umstellung noch nicht durch wäre.

  Im Dialog ist „Wake-on-LAN beim Start senden" jetzt ein einfacher Schalter (kein „Minuten vorher"-Feld mehr). Der Worker erkennt Konfigurationsfehler beim Start, statt erst im laufenden Betrieb auf die Nase zu fallen.

- **Geplante Deployments: Datum + Uhrzeit klar getrennt, immer Server-Zeitzone** — Im Plan-Dialog für Deployments gibt es jetzt zwei separate Felder: einen Datums-Picker und einen Uhrzeit-Picker (24-Stunden-Format, mit OK-Knopf). Die Eingabe wird immer als Berliner Zeit interpretiert — unabhängig davon, wo der Browser läuft. Unter den Feldern zeigt ein Hinweis live die resultierende UTC-Zeit, die der Server am Ende speichert. Damit lassen sich Zeitzonen-Verwechslungen (z.B. eine VNC-Sitzung mit UTC, während der Server schon auf Berlin steht) vermeiden.

- **Server-Setup: Zeitzone wird interaktiv abgefragt, Uhrzeit-Sync sichergestellt** — Das Setup-Skript hat bisher hart die Berliner Zeitzone gesetzt. Jetzt wird die Zeitzone interaktiv abgefragt (mit der aktuell eingestellten als Vorschlag und Beispielen) und die Eingabe gegen die Linux-Zeitzonen-Liste validiert. Bei automatisierten Setups (ohne Terminal) bleibt die bestehende Zeitzone erhalten — oder kann per Umgebungsvariable gesetzt werden. Zusätzlich schaltet das Setup die automatische Uhrzeit-Synchronisation (NTP) ein, falls noch nicht aktiv — ohne korrekte Uhrzeit kann die TLS-Verbindung zum Agent fehlschlagen.

- **Client-Installation: ISO-Skripte werden zuverlässig gefunden, Installation bricht bei Fehlern hart ab** — Auf manchen Installationen wurde das Folge-Skript der Tools-ISO nicht gefunden, je nach Pfad oder Aufrufweise — die Installation lief scheinbar durch, das Ergebnis war aber nicht funktionstüchtig. Die Suche kennt jetzt drei Wege: erst das Skript-eigene Verzeichnis, dann beliebige gemountete Pfade mit dem ISO-Label, schließlich automatisches Mounten der CD-Laufwerke. Wird nichts gefunden, bricht die Installation mit klarer Meldung ab statt nur zu warnen.

  Außerdem: Wenn die Daten-Partition nicht eingehängt oder kein btrfs-Dateisystem ist, bricht die Installation jetzt hart ab. Sonst hätten Token, Zertifikat und Agent-Binary versehentlich im Wurzel-Dateisystem landen können und wären beim nächsten Boot vom echten Daten-Mount überdeckt worden — der Agent wäre dann ohne State gestartet.

- **Neues Diagnose-Skript für Clients** — Auf der Tools-ISO liegt jetzt ein „Agent-Check"-Skript, das eine fertig installierte Client-VM von oben bis unten durchprüft: Mounts und Symlinks, Agent-Binary, Konfigurationsdatei, TLS-Zertifikat (inkl. Restlaufzeit), System-CA-Speicher, Tokens und Berechtigungen, Update-Skripte, alle relevanten systemd-Units, SSH-Setup, installierte Version und ein versuchter Verbindungs-Test zum Server. Am Ende eine Pass/Warn/Fail-Bilanz und passender Exit-Code für Skripte.


## 2026-04-26

- **Client-Installation: zweite Layout-Prüfschicht entfernt** — Die Tools-ISO hatte zusätzlich zur UI-gesteuerten Festplatten-Vorbereitung eine zweite Prüfschicht im Live-System, die nochmal das Layout verifizierte. Praktischen Nutzen gab es nicht (der Installer prüft selbst) und sie hat in bestimmten Pfad-Konstellationen sogar falsche Fehler ausgegeben. Entfernt — das UI ist die alleinige Quelle fürs Layout. Die Installations-Anleitungen sind entsprechend gestrafft.

- **Cloning-VM: Festplatten-Größenanzeige stimmt mit der UI-Eingabe überein** — Die Festplatten-Größe der Cloning-VM wurde im Status-Panel anders berechnet als im Wizard eingegeben — wer 60 GB eingab, sah anschließend 54 GB. Beide Stellen rechnen jetzt einheitlich. Auch die „Vergrößern"-Funktion wendet den UI-Wert jetzt korrekt an.

- **„Basis HD erstellen": Festplatten-Vorbereitung wurde im falschen Pfad ausgeführt** — Im Wizard „Basis HD erstellen" lief die Festplatten-Vorbereitung im Hintergrund in einem leeren Verzeichnis im Container statt im echten Datenverzeichnis auf dem Server — der Wizard meldete Erfolg, aber im Klone-Bereich tauchte nichts auf. Behoben: Die Vorbereitung schreibt jetzt zuverlässig in das Storage-Verzeichnis. Bestehende „nichts ist da"-Stände müssen einmal manuell aufgeräumt und das Anlegen wiederholt werden.

- **Cloning-VM: keine versehentliche Festplatten-Vergrößerung beim Container-Start mehr** — Wenn der Cloning-VM-Container startete und eine vorhandene Festplatte etwas kleiner als der erwartete Wert war, wurde sie automatisch vergrößert — dabei blieb die Partitionstabelle aber stehen, sodass der OS-Installer die Festplatte fälschlich als komplett leer ansah und einen Neuanfang vorschlug. Behoben: Die Vergrößerung beim Start ist entfernt. Festplatten werden ausschließlich über den UI-Wizard angelegt; fehlt eine, bricht der Container mit klarer Fehlermeldung ab.

- **VPN-Firewall: Peer-Isolation als feste Grundregel** — Neue Grundregel: Geräte hinter dem VPN sehen sich gegenseitig nicht (Client-zu-Client-Verkehr im VPN-Overlay wird gesperrt). Die Regel wird ganz vorne in der Firewall-Kette eingehängt, sodass eine später angelegte zu weit gefasste „Erlauben"-Regel den Schutz nicht aushebeln kann. Die Appliance selbst bleibt erreichbar — Agent-zu-API funktioniert weiterhin. Die zugehörige Topologie (Subnetz, lokale IP) wird aus der Tunnel-Konfiguration abgeleitet — funktioniert auch dann, wenn der VPS später ein anderes Overlay-Netz vergibt.

  Im VPN-Einstellungs-Dialog gibt es einen Schalter (Standard: an) — dieser ist zwei Tage später (siehe 2026-04-28) wieder entfernt worden, der Schutz ist seither fest verdrahtet.

- **Neuer „Basis HD erstellen"-Wizard im UI** — Im Cloning-Bereich gibt es einen neuen Knopf „Basis HD erstellen" mit Wizard-Dialog. Damit lässt sich die Festplatte der Cloning-VM direkt aus dem UI partitionieren, formatieren und mit den nötigen Subvolumes anlegen — vorher war das ein manueller Schritt im Rescue-Modus des Installers. Eingaben werden vorab auf sinnvolle Mindestgrößen geprüft (System ≥ 4 GB, EFI ≥ 100 MB, Daten ≥ 1 GB).

- **Vulnerability-Scan: Anzahl in Übersicht und Detail-Ansicht stimmen überein** — In der Sicherheits-Übersicht zeigte die Übersichts-Zelle pro Image teils andere Zahlen als die zugehörige Detail-Liste — z.B. „12 Kritisch" in der Zelle, „1 Kritisch (11 als akzeptiert markiert)" in der Detail-Ansicht. Die Übersichts-Zelle rechnet jetzt aus derselben Quelle wie die Detail-Ansicht (Roh-Zahl minus akzeptiert minus „nicht betroffen"). Außerdem werden technische Duplikate (dieselbe Schwachstelle in derselben Paket-Version, nur an verschiedenen Pfaden im Image) nicht mehr mehrfach gezählt — die Zahlen sind insgesamt realistischer und konsistent.

- **Vulnerability-Scan: postgres und redis werden wieder korrekt eingestuft** — Schwachstellen-Befunde für die Container-Images `postgres:18-alpine` und `redis:8-alpine` landeten fälschlich im Topf „benötigt Bewertung" — der Image-Name wurde aus dem Dateinamen abgeleitet und falsch gesplittet. Der Scan liest den Image-Namen jetzt direkt aus der Scan-Ausgabe; die 32 postgres- und 2 redis-CVEs werden beim nächsten Scan korrekt eingeordnet (Status WARN → PASS).

- **Vulnerability-Scan: zwei neue Schwachstellen als bekannt eingetragen** — Zwei aktuelle Befunde aus dem Audit dauerhaft eingeordnet:
  - Eine Telemetrie-Bibliothek im Caddy-Image (otel 1.40.0) hat einen Verfügbarkeits-Befund (DoS über manipulierte Header). Im LAN-only-Betrieb kein Datenabfluss, nur potenzieller Verfügbarkeitsverlust; Fix wartet auf den nächsten Caddy-Upstream-Build.
  - Ein gRPC-Befund im BT-Seeder-Image ist ein False-Positive: Die Schwachstelle betrifft die Go-Implementierung, das Image enthält die C++/Python-Variante.

- **Tools-ISO: zusätzlicher Pfad für die Debian-netinst-Installation** — Neues Begleit-Skript für die schlanke Debian-Netinst-ISO (`install-debian-minimal.sh`). Unterschied zur Live-Variante: die Installation läuft im Standard-Debian-Installer (kein Calamares), die Subvolumes werden im Vorbereitungsschritt manuell angelegt. Der Abschluss-Schritt ist identisch zur Live-Variante.


## 2026-04-25

- **Navigation: „Lizenz" und „Lokales Netzwerk" erscheinen in der Seitenleiste** — Zwei Tabs, die in den Views bereits existierten, aber im Seitenmenü nicht aufgetaucht waren, sind jetzt sichtbar: Einstellungen → „Lizenz" und Netzwerk → „Lokales Netzwerk". Ein direkter Klick aus der Seitenleiste landet jetzt auch tatsächlich auf dem gewünschten Tab.

- **Cloning-Konsole: Reload-Knopf für die VM-Ansicht** — In der Konsolen-Anzeige des „VM erstellen"-Tabs gibt es jetzt einen kleinen Refresh-Knopf in der Kopfzeile. Klick darauf erzeugt eine frische Verbindung zur Konsole — gelegentliche leere Konsolen-Anzeigen lassen sich damit ohne kompletten VM-Neustart beheben.

- **Klon-Liste: klarere Aktions-Bezeichnung** — Der „Wiederherstellen"-Knopf in der Klon-Liste heißt jetzt „Wiederherstellen zur VM" (englisch „Restore to VM"). Damit ist auf einen Blick klar, dass das Ziel die laufende Cloning-VM-Disk ist und nicht etwa der ausgewählte Client.

- **Frontend: Build-Pipeline strikter, Production-Image korrekt** — Der Frontend-Build prüft jetzt vor jeder neuen Version alle TypeScript-Fehler streng — über mehrere Monate angesammelte Warnungen (50 in 15 Dateien) sind dabei aufgeräumt worden. Außerdem: Die Production-Compose-Variante baut das Frontend-Image jetzt aus dem Production-Pfad (Caddy/Static) statt aus dem Entwicklungs-Pfad — bisher konnten Container-Neustarts in seltenen Fällen dazu führen, dass offene Browser-Tabs auf nicht mehr existierende Module-URLs liefen.

- **Update-Speichern: Versionsvorschlag berücksichtigt vorhandene Klone** — Beim Speichern eines neuen Updates schlug der Dialog die Versionsnummer rein aus dem letzten Snapshot der laufenden VM vor. Wenn der Snapshot-Stapel durch ein erzwungenes Neu-Anlegen der Baseline geleert wurde, aber Klone mit den alten Versionen noch auf der Platte lagen, wurde die alte Versionsnummer erneut vorgeschlagen — der Speichern-Vorgang brach dann mit Versions-Konflikt ab. Der Vorschlag berücksichtigt jetzt auch die vorhandenen Klone und nimmt jeweils die nächste freie Nummer.

- **Dienste-Panel: BT-Seeder und Multicast-Sender werden angezeigt** — Im Dienste-Panel (und unter Einstellungen → Logs) tauchen jetzt der BitTorrent-Seeder und alle aktiven Multicast-Sender auf. Der Seeder bekommt einen festen Eintrag, die Multicast-Sender werden zur Laufzeit aus der Container-Liste ermittelt (es können je nach aktiven Deployments null bis viele sein). Damit lassen sich Status und Logs dieser Hilfs-Container ohne Umweg über die Konsole einsehen.

- **Reverse-Proxy: PXE-Pfade nur noch im Client-Netz erreichbar** — Der Reverse-Proxy (Caddy) für die PXE-/Klon-Deploy-Pfade auf Port 80 bindet jetzt explizit nur an die im Setup-Wizard konfigurierte Client-Netz-IP statt an alle Netzwerk-Karten. PXE-Clients ziehen Boot-Dateien weiterhin wie gewohnt, das Management-Netz hat aber auf Port 80 nichts mehr zu sehen. Admin-Zugriff läuft sowieso über HTTPS auf Port 443 und ist unverändert.

- **BitTorrent-Seeder: bindet nur noch ans Client-Netz** — Der Seeder-Container für BitTorrent-Deployments (libtorrent + opentracker) hat seine Listener (Peer-Port 6881, Tracker-Port 6969) bisher auf allen Netzwerk-Karten geöffnet. Beide binden jetzt strikt nur an die Client-Netz-IP — außerhalb des Client-Netzes ist nichts mehr offen. Wenn das Client-Netz im Setup-Wizard geändert wird, wird der Seeder-Container automatisch neu mit der korrigierten IP angelegt. Der Multicast-Sender war schon zuvor korrekt isoliert; das ist jetzt explizit dokumentiert.

- **Deployments-Tab: neu erstellte Deployments tauchen sofort in der Liste auf** — Beim Anlegen eines BitTorrent-Deployments dauert das Erzeugen des Torrents einige Sekunden — in der Zwischenzeit konnte die anschließend nachgeladene Deployment-Liste den frischen Eintrag noch nicht enthalten, und der Operator musste den Tab manuell neu laden. Der Eintrag erscheint jetzt sofort oben in der Liste, das nachgelagerte Aktualisieren läuft im Hintergrund.


## 2026-04-22

- **Agent-Heartbeat: das im UI eingestellte Intervall wirkt dauerhaft** — Im Agent war ein internes Heartbeat-Intervall fest verdrahtet, das nach zwei erfolgreichen Heartbeats auf 120 Sekunden umgeschaltet und damit die UI-Einstellung überschrieben hat — wer im UI „alle 10 Sekunden" einstellte, sah trotzdem nach kurzer Zeit wieder 120 Sekunden. Die feste Logik ist entfernt; der Agent richtet sich jetzt nach dem Server-Wert und akzeptiert nur eine sinnvolle Untergrenze (10 s) und Obergrenze (3600 s).

- **BitTorrent-Deployments: mehrere Deployments parallel möglich** — Der BitTorrent-Seeder läuft jetzt als langlebiger Dienst, der mehrere Klon-Torrents gleichzeitig anbieten kann — mehrere BitTorrent-Deployments mit verschiedenen Klonen an unterschiedliche Gruppen sind damit problemlos parallel möglich. (Multicast-Deployments bleiben aus Protokoll-Gründen weiterhin auf eines pro Server begrenzt.)

  Sobald kein BitTorrent-Deployment mehr aktiv ist, wird der Seeder automatisch wieder gestoppt — Peer- und Tracker-Ports sind außerhalb von Roll-outs nicht mehr offen. Deployments desselben Klons teilen sich denselben Schwarm und überspringen die einmalige Extraktion — schnellere Starts bei Wiederholung. Klon-Löschungen räumen den zugehörigen Cache mit auf.

- **Ein Deployment kann mehrere Gruppen auf einmal versorgen** — Der „Deployment anlegen"-Dialog hat einen neuen Ziel-Modus „Mehrere Gruppen". Die ausgewählten Gruppen werden zu einer Client-Vereinigungsmenge zusammengefasst und in einem einzigen Deployment-Task ausgeliefert — bei Multicast wird das Image dadurch nur einmal über die Leitung gestreamt, unabhängig davon wie viele Gruppen daranhängen. In der Deployments-Liste erscheint der gemeinsame Eintrag mit allen beteiligten Gruppen-Namen (z.B. „Marketing, Sales").

- **Deployments: keine Geister-Einträge mehr bei Aktivierungsfehlern** — Wenn das Aktivieren eines Deployments fehlschlug (z.B. PXE-Setup nicht möglich), blieb der Deployment-Eintrag trotzdem als „aktiv" in der Datenbank stehen — und blockierte spätere Multicast-/BitTorrent-Deployments. Bei einem Fehler wird der Eintrag jetzt sauber wieder entfernt und die Ursache im UI als Hinweis angezeigt. Gleiches gilt für Restart-Aufrufe — ein gescheiterter Restart belässt das Deployment in seinem alten Zustand und meldet den Fehler zurück.


## 2026-04-21

- **Neues Lizenzsystem** — ThinForge unterstützt jetzt ein Lizenzsystem:
  - **Free-Tier bis 50 aktive Geräte** ohne Lizenzschlüssel — voller Funktionsumfang, keine Einschränkung der Bedienung.
  - Lizenzschlüssel werden als signiertes, verschlüsseltes Bundle geliefert und im neuen Tab „Einstellungen → Lizenzierung" hochgeladen.
  - Bei Überschreitung des lizenzierten Geräte-Limits werden **neue** Geräte-Registrierungen abgewiesen (HTTP 403); bereits registrierte Geräte laufen unbeeinträchtigt weiter.
  - Nach Ablauf der Lizenz gibt es eine **60-Tage-Karenzzeit**, danach Rückfall auf den Free-Tier.
  - Limit-Prüfungen greifen sowohl bei der einzelnen Anlage als auch beim CSV-Bulk-Import.

- **Setup-Wizard wird nicht mehr automatisch erzwungen** — Der Setup-Wizard wurde bisher bei jedem Seitenaufruf automatisch erzwungen, wenn das Backend ihn als „nicht abgeschlossen" meldete. Kombiniert mit dem unten beschriebenen Datenbank-Persistenz-Problem konnte das ungewollt Produktionsdaten überschreiben. Der Auto-Redirect ist entfernt; `/setup` bleibt weiterhin manuell aufrufbar.

- **Dashboard: Festplatten-Belegung wird wieder korrekt angezeigt** — Nach der Umstellung des Backend-Images auf Alpine wurde die Festplatten-Belegung auf dem Dashboard mit Nullwerten angezeigt — der intern verwendete `df`-Befehl unterstützte ein bestimmtes Optionsformat in der schlankeren Alpine-Variante nicht. Auf das portable Format umgestellt; die Werte werden wieder korrekt angezeigt.

- **Klone wiederherstellen: Größen-Anzeige stimmt mit Quelle überein** — Beim Wiederherstellen eines Hardware-basierten Basis-Klons (aufgenommen über die Tools-ISO) wurde die Ziel-Festplatte fälschlich auf 60 GB voreingestellt, obwohl die echte Disk-Größe in den Klon-Metadaten lag — die qcow2 passte dann nicht zur Partitionstabelle der Quelle. Sowohl die UI-Anzeige als auch die tatsächliche Erstellung greifen jetzt zuerst auf die echte Disk-Größe aus dem Klon zurück.

- **Datenbank-Persistenz korrigiert (Wichtig)** — Nach einem `rebuild.sh --no-cache` oder einem `docker volume prune` war die Datenbank leer und der Setup-Wizard lief erneut. Ursache: die Postgres-Daten landeten in einem anonymen Docker-Volume statt im sichtbar gemounteten Datenverzeichnis — der explizite Bind-Mount verwies auf den falschen Pfad innerhalb des Postgres-Images. Korrigiert: Daten liegen jetzt unter `ThinForgeDaten/postgres/pgdata/` und überleben Container-Neuanlagen.

  **Migration bestehender Installationen:** Die Daten müssen einmalig aus dem anonymen Docker-Volume in das neue Verzeichnis kopiert werden, Eigentümer wechseln auf den Postgres-Container-User, dann Postgres neu starten. Bei Bedarf melden, wir machen das gemeinsam — ohne diesen Schritt entstehen sonst beim nächsten harten Neuaufbau Datenverluste.

- **Sicherheits-Befunde werden präziser nach Erreichbarkeit gefiltert** — Die Schwachstellen-Übersicht unterscheidet jetzt strikt zwischen:
  - **Nicht betroffen** (Erreichbarkeits-Filter — z.B. Container ist isoliert, der Angriffsvektor erfordert Netzwerk-Zugriff, den der Container gar nicht hat) und
  - **Betroffen, aber als akzeptiert markiert** (bewusste Entscheidung, z.B. wartender Upstream-Fix).

  In der Übersicht steht pro Image und Schweregrad die ursprüngliche Zahl als durchgestrichener Wert daneben die tatsächlich relevante Zahl. Ein kleines Symbol pro Zeile zeigt die Erreichbarkeit (LAN / intern / isoliert). Im Detail-Popup ist die Aufschlüsselung pro Angriffsvektor sichtbar. Die Bewertung erfolgt vollständig vom System; die Akzeptanz-Liste lässt sich optional auch von einer externen Quelle abgleichen (zukünftiger Anwendungsfall).


## 2026-04-20

- **Dienste-Panel: wird automatisch aus der Compose-Konfiguration aufgebaut** — Welche Container im Dienste-Panel auftauchen, wird jetzt direkt aus der `docker-compose.yml` ermittelt. Anzeige-Name, Icon, „kritisch"- und „bei Bedarf"-Markierung kommen über Labels am Container — neue Dienste tauchen automatisch auf, sobald sie in der Compose-Datei eingetragen sind, ohne Backend-Code-Änderung. Welche profil-basierten Dienste angezeigt werden (z.B. Netzwerk, Monitoring) lässt sich per Umgebungsvariable steuern; der Standardwert deckt das übliche Deployment ab.

- **Sicherheits-Scan: Container-Basis-Images aktualisiert** — Erste Vorbereitungs-Runde für das umfassendere Schwachstellen-Audit (Folgetag): externe Image-Tags werden flexibler verwaltet, kritische Python-Bibliotheken im Cloning-VM-Image werden auf gefixte Versionen angehoben. Die Akzeptanzliste der bekannten, dauerhaft akzeptierten Befunde wurde substantiell ausgebaut (Caddy, OVMF/edk2, QEMU, Sqlite, Glib u.a.).

- **Backend-Container auf schlankere Basis umgestellt (Alpine)** — Der Backend-Container basiert jetzt auf einer schlankeren Linux-Distribution (Alpine 3.22 statt Debian) — Image-Größe sinkt um rund ein Drittel (691 MB → 497 MB). Alle weiteren ThinForge-Container nutzen damit dieselbe Basis. Funktional unverändert.

- **Komplette Ablösung des alten Python-Backends** — Der bisher noch im Repository liegende Python/FastAPI-Backend-Baum ist endgültig entfernt — der Rust-Nachfolger ist seit längerer Zeit der einzige produktive Stack. Damit verbunden: die alte Produktions-Compose-Variante (`docker-compose.prod.yml`) und ein paar tote Skripte sind ebenfalls weggeräumt. Bedienung und Funktionsumfang ändern sich nicht.

- **Monitoring (Prometheus, Grafana) und Ansible-Runner (Semaphore) abgeschaltet** — Prometheus, Grafana und Semaphore werden in allen Compose-Varianten ausgeschaltet — sie wurden im laufenden Betrieb nicht regulär genutzt, und das Semaphore-Image trug zudem viele kritische Schwachstellen, die nicht aus eigener Hand zu fixen waren. Die Datenverzeichnisse bleiben unangetastet, eine spätere Reaktivierung ist jederzeit möglich. Im UI war Semaphore bereits seit längerem ausgeblendet.

- **Vulnerability-Scan: nur noch über UI auslösbar, läuft komplett im Backend** — Der Schwachstellen-Scan läuft jetzt vollständig vom Backend aus — kein zusätzliches Setup auf dem Host nötig. Der einzige Auslöse-Weg ist der „Scan starten"-Knopf im Sicherheits-Tab. Damit ist der Zustand der Scan-Daten konsistent und Erst-Installationen werden einfacher.


## 2026-04-19

- **Speicher-Aufräumen: BitTorrent-Daten und alte Scan-Ergebnisse werden mitgeräumt** — Das interne Aufräum-Skript räumt jetzt zusätzlich verwaiste BitTorrent-Hilfsdaten aus dem Speicher-Verzeichnis (mehrere GB können sich nach einem Datenbank-Reset ansammeln) und entfernt verlegte Schwachstellen-Scan-Verzeichnisse aus dem alten Projektpfad — beides geschah bisher nicht automatisch.

- **Container-Basis: vollständige Umstellung auf Alpine 3.22** — Alle ThinForge-Container (BitTorrent-Seeder, Cloner, dnsmasq, Multicast-Sender, Cloning-VM sowie Chrony/NFS/WireGuard) wurden auf die schlankere Linux-Distribution Alpine 3.22 umgestellt. Effekt: Deutlich kleinere Image-Größen (z.B. Cloner 200 → 86 MB, Multicast-Sender 138 → 25 MB, BT-Seeder ~700 → 242 MB). Funktional unverändert. Außerdem wurde die Go-Toolchain für den Agent aktualisiert, was alle bekannten Go-Standardbibliotheks-Schwachstellen im Agent-Binary mit-fixt.

- **Schwachstellen-Scan: Daten liegen im zentralen Datenverzeichnis** — Die Ergebnisse der Schwachstellen-Scans wurden bisher direkt im Projekt-Verzeichnis abgelegt — passte nicht zur Konvention, dass alle Laufzeitdaten unter dem zentralen Datenverzeichnis liegen. Die Scan-Ausgabe ist umgezogen, und es wird jetzt automatisch beim Start eines neuen Scans aufgeräumt (verhindert das beobachtete Wachstum auf mehrere GB). Bedienung unverändert.

- **Frontend: Bibliotheks-Updates (Sicherheit)** — Mehrere Frontend-Bibliotheken (axios, vue, vuetify, MDI-Font, pinia, vue-router, vue-i18n, jsbarcode, sass) auf neuere Patch-Versionen angehoben, in denen bekannte Sicherheits-Befunde behoben sind. Größere Versionssprünge sind bewusst zurückgestellt, um zusätzliche Testarbeit zu vermeiden.

- **Reverse-Proxy-Konfiguration: eine einzige Quelle** — Bisher konnte die Reverse-Proxy-Konfiguration von drei verschiedenen Stellen geschrieben werden — zwei davon waren abgespeckte Varianten ohne die nötigen PXE-Pfade. Wer nach einem Re-Build den Setup-Wizard durchlief oder das TLS-Zertifikat neu generierte, bekam stillschweigend die kaputte Variante; PXE-Clients verfingen sich dann an einer fehlerhaften HTTPS-Umleitung und brachen mit „BOOT FAILED!" ab.

  Behoben: Die Reverse-Proxy-Konfiguration kommt jetzt aus genau einer Datei im Repository, wird wie Code reviewt und beim Setup unverändert übernommen. Setup-Wizard und Zertifikats-Generierung schreiben sie nicht mehr selbst. Der „Zertifikat entfernen"-Knopf ist entfernt — TLS ist immer aktiv.

- **Deployments-Tab: BitTorrent-Vorbereitungs-Phase ist sichtbar** — Bei einem BitTorrent-Deployment war der Status-Chip kurz auf „aktiv" gesprungen, obwohl der Seeder noch in der Vorbereitung war (Daten extrahieren, Torrents erzeugen, Tracker starten) — das hat im UI geflackert. Jetzt zeigt der Status sauber „Vorbereitung…" mit orangenem Balken, bis der Seeder wirklich verteilt; danach Wechsel auf „Aktiv".

- **PXE-Auslieferung: über den zentralen Reverse-Proxy statt Hilfs-Webserver** — Die Auslieferung der PXE-Boot-Dateien an die Client-Geräte (insbesondere die ~400 MB große `filesystem.squashfs`) lief bisher über einen kleinen Hilfs-Webserver im DNS/DHCP-Container, der pro Verbindung einen neuen Prozess startete — bei 100+ parallel bootenden Geräten ein realer Engpass. Jetzt übernimmt der zentrale Reverse-Proxy diese Auslieferung effizient asynchron mit Kernel-Optimierungen; bei wiederholten Zugriffen liegt das Image bereits im RAM-Cache des Servers (im Test 50 parallele Anfragen in 35 ms). Der Hilfs-Webserver im DNS/DHCP-Container ist im Folge-Schritt komplett entfernt; der Container kümmert sich nur noch um DHCP und TFTP.

- **BitTorrent-Deployment: Torrent-Dateien werden für Clients sichtbar abgelegt** — Beim ersten erfolgreichen End-to-End-BitTorrent-Deployment bekam jeder Client beim Abruf der Torrent-Datei einen „404 nicht gefunden" — der Seeder schrieb sie in ein anderes Verzeichnis als das, was die Clients über den Webserver abriefen. Es gibt jetzt eine Spiegelung in das richtige Verzeichnis; nach Ende des Deployments werden die Dateien automatisch wieder weggeräumt.

- **Sicherheit: neuer SBOM-Download im UI** — Im Sicherheits-Bereich gibt es einen neuen Sub-Tab „SBOM-Download". Er listet alle vorhandenen Scan-Läufe (mit Zeitstempel) und bietet pro Lauf die drei Standard-Software-Bestandslisten (Syft, CycloneDX, SPDX) zum Download an — wahlweise einzelne JSON-Datei pro Container oder das komplette Verzeichnis als Archiv. Damit lassen sich Software-Bestandslisten ohne Server-Zugriff erzeugen.


## 2026-04-18

- **Agent v2.5.3: TLS-Zertifikat-Sync + Re-Installations-Verbesserungen** — Mehrere Verbesserungen am Agent rund um Vertrauen und Re-Installation:

  - **Server-TLS-Zertifikat wird auf den Clients automatisch aktualisiert.** Der Agent zieht das Zertifikat jetzt regelmäßig vom Server und schreibt es in sein lokales Vertrauens-Verzeichnis. Damit wirken Zertifikats-Rotationen ohne erneutes Provisionieren aller Geräte.
  - **Re-Installations-Aufgaben spielen auch Vertrauens-Dateien aus.** Bei einer Re-Installation pusht der Server jetzt zusätzlich zum Agent-Binary auch Server-Zertifikat, Signing-Schlüssel und Heartbeat-Token mit — der Agent ist sofort einsatzbereit, ohne auf den nächsten Sync warten zu müssen.
  - **Pakete-Installation aus der Agent-Startsequenz entfernt.** Wenn ein Provisionierungs-Skript wegen langsamer Paket-Installation hängte (z.B. ohne Internet), blockierte das den gesamten Heartbeat-Loop. Pakete gehören in den initialen Image-Build, nicht in den laufenden Agent-Start; das ist jetzt sauber getrennt.
  - **Robusteres Timeout-Verhalten bei Unterprozessen.** Beim Abbruch eines Skripts werden jetzt zuverlässig alle Kind-Prozesse beendet — Hänger durch versteckte langlaufende Unterprozesse sind ausgeschlossen.

- **Cloning-VM: Fortschritts-Anzeige beim Klonen wieder live** — Beim Erstellen eines Klons stand die Fortschritts-Anzeige minutenlang bei 0 % und sprang dann direkt auf 100 % — kein Live-Feedback. Der Backend-Service liest jetzt während des Vorgangs einen kleinen Status-Indikator aus und spielt den Fortschritt prozentual ans UI weiter, analog zum Wiederherstellungs-Ablauf.

- **DHCP-/NFS-Authorisierung: jetzt strikt per IP, ohne Token-Pflicht** — Die Authentifizierung der internen DHCP-Lease-Meldungen läuft jetzt rein über die Netzwerk-Topologie — der bisherige Shared-Secret-Token ist wieder entfernt:
  - Backend hört nur noch auf der lokalen Loopback-Adresse (nicht vom LAN erreichbar).
  - Der Reverse-Proxy blockt den DHCP-Endpunkt explizit von außen.
  - Der DNS/DHCP-Container kann das Backend ausschließlich über Loopback ansprechen.

  Damit erübrigt sich die Token-Verwaltung — Sicherheit kommt aus der Topologie.

  Gleichzeitig wurde der Reverse-Proxy für PXE-Callbacks repariert: Stuck-Multicast-Deployments aus der Vergangenheit, deren Callbacks ins Leere liefen, funktionieren jetzt wieder.

- **Sicherheits-Audit: kritische Befunde behoben** — Aus dem internen Sicherheits-Audit wurden mehrere kritische Befunde geschlossen:

  - **Heartbeat-Token-Endpunkt war öffentlich zugänglich.** Jeder im LAN konnte den geteilten Client-Authentifizierungs-Token unauthentifiziert abrufen. Endpunkt entfernt — die Tools-ISO und die Klon-Images sind die offiziellen Provisionierungs-Quellen.
  - **Callback-Tokens bei Klon-Deployments wurden unter bestimmten Bedingungen übersprungen.** Ein leerer oder fehlender Token wurde behandelt wie „kein Token nötig". Validierung ist jetzt strikt — kein Token, kein Zugriff (403).
  - **Setup-Wizard-Wiederherstellungs-Pfade nach Setup-Abschluss gesperrt.** Nach abgeschlossenem Setup gehen Wiederherstellungs-Operationen nur noch über den authentifizierten Admin-Pfad im Backup-Tab.
  - **TOFU-Fallbacks im Agent entfernt.** Der Agent verweigert jetzt den Start, wenn das Server-Zertifikat oder der Signing-Schlüssel lokal fehlt — statt stillschweigend einen vom Server vorgeschlagenen Wert zu akzeptieren. Vertrauensanker kommen ausschließlich über die Tools-ISO bzw. das Klon-Image.
  - **Backend und alle Admin-Werkzeuge nur noch auf Loopback gebunden.** Der Reverse-Proxy (Caddy) ist die einzige Schnittstelle zum LAN. Admin-Werkzeuge wie Grafana, Prometheus, Semaphore sind nur über SSH-Tunnel erreichbar.
  - **Schutz gegen XSS im Changelog-Dialog.** Der gerenderte Markdown wird vor der Anzeige durch einen HTML-Sanitizer geschickt; ein potenzieller XSS-Pfad ist damit geschlossen.
  - **`curl`-basierter Bootstrap-Modus aus den Installations-Skripten entfernt.** Die Tools-ISO ist die alleinige Quelle.

  Pflicht-Rebuild von Backend-Container, Agent-Binary und Tools-ISO. Audit-Details intern dokumentiert.

- **Sicherheits-Audit: weitere Härtungen (Folge-Bundle)** — Aus dem gleichen Audit (Schweregrad „hoch"):

  - **Rate-Limit auf Login-/Auth-Endpunkten.** Die Authentifizierungs-Endpunkte sind jetzt auf eine sinnvolle Rate begrenzt (5 Anfragen/Sekunde mit kurzem Burst-Spielraum). Hinweis: Da der Reverse-Proxy davor steht, teilen sich aktuell alle LAN-Clients eine gemeinsame Quote; eine echte Per-IP-Begrenzung folgt später.
  - **Ausgeloggte Access-Tokens werden direkt gesperrt.** Bisher blieb ein gestohlener Access-Token bis zu 15 Minuten nach dem Logout gültig. Jetzt wird er bei Logout sofort in eine Sperrliste eingetragen und blockiert.
  - **Semaphore-Admin-Passwort kommt aus einer generierten Umgebungsvariable.** Das vorher hartcodierte Standard-Passwort ist weg; bei der ersten Erstellung der `.env`-Datei wird ein sicheres Zufalls-Passwort generiert.
  - **NFS-Freigaben strikt per Client-IP** statt subnet-weit. Wenn keine Client-IPs bekannt sind, wird die Freigabe weggelassen (deny-by-default).

- **NFS-Freigaben kommen erst beim tatsächlichen Boot** — Bisher wurden NFS-Freigaben für anstehende Aufgaben „prophylaktisch" über das gesamte Subnetz angelegt. Jetzt:
  - Jeder Client bekommt direkt beim Anlegen eine reservierte IP-Adresse aus dem DHCP-Pool zugewiesen.
  - Bei jedem realen DHCP-Lease-Event meldet der DHCP-Server das Backend; das Backend prüft, ob für den Client gerade eine Aufgabe (Capture, Deployment, Update) anliegt, und schaltet die passende NFS-Freigabe just-in-time auf genau diese IP frei.

  Damit ist keine NFS-Freigabe mehr „auf Vorrat" offen — sie entstehen punktgenau zum Zeitpunkt, an dem der Client sie braucht.

  Zusätzlich: Beim erneuten Exportieren der NFS-Freigaben wird der Container nicht mehr automatisch hart neugestartet — das hätte laufende Übertragungen abgebrochen. Stattdessen wird der Fehler protokolliert; der Operator entscheidet bei Bedarf manuell.


## 2026-04-17

- **BitTorrent-Daten: eigenes Unterverzeichnis im Speicher** — Die BitTorrent-Hilfsdaten für Klon-Verteilungen liegen jetzt in einem eigenen Unterordner `ThinForgeDaten/bittorrent/` statt vermischt mit den PXE-Boot-Dateien. Sauberere Trennung; nichts an der Bedienung ändert sich.

- **VPN-Remote: Schutz gegen versehentliches Löschen des Hauptservers** — Im RemoteSync-Bereich gab es einen „Löschen"-Knopf für jeden Peer auf dem VPN-Server — inklusive des eigenen Servers (MainServer). Ein Klick darauf hätte die eigene Verbindung gekappt. Der Löschen-Knopf ist beim MainServer durch ein Schild-Icon mit Tooltip ersetzt; das Backend lehnt einen Löschversuch zusätzlich ab.

- **Navigation: „Automation"-Eintrag in der Seitenleiste ausgeblendet** — Der „Automation"-Eintrag in der Seitenleiste ist ausgeblendet — passend zum Automation-Tab in der Client-Ansicht, der seit längerem nicht aktiv ist. Code bleibt erhalten für spätere Reaktivierung.

- **Clients-Tab: Refresh-Knopf in der Filterzeile** — Ganz rechts in der Filter-Zeile der Client-Liste gibt es jetzt einen kleinen Refresh-Knopf, mit dem sich die Liste manuell aktualisieren lässt. Die automatische Aktualisierung im Hintergrund läuft unverändert weiter.

- **Cloning-Tab: Info-Hinweis zum optimierten System** — Neben der Überschrift im Cloning-Tab gibt es jetzt ein Info-Icon mit Tooltip: „System ist für Debian/Manjaro XFCE optimiert, für produktive Systeme minimale Installation empfohlen."

- **Heartbeat-Intervall der Agents zentral einstellbar** — Wie oft die Agents auf den Geräten sich beim Server melden (Heartbeat-Intervall) lässt sich jetzt im Agent-Tab zentral einstellen (Bereich 10–3600 Sekunden). Die Geräte übernehmen den neuen Wert beim nächsten Heartbeat automatisch.

- **Signaturen: „Signieren"-Knopf im Agent-Tab + Rotation umfasst Agent-Binary** — Im Agent-Tab steht jetzt neben dem Upload-Knopf ein dedizierter „Signieren"-Knopf, der gezielt nur das Agent-Binary signiert. Label und Farbe passen sich an (gelb, wenn unsigniert, grün, wenn bereits signiert).

  Außerdem: Bei einer Rotation des Signing-Schlüssels wird das Agent-Binary jetzt automatisch mit-signiert. Bisher konnte das Binary nach einer Rotation mit veralteter Signatur liegenbleiben, sodass das Selbst-Update des Agents stumm fehlgeschlagen wäre. Im Signatur-Status sind außerdem Anwesenheit und Versionsstand des Agent-Binarys ablesbar.

- **Geräte-Hostname auf Clients: einheitliches „TF-<MAC>"-Format** — Der Agent setzt den OS-Hostnamen auf den Geräten jetzt einheitlich auf „TF-<MAC>" (aus der physischen LAN-MAC-Adresse abgeleitet, z.B. „TF-AABBCCDDEEFF"). Der kanonische Name liegt im Daten-Verzeichnis des Geräts und überlebt Updates; der Agent setzt den Hostnamen nach jedem Update neu. Wechselt die Hardware-MAC (z.B. NIC-Tausch), bleibt der gespeicherte Name stabil und der Agent meldet das als „MAC geändert"-Alarm an den Server. Bestehende Geräte mit altem „PC-<MAC>"-Namen werden automatisch beim nächsten Schema-Update umbenannt.

- **VPN: TPM-versiegelte WireGuard-Schlüssel (Erstversion)** — Auf Geräten mit TPM 2.0 wird der private WireGuard-Schlüssel jetzt im TPM versiegelt — Klartext existiert nur kurzzeitig im RAM während des Tunnel-Aufbaus. Damit ist der VPN-Schlüssel gegen Diebstahl der Festplatte deutlich besser geschützt.

  Der Agent kümmert sich selbst um Versiegelung, Aufhebung und das Nachinstallieren der TPM-Werkzeuge — gesteuert über den Heartbeat. Geräte ohne TPM-Hardware laufen wie bisher mit dem unversiegelten Schlüssel und werden im UI mit einem Warn-Symbol markiert.

  Bewusst ausgeschlossen in dieser ersten Ausbaustufe: PCR-Bindung (würde aufwändige Wiederherstellungs-Prozesse erfordern) und LUKS-Festplattenverschlüsselung (separates Konzept).

- **Sicherheits-Tab: neues Vulnerability-Scan-Panel mit Live-Trigger** — Im Sicherheits-Tab gibt es jetzt einen direkten Schwachstellen-Scan im UI:
  - Pro Container-Image die Anzahl der Befunde nach Schweregrad.
  - Aufklappbar pro Image mit CVE-Liste, Fix-Status und betroffenem Paket; CVE-IDs verlinken zur NVD-Datenbank.
  - „Scan starten"-Knopf löst direkt aus dem UI einen neuen Scan aus. Der Fortschritt wird angezeigt; nach Abschluss wird die Tabelle automatisch neu geladen. Nur ein Scan gleichzeitig.

- **Datenbank-Migrationen zusammengeführt** — Mehrere inkrementelle Schema-Erweiterungen der letzten Tage (Rechnungs-Felder, TPM-Statusfelder, Hostnamen-Umbenennung, neue Alarm-Kategorie) sind in die ursprüngliche Schema-Datei zusammengeführt. Fresh-Installationen laufen damit in einer Transaktion durch. Bestehende Datenbanken sind schon auf dem aktuellen Stand — kein Eingriff nötig.


## 2026-04-16

- **Geräte: neue Felder „Rechnungsnummer" und „Lieferant"** — Pro Gerät lassen sich jetzt eine Rechnungsnummer und ein Lieferant erfassen. Beide Felder sind optional, sichtbar im Geräte-Detail (unter den Garantie-Feldern) und im Anlege-Formular. Beim CSV-Import werden mehrere Spaltennamen akzeptiert; beim Export werden beide Spalten am Ende der Datei mit-exportiert. In der Geräte-Liste und der Garantie-Übersicht sind die Werte bewusst nicht sichtbar — sie dienen primär der Recherche im Garantiefall.

- **Gruppen: Untergruppe auf Wurzelebene zurücksetzen möglich** — Beim Bearbeiten einer Untergruppe konnte der Eltern-Bezug nicht entfernt werden — sie blieb in ihrer Hierarchie hängen. Jetzt akzeptiert das Speichern explizit „kein Eltern-Eintrag", die Gruppe wandert in die Wurzelebene. Gleicher Fix für das Beschreibungs-Feld.

- **Setup-Wizard: Backend und Worker werden nach Abschluss neu gestartet** — Nach dem Setup-Wizard wurde nur der Reverse-Proxy neu gestartet — Backend und Worker liefen weiter mit den noch nicht vorhandenen Schlüsseln, bis der Operator manuell eingriff. Jetzt werden beide automatisch wenige Sekunden nach dem Wizard-Ende neu gestartet und lesen die frisch erzeugten Schlüssel und Tokens sauber ein.

- **Klone-Baum: Selbst-Reparatur und klarere Baum-Darstellung** — Wenn ein Klon als „Eltern" eines anderen Klons gelöscht wurde, blieb der verwaiste Verweis als kaputter Baum-Pfad hängen. Das System erkennt das jetzt automatisch und repariert den Baum: pro Versionslinie wird die kleinste Version zur Basis, alles andere hängt darunter. Außerdem sind im Klone-Tab jetzt klassische Baumzeichen (`├─` und `└─`) zu sehen, die die Verzweigungen besser erkennen lassen.

- **Client-Installation: Tools-ISO wird auch bei KDE-Auto-Mount gefunden** — Auf manchen Linux-Desktops (insbesondere KDE auf Debian) wird die Tools-ISO automatisch unter `/media/$USER/THINFORGE_TOOLS` eingehängt — dieser Pfad fehlte in der Suchliste der Installations-Skripte. Folge: Die Agent-Installation wurde stumm übersprungen, das Gerät kam halb-installiert hoch. Pfad ergänzt — die Installation läuft jetzt auch auf KDE-Hosts zuverlässig durch.

- **PXE-Server-IP lässt sich zur Laufzeit ändern** — Wer im Setup-Wizard zuerst eine teilweise Konfiguration mit leerer Rollout-IP speicherte und später nachreichte, bekam einen stehenbleibenden Cache mit leerer IP — jedes Klon-Deployment wurde danach mit kryptischer Fehlermeldung verworfen, bis das Backend neu gestartet wurde. Behoben: Die IP lässt sich zur Laufzeit aktualisieren, leere Werte werden ignoriert und mit einem Hinweis im Log markiert. Beim Backend-Start gibt es zusätzlich eine deutliche Warnung, falls noch keine IP gesetzt ist.

- **Worker-Gesundheitsprüfung wirkt jetzt tatsächlich** — Die Gesundheitsprüfung des Worker-Containers war seit ihrer Einführung dauerhaft auf „ungesund", weil sie auf eine Datei prüfte, die niemand schrieb. Der Worker meldet seine Lebendigkeit jetzt durch regelmäßiges Berühren einer Marker-Datei; bleibt die Datei länger als eine Minute alt, schaltet der Container auf „ungesund" — echter Liveness-Indikator statt Dauer-Falschmeldung.


## 2026-04-14

- **ISO-Download: zuverlässiger und speichersparender** — Beim Download eines ISO-Image konnte es vorkommen, dass bei Mirror-Servern mit mehreren A/AAAA-Records die Adressauflösung intern fehlschlug — der Download brach ab. Behoben. Außerdem: Das Image wird jetzt direkt während des Downloads auf die Festplatte gestreamt, statt komplett im RAM zwischengespeichert. Bei mehreren GB Image entlastet das den Server-Speicher; der Fortschrittsbalken aktualisiert sich live, statt am Ende auf 100 % zu springen. Bei Fehlern werden Teil-Dateien sauber weggeräumt.

- **Dashboard: bedarfsgesteuerte Container werden nicht mehr als Warnung angezeigt** — Cloning-Container, die nur bei Bedarf laufen (z.B. die Cloning-VM, der Cloner), wurden auf der Dashboard-Dienste-Karte als „nicht aktiv" — also unter den Warn-Einträgen — gelistet, obwohl ihr Stopzustand der Normalfall ist. Diese Container sind jetzt als bedarfsgesteuert markiert: in der Dienste-Karte erscheinen sie im Normal-Stopzustand nicht mehr als Warnung; im Dienste-Panel haben sie einen neutralen grauen Rahmen mit „On-Demand"-Markierung statt rotem Fehler-Look. Unerwartete Zustände (z.B. „neustartend" oder „pausiert") werden weiterhin angezeigt.

- **Changelog-Anzeige im UI wieder funktional** — Beim Klick auf die Versionsnummer rechts oben in der Kopfleiste zeigte das System „No changelog available." statt der Änderungsliste — die Datei lag nicht im Backend-Image. Behoben: Der Changelog wird beim Build des Backend-Images mit eingepackt und ist im UI direkt sichtbar.


## 2026-04-13

- **VPN: erste vollständige Funktion (Statistiken, Deploy, Status, Restore)** — Großer Funktions-Schub rund um den VPN-Bereich:
  - **Traffic-Statistiken pro Client** als neuer Tab mit Übertragungs-Daten und resilientem Sync.
  - **VPN-Deploy / -Undeploy** sind jetzt durchgängig funktional: Client-Anlegen, Deploy-Knopf, automatischer Tunnel-Neustart nach Konfigurations-Push, Undeploy-Job bei Client-Deaktivierung.
  - **Detaillierte VPN-Status-Chips** in der Client-Tabelle.
  - **Tunnel wird nach einem Delta-Update wieder hergestellt** (Skript robust gemacht, mit Deploy-Verifikation).
  - **VPN-Erkennung im Agent korrigiert** (prüft das richtige Interface und die tatsächliche Route).
  - **Monatliche Fehler-Toasts unterdrückt** (regelmäßige „Statistiken noch nicht da"-404er sind kein Fehler).

  Agent v2.5.2 + v2.5.3 begleiten den Schub.

- **Netzwerk: lokales Netzwerk im UI konfigurierbar, dnsmasq pflegt eigene Domain** — Im Netzwerk-Bereich gibt es jetzt einen Tab „Lokales Netzwerk", in dem die Server-Schnittstelle konfiguriert wird. Die PXE-Server-IP kommt nicht mehr aus der `.env`-Datei, sondern direkt aus der Datenbank (Fallback ist die Gateway-IP). Der Setup-Wizard pflegt zusätzlich eine lokale Domain für den internen DNS-Server, und die Auflösung externer Adressen läuft über das Management-Gateway statt einer fest hinterlegten externen Adresse.

- **Werksreset: vollständig statt selektiv** — Der Werksreset hat sieben Tabellen rund um Update-Rollouts und Rollback-Aufgaben bisher nicht zurückgesetzt. Statt einer manuellen Liste löscht der Reset jetzt **alle** Tabellen dynamisch — bleibt damit auch bei späteren Schema-Erweiterungen automatisch konsistent. Zusätzlich werden Redis-Caches geleert (Token-Sperrliste, Rate-Limiter, Session-Daten) und das komplette Storage-Verzeichnis bereinigt.

  Außerdem: Der Server-Schlüssel wird beim ersten Start automatisch erzeugt und gespeichert (kein manuelles Setzen in der `.env`-Datei mehr nötig). Beim Werksreset wird er mit gelöscht und beim nächsten Start frisch generiert; Backup/Restore stellt ihn wieder her.

- **Diverse kleinere Korrekturen** — - **PXE-Konfiguration eines Geräts wird beim Löschen sauber aufgeräumt** (war zuvor stehengeblieben).
  - **VM-Einstellungen werden beim Klon-Capture korrekt mit übernommen** (der 64-GB-Default-Bug ist gefixt).
  - **Setup-Skript für Server-Voraussetzungen** läuft ohne doppelte Variablen-Definitionen, Zeitzone wird auf Berlin gesetzt; veraltete „Edit .env"-Hinweise sind entfernt (Schlüssel werden automatisch erzeugt).
  - **Zeitzonen-Einstellung aus dem UI entfernt** — wirkte aus dem Container nicht auf das Host-System; Zeitzone wird auf dem Host konfiguriert.
  - **Logs-Ansicht zeigt drei zusätzliche Container** (Semaphore, Cloning-VM, Cloner), die bisher fehlten.
  - **Interne Daten-Migrationen** sind zur Übersichtlichkeit in einer Datei zusammengeführt.


## 2026-04-12

- **Backup-System: Validieren und Wiederherstellen funktional** — Backup-Archive können jetzt vor dem Restore validiert und vollständig wiederhergestellt werden. Das Archiv-Format umfasst das Manifest, alle Konfigurationsverzeichnisse (SSH, VPN, dnsmasq, NFS, Chrony, Reverse-Proxy, Signaturen), den Verschlüsselungs-Schlüssel sowie optional Images, Klone und Captures. Datenbank-Restore läuft über das Standard-Werkzeug; im Setup-Wizard sind die zugehörigen Pfade ebenfalls aktiv.

- **Wartungsfenster vollständig im neuen Backend** — Die 5 API-Endpunkte zur Verwaltung von Wartungsfenstern sind portiert — damit sind alle 41 API-Endpunkte vollständig im neuen Rust-Backend. Die separate `docker-compose.rust.yml`-Datei entfällt; `docker compose up -d` startet direkt das aktuelle Backend.

- **Klone werden nach Software-Deinstallation tatsächlich kleiner** — Nach dem Entfernen von Software in einem Klon-Snapshot blieben Klone gleich groß — die intern freigegebenen Datenblöcke waren beim Klon-Vorgang noch nicht final als „frei" registriert, das Klon-Werkzeug zählte sie weiter als belegt. Der Synchronisationsschritt wartet jetzt explizit ab — Klone werden nach Deinstallation auch tatsächlich kleiner.

- **Sicherheit: Signatur-Prüfung lehnt Updates ohne Schlüssel ab** — Wenn auf einem Gerät der lokale Signatur-Prüfschlüssel fehlte, akzeptierte der Agent Updates bisher stillschweigend. Jetzt lehnt er sie ab — fehlender Schlüssel ist ein Fehler, kein „durchwinken". Außerdem stürzt das Backend nicht mehr ab, wenn ein bestimmter Schlüssel-Pfad fehlerhaft ist; stattdessen wird ein sauberer Fehler zurückgegeben.

- **Stabilität: kein Server-Crash mehr bei internen Sperr-Konflikten** — Eine interne Klasse von Sperr-Mechanismen konnte bei einem Fehler den Server in einen nicht-wiederherstellbaren Zustand bringen („Mutex poison"). Diese Sperren sind durch eine robustere Variante ersetzt — der Server überlebt entsprechende Fehlerpfade jetzt ohne Crash. Zusätzlich: ein langsamer Anwendungs-Pfad in der Rollback-Verwaltung wurde von tausenden Datenbank-Abfragen auf eine einzige reduziert.

- **Interne Verbesserungen** — Globaler Timeout für API-Anfragen (30 Sekunden, mit Ausnahmen für absichtlich lange Operationen wie Backup oder Klon-Erstellung). Log-Rotation für Backend- und Worker-Container (50 MB pro Datei, 3 Dateien rolling). Größe des Datenbank-Verbindungspools über Umgebungsvariablen konfigurierbar. Automatischer Aufräum-Schritt für den Docker-Build-Cache nach jedem Re-Build. Fehler im Frontend, die intern bereits vom globalen Fehler-Mechanismus angezeigt werden, sind jetzt einheitlich und nachvollziehbar dokumentiert.


## 2026-04-11

- **NFS-Freigaben: Capture-Vorgänge funktionieren wieder, Aufräumen läuft korrekt** — Beim Start eines Klon-Aufnahme-Vorgangs (Capture) blieb die NFS-Freigabe für die Captures aus — Clonezilla meldete „Access denied NFS" und brach ab. Die Freigabe wird jetzt automatisch beim Capture-Start aktiviert und nach Abschluss des Rollouts wieder weggeräumt; Status der Freigaben überlebt Container-Neustarts. Außerdem: Der zugehörige Capture-Job wird korrekt in der Datenbank angelegt, sodass der Fortschritt im UI verfolgbar ist.

- **DNS-Vorschau im UI um die Hosts-Datei erweitert** — Das DNS-Panel zeigt jetzt neben der Haupt-Konfiguration auch die Datei mit den benutzerdefinierten DNS-Einträgen in der Vorschau an. Außerdem: Die DHCP-Konfigurations-Vorschau lädt jetzt sofort beim ersten Klick statt leer zu bleiben.

- **Sicherheit: Eingaben in Shell-Aufrufe gehärtet, ISO-Downloads gegen SSRF geschützt** — Eine ganze Klasse von Werten, die intern in Shell-Aufrufe oder PXE-Skripte fließt, wird jetzt streng validiert (zulässige Zeichen, max. Länge) — versehentlich oder bewusst manipulierte Eingaben können keine fremden Befehle einschleusen. Versions-Strings werden bereits beim API-Eintritt geprüft (saubere 400er-Meldung statt späteren Folge-Fehlern).

  Außerdem: Der Agent verwendet bei Self-Update und Skript-Download nicht mehr „TLS-Prüfung überspringen" als Notlösung, sondern besteht auf dem gepinnten Server-Zertifikat. Und der ISO-Download im Backend ist gegen sogenannte SSRF-Angriffe geschützt: DNS wird vorab aufgelöst, private Adressen werden geblockt, Umleitungen auf interne Hosts abgelehnt.

- **Agent-Verwaltung: „Re-Installieren"-Knopf** — Im Agent-Tab gibt es einen neuen Knopf „Re-Installieren" mit Auswahl-Dialog (alle / Gruppe / einzelne Geräte). Der Re-Install überspringt den Offline-Filter und schickt die Aufgabe sofort an die ausgewählten Geräte (kein Warten auf den nächsten Heartbeat). Derselbe Dialog kommt auch für reguläre Updates zum Einsatz.

- **Agent-Binary: korrekte Version wird ausgeliefert** — Der Endpoint, über den Geräte ihr Agent-Binary nachladen, lieferte fälschlicherweise eine alte Version aus dem Tools-ISO-Verzeichnis statt der aktuellen aus dem Build-Verzeichnis — die Folge war eine Endlos-Update-Schleife. Behoben: das aktuelle Build-Verzeichnis wird zuerst durchsucht. Außerdem: Wenn die IP eines Geräts nicht in der Datenbank steht, wird sie jetzt aus der DHCP-Lease-Datei abgeleitet, bevor auf den Hostnamen zurückgegriffen wird.

- **DNS / Docker-Container: Service-Auflösung repariert** — In der internen DNS-Konfiguration wurde ein falsches Feld gelesen, sodass AAAA-Anfragen (IPv6) für lokale Hostnamen an externe Server weitergeleitet wurden statt direkt mit „keine Daten" beantwortet zu werden — der Agent hing dadurch in Timeouts. Behoben.

  Außerdem: Backend und Worker hatten eine eigene DNS-Direktive, die Dockers internen DNS umging — Service-Namen wie `postgres` oder `redis` ließen sich nicht mehr auflösen, der Reverse-Proxy schlug auf die externe IP zurück und scheiterte. Die Direktive ist entfernt; die interne Auflösung funktioniert wieder.

- **Client-Migration: Avahi blockiert keine DNS-Anfragen mehr** — Der DNS-Resolver der Clients hatte Avahi (mDNS) in einer Reihenfolge eingehängt, die DNS-Anfragen blockierte. Ein Migrationsschritt im Agent stellt jetzt die Reihenfolge so um, dass DNS Vorrang hat.

- **BitTorrent-Deployment: korrekte Partitions-Anzahl im UI** — Beim BitTorrent-Deployment zeigte das UI die Partitions-Anzahl als 0, obwohl der Seeder bereits mehrere Torrents bereithielt. Der Wert wird jetzt korrekt vom Seeder mit-übermittelt und im UI angezeigt.

- **Cloning-VM: keine Race-Condition mehr zwischen Klon-Aufnahme und Update-Speichern** — Wenn ein Update gespeichert oder Deltas zusammengeführt werden sollten, während die Cloning-VM noch lief, kam es zu kryptischen Festplatten-Fehlern. Der Backend-Service prüft jetzt explizit, ob die VM noch läuft, und meldet eine klare Fehlermeldung statt eines verwirrenden internen Fehlers.

- **Setup-Wizard: Defaults, automatische DNS-/NTP-Befüllung, sichtbarer Countdown** — Der Setup-Wizard ist deutlich benutzungsfreundlicher geworden:

  - Admin-Konto und Domain sind sinnvoll vorbelegt; Passwort bleibt leer.
  - Upstream-DNS und DHCP-DNS-Server werden nicht mehr mit hartkodierten externen Adressen vorbelegt, sondern erst nach Auswahl des Netzwerk-Interfaces korrekt aus den erkannten Standards befüllt.
  - Upstream-NTP-Server und DHCP-Domain werden automatisch aus den vorigen Schritten übernommen.
  - Auf schmalen Bildschirmen ist das Layout aufgeräumter (kleinere Innenabstände).
  - Nach dem Setup-Abschluss läuft ein sichtbarer 10-Sekunden-Countdown mit Fortschritts-Ring, bevor der Wechsel auf HTTPS erfolgt — gibt dem Reverse-Proxy Zeit, das frische Zertifikat zu laden.

- **Diverse kleine Korrekturen** — - **Gruppen-Tab Datenbank-Fehler behoben** — Die Client-Liste einer Gruppe ließ sich wegen einer Konvertierungs-Inkompatibilität nicht laden; jetzt nutzt sie denselben sauberen Abfrage-Helper wie der Haupt-Tab.
  - **Agent-Tab öffnet sich wieder direkt per URL** (`?tab=agent` wurde in der Tab-Logik nicht zugelassen).
  - **Klon-Löschung nicht mehr durch laufende VM blockiert.** Die Warnung „VM läuft aktuell mit dieser Version" ist jetzt nur noch informativ — das Löschen ist möglich, ohne extra Bestätigungs-Checkbox.
  - **Agent-Build: Signatur-Schritt läuft sauber durch** (Berechtigungs-Problem auf dem Build-Verzeichnis behoben).


## 2026-04-10

- **Rollback-Funktion: vollständiger Abgleich mit dem bisherigen Backend** — Die Rollback-Funktion ist jetzt vollständig auf dem aktuellen Backend implementiert. Mehrere Folgefehler behoben:
  - Die UI-Route entsprach nicht dem Backend — der Rollback-Tab lud nicht.
  - Verschiedene Status-Werte hatten Format-Probleme in der Datenbank.
  - Eine Race-Condition beim Heartbeat führte dazu, dass Versionswechsel nicht erkannt wurden.
  - Rollback-Aufgaben werden automatisch als „abgeschlossen" markiert, sobald alle betroffenen Geräte fertig sind.
  - Bei gelöschten Geräten zeigt die Liste sauber „?" statt leere Felder.

- **Rollback: erkennt verfügbare Snapshots auf den Geräten** — Beim Rollback wird beim Boot ein beschreibbarer Schnappschuss des Home-Verzeichnisses der gewünschten Version erstellt, statt fest ein generisches Home zu mounten (das auf der falschen Version lag). Der Agent meldet im Heartbeat die auf dem Gerät verfügbaren Snapshots mit; im Rollback-Dialog kann man jetzt aus diesen statt nur aus der installierten Version wählen. Verwaiste temporäre Snapshots werden beim Update-Anwenden mit aufgeräumt.

- **Neuer Agent-Management-Tab** — Im Bereich Geräte gibt es einen neuen Tab „Agent":
  - **Upload-Knopf** für ein neues Agent-Binary; das System signiert es automatisch und liest die Versionsnummer aus.
  - **Update-Aufgabe** an alle Geräte mit veralteter Version; das Update wird beim nächsten Heartbeat per SSH eingespielt (stoppen, ersetzen, starten).
  - **Status-Anzeige** mit aggregiertem Fortschritt und Pro-Gerät-Status.
  - Neuer „Agent"-Eintrag in der Seitenleiste.

- **Klon und Delta werden korrekt miteinander verknüpft** — Wenn beim Speichern eines Updates auch ein Klon erzeugt wurde, wurde die Verknüpfung zwischen Klon und Delta in der Datenbank bisher nicht gesetzt. Jetzt ist die Verknüpfung sauber, und die Lösch-Analyse für einen Klon ist vollständig implementiert: Sie zeigt eingehende/ausgehende Deltas, Geräte auf dieser Version, aktive Roll-outs und VM-Status; das eigentliche Löschen respektiert das Löschen-Deltas-Flag, blockt bei aktiven Roll-outs und kann bei Bedarf einen Geräte-Rollback auslösen.

- **BitTorrent-Deployment: Seeder-Schlüssel wird erzeugt** — Beim Anlegen eines BitTorrent-Deployments wurde der interne Schlüssel für den Seeder-Container nicht erzeugt — der Container stürzte sofort ab. Schlüssel wird jetzt zuverlässig generiert; das Anlegen läuft sauber.


## 2026-04-09

- **Update-Roll-outs starten wieder zuverlässig** — Beim Anlegen eines neuen Update-Roll-outs (Delta-Verteilung) stürzte das Backend mit einem internen Typ-Fehler ab — Roll-outs ließen sich nicht starten. Die internen Status-Felder sind jetzt auf einer typsicheren Darstellung; der Fehler ist behoben. Außerdem: Ein Gerät, dessen Signatur-Prüfung scheitert, wird als Endzustand „Signatur fehlgeschlagen" gezählt — vorher hingen Roll-outs in solchen Fällen dauerhaft im Zustand „aktiv".

- **Schlüssel und Tokens liegen jetzt im Datenverzeichnis (nicht mehr im Repository)** — Mehrere Laufzeit-Schlüssel und Tokens (SSH-Schlüsselpaar, Heartbeat-Token, Signatur-Pubkey) sind aus dem Repository entfernt und werden ausschließlich im Datenverzeichnis verwaltet. Beim Start des Backends prüft das System die Schlüssel-Existenz und legt fehlende sofort an — der erste Heartbeat auf einem frischen System findet sofort einen gültigen Token vor.

  Bei einer halb-vorhandenen Schlüssel-Hälfte (z.B. nach einer Teil-Wiederherstellung) wird der Start mit klarer Fehlermeldung abgebrochen, statt stillschweigend einen neuen zu erzeugen und die auf den Geräten bereits provisionierte Hälfte zu überschreiben. Ein zuvor bestehender Pfad-Mismatch beim Heartbeat-Token (Lese-Pfad ≠ Schreib-Pfad) ist behoben — Heartbeats werden wieder akzeptiert.

- **Setup-Wizard erzeugt das Signatur-Schlüsselpaar automatisch** — Der Setup-Wizard erzeugt jetzt am Ende automatisch das Schlüsselpaar für die Update-Signatur und kopiert den öffentlichen Teil in die nächste Tools-ISO-Erzeugung. Voraussetzung: Das nötige Werkzeug ist jetzt fest im Backend-Image enthalten — vorher schlug das Signieren still fehl, weil das Programm fehlte.

- **TLS-Zertifikat: rotierbar im laufenden Betrieb** — Neuer Mechanismus für das Server-TLS-Zertifikat:
  - Der Signatur-Schlüssel der Tools-ISO ist die Vertrauens-Wurzel.
  - Das TLS-Zertifikat ist daraus delegiert und kann jederzeit rotiert werden.
  - Die Agents merken sich den Hash des aktuellen Zertifikats und schicken ihn im Heartbeat mit. Erkennt der Server ein veraltetes Zertifikat, schickt er das neue mit signiert mit; der Agent prüft die Signatur und tauscht das Zertifikat atomar aus.
  - Auf einem frisch installierten Gerät bzw. wenn der gepinnte Anker veraltet ist, läuft ein einmaliger Recovery-Pfad — die Signatur wird trotzdem verifiziert, ein Mann-in-der-Mitte kann kein gefälschtes Zertifikat einschleusen.

- **Cloning: Fortschritts-Anzeige beim Restore + persistente VM-Einstellungen** — Beim Restore eines Klons sprang die Fortschrittsanzeige bisher von 0 % direkt auf 100 %. Es gibt jetzt eine laufende Aktualisierung während des Restore-Vorgangs.

  Zusätzlich: RAM, CPU-Anzahl, Festplatten-Größe und Virtualisierungs-Beschleunigung der Cloning-VM werden nach einem erfolgreichen Start dauerhaft mit dem Klon gespeichert. Bisher gingen die Werte bei jedem Backend-Neustart oder Container-Neuaufbau verloren; jetzt überleben sie und greifen automatisch beim nächsten Restore.


- **Rust-Migration: Delta-Rollout-Bugfix + Tech-Debt-Refactor** — - **Typisierte sqlx-Enums fuer Update-Status** — `UpdateDelta`, `UpdateRollout`
    und `UpdateRolloutClient` nutzen jetzt ihre `sqlx::Type`-derived Rust-Enums
    (`UpdateDeltaStatus`, `UpdateRolloutStatus`, `UpdateRolloutClientStatus`)
    statt `String`-Feldern mit `status::text AS status`-Cast-Workaround. Der
    ungefixte `INSERT ... RETURNING *` in `create_rollout` hat bisher mit
    `"mismatched types; Rust type alloc::string::String is not compatible
    with SQL type updaterolloutstatus"` gecrashed. ~20 Touchpoints in 5
    Dateien; wire format unveraendert dank `#[serde(rename_all)]`.
  - **`SignatureFailed` als terminal Client-State** — Ein Client, dessen
    Signaturverifikation scheitert, wird nicht automatisch retryt und muss
    als Endzustand zaehlen. Vorher hat `is_terminal_client_status` die
    Variante ignoriert, wodurch `check_rollout_completion` bei solchen
    Clients nie `all_done = true` gesehen hat und Rollouts ewig auf `active`
    stecken geblieben sind.

- **Runtime-Secrets: komplette Umstellung auf /data (Weg A)** — - **Nichts mehr in git** — `provisioning_key.pub`, `heartbeat_token` und
    `thinforge.pub` sind aus `scripts/Tools-ISO/advanced/` entfernt und in
    `.gitignore` aufgenommen. Kanonischer Pfad fuer alle Runtime-Secrets ist
    jetzt `/data/ssh/` (SSH + Heartbeat-Token) und `/data/keys/` (Minisign).
  - **Eager-Init beim Backend-Boot** — `ensure_runtime_secrets()` in
    `lib.rs` ruft `ensure_heartbeat_token()` + `ensure_ssh_keypair()` direkt
    nach Config-Load auf. Keine Lazy-On-UI-Access-Pitfalls mehr: der erste
    Client-Heartbeat auf einem frischen System findet sofort einen gueltigen
    Token vor.
  - **`ensure_ssh_keypair` mit Guard-Klauseln** — Wenn nur eine Haelfte des
    Keypairs existiert (typisch nach Recovery oder Teilrestore) wirft die
    Funktion einen Error statt stumm zu regenerieren und dabei die vorher
    bei Clients provisionierte Pub-Key-Haelfte zu ueberschreiben.
  - **Heartbeat-Pfad-Drift gefixt** — `handlers/clients.rs:client_heartbeat`
    und `cloningvm_service.rs:rebuild_tools_iso` lasen aus unterschiedlichen
    Pfaden (`/data/ssh/heartbeat.token` vs `Tools-ISO/advanced/heartbeat_token`),
    wodurch jede Heartbeat-Request mit 403 rejected wurde. Beide Seiten
    nutzen jetzt `klon::heartbeat_token_path()`.

- **Setup-Wizard: automatische Minisign-Generation** — - **Wizard erzeugt Delta-Signing-Keypair** — `ensure_signing_keypair()` in
    `handlers/signing.rs` ist als pub(crate) exportiert und wird aus
    `complete_setup` aufgerufen. Der Tools-ISO-Rebuild beim Cloning-VM-Start
    kopiert den frischen `thinforge.pub` automatisch in die ISO, sodass
    Clients beim ersten Boot den richtigen Key per TOFU bekommen.
  - **`minisign` Paket im Backend-Image** — Dockerfile.rust installiert jetzt
    `minisign` in der Runtime-Stage. Vorher hat `ensure_signing_keypair` mit
    `"No such file or directory (os error 2)"` gewarnt und das Delta-Signing
    war komplett broken.

- **Cert-Rotation (neu, Plan in docs/todo/Rust-Todo.md)** — - **Minisign-signierte TLS-Cert-Rotation** — Neue Chain-of-Trust: der
    Minisign-Key ist Root-of-Trust (baked into Tools-ISO), der TLS-Cert ist
    delegiert und rotierbar. Clients pinnen `/data/thinforge/server.crt` und
    schicken dessen SHA-256 in jedem Heartbeat mit. Wenn der Server-Cert
    drifted, haengt der Backend eine `cert_update`-Payload (PEM + base64
    minisign-Signatur) an die Response. Agent verifiziert mit `minisign -V`
    gegen den lokalen `thinforge.pub` und swapt atomar.
  - **Bootstrap-Recovery** — Erste Heartbeat nach Fresh-Install oder wenn
    der gepinnte Cert stale ist: Fallback auf `InsecureSkipVerify` fuer
    genau diesen einen Request, um die signed cert_update zu empfangen.
    Die minisign-Signatur wird trotzdem validiert — ein MITM in der
    Fallback-Luecke kann keinen unsignierten Cert injizieren.
  - **Server-seitiger Sign-Cache** — `server.crt.minisig`-Sidecar wird nur
    neu erzeugt wenn `.crt` mtime sich aendert. Minisign-Subprocess laeuft
    maximal einmal pro Cert-Rotation, nicht einmal pro Heartbeat.
  - **`agent-go` TLS-Client umgebaut** — `buildHTTPClient(insecure bool)`
    mit `RootCAs` aus `config.TrustedCertPath`. `InsecureSkipVerify: true`
    ist nur noch in drei explizit scoped Faellen aktiv: Bootstrap (kein
    Cert vorhanden), Parse-Fehler, Rotation-Fallback.

- **Cloning: Restore-Progress-Bar + persistente VM-Settings** — - **Progress-Polling fuer Clone-Restore** — `run_restore_clone` spawnt
    einen tokio-Task, der den `restore-progress`-Sidecar alle 2s liest und
    `OPERATION_STATE.progress_pct` aktualisiert. Vorher sprang die UI-Bar
    direkt von 0% auf 100% beim Docker-Container-Exit. Mirror der
    Python-Referenz `clones_service._poll_progress`.
  - **VM-Settings persistieren beim VM-Start** — RAM, CPUs, Disk-Size und
    KVM-Flag werden nach erfolgreichem `cloningvm_service::start` in die
    `info.json` des Clones und in `.active-clone-settings` geschrieben.
    Vorher lebten die Werte nur in einer volatile in-memory `VMState` und
    setzten sich bei jedem Backend-Restart oder Container-Recreate zurueck.
    Restore liest `vm_settings` bereits aus `info.json`, also greift der
    persistierte Zustand beim naechsten Restore automatisch.


## 2026-04-07

- **Persönliche Einstellungen aus dem Admin-Bereich verschoben** — Passwort ändern und Zwei-Faktor-Authentifizierung (TOTP) sind aus dem Admin-Sicherheits-Tab in eine eigene Profil-Ansicht gewandert, erreichbar über das Account-Menü oben rechts. Damit haben alle Rollen (nicht nur Admin) ihre persönlichen Einstellungen an einer logischen Stelle. Der Sicherheits-Tab zeigt jetzt nur noch System-Themen (TLS, Remote Desktop, Update-Signatur).

- **Passwort-Reset per E-Mail und Admin-Reset** — Auf der Login-Seite gibt es „Passwort vergessen?" — schickt einen Reset-Link per E-Mail (15 Minuten gültig). Nur sichtbar, wenn der SMTP-Versand konfiguriert ist. Der Link ist mit dem aktuellen Passwort-Hash gekoppelt und damit automatisch ein Einmal-Link.

  Zusätzlich: Admins können in der Benutzerverwaltung Passwörter von Operator- und Viewer-Konten zurücksetzen sowie die Zwei-Faktor-Authentifizierung für einzelne Benutzer deaktivieren.

- **Cloning: Hänger beim „Update-Delta speichern" behoben** — Beim Auslösen des Workflows „Update-Delta speichern & Klon erstellen" konnte das Backend in einer internen Sperre dauerhaft hängenbleiben (Deadlock). Behoben — der Aufruf läuft sauber durch.

- **Remote-Desktop: Wechsel des Video-Codecs auf VP8 (lizenzfrei)** — Die Übertragung beim Remote-Desktop läuft jetzt auf einem komplett lizenzfreien Video-Codec (VP8). Container-Format ist WebM, FFmpeg-Einstellungen sind auf Echtzeit/niedrige Latenz optimiert. Im Browser greift automatisch das passende WebM-Format.

- **noVNC läuft über den Reverse-Proxy** — Der Zugriff auf die Cloning-VM-Konsole über noVNC lief bisher direkt auf einem separaten Port (6081), der vom Reverse-Proxy nicht abgedeckt war. Jetzt läuft der gesamte noVNC-Verkehr über den Reverse-Proxy auf dem üblichen HTTPS-Pfad (`/novnc/*`) — saubere TLS-Terminierung, kein zusätzlicher Port nötig.

- **Verwaltete Agent-Skripte: einheitliche Namensgebung mit Kategorie-Prefix** — Alle Hilfs-Skripte, die der Agent verwaltet, bekommen jetzt ein Kategorie-Präfix:
  - `agent-` für operative Skripte
  - `provision-` für Skripte, die bei jeder Inhalts-Änderung automatisch auf dem Client ausgeführt werden
  - `manual-` für Skripte, die nur heruntergeladen werden, aber nicht automatisch laufen

  Damit werden z.B. zukünftige Skript-Updates (wie der Codec-Wechsel auf VP8 oben) automatisch auf bestehenden Clients eingespielt.

- **UI-Anpassungen** — - „Wartungsfenster"-Tab vorübergehend ausgeblendet (noch nicht produktionsreif). Reaktivierung ist in der internen Doku beschrieben.
  - Neuer Sidebar-Eintrag „Rollback" im Cloning-Bereich.
  - Sidebar-Einrückung der Unterpunkte leicht angepasst (lesbarer).

- **Gerätedaten-Import per CSV: Gruppenzuordnung wird übernommen** — Die exportierte `clients.csv` enthielt die Gruppenspalte bereits; beim Re-Import wird sie jetzt auch ausgewertet (akzeptiert mehrere Spalten-Bezeichnungen wie `gruppe`, `group`, `groups`). Wenn die CSV Gruppen referenziert, die im System nicht existieren, fragt ein Dialog, ob diese automatisch angelegt werden sollen — bei Zustimmung sind die Geräte direkt zugewiesen.


## 2026-04-06

- **Geräte bleiben während eines Rollbacks bedienbar (Overlay-Boot)** — Während eines Rollbacks ist das System auf den Geräten jetzt mit einem temporären Schreib-Overlay bootbar — der Nutzer kann das System weiter benutzen, während der Rollback-Mechanismus im Hintergrund das Wurzel-Subvolume tatsächlich auf den gewünschten Snapshot zurücksetzt. Wirkt sowohl auf Manjaro als auch auf Debian. Der Agent meldet den Boot-Modus („overlay" oder „normal") über den Heartbeat zurück.

  Außerdem: Beim Overlay-Boot wird das Home-Verzeichnis weiterhin beschreibbar eingebunden — sonst hätte ein Login an Dateien wie `.Xauthority` scheitern können.

- **Installations-Skripte: Image-Rebuild läuft erst am Ende** — Die Installations-Skripte für die Cloning-VMs bauen die initrd-Datei jetzt erst am Ende des Installations-Skripts, nach allen Paket-Updates und Aufräumarbeiten — damit sind alle Kernel-Updates korrekt in der initrd enthalten.

- **Cloning: keine NBD-Kollision mehr zwischen parallelen Operationen** — Mehrere Cloning-Operationen (Zusammenführen von Deltas, Update speichern) nutzen intern dasselbe Block-Device (`/dev/nbd0`), hatten aber keine gegenseitige Sperre. Bei gleichzeitiger Klon-Erstellung konnte das zu undefinierbaren Festplatten-Fehlern führen. Jetzt sind die Operationen sauber gegeneinander serialisiert; falls noch eine Klon-Operation läuft, wird die zweite mit klarer Meldung sofort abgebrochen.

- **VPN: Tunnel wird nach einem Delta-Update wieder hergestellt** — Ein Delta-Update ersetzt den Wurzel-Snapshot des Systems — alle VPN-Spuren auf dem Wurzel-Dateisystem (Symlinks, systemd-Override, NetworkManager-Konfiguration, DNS-Eintrag) gehen dabei verloren. Die eigentliche Konfiguration im Daten-Verzeichnis überlebt, der Tunnel kam aber nicht wieder hoch.

  Jetzt: Beim VPN-Deploy wird ein idempotentes Wiederherstellungs-Skript zusammen mit den DNS-Informationen mitgeliefert. Der Agent erkennt beim Start, dass die VPN-Konfiguration zwar existiert, der Tunnel aber nicht aktiv ist — und stellt ihn automatisch wieder her.

- **Setup-Wizard: Reverse-Proxy-Neustart läuft im Hintergrund** — Beim Setup-Wizard wurde der Reverse-Proxy vorher noch während der laufenden Anfrage neugestartet — das hat die HTTPS-Verbindung gekappt, bevor das Login-Token den Browser erreichte. Der Neustart läuft jetzt im Hintergrund nach der Antwort und nach dem Datenbank-Commit. Beim kurzen Reverse-Proxy-Ausfall überbrückt der Browser die Lücke.


## 2026-04-05

- **Cloning-VM: bleibt nach „Update speichern" weiterhin lauffähig** — Nach dem Workflow „Update-Delta speichern & Klon erstellen" wurde die VM-Festplatte vorher zurückgesetzt — vor dem nächsten Update musste man manuell wieder einen Klon zurückspielen. Jetzt bleibt die VM mit dem frisch erzeugten Klon-Stand aktiv, das nächste Update kann ohne Zwischenschritt direkt darauf aufbauen.

- **VM-Einstellungen überleben Container-Neustarts** — Die Konfiguration der Cloning-VM (RAM, CPUs, Festplatten-Größe, Virtualisierungs-Beschleunigung) ging bisher bei jedem Backend-Neustart oder Container-Re-Build verloren. Jetzt werden die Werte zusammen mit dem aktiven Klon dauerhaft gespeichert und beim nächsten Start wieder eingelesen.

- **Tools-ISO: wird beim VM-Start automatisch neu gebaut** — Beim Klick auf „VM starten" wird die Tools-ISO jetzt automatisch frisch erstellt — sie enthält damit immer die neuesten Skripte, den aktuellen Heartbeat-Token, den Signatur-Schlüssel, das TLS-Zertifikat und die Server-URL. Kein manueller Re-Build mehr nötig.

- **Installations-Skripte: Daten-Partitionsgröße interaktiv** — Die Installations-Skripte für Cloning-VMs fragen jetzt die gewünschte Größe der dauerhaften Daten-Partition ab — akzeptiert Eingaben in GB (z.B. `5`, `10G`) oder Prozent der Festplatte (z.B. `10%`). Standard ist 5 GB.

- **Update-Deltas: schneller komprimiert, gleiche Größe** — Die Delta-Kompressionsstufe ist von Stufe 9 auf Stufe 3 reduziert. Da die Datenblöcke beim Erzeugen schon vorkomprimiert sind, bringt eine höhere Kompressionsstufe praktisch keinen Größenvorteil (Test: 581 MB vs. 583 MB), kostet aber spürbar CPU-Zeit. Schnellere Updates, fast gleiche Dateigröße.

- **UI: Knöpfe während Klon-Operation deaktiviert** — „VM zurücksetzen" und „Update-Delta speichern" sind während einer laufenden Klon-Operation jetzt deaktiviert — verhindert versehentliches Auslösen mitten in einem Vorgang.


## 2026-04-04

- **Ansible-Automatisierung mit Semaphore integriert** — ThinForge bringt jetzt einen integrierten Ansible-Runner („Semaphore") mit, mit dem sich wiederkehrende Konfigurations-Aufgaben automatisiert auf die verwalteten Geräte ausrollen lassen.

  Was sich für den Betrieb ändert:
  - Beim Setup wird Semaphore automatisch konfiguriert — Admin-Konto wird auf die ThinForge-Werte gesetzt, ein API-Token angelegt, das Projekt „ThinForge" und der Provisionierungs-SSH-Schlüssel registriert.
  - Bei einer Rotation des Provisionierungs-Schlüssels wird der neue Schlüssel automatisch zusätzlich im Semaphore-Schlüssel-Speicher hinterlegt (alter bleibt für bestehende Geräte erhalten).
  - Bei einer Änderung des Admin-Passworts wird sie automatisch in Semaphore mit-übernommen (nur für den Admin-Account).
  - Alle Geräte werden als dynamisches Inventar an Semaphore geliefert, gruppiert nach den ThinForge-Gruppen — stündlicher automatischer Sync, auch manuell auslösbar.
  - Erreichbar über `https://<server>:8443`.

- **Neuer Tab „Automation": Playbook-Pakete verwalten** — Unter dem Geräte-Bereich (neben „Liste" und „Garantie") gibt es jetzt einen Tab „Automation". Hier lassen sich Ansible-Playbook-Pakete als ZIP-Archive hochladen (mit einer `thinforge.yml`-Beschreibungsdatei), exportieren und entfernen. Beim Upload entsteht automatisch eine passende Semaphore-Vorlage zum Ausführen.

  Vorgesehen ist das z.B. für vordefinierte Konfigurations-Aufgaben wie „XFCE-Desktop-Einstellungen ausrollen" oder „bestimmte Standard-Apps installieren". Ein erstes solches Paket (XFCE-Desktop-Konfiguration) ist mit dabei.

- **Teil-Backup nur für Schlüssel** — Neuer Knopf in den Backup-Einstellungen: „Schlüssel exportieren". Liefert SSH-Schlüssel, Signatur-Schlüssel, Heartbeat-Token und TLS-Zertifikat als ZIP. Im Setup-Wizard gibt es eine entsprechende dritte Option, die Schlüssel direkt aus einem solchen ZIP zu importieren — fehlende Dateien werden automatisch generiert.

  Damit verbunden: Der Schritt „Signatur-Schlüssel" aus dem Setup-Wizard ist entfernt — der Schlüssel wird automatisch beim Setup erzeugt (oder aus dem importierten Teil-Backup übernommen).

- **Diverse Korrekturen rund um Semaphore** — - Reverse-Proxy: Zertifikat-Cache wird beim Neuladen geleert (verhindert veraltete Zertifikate nach einem Container-Neustart).
  - Erst-Konfiguration ist nach einem Teilfehler wiederholbar (kein Sackgassen-Zustand mehr).
  - Passwort-Sync zu Semaphore feuert nur noch beim Admin-Account, nicht bei Operator/Viewer-Konten.


## 2026-04-03

- **Update mit Nutzer-Benachrichtigung und automatischem Reboot** — Beim Erstellen einer Update-Zuweisung gibt es jetzt einen Schalter „Nutzer benachrichtigen". Wenn aktiv: Nach dem Bereitstellen des Updates zeigt der Agent dem angemeldeten Nutzer am Gerät einen 15-Minuten-Countdown-Dialog mit „Jetzt neustarten" und „Abbrechen". Keine Reaktion → automatischer Neustart. Abbruch → das Update wird beim nächsten regulären Herunterfahren angewendet (für dasselbe Update erscheint der Dialog dann nicht mehr; bei einem neuen Update wieder).

  Ist kein Nutzer angemeldet, wird sofort neugestartet (kein Dialog).

- **Debian-Unterstützung für Cloning-VMs** — Neue Installations-Routine für Debian-basierte Cloning-VMs (analog zur bestehenden Manjaro-Variante). Wirkt zweistufig: Vorbereitung (Festplatten-Aufteilung + Calamares-Konfiguration) und Abschluss (Boot-Loader, Agent, Zeit-Sync, SSH, Pakete). Damit lassen sich auch Debian/Trixie-basierte Klone erzeugen und ausrollen.

  Begleitend: Der Agent und alle Hilfs-Skripte erkennen jetzt automatisch, ob das Wurzel-Subvolume `@root` (Manjaro/Arch) oder `@` (Debian) heißt — sämtliche Pfade werden dynamisch ermittelt. Schutz vor versehentlichem Löschen umfasst beide Varianten.

- **Boot-Loader: Debian-kompatibler Aufruf** — Beim Anwenden von Updates und im Agent wird jetzt zuerst der Debian-übliche Boot-Loader-Aktualisierungs-Befehl probiert und nur bei Bedarf auf den Arch/Manjaro-Befehl zurückgegriffen — kein manueller Eingriff mehr nötig je nach Distribution.

- **Zeit-Synchronisation: Chrony als Standard auf den Clients** — Beide Installations-Routinen (Manjaro und Debian) installieren jetzt Chrony als Zeit-Synchronisations-Dienst und richten den ThinForge-Server als Zeit-Quelle ein. Verhindert TLS-Fehler durch verstellte Uhren auf den Geräten.

- **SSH-Absicherung läuft erst nach Agent-Installation** — Bisher wurde SSH bereits vor der Agent-Installation gehärtet (Passwort-Login deaktiviert). Brach die Installation zwischen Härtung und Schlüssel-Übertragung ab, war das Gerät anschließend nicht mehr erreichbar. Reihenfolge umgekehrt: Härtung läuft jetzt nach erfolgreicher Schlüssel-Installation. Auf Debian wird der SSH-Server bei Bedarf automatisch nachinstalliert.

- **NFS-Server: Endlos-Neustart behoben** — Der NFS-Server-Container lief in einer Neustart-Schleife, weil ein veralteter Aufruf-Parameter („NFSv2 deaktivieren") in der neueren Server-Version nicht mehr unterstützt wird. Aufruf entfernt — der Container läuft stabil.

- **Anleitungen zweisprachig (Deutsch + Englisch) auf der Tools-ISO** — Die Tools-ISO und die Dokumentations-Sammlung enthalten jetzt vollständige Installations-Anleitungen für Debian und Manjaro — sowohl in Deutsch als auch in Englisch. Frühere Manjaro-spezifische Texte sind allgemein formuliert, sodass sie für beide Distributionen passen.


## 2026-04-02

- **Sicherheit: Container-Images aufgeräumt** — Mehrere Container-Images wurden auf neuere Basen umgestellt — die Zahl der bekannten Schwachstellen sinkt deutlich:

  - **NFS-Server-Image** vollständig ersetzt (vorher veraltetes Drittanbieter-Image mit 13 kritischen und 72 hohen Schwachstellen, jetzt eigenes schlankes Image auf Alpine).
  - **Chrony, WireGuard** auf Alpine umgestellt (eliminiert glibc-/ncurses-Schwachstellen und über 80 niedrige Befunde).
  - **Cloner-Image** wurde mehrstufig aufgebaut — Build-Werkzeuge sind nicht mehr im finalen Image enthalten.
  - **Cloning-VM**: noVNC wird jetzt direkt als statische Dateien statt über das Debian-Paket installiert (entfernt eine Node.js-Abhängigkeit und damit zwei kritische Schwachstellen).
  - **Versionen externer Images sind eingefroren** (Postgres, Redis, Caddy, Prometheus, Grafana) — keine unkontrollierten Versionssprünge mehr.

  Begleitend: Neue dokumentierte Akzeptanzliste für nicht behebbare Schwachstellen mit Begründung und Wiedervorlage-Datum. Automatischer Scan einmal pro Woche und bei jedem Image-Build.

- **Zeit-Einstellungen: zentral konfigurierbar und an Clients verteilt** — Unter Einstellungen → Allgemein lassen sich jetzt der Upstream-NTP-Server und die globale Zeitzone konfigurieren. Die Zeitzone wird über den Heartbeat an alle verwalteten Geräte ausgespielt (der Agent setzt sie auf dem Gerät). Funktioniert auf Manjaro/Arch und Debian/Ubuntu.

- **Update-Zuweisung: Geräte mit aktueller Version werden automatisch ausgeschlossen** — Beim Anlegen einer Update-Zuweisung werden Geräte, die bereits die Ziel-Version oder eine neuere haben, automatisch übersprungen. In der Status-Tabelle erscheinen bestätigte Geräte und solche mit höherer Version nicht mehr — die Liste konzentriert sich auf das, was tatsächlich noch ansteht.

- **Klone importieren: vor einen bestehenden Klon einordnen** — Importierte Klone lassen sich jetzt vor einen bereits vorhandenen Klon in der Versions-Kette einordnen. Die Original-Version wird aus dem Klon-Namen extrahiert (z.B. „Update v1.001" → v1.001) und gegen die Ziel-Position validiert — falsche Reihenfolgen werden verhindert. Im Zuordnungs-Dialog tauchen für nicht-zugeordnete Klone mit erkennbarer Version gruppierte „Vor Klon einordnen"-Optionen auf.

- **Update-Deltas: Export und Import** — Einzelne Update-Deltas lassen sich jetzt als 7z-Archiv exportieren und auf einer anderen Installation wieder importieren. Der Import erkennt die Versionen aus dem Dateinamen, validiert sie gegen die bestehende Kette und lehnt Duplikate ab.

- **Klon-Import: nutzt die im Klon hinterlegte Version** — Beim Import eines Klons wird die Version jetzt aus dem Namen entnommen (z.B. „Baseline v1.000" → v1.000) statt eine neue Wurzelnummer zu vergeben. Klone ohne erkennbare Version im Namen bekommen weiterhin eine neue Wurzelnummer.

- **Rollback-Tab: persistente Zuweisungen mit Pro-Gerät-Status** — Der Rollback-Tab im Cloning-Bereich funktioniert jetzt analog zu den Update-Zuweisungen: persistente Rollback-Zuweisungen mit Pro-Gerät-Status (ausstehend / vorbereitet / erledigt), aufklappbare Detail-Zeilen, automatische Status-Aktualisierung über Heartbeat, Sammel-Aktionen (Neustart / Herunterfahren).

- **Update-Ketten: Auf-/Zugeordnet-Status statt Freigabe-Häkchen** — Die Freigabe-Häkchen an Update-Deltas sind weg. Die Verfügbarkeit eines Deltas wird ausschließlich über die Zuweisungen (Roll-outs) gesteuert — alle Deltas sind nach Erstellung oder Import sofort verfügbar. Die Update-Kette wird jetzt nach Version sortiert (statt nach Erstellungsdatum), sodass importierte Deltas korrekt einsortiert sind.

  Ebenfalls vereinfacht: Die Logik, beim Löschen eines Klons automatisch Deltas in den Nachfolger zu „absorbieren", ist entfernt. Deltas bleiben beim Klon-Löschen erhalten und sind weiterhin nutzbar; nur beim letzten Klon der Kette wird das gleichzeitige Löschen der zugehörigen Deltas optional angeboten.

  Außerdem entfernt: das frühere „Konflikt-Geräte"-Feature in der Seitenleiste — Rollback-Funktionalität läuft sauberer im dedizierten Rollback-Tab.


## 2026-04-01

- **Klon-Löschen: optionaler Rollback der betroffenen Geräte** — Wenn ein Klon gelöscht wird, auf dem noch Geräte laufen, fragt der Bestätigungs-Dialog jetzt, ob für die betroffenen Geräte ein automatischer Rollback ausgelöst werden soll. Der Rollback folgt dem gleichen Schema wie Updates: Server-Hinweis → Heartbeat → lokaler Marker → beim nächsten Herunterfahren wechselt das Gerät auf den vorherigen Snapshot.

  Begleitend: Eine dynamische „Konflikt-Geräte"-Gruppe in der Seitenleiste (erscheint nur, wenn betroffene Geräte existieren) listet diese Geräte mit Status-Markern und einem Rollback-Knopf — einzeln oder gesammelt für alle.

- **Update-Zuweisung: erst Gruppe wählen, dann Geräte** — Die Geräte-Auswahl in der Update-Zuweisung folgt jetzt demselben Kaskaden-Schema wie die Deployment-Erstellung: zuerst Gruppe wählen, dann Geräte innerhalb der Gruppe. Vorher wurden alle Geräte ungefiltert angezeigt — bei vielen Geräten unübersichtlich.

- **Update-Deltas: einzeln exportieren** — Einzelne Update-Deltas lassen sich jetzt als 7z-Archiv herunterladen — optional mit AES-256-Passwort. Das Archiv enthält alle zugehörigen Dateien (Delta, Signatur, Metadaten). Knopf direkt neben jedem Delta in der Update-Kette.

- **Klon intelligent löschen** — Klone können jetzt „intelligent" gelöscht werden. Das System analysiert die Position des Klons in der Delta-Kette und handelt entsprechend:
  - Beim **letzten Klon** der Kette wird das zugehörige Delta mit-gelöscht (die Versionsnummer wird beim nächsten Speichern wiederverwendet).
  - Bei einem **Klon in der Mitte** der Kette wird das eingehende Delta automatisch in den Nachfolger übernommen (z.B. v1.001→v1.002 + v1.002→v1.003 wird zu v1.001→v1.003). Die Delta-Übernahme läuft im Hintergrund mit Fortschrittsbalken.

  Vor dem Löschen wird geprüft, ob die VM gerade mit dieser Version läuft (mit Warnung und Bestätigung). Der Bestätigungs-Dialog zeigt alle Seiten-Effekte an.

- **Diverse Korrekturen** — - **Agent-Pfade einheitlich auf `/data/thinforge/`** — Konfiguration, Token, Versionsdateien und Signatur-Schlüssel liegen jetzt unter `/data/thinforge/` statt `/etc/thinforge/`, damit sie über Reboots auf der Daten-Partition persistieren.
  - **Signatur-Prüfung des Update-Schlüssels** — der Agent extrahiert jetzt zuverlässig nur die eigentliche Schlüssel-Zeile (ignoriert Kommentar-Header). Behebt Verifikationsfehler.
  - **Geräte auf der Basis-Version** wurden bisher nicht korrekt zugeordnet, weil sie keine Version meldeten. Der Server leitet die Basis-Version jetzt aus dem ältesten freigegebenen Delta ab und merkt sie sich.
  - **Race-Condition beim Anlegen eines Update-Roll-outs mit Merge** behoben — der Hintergrund-Merge findet den frisch angelegten Roll-out jetzt zuverlässig.
  - **Doppelter Bestätigungs-Dialog beim Löschen eines Roll-outs entfernt.**
  - **Cloning-Seitennavigation**: Klick auf einen Unterpunkt im Cloning-Menü öffnete bisher die Seite zweimal — der Tab erschien erst beim zweiten Klick. Behoben.
  - **DHCP-Leases zurücksetzen**: Neuer Knopf im DHCP-Tab, der alle aktiven Leases löscht und den DHCP-Dienst neu startet (Geräte bekommen beim nächsten Request die reservierte IP).
  - **Genehmigte Geräte erhalten beim Genehmigen jetzt eine IP-Reservierung** (war bisher übersprungen worden).


## 2026-03-31

- **Update-Zusammenführungen: Echtzeit-Fortschritt + Klon-Wiederherstellung im Hintergrund** — Das Erzeugen von zusammengeführten Update-Deltas zeigt jetzt einen echten Fortschrittsbalken (statt eines unbestimmten Spinners), mit benannten Schritten und Prozentwert. Mehrere offene Browser-Tabs werden gleichzeitig versorgt.

  Außerdem: „Klon wiederherstellen" blockiert die Bedienoberfläche nicht mehr. Der Dialog schließt sofort; der Fortschritt erscheint im üblichen Status-Mechanismus. Bei Abschluss kommt eine Benachrichtigung und die Ansicht wechselt automatisch zum VM-Tab.


## 2026-03-30

- **Zusammengeführte Update-Deltas nur für tatsächlich zugewiesene Geräte** — Das System hat zusammengeführte Deltas bisher pauschal für **alle** Geräte aus der Datenbank berechnet — auch wenn nur ein Bruchteil davon in der konkreten Update-Zuweisung saß. Jetzt werden ausschließlich die installierten Versionen der wirklich zugewiesenen Geräte berücksichtigt; bereits vorhandene zusammengeführte Deltas werden weiterhin wiederverwendet.

  Außerdem: Mehrere kleinere Korrekturen am Manjaro-Installationsskript, und die internen Skript-Pfade auf der Tools-ISO wurden konsistent umstrukturiert. Die alte Ansible-Integration ist komplett entfernt — sie wird vom Agent-basierten Verwaltungs-Pfad abgelöst.


## 2026-03-29

- **Update-Deltas werden jetzt signiert (kryptografisch geprüft)** — Alle Update-Deltas (einzelne, zusammengeführte, Home-Deltas) werden ab jetzt automatisch mit `minisign` signiert (Ed25519). Die Geräte prüfen die Signatur vor jeder Anwendung; eine ungültige Signatur führt zum harten Abbruch (eine zweite Prüfung im Anwende-Skript schützt zusätzlich). Der öffentliche Schlüssel wird per Heartbeat verteilt — bei einer Rotation übernimmt das System die Vertrauenskette automatisch. Verwaltung unter Einstellungen → Sicherheit: Erzeugen, Rotieren, bestehende Deltas nachsignieren.

  Damit ist die Auslieferung über NFS, Multicast und BitTorrent gegen Manipulation und Übertragungs-Fehler abgesichert.

- **Update-Mechanismus: zusammengeführte Deltas + automatische Pakete-Updates auf Manjaro** — Geräte, die mehrere Versionen hinterherhinken, können jetzt in einem einzigen Schritt aktualisiert werden statt sequentiell (1 Reboot statt N). Das System erzeugt dafür „zusammengeführte" Deltas auf einer temporären Disk und wählt automatisch den größten verfügbaren Versions-Sprung. Beim Anlegen einer Update-Zuweisung gibt es eine Checkbox „Zusammengeführte Deltas erzeugen"; das Backend startet das Zusammenführen im Hintergrund, Geräte warten automatisch, bis die zusammengeführten Deltas vorliegen.

  Pro zusammengeführtem Delta lässt sich die Freigabe per Checkbox steuern. Manuell erstellte Merges sind zunächst nicht freigegeben, Roll-out-getriebene werden automatisch freigegeben. Mit Knöpfen lassen sich Merges einzeln oder gesammelt löschen. Update-Kette und Merge-Liste werden nebeneinander statt untereinander angezeigt.

- **Agent v2.4.1: VPN-Routen werden live aktualisiert** — Wenn im VPN-Netzwerke-Tab die gerouteten Netze geändert werden (z.B. Full-Tunnel `0.0.0.0/0`), bekommen alle VPN-Geräte die neue Liste automatisch beim nächsten Heartbeat. Der Agent vergleicht mit der lokalen Konfiguration und startet den Tunnel bei Änderung neu. Kein manuelles Re-Deployment mehr nötig.

- **Update-Anwende-Mechanismus überarbeitet** — Mehrere Folgekorrekturen rund um den Update-Anwende-Pfad:
  - Geänderte Snapshot-Berechtigungen führten dazu, dass das interne Daten-Format der Snapshots gebrochen war — die System-Tools konnten den Eltern-Snapshot nicht mehr finden. Empfangene Snapshots werden jetzt nicht mehr nachträglich modifiziert. Boot-Konfiguration wird **vor** dem Subvolume-Tausch erzeugt; Home-Verzeichnis-Mount funktioniert auch beim Rollback-Boot korrekt; nur der unmittelbar vorherige Snapshot erscheint als Rollback im Boot-Menü.
  - Agent v2.4.0 lädt das Migrations-Skript bei jedem Start und führt es idempotent aus — fehlende Dienste nach einem Subvolume-Tausch werden automatisch nachinstalliert.

- **Diverse Korrekturen** — - Mehrere Bugfixes im „Update speichern"-Flow (Snapshot-Filter, Doppel-Erzeugung, JSON-Escaping, Concurrency-Schutz, sauberere Versions-Prüfung).
  - Tunnelstatus aktualisiert sich nach Importieren oder Speichern einer VPN-Konfiguration automatisch.
  - Hängende „Zusammenführen läuft"-Markierungen werden beim Backend-Start zurückgesetzt.
  - Die Deltas-Liste lädt nach Abschluss eines Merges automatisch neu.


## 2026-03-28

- **Klone und Deltas: „veraltet"-Markierung für überholte Stände** — Vollständige Klone und Update-Deltas, die von allen aktiven Geräten bereits überholt sind, werden jetzt mit Durchstreichung und „veraltet"-Markierung angezeigt — hilft beim Erkennen nicht mehr benötigter Stände. Aufklappbare Detail-Zeilen pro Klon/Delta zeigen, welche Geräte noch nicht auf dem jeweiligen Stand sind (aufgeteilt in aktive Geräte und Lager-Geräte).

- **PXE-Boot funktioniert auf allen Geräten + GRUB-EFI-Verbesserungen** — Alle registrierten Geräte bekommen jetzt bei jedem Start ein PXE-Boot-Image vom Server. Die individuelle PXE-Konfiguration pro Gerät steuert, ob lokal oder per Clonezilla gestartet wird. Funktioniert OS-unabhängig auf Windows und Linux.

  Außerdem: GRUB scannt jetzt lokale EFI-Partitionen und lädt den OS-Boot-Loader direkt (chainload) — funktioniert für Manjaro, Debian, Windows usw. Löst eine bisherige Endlos-Schleife, wenn PXE als erste UEFI-Boot-Option eingestellt war.

- **Updates-Tab: Sammel-Aktionen direkt in der Status-Tabelle** — In der Geräte-Status-Tabelle im Updates-Tab gibt es jetzt Auswahl-Boxen und Sammel-Aktionen „Neustart" und „Herunterfahren" — analog zum Haupt-Geräte-Tab.

- **Agent: automatische Skript- und Versionsaktualisierung, Snapshot-Aufräumen** — - Der Agent aktualisiert beim Start nicht nur sich selbst, sondern auch die Hilfs-Skripte (`apply-delta.sh`, `thinforge-apply-update.sh`, `manage-snapshots.sh`) automatisch (per Hash-Vergleich mit dem Server).
  - Beim Start werden alte btrfs-Snapshots aufgeräumt (zwei aktuelle Snapshots bleiben, plus jeweils ein Paar Pre-Update-Snapshots). Geräte verbrauchen dauerhaft weniger Festplattenplatz.
  - Selbst-Update läuft jetzt bei jedem Heartbeat (statt nur beim Start) — neue Versionen kommen innerhalb max. 60 Sekunden an.
  - Vollständiger Snapshot-Rollback: Beim Rollback wird auch das Home-Verzeichnis vom passenden Snapshot eingebunden statt vom aktuellen Stand.
  - GRUB-Konfiguration wird sofort nach dem Subvolume-Tausch beim Herunterfahren aktualisiert — Rollback-Einträge sind beim nächsten Boot direkt verfügbar, auch wenn der neue Boot fehlschlägt.

- **VPN-Firewall: persistent und gehärtet** — - Firewall-Regeln werden persistent gespeichert und beim Container-Start automatisch wieder geladen. Vorher waren nach einem Neustart alle Regeln weg.
  - Beim Backend-Start werden die Regeln vorsichtshalber neu angewendet.
  - System-Regeln (DNS, HTTPS) können nur noch aktiviert/deaktiviert, aber nicht mehr inhaltlich verändert werden.
  - Eingaben in Firewall-Regeln werden streng validiert (verhindert Befehls-Einschleusung).
  - Die VPN-Management-API ist nicht mehr aus dem LAN-Interface erreichbar (nur noch über die interne Docker-Bridge).


## 2026-03-27

- **Agent-Selbst-Update und Snapshot-Verwaltung** — Der Agent prüft beim Start seine Version gegen den Server und aktualisiert sich automatisch (Backup als `.bak` vor dem Tausch, systemd-Neustart danach). Nach einem Delta-Update wird der Boot-Loader vom Agent neu konfiguriert, damit alle Snapshots im Boot-Menü erscheinen. Ein erfolgreicher Boot auf einer neuen Version wird automatisch dem Server bestätigt und alte Snapshots werden aufgeräumt.

  Außerdem: Inventarnummer wird in Update-Ansichten (Zuweisungen und Status-Tabelle) als zusätzliche Spalte angezeigt, beide Tabellen sortieren standardmäßig danach. Refresh-Knöpfe an allen Stellen, die regelmäßig nachgeladen werden müssen. Jede Update-Zuweisung lässt sich aufklappen, um die zugehörigen Geräte mit Hostname, MAC, installierter Version und Status zu sehen.

- **Versions-Schema: einheitlich „vMAJOR.MINOR" mit dreistelliger Minor** — Alle Versions-Strings werden jetzt automatisch mit „v"-Präfix normalisiert (`1.0` → `v1.0`) — verhindert inkonsistente Snapshot-Namen. Die Minor-Version ist dreistellig (z.B. `v1.000`, `v1.001`), damit Dateinamen und Snapshot-Listen alphabetisch korrekt sortieren. Im „Update speichern"-Dialog kann zwischen Delta-Update (Minor-Bump) und neuem Basis-Image (Major-Bump, neue Versionskette) gewählt werden. Ohne vorhandene Klone wird immer eine frische Baseline `v1.000` erzwungen.

- **Update-Anwendung beim Herunterfahren statt im laufenden Betrieb** — Delta-Updates werden jetzt beim Herunterfahren angewendet (durch einen systemd-Dienst), statt im laufenden System. Verhindert Einfrieren des Desktops während des internen Subvolume-Tauschs. Der Agent legt das Delta lokal ab; beim nächsten Herunterfahren erfolgt der eigentliche Wechsel.

  Außerdem: Vor einem neuen Basis-Image werden alte Snapshots in der Cloning-VM automatisch gelöscht (verhindert Namens-Kollisionen). Die Geräte-Provisionierung umfasst jetzt zusätzlich den systemd-Anwende-Dienst und das Snapshot-Verwaltungs-Skript.

- **Diverse Korrekturen** — - Desktop-Einfrieren nach Delta-Update behoben (Subvolume-Tausch nur noch beim Herunterfahren; GRUB-Snapshot-Daemon deaktiviert).
  - Doppelter Delta-Download verhindert (Agent prüft jetzt eine zusätzliche lokale Markierung).
  - Pre-Update-Snapshots wachsen nicht mehr unbegrenzt — Agent räumt sie auf.
  - Multicast-Import-Fehler durch fehlerhaften internen Import behoben.


## 2026-03-26

- **Cloning-VM: Daten-Partition wird automatisch angelegt** — Beim Manjaro-Installations-Skript wird jetzt automatisch eine ca. 5 GiB große Daten-Partition mit btrfs und `@data`-Subvolume erstellt — wird unter `/data` eingehängt und überlebt alle Updates. Die System-Partition wird live online verkleinert; die Logik liegt in einem aufrufbaren Skript mit Größen-Parameter.

- **Tools-ISO aufgeräumt + Versionierungs-Konsistenz** — Die Tools-ISO enthält nur noch drei Haupt-Skripte (`install-manjaro.sh`, `1-create-client-management.sh`, `enable-ssh.sh`); Helfer liegen in einem Unterordner. Beim Erstellen eines Klons wird die Version automatisch in der Disk hinterlegt — frisch ausgerollte Geräte kennen ab dem ersten Boot ihre Version und melden sie korrekt. Update-Zuweisungen lassen sich im Updates-Tab löschen (laufende werden sauber abgebrochen). VM-Festplatte wird nach erfolgreichem Klon automatisch zurückgesetzt — nächste Session startet sauber mit frischer Installation.

- **Update-Deltas: mehrere Subvolumes + automatischer Subvolume-Tausch + WireGuard persistent** — - **Mehrfach-Subvolume-Deltas:** Snapshots und Deltas erfassen jetzt sowohl `@root` als auch `@home` (statt nur `@root`). Desktop-Anpassungen (XFCE-Icons, Workspace-Layout, Panel-Einstellungen) fließen automatisch vom Master-System zu den Geräten. `@cache`/`@log` sind temporär und werden nicht erfasst.
  - **Automatischer Subvolume-Tausch beim nächsten Boot** — kein manueller GRUB-Eingriff mehr nötig.
  - **WireGuard-Konfiguration auf der Daten-Partition** — überlebt alle Updates. Symlink ins System-Verzeichnis wird automatisch wiederhergestellt.
  - **NFS-Freigaben für VPN-Geräte:** Das VPN-Subnetz wird automatisch aus der Tunnel-Konfiguration ausgelesen und allen NFS-Freigaben (Klone, Captures, Deltas) hinzugefügt.
  - **VPN-Deploy: DNS-Override für Server-Hostname** — der Server-FQDN wird auf die interne IP gemappt, damit Heartbeats und Update-Downloads korrekt durch den Tunnel laufen.

- **Diverse Korrekturen** — - „Installiertes Image" zeigt die richtige (sichtbare) Version statt der internen Nummer.
  - Doppeltes „v" in der Geräte-Liste behoben (`vv1.1` → `v1.1`).
  - Klon-Wiederherstellung stürzte ab, wenn die Version mit `v` begann — gefixt.
  - VM startet wieder zuverlässig (ungültige MAC-Adresse korrigiert; UEFI-Boot-Reihenfolge wird bei eingelegter ISO zurückgesetzt).
  - Capture mit Leerzeichen im Namen funktioniert (Leerzeichen werden automatisch durch Unterstriche ersetzt).
  - Mehrere Capture-Folgefehler (fehlender Callback-Token, inkompatibles Image-Splitting) behoben.
  - VPN-Geräte können wieder per NFS auf Update-Dateien zugreifen.
  - VPN-Geräte erreichen den Server jetzt über den Tunnel statt versehentlich über das Internet.

- **Sicherheit (Hinweis)** — Als wichtiges Vor-Produktiv-TODO dokumentiert: WireGuard-Schlüssel liegen aktuell als Klartext auf der Daten-Partition. Vor dem produktiven Betrieb soll die Daten-Partition mit LUKS verschlüsselt und mit TPM-2.0-Auto-Entriegelung (oder Hardware-ID-Fallback) versehen werden. Datenbank-Schema und UI-Vorbereitung dafür sind bereits vorhanden.


## 2026-03-25

- **Erstes vollständiges Delta-Update auf echter Hardware** — Erster kompletter Delta-Update-Durchlauf auf einem echten Gerät: Cloning-VM (Manjaro XFCE) → v1.0 Baseline → v1.1 Update → Delta 1,6 GB. Das Empfangs-Gerät zog das Delta in 2 Sekunden per NFS, wendete es in 26 Sekunden an, GRUB wurde konfiguriert — kein Nutzer-Eingriff, kein erzwungener Neustart. Damit ist der End-zu-End-Pfad funktional.

- **Automatische Versions-Nummerierung + Boot-Loader als Standard-Manjaro-Logik** — Versionen werden automatisch hochgezählt (v1.0 → v1.1 → v1.2 …); kein manuelles Eingabefeld mehr. Optionaler Kommentar statt Versionsnummer (z.B. „Kernel-Update"). Klon-Namen folgen dem Muster „Baseline v1.0" (erste Version) bzw. „Update v1.1" (folgende).

  Außerdem: Der eigene GRUB-Boot-Loader-Mechanismus ist abgelöst — Manjaros nativer `grub-mkconfig` plus das Werkzeug `grub-btrfs` reicht aus. Snapshots erscheinen automatisch als bootbare Einträge im GRUB-Menü; Rollback bedeutet einfach „Snapshot im Menü wählen". Die zugehörige Snapshot-Software „Timeshift" wird nicht mehr benötigt; rund 300 Zeilen Code sind weggefallen.

- **Manjaro-Installations-Skript zweistufig + diverse Korrekturen** — Neues Skript `install-manjaro.sh` mit Phase `prepare` (Calamares anpassen) und Phase `finish` (GRUB + Agent einrichten). Kernel-Erkennung dynamisch (statt fest auf einen Kernel-Namen). Zusätzlich `enable-ssh.sh` für schnellen SSH-Zugriff zur VM (nur Schlüssel + sshd, ohne Agent).

  Folgekorrekturen aus Live-Tests: NBD-Schreib-Fehler durch Schreib-Puffer-Sync vor dem Trennen behoben; Heartbeat-Token wird vom Python-Agent jetzt mitgeschickt (vorher 403); frisch ausgerollte Geräte ohne gemeldete Version bekommen die Basis-Version aus der Delta-Kette zugewiesen; Snapshot-Listen werden korrekt geparst; Deltas-Verzeichnis ist im Backend-Container sichtbar.

- **Cloning-VM-Info: MAC + IP + Fortschrittsbalken** — VM-Tab zeigt MAC-Adresse und IP der VM im Info-Panel an. Beim „Update speichern" gibt es einen prozentualen Fortschrittsbalken — analog zum Klon-Erstellen.


## 2026-03-23

- **Großes Feature: Delta-Update-System für Klone** — Erste Ausbaustufe des Delta-Update-Mechanismus. Statt jeder Aktualisierung über vollständige Re-Deployments (15+ GB) reicht jetzt ein Delta (typisch 50–200 MB) zwischen zwei Versionen.

  Was sich für den Betrieb ändert:
  - **Neues Partitionsschema** auf den Geräten: EFI + System (btrfs mit Wurzel-Subvolume + Snapshots) + Daten (btrfs, ~5 GB). Rollbacks laufen über btrfs-Snapshots und ein Boot-Loader-Zählwerk.
  - **„Update speichern"-Knopf im VM-Tab:** Erstellt Snapshot + Delta + vollen Klon in einem Schritt; erkennt automatisch, ob ein Basis-Snapshot fehlt oder ein Delta erzeugt werden kann.
  - **Neuer Updates-Tab:** Liste der Deltas (mit Löschen) und Roll-out-Verwaltung (Anlegen, Geräte-Status, Abbrechen). Aktive Roll-outs werden automatisch nachgeladen.
  - **Agent prüft Boot:** Nach einem Update-Boot bestätigt der Agent den erfolgreichen Boot ans Backend und setzt das Zählwerk zurück.
  - **Update-Auslieferung über NFS** (Freigabe `/nfs/deltas`) mit dynamischer Beschränkung auf die berechtigten Geräte. Kein automatischer Neustart — das Update wird beim nächsten regulären Reboot aktiv.
  - **Distributionsneutral:** Funktioniert auf Debian-basierten und Arch/Manjaro-Systemen.

- **Update-Freigabe, Update-Kette und Gruppen-Zuweisungen** — - **Freigabe-Mechanismus:** Updates müssen explizit freigegeben werden, bevor Geräte sie erhalten. Roll-outs starten im Status „Entwurf"; Klick auf „Freigeben" → „Aktiv". Ein Roll-out wird automatisch als „abgeschlossen" markiert, sobald alle Geräte fertig sind.
  - **Update-Kette als sichtbare Reihenfolge** im UI, mit Häkchen für Freigabe — die Reihenfolge wird erzwungen (v1.1 lässt sich nur freigeben, wenn v1.0 bereits aktiv ist; v1.0 nicht deaktivieren, solange v1.1 aktiv ist).
  - **Gruppen-Zuweisungen:** Verschiedene Gruppen/Geräte können verschiedene Ziel-Versionen haben. Roll-outs werden je nach Bedarf freigegeben.
  - **Automatischer Ketten-Durchlauf:** Geräte bekommen pro Heartbeat den nächsten Schritt der Kette — ein Gerät auf v1.0 mit Ziel v1.3 läuft sauber v1.0→v1.1→v1.2→v1.3 durch.
  - **Lösch-Warnung:** Beim Löschen eines Deltas wird geprüft, ob Geräte oder die Versions-Kette betroffen sind.

- **Neues Festplatten-Schema kann aus dem UI angewendet werden** — Im VM-Tab gibt es jetzt einen Knopf „Festplatten-Schema anwenden", der die Disk bei Bedarf erstellt und anschließend mit dem neuen Schema partitioniert (EFI + System-btrfs + Daten-btrfs). Ein Warn-Dialog zeigt das Layout und weist explizit auf Datenverlust hin. Bei wiederhergestellten Klonen ist der Knopf deaktiviert.

- **Agent-Refactoring (v2.0)** — Der Python-Agent wurde grundlegend überarbeitet:
  - Wiederholungsversuche pro Delta sind auf maximal 3 begrenzt.
  - Es wird kein neues Delta angenommen, solange das vorhergehende nicht erfolgreich gebootet hat.
  - Die installierte Version wird in einer eigenen Datei dauerhaft mit-getrackt.
  - Installation läuft jetzt sauber über die Tools-ISO und das Provisionierungs-Skript.


## 2026-03-22

- **Setup-Wizard: Wiederherstellung aus Backup als Einstiegs-Option** — Der Setup-Wizard fragt jetzt als ersten Schritt: Neuinstallation oder Wiederherstellung aus einem Backup? Bei der Wiederherstellung wird das Backup hochgeladen, validiert und vollständig zurückgespielt — inklusive Datenbank, Konfigurationen (VPN, DHCP, NFS, Chrony, Reverse-Proxy) und Verschlüsselungs-Schlüssel. Bei Bedarf werden Dienste neu gestartet, damit der importierte Schlüssel wirksam wird.

- **VPN: FullVPN-Subnetz-Verwaltung** — ThinForge unterstützt jetzt die FullVPN-Endpunkte des thinVPN-Servers. Geroutete Netzwerke werden automatisch als individuelle Subnetze des Haupt-Servers (MainServer) auf dem VPN-Server synchronisiert. Im VPN-Netzwerke-Panel ist der FullVPN-Status sichtbar; ein „VPS Sync"-Knopf gleicht manuell ab.

  Damit ist ein bisheriges VPN-Routing-Problem gelöst: Das lokale Subnetz wird automatisch in die Routen des MainServer-Peers eingetragen — vorausgesetzt, auf dem VPN-Server ist `fullvpn: true` aktiv.

- **Diverse Korrekturen** — - **PXE-Konfiguration eines Geräts wird beim Capture nicht mehr fälschlich zurückgesetzt** (durch Heartbeat-Sicherungs-Netz unterdrückt, solange ein aktiver Capture-Job läuft).
  - **Neuer Deployment-Dialog wählt automatisch den jüngsten Klon vor** (Liste absteigend sortiert).
  - **VPS-Statusanfragen liefern bei nicht erreichbarem VPS einen leeren Standard** statt einer Fehlermeldung (z.B. direkt nach einem Tunnel-Import, während WireGuard noch startet).
  - **Tools-ISO wird vor jedem VM-Start automatisch neu gebaut** — VM startet mit den aktuellsten Skripten.
  - **CSV-Import-Dialog schließt nach erfolgreichem Import automatisch.**
  - **WireGuard-Container hängt nicht mehr im „ungesund"-Status nach Werksreset** (Healthcheck wurde robuster gemacht).

- **Geräte-spezifische SSH-Schlüssel entfernt** — Die individuelle SSH-Schlüssel-Verwaltung pro Gerät ist komplett weg. Für alle SSH-Verbindungen wird ausschließlich der zentrale Provisionierungs-Schlüssel verwendet. Mehrere zugehörige API-Endpunkte und UI-Bereiche sind entfernt. Schlanker, weniger Fehlerquellen, kein Funktionsverlust.

- **Geräte: neues Feld „Verbindungsart" (LAN / VPN / VPN-Sync)** — Jedes Gerät führt jetzt eine Verbindungsart-Information mit: `lan`, `vpn` (Heartbeat über VPN) oder `vpn_sync` (nur über VPN-API-Sync erkannt, kein Heartbeat). Status-Anzeige im UI mit passenden Symbolen („Online (LAN)", „Online (VPN)", „Online (VPN sync)"), neuer Filter „Verbindung" in der Geräte-Liste, Anzeige im Detail und auf der Dashboard-Karte.

- **VPN: neuer Tab „VPN-Netzwerke" und sauberes Deaktivieren** — - Neuer Tab „VPN-Netzwerke" mit Checkboxen für erkannte Host-Interfaces und manueller CIDR-Eingabe.
  - Bei einer VPN-Deaktivierung wird automatisch ein Aufräum-Job auf dem Gerät ausgelöst (WireGuard stoppen, Konfiguration entfernen).
  - Beim Deploy wird eine systemd-Override-Datei installiert, die die Routen-Metriken beim Systemstart fixiert.


## 2026-03-21

- **Setup-Skripte konsolidiert, Host-Abhängigkeiten reduziert** — Zwei separate Setup-Skripte sind in ein einziges (`install-deps.sh`) zusammengeführt. Die Host-Abhängigkeiten sind auf das Minimum reduziert: nur noch Docker, Git, OpenSSL und ein paar Kernel-Module. Pakete wie qemu-kvm, NFS-Server-Pakete, WireGuard-Tools, libvirt werden nicht mehr auf dem Host installiert — die Kernel-Module sind auf Ubuntu 24.04 bereits enthalten. KVM-Vendor wird automatisch erkannt. Konfligierende Host-NFS-Dienste werden nur noch gewarnt, nicht mehr abgeschaltet.

- **Versionsanzeige + Changelog-Dialog in der Kopfleiste** — Die ThinForge-Versionsnummer (z.B. „v20260321") wird oben rechts in der Kopfleiste angezeigt. Klick darauf öffnet einen Dialog mit dem aktuellen Changelog (Markdown gerendert).

- **Großer Codebase-Bereinigungs-Lauf** — Umfangreiche interne Aufräum-Arbeiten in rund 40 Bereichen — keine Funktionsänderungen, dafür weniger doppelter Code, schnellere Datenbank-Abfragen (mehrere Stellen mit „N+1"-Mustern eliminiert, eine Stelle spart rund 700 Datenbank-Abfragen pro Zyklus) und insgesamt stabilerer Betrieb.


## 2026-03-20

- **Großes Bündel an Verbesserungen rund um Deployment, VPN und Tasks** — Mehrere neue Funktionen und Korrekturen:

  - **Disk-Größen-Prüfung vor Restore:** Alle Deploy-Wege (Unicast, Multicast, BitTorrent) prüfen vor dem eigentlichen Restore, ob die Ziel-Festplatte groß genug ist. Bei zu kleiner Disk gibt es eine klare Fehlermeldung im UI (z.B. „Zielfestplatte zu klein: 32 GB verfügbar, 49 GB benötigt") und der Vorgang bricht sauber ab statt mitten im Restore zu scheitern.
  - **Neuer Einstellungs-Tab „Allgemein":** Sitzungsdauer (1 h bis 30 Tage) ist konfigurierbar.
  - **VPN-Tasks-Tab:** Zeigt VPN-bezogene Hintergrund-Aufgaben (Schlüssel-Setup, Rotation) mit Live-Status, Dauer und Fehlermeldungen. Aktive Aufgaben werden alle 5 Sekunden aktualisiert.
  - **VPN-Konfiguration neu auf einen Client pushen** — wahlweise einzeln oder als Sammel-Aktion, ohne dass die Schlüssel neu erzeugt werden müssen.
  - **VPN-Aufgaben Retry/Cancel** direkt im Tab möglich.
  - **VPN-Remote-Sync-Tab:** Zeigt alle Clients, die auf dem VPN-Server konfiguriert sind. Verwaiste Einträge sind rot markiert; Inventarnummern werden aufgelöst und verlinken auf das jeweilige Gerät.
  - **Aufgaben-Vorlagen mit Zeitplan:** Wiederkehrende oder zeitgesteuerte Aufgaben (z.B. „jeden Montag 6:00 SSH-Befehl ausführen") lassen sich als Vorlagen definieren; das System reiht sie zum richtigen Zeitpunkt automatisch ein.
  - **Gruppen-Filter für Geräte-Auswahl:** Captures, Remote Execution, Web Terminal und Wartungsfenster nutzen jetzt ein einheitliches „Gruppe → Geräte"-Filter-Muster.
  - **VPN: automatische Wiederherstellung bei Schlüssel-Entschlüsselungs-Problemen** — der Client wird beim nächsten Konfigurations-Abruf automatisch neu provisioniert.
  - **Lager-Modus mit visueller Markierung:** Geräte im Lager werden in der Liste ausgegraut, der Status-Chip steht in Orange. Beim Einlagern wird die IP automatisch freigegeben und steht anderen Geräten zur Verfügung; beim Rückholen wird eine neue IP aus dem Pool zugewiesen.

  Außerdem viele kleinere Korrekturen: Prometheus-Metriken werden korrekt gezählt; Rate-Limiter ist gegen Race-Conditions abgesichert; Dashboard-Suche bleibt beim Wechsel zur Geräte-Liste erhalten; VPN-Tab erkennt aktiven Tunnel auch ohne DB-Konfigurationseintrag; Worker-Container nutzt denselben Provisionierungs-SSH-Schlüssel wie das Backend (löst kryptische „Permission denied"-Fehler bei VPN-Deploys); IP-Allocation gegen Race-Condition abgesichert; Werks-Reset bricht nicht mehr an einer nicht existierenden Tabelle ab; mehrere Datenbank-N+1-Abfragen für Gruppen- und Task-Listen sind durch effiziente JOINs ersetzt.


## 2026-03-19

- **Großes Feature: VPN-Integration auf Basis von thinVPN (Cloud)** — Das bisherige lokale WireGuard-VPN-System ist durch eine Cloud-basierte thinVPN-Integration ersetzt. Der ThinForge-Server verbindet sich als WireGuard-Client zu einem externen thinVPN-Server (auf einem VPS) und verwaltet von dort aus die VPN-Profile für die verwalteten Geräte über eine REST-API.

  Was sich für den Betrieb ändert:
  - VPN-Tunnel-Konfiguration wird im neuen VPN-Tab (Netzwerk-Bereich) per Import eingerichtet, mit Bestätigungs-Dialog auch wieder löschbar.
  - VPN-Konfigurationen werden jetzt **über Gruppen gesteuert** — Toggle „VPN aktiv" pro Gruppe; Bulk-Operationen „Fehlende generieren" oder „Alle neu generieren (Schlüssel-Rotation)".
  - Optionale Speicherung der VPN-Schlüssel im TPM der Geräte.
  - Periodischer Sync mit dem thinVPN-Server (Intervall konfigurierbar).
  - Traffic-Monitoring (Live-RX/TX + monatliche Logs).
  - Optionale Firewall: definiert, welcher VPN-Verkehr ins LAN darf. Default „alles erlaubt"; bei Aktivierung „alles verboten" + Whitelist, mit Drag-and-Drop-Reihenfolge.

  Begleitend: automatisches SSH-Deployment der WireGuard-Konfiguration auf die Geräte (mit Auto-Installation von `wireguard-tools`, falls nötig); WireGuard-Tools sind in der Klon-ISO bereits vorinstalliert; bei Klon-Start wird gewartet, bis der noVNC-Server tatsächlich erreichbar ist (kein Reload-Fehler mehr).

- **Profil-Funktion entfernt** — Die separate „Konfigurationsprofil"-Funktion wurde komplett entfernt — sie wurde im Betrieb nicht genutzt. Gruppen tragen jetzt direkt die zugehörigen Einstellungen. Datenmigration läuft automatisch.

- **Diverse VPN- und TLS-Korrekturen** — - Tunnel-Status wird im UI korrekt angezeigt (vorher dauerhaft „getrennt").
  - Firewall-Toggle überschreibt nicht mehr die übrigen VPN-Einstellungen.
  - DNS-Auflösung des Backends nach WireGuard-Start funktioniert wieder (interner Docker-DNS bleibt erhalten).
  - WireGuard-Container läuft auch ohne anfängliche Konfiguration stabil (keine Restart-Schleife mehr).
  - TLS-Zertifikate beinhalten jetzt alle erkannten Server-IPs (verhindert Zertifikatsfehler beim Zugriff über das Management-Interface).


## 2026-03-18

- **BitTorrent-Deployment funktioniert wieder** — Bei BitTorrent-Deployments suchten die Geräte ihre Torrent-Dateien in einem Verzeichnis, das der Seeder gar nicht befüllte (Konflikt in der Reihenfolge, in der ein interner Schlüssel erzeugt wurde). Behoben — der Schlüssel wird jetzt vor der eigentlichen Aktivierung erzeugt, die PXE-Konfigurationen passen.

- **Deployment-Status: Fehler werden korrekt angezeigt** — Bisher zeigte ein Deployment dauerhaft „Abgeschlossen" (grün), selbst wenn alle Geräte fehlgeschlagen waren. Neuer Status „Mit Fehlern abgeschlossen" (rot) — Fehler sind sichtbar statt versteckt. Außerdem werden Torrent- und Hilfs-Dateien beim Löschen eines Deployments mit aufgeräumt; falsche Offline-Alarme nach einem Deployment treten nicht mehr auf.

- **Aktive Geräte-Prüfung („Ping") und Standard-Sortierung nach Inventarnummer** — Klick auf den grünen „Online"-Status eines Geräts in der Liste löst zwei parallele Pings aus. Reagiert keiner, wird das Gerät sofort als offline markiert. Voraussetzung: ICMP muss in der Firewall des Geräts erlaubt sein. Außerdem ist die Geräte-Liste jetzt standardmäßig nach Inventarnummer sortiert (aufsteigend).

- **Container-Basis auf Debian Trixie + neuere Partclone-Version** — Alle ThinForge-Container nutzen jetzt Debian 13 (Trixie, stabil) statt der unstabilen Entwicklungs-Variante. Partclone (das Disk-Klon-Werkzeug) ist auf Version 0.3.47 angehoben. Build-Quellen werden lokal zwischengespeichert — schnellere Re-Builds, weniger Netzwerk-Last.

- **Verbesserungen rund um Deployment-Wiederholung** — - Inventarnummer in der Geräte-Liste eines aufgeklappten Deployments sichtbar.
  - Restart-Knopf erscheint jetzt auch bei abgebrochenen Deployments (nicht nur bei fehlgeschlagenen); ein Abbruch räumt den Status sauber zurück.
  - **Multicast-Timeout:** Geräte, die nach Abschluss der Multicast-Übertragung keine Rückmeldung senden (z.B. neugestartet während der Übertragung), werden automatisch als fehlgeschlagen markiert. Timeout in den Multicast-Einstellungen konfigurierbar (Standard 120 Sekunden).
  - Beim Wiederholen fehlgeschlagener Geräte wird die NFS-Freigabe zuverlässig reaktiviert.

- **Sicherheit: BitTorrent-Pfade nicht mehr vorhersagbar** — Die Torrent-Dateien werden jetzt unter einem zufälligen 32-stelligen Pfad statt unter der vorhersagbaren Deployment-ID ausgeliefert. Zusätzlicher Schutz: Die DHCP-Konfiguration filtert unbekannte Geräte (`dhcp-ignore=tag:!known`) — nur registrierte Geräte bekommen überhaupt eine IP.

- **HTTPS von Anfang an + TLS-Zertifikat auf Clients** — Beim ersten Server-Start wird automatisch ein selbstsigniertes TLS-Zertifikat erzeugt; der Reverse-Proxy liefert sofort HTTPS aus und leitet HTTP automatisch um. Der Setup-Wizard ersetzt das Zertifikat im sechsten Schritt durch eines mit korrektem CN und SANs.

  Das Server-Zertifikat wird automatisch in die Tools-ISO eingebettet und vom Client-Installations-Skript in den System-Vertrauensspeicher der Geräte eingetragen — alle Server-URLs (Heartbeat, Agent, ISO) laufen damit über HTTPS.

- **Sicherheit: stärkere Schlüsselableitung + Rate-Limit auf Login** — - Die Verschlüsselung der gespeicherten SSH- und WireGuard-Schlüssel nutzt jetzt eine moderne Schlüsselableitung (PBKDF2-HMAC-SHA256 mit 600.000 Iterationen und persistentem Salt). Bestehende Daten werden bei Bedarf transparent migriert.
  - **Rate-Limit** auf Anmelde-Endpunkte (`/login` 5 Versuche/5 Min, `/totp/login` 3/5 Min, `/change-password` 5/5 Min).
  - Ein unauthentifizierter Web-Terminal-Endpoint (Root-Shell für jeden im LAN) ist entfernt — der Terminal-Dialog nutzt nur noch den authentifizierten Endpoint.


## 2026-03-17

- **Worker stabilisiert + BitTorrent-Modus erkannt + dauerhafte PXE-Stände** — Der Worker-Container stürzte bei allen wiederkehrenden Aufgaben mit einem internen Fehler ab. Behoben — alle nötigen Datenmodelle sind sauber verbunden.

  BitTorrent-Deployments: Die Modus-Erkennung suchte einen anderen Modus-Namen als die PXE-Konfiguration schrieb — die Geräte bekamen kein Boot-Image. Beide Varianten werden jetzt akzeptiert; der Modus-Name ist intern vereinheitlicht.

  Außerdem: Bei einem Backend-Neustart verloren laufende Deployments ihre PXE-Konfiguration. Aktive Deployments werden jetzt beim Start aus der Datenbank wiederhergestellt; PXE-Konfiguration wird erst danach neu erzeugt — Deployments überleben Backend-Neustarts.

- **VPN-Erweiterungen: Live-Status, Auto-Install, Retry, Revokation** — - **Handshake-Synchronisation:** Aktualisiert WireGuard-Handshake-Daten (letzter Handshake, Übertragungs-Bytes) jede Minute in die Datenbank.
  - **Agent meldet VPN-Status** im Heartbeat (VPN-Interface vorhanden? IP? aktueller Handshake?).
  - **WireGuard-Tools** werden bei Bedarf automatisch auf dem Gerät installiert.
  - **VPN-Deploy-Retry:** Bis zu drei Versuche mit ansteigendem Abstand (30 s, 120 s, 300 s) bei SSH-Fehlern.
  - **VPN-Revokation:** Beim Widerrufen wird die WireGuard-Konfiguration auch vom Gerät entfernt (Dienst stoppen, deaktivieren, Datei löschen).

- **Dashboard: Speicher-Auslastung + neuer Info- und Backup-Bereich** — - Neue Dashboard-Karte mit Festplatten-Belegung des Servers (belegt/frei/gesamt), farbcodierter Balken (grün < 75 %, gelb 75–90 %, rot > 90 %).
  - Neuer Menüpunkt „Info & Backup" mit Tab „Info" (Ersteller, Kontakt, Hinweis zum Wartungsvertrag) und Tab „Backup" (vollständige Sicherung und Wiederherstellung; Datenbank und Konfiguration immer dabei, ISOs/Klone/Captures optional zuwählbar; Download als Archiv, Restore per Upload mit Passwort-Bestätigung).
  - ThinForge-Logos in Seitenleiste, Kopfleiste, Login-Seite, Setup-Wizard und Info-Seite, mit automatischer Dark/Light-Umschaltung je nach aktivem Theme.


## 2026-03-16

- **Neues Feature: Remote Desktop (Live-Bildschirm der Geräte)** — Live-Desktop-Streaming der verwalteten Geräte direkt im Browser. Nutzt intern `ffmpeg` mit H.264 über SSH, plus `xdotool` für die Eingabe — kein VNC, keine zusätzlichen Ports. Funktioniert mit X11/XFCE (Wayland geplant).

- **Geräte: Herunterfahren als Bulk-Aktion + Aktions-Dropdown** — Neuer „Herunterfahren"-Knopf in der Geräte-Detailansicht und als Sammel-Aktion. Wake/Reboot/Shutdown sind in einem aufgeräumten Aktions-Menü zusammengefasst.

- **DHCP: feste IP-Vergabe + Mismatch-Erkennung** — Beim Anlegen oder Importieren eines Geräts wird automatisch eine IP aus dem DHCP-Pool zugewiesen; dnsmasq reserviert sie fest auf die MAC-Adresse. Wenn ein Gerät später eine andere IP meldet (außer VPN-IP in anderem Subnetz), warnt das UI.

- **Heartbeat- und Klon-Provisioning, dynamische Server-URL** — - **Heartbeat:** Token-authentifiziert, meldet MAC und IP an den Server.
  - **Klon-Provisioning:** Globaler SSH-Schlüssel + `installKlon.sh` + Auto-Provisioning.
  - **Server-DNS-Eintrag** wird automatisch beim Setup-Wizard angelegt.
  - **Tools-ISO:** Server-URL wird dynamisch aus der Setup-Konfiguration eingebettet.
  - **zstd-Kompression** für Hardware-Captures — passwortloser Klon-Import möglich.
  - **TLS-Formular** beim Setup-Wizard mit Hostname und IPs vorbelegt.

- **Diverse Korrekturen** — - Remote Desktop: X11-Zugriff für Root automatisch korrekt eingerichtet.
  - Reboot funktioniert wieder (interne Bibliotheks-Inkompatibilität behoben).
  - DNS-Loop behoben (interner DNS-Upstream zeigte auf sich selbst).
  - PXE-Boot funktioniert (mehrere kleine Korrekturen rund um Boot-Modus, DHCP-Reload und feste IPs).
  - NFS-Mounts nutzen die fest zugewiesene IP statt der Heartbeat-IP.
  - Clean-Reset-Skript ist vollständiger.
  - Hardware-Captures im älteren `.gz.aa`-Format können wieder wiederhergestellt werden.


## 2026-03-15

- **Mehrere neue Funktionen rund um Klone, NFS und Wartung** — - **NFS-Export-Isolation:** Freigaben nur für autorisierte Geräte-IPs zugänglich.
  - **Capture-Nachfolge-Aktion:** Konfigurierbar, was nach einem Capture passiert.
  - **Lager-Modus:** Geräte können als eingelagert markiert werden.
  - **Versions-Mismatch-Alarm:** Warnung, wenn ein Gerät nicht mehr auf der aktuellen Klon-Version läuft.
  - **Wartungsfenster:** Zeitfenster für geplante Deployments.
  - **TLS-Zertifikatsverwaltung über die UI** mit eigener Sidebar-Navigation.
  - **Tools-ISO für die Cloning-VM:** AHCI-CD-ROM-Korrektur, verbesserte Anzeige, Hostname-Skript.
  - **Umbenennung des Produkts** von ThinOS auf ThinForge (App-Name zentral, Setup-Wizard entsprechend angepasst).


## 2026-03-14

- **Zeit-Synchronisation auf den Clients + UEFI-PXE-Verbesserungen** — Neuer Chrony-basierter NTP-Server für die Geräte. Setup-Wizard mit Capture-Restart und Netzwerk-Härtung verbessert. UEFI-Geräte können per PXE mit lokalem Boot-Fallback gestartet werden.


## 2026-03-13

- **Geplante Deployments, BitTorrent-Stabilität, Wake-on-LAN** — - Zeitgesteuerte Klon-Deployments (zu einem geplanten Zeitpunkt).
  - Stabilitäts- und Performance-Verbesserungen am BitTorrent-Seeder.
  - Wake-on-LAN-Knopf in der UI.
  - Bessere Benutzungsführung beim Werks-Reset.


## 2026-03-12

- **BitTorrent- und Multicast-Deployment** — - **BitTorrent:** Peer-zu-Peer-Verteilung der Klon-Images für viele parallel zu klonende Geräte.
  - **Multicast:** Server streamt das Image einmal, mehrere Geräte empfangen gleichzeitig. Mit Countdown-Anzeige für den Nutzer, bis alle Empfänger bereit sind.


## 2026-03-11

- **Container-Stabilität + neuer Deployments-Tab** — Alle Docker-Dienste sind jetzt mit automatischem Neustart und Gesundheitsprüfungen ausgestattet. Neuer Tab „Klon-Deployments" für die Deployment-Verwaltung; Klone können einzelnen Geräten zugewiesen werden.


## 2026-03-10

- **Capture-Jobs-System und Dashboard-Einstellungen** — PXE-basierte Disk-Captures mit Abbruch-Funktion. Layout-Anpassungen und Einstellungs-Möglichkeiten im Dashboard.


## 2026-03-09

- **Aufgaben-System mit Fortschritt + verschlüsselter Klon-Export** — - Fortschrittsanzeige für laufende Aufgaben.
  - Zeitgesteuerte Aufgaben.
  - Optional passwort-verschlüsselter Klon-Export.
  - Versionsverfolgung des Geräte-Agents.


## 2026-03-08

- **UEFI-Boot, DNS-Weiterleitung, Restore-Fortschritt** — - **UEFI-PXE-Boot** (GRUB-EFI-Unterstützung).
  - **DNS-Weiterleitung** über dnsmasq mit UI-Konfiguration.
  - **Fortschrittsanzeige beim Klon-Wiederherstellen.**
  - **Automatische Erkennung der externen DNS-Server** im Setup.
