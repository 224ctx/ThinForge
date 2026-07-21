# ThinForge Changelog

## 2026-07-21

- **Geräte mit automatischer Anmeldung fragen beim Aufwachen kein Passwort mehr ab** — Auf Geräten mit automatischer Anmeldung verlangte der Bildschirm nach Bildschirmschoner oder Energiesparmodus bislang trotzdem ein Passwort. Die Ersteinrichtung schaltet die Bildschirmsperre jetzt passend zur automatischen Anmeldung ab; Bildschirmschoner und Energiesparen bleiben aktiv, nur die Passwortabfrage beim Aufwachen entfällt. *(Tools-ISO)*

## 2026-07-19

- **Änderungsverlauf auf Englisch und in kompakter Form** — Der Änderungsverlauf (Klick auf die Versionsnummer) erscheint jetzt in der Sprache der Oberfläche; dafür gibt es eine englische Fassung des gesamten Verlaufs. Zugleich wurden die Einträge beider Sprachen auf eine kompakte Kurzform gestrafft; die ausführlichen früheren Fassungen bleiben in der Projekthistorie erhalten. *(Backend, Verwaltungsoberfläche)*

- **Dienste-Status: Verwaltungsoberfläche wird nicht mehr fälschlich als „unhealthy" angezeigt** — Seit dem gehärteten, minimalen Laufzeit-Image meldete die Container-Zustandsprüfung die Verwaltungsoberfläche dauerhaft als „unhealthy", weil die alte Prüfung eine im Image bewusst nicht vorhandene Shell voraussetzte. Die Zustandsprüfung läuft jetzt über eine eigene, mit ins Image eingebaute Prüfkomponente. Der Status wird wieder korrekt ermittelt, ohne die Härtung des Images aufzuweichen. *(Verwaltungsoberfläche, Deploy-Repo)*

- **Deployments beziehen nur noch getestete, versionierte Container-Images** — Die Bereitstellung nutzt jetzt ein Zwei-Kanal-Modell: Entwicklungsstände laufen in der Registry als eigener Entwicklungs-Kanal, produktive Deployments beziehen fest verankerte, nach Jahr-Monat-Tag versionierte Stände, die erst nach bestandenem Test freigegeben werden — auch der bisherige „neueste Version"-Verweis zeigt jetzt immer auf den zuletzt getesteten Stand. Für bestehende Installationen ändert sich am gewohnten Update-Ablauf nichts; ein Zurückgehen auf einen früheren Stand ist über die Versionshistorie jederzeit möglich, da alle Stände in der Registry erhalten bleiben. Ein Deployment kann damit nicht mehr versehentlich einen ungetesteten Zwischenstand ziehen. *(Deploy-Repo)*

- **Ausgesperrte Clients per Klick wiederherstellen: „Reset auf Install Token"** — Meldete sich ein Client mit dem generischen Install-Token, obwohl er bereits mit einem eigenen Geräte-Token registriert war (etwa nach einer Neuinstallation außerhalb eines Rollouts), wies der Server ihn aus Sicherheitsgründen ab — der Client erschien dann dauerhaft als offline, ohne erkennbare Ursache. Die Client-Liste zeigt diesen Zustand jetzt als **„Install Token erkannt!"** an, mit einer neuen Aktion **Reset auf Install Token**: Nach einer Sicherheitsabfrage verwirft sie die veraltete Registrierung, sodass sich der Client beim nächsten Lebenszeichen automatisch neu registriert — ohne Neuinstallation oder manuellen Eingriff in der Datenbank. *(Server-Dienste, Verwaltungsoberfläche)*

- **Herunterfahren bleibt nicht mehr am Ausschalt-Bildschirm hängen (veralteter Agent)** — War ein älterer Agent ohne den neueren Update-Befehl mit einer neueren Dienst-Konfiguration kombiniert, konnte der Update-Aufruf beim Herunterfahren versehentlich den Agent-Hintergrunddienst starten, auf dessen Ende das System bis zu zehn Minuten vergeblich wartete. Der Agent bricht unbekannte Aufrufe jetzt sofort mit einer Fehlermeldung ab, statt in den Hintergrunddienst zu wechseln. Das Herunterfahren läuft damit auch bei einem Versionsunterschied zwischen Agent und Dienst-Konfiguration ohne Verzögerung. *(Agent)*

## 2026-07-18

- **Ersteinrichtung ohne irreführende Warnung zum Playbook-Dienst** — Beim Abschluss der Ersteinrichtung erschien bisher eine Warnung zum Playbook-Dienst (Semaphore), obwohl dieser derzeit gar nicht Teil der Installation ist. Die Einrichtung erkennt das jetzt und überspringt den Schritt ohne Warnung, auch beim Ändern des Admin-Passworts. **Sicherheitsrelevant:** Bei jedem dieser vergeblichen Versuche blieb bisher eine temporäre Datei mit Zugangsdaten im Klartext im Datenverzeichnis liegen — sie wird nicht mehr geschrieben, und eine aus früheren Läufen vorhandene Datei wird beim nächsten Setup bzw. Passwort-Wechsel automatisch entfernt. *(Server-Dienste)*

- **Client löschen widerruft jetzt auch den VPN-Zugang** — Wurde ein Client gelöscht, ohne sein VPN vorher zu deaktivieren, blieb der zugehörige VPN-Zugang bestehen, war in der Verwaltung aber nicht mehr sichtbar. Das Löschen entfernt jetzt automatisch auch den VPN-Zugang; ist die VPN-Verwaltung gerade nicht erreichbar, wird das Löschen dadurch nicht blockiert, sondern nur protokolliert. Zusätzlich zeigt die Lizenzanzeige ohne gültige Lizenz keine irreführende Belegungszeile mehr an. *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-07-17

- **Neues Lizenzmodell: Vollversion für alle Clients, Lizenz nur noch für VPN-Clients** — Die Unterscheidung zwischen Light- und Full-Clients entfällt ersatzlos: Delta-Updates, Snapshots und Rollback stehen jetzt jedem Client zur Verfügung, und die Anzahl verwalteter Clients ist nicht mehr begrenzt. Lizenzpflichtig ist stattdessen die Aktivierung von VPN-Clients — ohne gültige Lizenz können keine neuen VPN-Clients aktiviert werden, mit Lizenz bestimmt sie deren maximale gleichzeitige Anzahl; bereits aktive VPN-Clients laufen bei Ablauf der Lizenz unverändert weiter, eine Nachfrist gibt es nicht mehr. **Wichtig:** Lizenzdateien des alten Formats sind ab dieser Aktualisierung ungültig und werden mit klarer Fehlermeldung abgewiesen — für die VPN-Client-Aktivierung ist eine neue Lizenzdatei erforderlich; beim Worker ist zusätzlich eine aktualisierte Compose-Konfiguration mit Lizenz-Verzeichnis-Freigabe nötig. *(Server-Dienste, Verwaltungsoberfläche, Agent)*

## 2026-07-13

- **ThinForge ist jetzt Open Source (GPL-3.0-or-later)** — Die gesamte von ThinForge stammende Software — Server-Dienste, Verwaltungsoberfläche, Agent und Werkzeuge — steht ab sofort unter der GNU General Public License Version 3 (oder, nach Wahl, jeder späteren Version). Die Datei LICENSE enthält den vollständigen GPLv3-Text; NOTICE erläutert die Lizenzlage inklusive der weiterhin unter GPL v2 stehenden Drittkomponenten Partclone und EZIO. Am Betrieb, Funktionsumfang und den bestehenden Wartungs- und VPN-Angeboten ändert sich nichts — neu ist, dass der Quellcode offen einsehbar, prüfbar und unter den Bedingungen der GPL weiterverwendbar ist. *(Server-Dienste, Verwaltungsoberfläche, Agent, Tools-ISO)*

## 2026-06-23

- **Einheitlicher Grauton für ausgeklappte Detailbereiche** — Ausgeklappte Detailbereiche und einige Übersichtsflächen hatten im dunklen Erscheinungsbild einen fast weißen Hintergrund, der sich unschön abhob. Sie verwenden jetzt überall denselben, zum Design passenden Grauton — sowohl im dunklen als auch im hellen Erscheinungsbild. *(Verwaltungsoberfläche)*

- **Sitzungsdauer wirkt jetzt tatsächlich** — Die Einstellung Sitzungsdauer hatte bisher keine Wirkung: Sitzungen liefen unabhängig vom gewählten Wert erst nach sieben Tagen Inaktivität ab, und ein Neustart des Rechners beendete die Sitzung nicht. Der eingestellte Wert steuert die Sitzung jetzt als gleitendes Zeitfenster — nach der gewählten Dauer ohne Aktivität ist eine erneute Anmeldung erforderlich, aktive Nutzung verlängert das Fenster fortlaufend. Die Änderung gilt für neue Anmeldungen; bestehende Sitzungen übernehmen sie mit der nächsten automatischen Erneuerung. *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-06-22

- **Geräte „Auf Lager" verfälschen keine Alarme, Berichte und Lizenzzählung mehr** — Geräte mit Status „Auf Lager" werden jetzt überall einheitlich behandelt: Sie lösen keine Dashboard-Warnungen mehr aus, ein bereits gemeldeter Alarm wird beim Einlagern automatisch geschlossen, und sie zählen nicht mehr in die Flotten-, Auslastungs-, Lebenszyklus-, VPN- und Verfügbarkeitskennzahlen der Berichte hinein. In den Bestands-Übersichten werden sie als eigener Block getrennt ausgewiesen, und die Dashboard-Kacheln zeigen die aktive Flotte ohne Lagerbestand, weisen ihn aber separat aus. Die Lizenzzählung war bereits korrekt und wurde an dieselbe zentrale Filterregel angeschlossen; die Tages-Verlaufskurve der Verfügbarkeit wird ab der Aktualisierung bereinigt erfasst, bereits aufgezeichnete Tage bleiben unverändert. *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-06-19

- **Dashboard: direkte Verknüpfung zu den passenden Berichten** — Die Metrik-Kacheln auf dem Dashboard erhalten ein kleines Diagramm-Symbol, das direkt den passenden Bericht öffnet (z. B. Speicher → Speicher-Bericht, Client-Status → Verfügbarkeit, Lizenz → Lizenz, Aktive Alarme → Störungen, Rollouts → Deployments, Aktivität → Tasks, Compliance → Compliance). Die bisherigen Verknüpfungen bleiben daneben erhalten. *(Verwaltungsoberfläche)*

## 2026-06-18

- **Berichte: interne Überarbeitung, Bedienung verbessert** — Die Berichtssektion wurde technisch neu strukturiert, mit gleichen Inhalten, Tabs und Diagrammen wie zuvor. Spürbar: Der Aktualisieren-Knopf lädt jetzt gezielt den gerade geöffneten Bericht neu, der Speicher-Bericht blockiert den Server beim Einlesen der Datenträger nicht mehr, und eine Aktualisierung läuft auch bei Altbeständen mit Doppelwerten in der Datenbank sauber durch (keine Neustart-Endlosschleife mehr). *(Server-Dienste, Verwaltungsoberfläche)*

- **Berichte: Flotten-Verfügbarkeit als Tagestrend** — Die Berichtssektion erhält einen neuen Tab Verfügbarkeit mit Zeitraumwahl (7/30/90 Tage): aktuelle Flotte (online/offline/Fehler/gesamt), Verlauf der Online-Quote als Diagramm, Verteilung nach letztem Kontakt sowie eine Liste chronisch offline gefallener Geräte. Der Tagestrend baut sich ab dem Tag der Aktualisierung auf, da eine tägliche Momentaufnahme erst ab jetzt erfasst wird — rückwirkende Werte gibt es nicht; die Übersicht „letzter Kontakt" und die chronisch-offline-Liste stehen dagegen sofort zur Verfügung. *(Server-Dienste, Verwaltungsoberfläche)*

- **Berichte: Speicher-/Kapazitätsübersicht + VPN-/LAN-Konnektivitätsabdeckung** — Zwei neue Übersichts-Tabs: Speicher zeigt das belegte Image-Volumen, die Datenträger-Auslastung in Prozent (ab 85 % farblich hervorgehoben), eine Prognose bis zur Speicher-Erschöpfung sowie die größten Verbraucher nach Ordner-Kategorie; VPN zeigt eine Momentaufnahme der Konnektivität — aktive und Cloud-Verbindungen, Fehler, versiegelte TPM-Module sowie die Abdeckung je VPN-Gruppe. Beide Übersichten brauchen keine Zeitraumwahl und laden beim ersten Öffnen. *(Server-Dienste, Verwaltungsoberfläche)*

- **Berichte: Lizenz-Auslastung + Lebenszyklus/Ablauf — für alle Rollen sichtbar** — Zwei neue Tabs: Lizenz zeigt einen Seat-Forecast mit Belegung, Auslastung, Lizenz-Status und verbleibenden Tagen bis Ablauf sowie den Verlauf der Geräte-Aufnahmen; Lebenszyklus zeigt bevorstehende Abläufe von Zertifikaten und Geräte-Garantien gruppiert nach Restlaufzeit. Die Lizenz-Auswertung zeigt bewusst nur zusammengefasste Kennzahlen ohne sensible Details und ist daher auch für reine Leserechte-Konten sichtbar. *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-06-17

- **Berichte: drei weitere zeitbasierte Auswertungen** — Drei zusätzliche Tabs mit Zeitraumwahl (7/30/90 Tage, Gruppierung nach Tag/Woche): Updates zeigt Erfolgsquote, Signaturfehler, Wiederholungen und Download-Rate der Delta-Updates; Tasks zeigt Durchsatz und Fehlerquote der Geräte-Aufgaben je Typ; DHCP zeigt die Vergabe von Netzwerk-Adressen im Zeitverlauf. Updates und Tasks lassen sich als CSV exportieren. *(Server-Dienste, Verwaltungsoberfläche)*

- **Berichte: drei neue zeitbasierte Auswertungen** — Drei weitere Tabs mit Zeitraumwahl und CSV-Export: Störungen zeigt den Verlauf neuer Störungen sowie Bestätigungs- und Lösungszeiten je Störungsart; Aktivität zeigt die SSH-Befehlsaktivität mit Fehlerquote und den aktivsten Geräten; Deployments zeigt die Erfolgsquote von Rollouts mit Abschluss-Verlauf und Dauer-Kennzahlen. *(Server-Dienste, Verwaltungsoberfläche)*

- **Berichtssektion wieder verfügbar und erweitert** — Der Menüpunkt Berichte (Tabs Compliance und Nutzung) ist wieder in der Navigation erreichbar. Compliance zeigt zusätzlich die Verteilung der Agent-Versionen über die Flotte samt Hinweis auf veraltete oder nie eingecheckte Geräte sowie den Gesundheitszustand geplanter Hintergrund-Aufgaben; Nutzung zeigt zusätzlich die Hardware-Auslastung pro Gruppe (Ampel-Tabelle) sowie die Verteilung der Geräte über Gruppen und Image-Versionen. Alle Auswertungen lassen sich mitdrucken. *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-06-12

- **Geräte-Updates passen sich schwankender Bandbreite an (Home-Office/VPN/WLAN)** — Die Download-Drosselung für Betriebssystem-Updates misst die Leitungsqualität jetzt direkt an der laufenden Verbindung statt an einem vorab erhobenen Referenzwert. Das behebt zwei Probleme: Nach einem Standortwechsel verharrte ein Update unnötig auf Minimalgeschwindigkeit, und auf schwachen Anschlüssen bremste es zu spät und störte parallele Arbeitssitzungen. Updates nutzen die verfügbare Bandbreite jetzt besser aus und drosseln automatisch, sobald die Leitung anderweitig gebraucht wird. *(Agent)*

- **Zuverlässigere Geräte-Aktionen und Rollouts** — Mehrere seltene Fehler wurden behoben: Geräte-Befehle wie Neustart konnten bei ungünstigem Timing doppelt ausgeführt werden, ein gestufter Rollout konnte hängen bleiben, wenn das gewählte Abbild noch nicht fertig gebaut war, und das Abbrechen eines Rollouts konnte ein gerade startendes Gerät fälschlich als abgebrochen markieren. Diese Abläufe sind jetzt abgesichert. *(Server-Dienste)*

- **Geräte-Updates lassen kein Rollback-Abbild mehr verlieren** — In seltenen Fällen konnte die automatische Aufräumung alter Systemstände den gerade laufenden Stand löschen, wodurch das nächste Update fehlschlug und eine Neuinstallation nötig wurde. Der laufende Stand ist jetzt geschützt, und beim Löschen eines Standes werden auch die zugehörigen Home-Daten entfernt. *(Agent)*

- **Abbruch während der ersten Update-Phase wird korrekt angezeigt** — Wurde ein Update-Klon während der ersten Phase abgebrochen, meldete die Oberfläche fälschlich „abgebrochen" und blieb stehen. Der Fortschritt läuft jetzt sichtbar weiter, bis die laufende Phase sauber endet. *(Server-Dienste)*

- **Zertifikats-Austausch hinterlässt nie ein unpassendes Schlüsselpaar** — Beim Hochladen eines eigenen TLS-Zertifikats konnte ein Fehler im letzten Schritt Zertifikat und Schlüssel inkonsistent zurücklassen. Schlägt der Austausch jetzt fehl, wird automatisch auf das vorherige, funktionierende Paar zurückgesetzt. *(Server-Dienste)*

- **Netzwerk-Adresse wird nicht mehr versehentlich entfernt** — Beim erneuten Setzen der Server-Adresse konnte eine ähnliche Bestandsadresse falsch erkannt werden, wodurch die Netzwerkkarte adresslos zurückblieb. Die Adress-Erkennung ist jetzt exakt. *(Server-Dienste)*

- **Aussagekräftige Fehlermeldungen in der Verwaltungsoberfläche** — Bisher zeigte die Oberfläche bei vielen Fehlern nur einen allgemeinen Hinweis, selbst bei einer gestörten Serververbindung. Fehlermeldungen nennen jetzt die konkrete Ursache — Server nicht erreichbar, Zeitüberschreitung, fehlende Berechtigung, nicht gefundene Ressource u. a. — in der eingestellten Sprache, ohne sich bei einer Verbindungsstörung im Sekundentakt zu wiederholen. Zusätzlich wird das Aktivieren eines Lager-Geräts am Lizenz-Limit jetzt mit klarer Meldung abgelehnt statt ohne Rückmeldung zu scheitern. *(Server-Dienste)*

- **Client-Agent: Update-Signatur wird vor dem Einspielen erzwungen** — Beim Anwenden eines Betriebssystem-Updates wurde die Signaturprüfung in einem Sonderfall — fehlende Signaturdatei — bisher stillschweigend übersprungen, statt das Update abzulehnen. **Sicherheitsrelevant:** Die Prüfung greift jetzt in jedem Fall, und die Update-Beschreibungsdaten werden zusätzlich streng auf gültige Form geprüft, damit keine manipulierten Update-Daten eingespielt werden können. *(Agent)*

- **Client-Agent: Update lässt das Gerät nie ohne Agent zurück** — Bei der Agent-Aktualisierung wurde die laufende Agent-Datei bisher entfernt, bevor die neue vollständig übertragen war — ein Übertragungsfehler hätte das Gerät ohne Agent zurückgelassen. Die neue Datei wird jetzt erst vollständig übertragen und geprüft, bevor sie die alte ersetzt; bei einem Fehler bleibt die funktionierende Version erhalten. *(Server-Dienste)*

- **Image-Wiederherstellung auf NVMe-/eMMC-Geräten** — Auf Geräten mit NVMe- oder eMMC-Speicher schlug das Anlegen der Daten-Partition fehl, weil der Gerätename falsch abgeleitet wurde. SATA-, NVMe- und eMMC-Datenträger werden jetzt korrekt erkannt. *(Tools-ISO)*

- **Image-Vorbereitung bricht bei fehlender Daten-Partition ab** — Konnte die Daten-Partition nicht eingebunden werden, lief die Installation bisher trotzdem weiter und legte Agent-Daten am falschen Ort ab, die nach dem ersten Update verloren gingen. Die Installation bricht jetzt mit klarer Meldung ab, statt fehlerhaft fortzufahren. *(Tools-ISO)*

- **Klon-Fehler werden zuverlässig gemeldet** — Beim Erstellen eines Klons konnte ein Fehler an einer Partition den Vorgang bisher stillschweigend abbrechen, ohne ihn als Fehler auszuweisen — solche Fehler werden jetzt erkannt und mit der betroffenen Partition gemeldet. Zusätzlich wurde die Wiederherstellung von Festplatten-Abbildern korrigiert, die zuvor ihre Dateien nicht fand. *(Tools-ISO)*

- **Agent-Upload kann die Agent-Datei nicht mehr zerstören** — Ein versehentlich leerer oder ungültiger Upload der Agent-Datei überschrieb bisher die funktionierende Version, bevor er geprüft wurde. Uploads werden jetzt erst auf Inhalt und Dateityp geprüft und nur bei Gültigkeit übernommen. *(Server-Dienste)*

- **Agent-Update einzelner Geräte stoppt keine fremden Updates mehr** — Das Starten eines Agent-Updates für ausgewählte Geräte oder eine Gruppe brach bisher alle laufenden Agent-Updates flottenweit ab. Jetzt sind nur noch die tatsächlich angesprochenen Geräte betroffen. *(Server-Dienste)*

- **Stapel-Befehle per SSH berücksichtigen das eingestellte Zeitlimit** — Beim gleichzeitigen Ausführen eines Befehls auf mehreren Geräten wurde das angegebene Zeitlimit ignoriert und stattdessen fest 30 Sekunden verwendet, sodass länger laufende Befehle wie Paket-Updates vorzeitig abbrachen. Das eingestellte Zeitlimit wird jetzt tatsächlich verwendet. *(Server-Dienste)*

- **Gleichzeitige Klon-/Wiederherstellungs-Vorgänge stören sich nicht mehr** — Wurden zwei Cloning-Vorgänge fast gleichzeitig gestartet, etwa per Doppelklick, konnten beide starten und sich gegenseitig die Daten beschädigen. Der Einzelvorgang-Schutz greift jetzt zuverlässig, und ein Abbruch während der ersten Phase eines Update-Klons wird ehrlich gemeldet und tatsächlich befolgt. *(Server-Dienste)*

- **Server bleibt nach kurzen Docker-Aussetzern erreichbar** — Bei einem kurzen Aussetzer des Container-Dienstes während des Speicherns der Netzwerk-Konfiguration konnte der Server die korrekt eingestellten Adressen verlieren und für Clients unerreichbar werden, obwohl „gespeichert" gemeldet wurde. Die Adressermittlung greift in diesem Fall jetzt auf die hinterlegte Konfiguration zurück. *(Server-Dienste)*

- **Netzwerk-Adresse wird vor dem Anwenden geprüft** — Beim Setzen der Rollout-Netzwerkadresse wurden ungültige Adressen bisher erst akzeptiert und die alte Adresse entfernt, was die Netzwerkkarte adresslos zurücklassen konnte. Adressen werden jetzt vorab geprüft, und die neue wird gesetzt, bevor die alte entfernt wird. *(Server-Dienste)*

- **NTP-Zugriffsbeschränkung bleibt nach Bearbeitung erhalten** — Das Bearbeiten der Zeitserver öffnete bisher den Zeitdienst versehentlich für das gesamte Netzwerk, statt ihn auf das Rollout-Subnetz beschränkt zu lassen. Die im Setup gesetzte Beschränkung bleibt jetzt erhalten. *(Server-Dienste)*

- **Verteilung per BitTorrent meldet Fehler korrekt** — Schlug das Hinzufügen einer Partition beim BitTorrent-Restore fehl, wurde der Vorgang trotzdem als erfolgreich gemeldet, obwohl eine Partition nicht geschrieben war. Solche Fehler werden jetzt erkannt und der Vorgang als fehlgeschlagen gemeldet. *(Server-Dienste)*

- **Aufgaben werden bei Worker-Ausfall nicht mehr mehrfach ausgeführt** — Fiel der Hintergrund-Dienst zeitweise aus, wurde eine wartende Aufgabe bei jedem Geräte-Kontakt erneut eingereiht und später vielfach ausgeführt. Aufgaben werden jetzt nur noch einmal eingereiht. *(Server-Dienste)*

- **ThinVPN: Modul- und Router-Verwaltung robuster** — Doppelte oder mit internen Namen kollidierende VPN-Modulnamen werden jetzt abgewiesen, statt eine dauerhaft instabile Konfiguration zu erzeugen. Bei mehreren Geräten gleichen Namens wird die VPN-Zuordnung nicht mehr falsch geraten, und ein zweiter, manuell angelegter Netzwerk-Router wird nicht mehr versehentlich überschrieben. *(Server-Dienste)*

- **Fehler werden nicht mehr stillschweigend verschluckt** — An mehreren Stellen wurden interne Fehler ignoriert und Aktionen fälschlich als erfolgreich gemeldet. Behoben u. a.: Ein kurzer Datenbank-Aussetzer löscht beim Speichern von Alarm-Kanälen nicht mehr das hinterlegte SMTP-Passwort, ein abgebrochener ISO-Upload hinterlässt keine unvollständige, trotzdem auswählbare Datei mehr, die Dienst-Überwachung meldet einen Datenbank-Ausfall jetzt ehrlich als „degraded", und fehlgeschlagene NFS-Freigaben, Zeitdienst-Neustarts, Playbook-Importe sowie ein unvollständiger Werksreset werden sichtbar gemeldet statt verschluckt. *(Server-Dienste)*

- **NTP-Server-Eingaben werden geprüft** — Beim Speichern der Zeitserver-Einstellungen werden ungültige Einträge — leer oder mit unerlaubten Zeichen — jetzt abgewiesen, statt eine fehlerhafte Zeitdienst-Konfiguration zu schreiben. *(Server-Dienste)*

- **Sicherheitsprotokoll erfasst jetzt An-/Abmeldungen und Verwaltungsaktionen** — Das Audit-Protokoll blieb bisher faktisch leer: An- und Abmeldungen, fehlgeschlagene Anmeldeversuche, Passwort- und 2FA-Änderungen, Benutzerverwaltung sowie Lizenz- und Signaturschlüssel-Aktionen wurden nicht aufgezeichnet. **Sicherheitsrelevant:** Diese Ereignisse landen jetzt im Audit-Protokoll; ein Werksreset wird zusätzlich ins Server-Log geschrieben, da er das Protokoll selbst leert. *(Server-Dienste)*

- **Passwort-Zurücksetzen beendet bestehende Sitzungen** — Wurde das Passwort eines Benutzers über die Benutzerverwaltung geändert, blieben dessen bestehende Sitzungen bisher gültig — ein zuvor entwendeter Zugang funktionierte weiter. **Sicherheitsrelevant:** Jetzt werden bestehende Sitzungen beendet und die Zwei-Faktor-Anmeldung zurückgesetzt. *(Server-Dienste)*

- **Mindestlänge für Passwörter durchgängig erzwungen** — Die Mindestlänge von 8 Zeichen galt bisher nur beim Selbst-Ändern des Passworts; beim Zurücksetzen sowie beim Anlegen und Bearbeiten von Benutzern konnten leere oder sehr kurze Passwörter gesetzt werden. Das wird jetzt überall geprüft. *(Server-Dienste)*

- **Härtung der Anmelde-Schnittstelle** — **Sicherheitsrelevant:** Die Abmelde-Schnittstelle ist jetzt ratenbegrenzt und akzeptiert nur noch gültige Sitzungs-Token; die Anmelde-Schnittstellen weisen übergroße Anfragen ab. Damit kann ein Gerät im Netzwerk den Server nicht mehr durch massenhafte oder überdimensionierte Anfragen belasten. *(Server-Dienste)*

- **Image-Aufnahme: Manipulation eines anstehenden Auftrags verhindert** — **Sicherheitsrelevant:** Ein Gerät im Netzwerk konnte bisher einen anstehenden Image-Aufnahme-Auftrag eines anderen Geräts stören, indem es dessen Netzwerk-Boot-Konfiguration zurücksetzte, bevor das Zugangs-Token geprüft wurde. Die Prüfung erfolgt jetzt zuerst. *(Server-Dienste)*

- **ThinVPN: Modul-Freigaben wirken nur noch auf den jeweiligen Host** — **Sicherheitsrelevant:** Bei den optionalen ThinVPN-Host-Modulen galten freigegebene Ports bisher versehentlich für die gesamte Zielgruppe statt nur für den Host des jeweiligen Moduls. Die Freigaben sind jetzt exakt auf den jeweiligen Modul-Host beschränkt; bestehende Konfigurationen werden beim nächsten Abgleich automatisch korrigiert. *(Server-Dienste)*

- **Image-Verteilung: Statusmeldung eines Geräts kann fremde Geräte nicht mehr stören** — **Sicherheitsrelevant:** Über die öffentliche Abschluss-Meldung einer Image-Verteilung konnte ein Gerät im Netzwerk bisher ein anderes registriertes Gerät ohne gültiges Zugangs-Token auf „offline" setzen und ihm den Dateizugriff entziehen. Diese Aktionen erfordern jetzt einen gültigen, zur laufenden Verteilung gehörenden Token. *(Server-Dienste)*

- **Stufenweise Image-Verteilungen werden vollständig nachverfolgt** — Bei stufenweisen Rollouts wurde der Abschluss einzelner Rechner intern nicht verbucht: Die Stufen-Statistik blieb auf „wird verteilt" stehen, und die Sicherheitsbremse bei zu vielen Fehlern konnte nie auslösen; zudem konnte ein ungünstig getimter Statusbericht die anstehende Neuinstallation eines Rechners unbemerkt entschärfen. Rollout-Stufen nutzen jetzt dieselbe bewährte Mechanik wie einzelne Verteilungen, mit korrekter Statistik und funktionierender Fehlerbremse. *(Server-Dienste)*

- **Benachrichtigungen bei Störungen funktionieren wieder** — Die regelmäßige Prüfung der Alarm-Regeln, etwa Client offline oder Festplatte voll, war durch einen Platzhalter lahmgelegt und lief nie. Sie läuft jetzt alle fünf Minuten. *(Server-Dienste)*

- **Wartungsfenster unterdrücken Alarme jetzt wirklich** — Wartungsfenster mit Geltungsbereich „alle Rechner" (die Voreinstellung) sowie wiederkehrende Fenster wurden bei der Alarm-Unterdrückung bisher ignoriert — Benachrichtigungen kamen trotz geplanter Wartung. Beides wird jetzt korrekt ausgewertet, auch in der Aktiv-Anzeige der Fenster-Liste. *(Server-Dienste)*

- **ThinVPN-Protokoll wächst nicht mehr unbegrenzt** — Die VPN-Ereignis-Übernahme speicherte dieselben Ereignisse bei jedem Abruf erneut, wodurch die Protokoll-Tabelle unbegrenzt wuchs. Ereignisse werden jetzt eindeutig erkannt und nur einmal gespeichert. *(Server-Dienste)*

- **TPM-Status der Clients wird gespeichert** — Der vom Client gemeldete TPM-Status — vorhanden oder versiegelt — ging beim Speichern still verloren, weil die dafür nötigen Datenbankfelder fehlten. Er wird jetzt zuverlässig gespeichert. *(Server-Dienste)*

- **„Lager"-Markierung beim Anlegen eines Clients wird übernommen** — Der Lager-Schalter im Anlege-Formular wurde beim Speichern bisher verworfen; die Markierung musste nachträglich gesetzt werden. Sie wird jetzt direkt beim Anlegen übernommen. *(Server-Dienste)*

- **Client-Agent: Sicherungsstände werden korrekt verwaltet** — Der Agent behält jetzt zuverlässig genau zwei Sicherungsstände — den aktuellen und den vorherigen — samt der zugehörigen Home-Bereiche. Bisher konnte eine fehlerhafte Sortierung dazu führen, dass die falschen Stände gelöscht und im Fehlerfall ein ungeeigneter Stand zur Wiederherstellung gewählt wurde. *(Agent)*

- **Mehrstufige Betriebssystem-Updates bleiben nicht mehr hängen** — Musste ein Client mehrere Update-Schritte nacheinander durchlaufen, etwa über eine Zwischenversion, konnte die Kette nach dem ersten Schritt stehen bleiben, weil der nächste Schritt nie eine Download-Freigabe erhielt. Betroffen waren nur Ketten ohne zusammengefasste Updates; das ist jetzt behoben. *(Server-Dienste)*

- **Einrichtungs-Assistent prüft Eingaben und meldet Teilprobleme** — Der Assistent nimmt fehlerhafte Eingaben — etwa ein zu kurzes Administrator-Passwort, ungültige Netzwerk-Adressen oder eine ungültige Zertifikats-Laufzeit — nicht mehr an, sondern weist sie vor dem Speichern mit klarer Fehlermeldung ab. Schlägt beim Abschluss ein Teilschritt fehl, etwa das Erzeugen des Zertifikats, wird das jetzt am Ende des Assistenten angezeigt statt hinter einer Erfolgsmeldung zu verschwinden. *(Server-Dienste)*

- **Geplante Verteilungen funktionieren auch im Release-Deployment** — In der Auslieferungs-Variante der Dienste fehlten dem Hintergrund-Dienst einige Zuordnungen und Einstellungen, die er zum Aktivieren geplanter Verteilungen braucht, und die DHCP/PXE-Überwachung nutzte dort noch eine weniger aussagekräftige Prüfung. Beides ist jetzt an die Entwicklungs-Variante angeglichen. *(Server-Dienste)*

- **Werksreset macht den Server nicht mehr unbrauchbar** — Nach einem Zurücksetzen auf Werkseinstellungen konnte der Server beim nächsten Neustart in einer Fehlerschleife hängen bleiben, weil eine interne Verwaltungstabelle mitgeleert wurde; außerdem ließ sich die ThinVPN-Verwaltung danach nicht mehr einrichten. Beides ist behoben — der Reset hinterlässt jetzt einen sauberen Zustand für den Einrichtungs-Assistenten. *(Server-Dienste)*

- **Zertifikats-Upload kann die Weboberfläche nicht mehr lahmlegen** — Beim Hochladen eines eigenen TLS-Zertifikats wurde das bisherige Zertifikat bisher ersetzt, bevor die Dateien geprüft waren — ein defekter Schlüssel machte die Weboberfläche anschließend unerreichbar. Zertifikate und Schlüssel werden jetzt vollständig geprüft, bevor sie übernommen werden; bei Fehlern bleibt das bisherige Zertifikat aktiv und der Upload wird mit klarer Meldung abgewiesen. *(Server-Dienste)*

- **Abgebrochene Verteilungen starten keine neuen Installationen mehr** — Wurde ein stufenweiser Rollout abgebrochen, blieben betroffene Rechner trotzdem für die Neuinstallation vorgemerkt und wurden beim nächsten Start neu bespielt. Ein Abbruch nimmt noch nicht gestartete Rechner jetzt zuverlässig aus der Verteilung, während bereits laufende Installationen ungestört zu Ende laufen. *(Server-Dienste)*

- **DHCP/PXE-Dienst übersteht Server-Neustarts zuverlässig** — Kam nach einem Server-Neustart die Rollout-Netzwerkkarte erst nach dem Container-Dienst hoch, startete der DHCP/PXE-Dienst nicht mehr und blieb dauerhaft stehen. Er wartet jetzt automatisch auf die Netzwerkkarte und bindet sich, sobald sie verfügbar ist; ein dauerhaft fehlendes oder falsch konfiguriertes Interface wird zusätzlich in der Dienst-Überwachung als fehlerhaft angezeigt. *(Server-Dienste)*

- **Namensauflösung „thinforge-server" zeigt nicht mehr auf eine falsche Adresse** — Wurden Netzwerk- oder DNS-Einstellungen gespeichert, während das Rollout-Interface gerade nicht verfügbar war, konnte der interne DNS-Eintrag „thinforge-server" dauerhaft auf eine falsche Adresse zeigen — Clients hätten den Server dann nicht erreicht. Das Speichern verwendet jetzt die hinterlegte Rollout-Adresse oder weist die Änderung mit klarer Fehlermeldung ab. *(Server-Dienste)*

- **Hinweis-Dialoge auf den Client-Rechnern erscheinen wieder zuverlässig** — Meldungen, die der Agent auf dem Bildschirm des angemeldeten Benutzers anzeigt — etwa der Neustart-Countdown nach einem Update — wurden in bestimmten Anmelde-Situationen nicht mehr angezeigt, weil der Agent versehentlich eine bereits abgemeldete Sitzung ansprach. Er wählt jetzt zuverlässig die tatsächlich aktive Sitzung. *(Agent)*

- **Image-Vorbereitung: sudo-Rechte je Benutzer auswählbar** — Beim Abschließen einer Basis-Installation über die Tools-ISO lässt sich jetzt per Auswahlliste festlegen, welche lokalen Benutzer sudo-Rechte erhalten; die Auswahl wird geprüft und sauber hinterlegt. Der ausgewählte Benutzer wird zugleich als automatische Anmeldung eingerichtet — wird niemand ausgewählt, wird auch nichts vergeben. *(Tools-ISO)*

- **Desktop-Hintergrund wird zuverlässig gesetzt** — Der ThinForge-Hintergrund wird beim Login jetzt auch auf XFCE-Desktops unter Debian 13 korrekt übernommen und sofort angewandt; bisher konnte in manchen Konstellationen der voreingestellte System-Hintergrund bestehen bleiben. *(Tools-ISO)*

- **Image-Vorbereitung: nicht benötigte Programme werden entfernt** — Beim Abschließen einer Basis-Installation werden vorinstallierte, im Thin-Client-Betrieb nicht benötigte Programme — u. a. LibreOffice, diverse XFCE-Zubehör-Apps, Terminal-Emulatoren — jetzt automatisch entfernt und der Paket-Cache geleert. Die Desktop-Oberfläche bleibt dabei vollständig erhalten, das Image wird schlanker. *(Tools-ISO)*

- **VDI-Clients (Citrix / Parallels / Omnissa Horizon) integrierbar** — Die VDI-Clients lassen sich jetzt über einen Ordner auf der Tools-ISO bereitstellen; zum Abschluss der Image-Vorbereitung wird ihre Installation optional angeboten. *(Tools-ISO)*

- **Neue Funktion: VDI-Client-Pakete über die Weboberfläche hochladen** — Im Bereich Cloning gibt es einen neuen Tab „VDI-Clients", über den die Installationspakete für Citrix Workspace App, Parallels Client und Omnissa Horizon Client hochgeladen werden können. Die Pakete werden beim nächsten Start der Cloning-VM automatisch in die Tools-ISO übernommen; bisher mussten sie manuell auf dem Server abgelegt werden, was vor allem bei Omnissa problematisch war, weil der Download eine Herstelleranmeldung erfordert. *(Server-Dienste)*

- **Hardware-Inventar der Geräte wird wieder erfasst** — Die per Inventar-Abfrage ermittelten Hardware-Daten — CPU, Arbeitsspeicher, Hersteller, Modell, Seriennummer, BIOS, Datenträger — wurden zwar abgefragt, aber nicht gespeichert; die entsprechenden Felder blieben leer. Sie werden jetzt ausgewertet und beim Gerät hinterlegt. *(Server-Dienste)*

- **Verteilungen werden zuverlässig als abgeschlossen erkannt** — Ging die abschließende Fertig-Meldung eines Geräts verloren, etwa durch einen Neustart kurz vor der Rückmeldung, blieb eine Verteilung dauerhaft als „aktiv" stehen. Ein Abgleich erkennt jetzt Verteilungen, bei denen bereits alle Geräte fertig sind, und schließt sie ab. *(Server-Dienste)*

- **Wiederherstellung prüft alle ausgewählten Sicherungen** — Schlug bei der Auswahl mehrerer Sicherungsdateien die Prüfung einer Datei fehl, konnte die Wiederherstellung trotzdem mit ungeprüften Dateien weiterlaufen. Sie wird jetzt blockiert, bis jede ausgewählte Datei erfolgreich geprüft wurde. *(Server-Dienste)*

- **Speichern eines Updates legt nicht versehentlich eine neue Basis an** — Konnte der Dialog „Klon speichern" den VM-Status beim Öffnen nicht laden, wechselte er bisher stillschweigend in den Basis-Modus — der Bediener hätte unbemerkt eine neue Basis statt eines Updates angelegt. Jetzt erscheint stattdessen ein deutlicher Fehlerhinweis, und das Speichern bleibt gesperrt. *(Server-Dienste)*

- **Fortschrittsanzeige hängt nicht mehr bei kurzen Aussetzern** — Ein einzelner kurzer Abfrage-Fehler während eines Klon-/Wiederherstellungs-Vorgangs ließ die Anzeige bisher dauerhaft auf „läuft" stehen. Erst nach mehreren aufeinanderfolgenden Fehlern wird die Aktualisierung jetzt gestoppt. *(Server-Dienste)*

- **Anmeldung und Uploads in der Weboberfläche robuster** — Eine fehlgeschlagene Anmeldung zeigt wieder die konkrete Fehlermeldung, statt den Nutzer wortlos zur Anmeldeseite zurückzuwerfen, und ein Datei-Upload beendet eine gültige Sitzung nicht mehr unnötig. *(Server-Dienste)*

- **Englische Beschriftung der Zeitserver-Einstellungen** — Im englischsprachigen Bereich der Zeitserver-Einstellungen wurden interne Platzhalter statt der eigentlichen Texte angezeigt. Die fehlenden Übersetzungen wurden ergänzt. *(Server-Dienste)*
## 2026-06-02

- **OS-Update nach Lizenz-Upgrade wird zuverlässig nachgeholt** — Ein während des lizenzlosen (eingeschränkten) Modus zurückgehaltenes Betriebssystem-Update wird nach dem Einspielen einer gültigen Lizenz jetzt automatisch nachgeholt. Bisher blieb das Update mitunter dauerhaft mit dem Hinweis „zu oft fehlgeschlagen" blockiert, weil Fehlversuche aus der lizenzlosen Zeit fälschlich mitgezählt wurden. *(Agent)*

- **Status-Ping erreicht jetzt auch VPN-Clients** — Der Erreichbarkeits-Ping aus der Clients-Übersicht wurde für über ThinVPN verbundene Clients bisher von der VPN-Firewall blockiert, sodass sie fälschlich als offline erschienen. Eine neue VPN-Regel erlaubt dem Server jetzt gezielt den Ping zu diesen Clients. *(Server-Dienste)*

- **Durchgängige Zweisprachigkeit (Deutsch/Englisch)** — Server-Fehlermeldungen und bisher fest deutsche Oberflächentexte folgen jetzt der gewählten Sprache. Die Provisionierungs-Skripte (Tools-ISO) geben ihre Meldungen einheitlich auf Englisch aus, und die Sprache der Hinweis-Dialoge auf den Client-Rechnern lässt sich serverseitig vorgeben. *(Server-Dienste, Agent)*

## 2026-06-01

- **Client-Authentifizierung gehärtet (individuelle Token)** — Jeder Client erhält nach dem ersten Kontakt ein eigenes Authentifizierungs-Token statt eines gemeinsamen. Ein kompromittierter Client kann dadurch nicht mehr im Namen anderer Clients Meldungen senden. Bei einem neu verteilten Client vergibt der Server das Token beim nächsten Kontakt automatisch neu. *(Server-Dienste)*

- **Clients-Übersicht: abgewiesene Anmeldungen sichtbar** — Kann sich ein Client nicht mehr mit gültigem Token anmelden, wird er in der Clients-Übersicht jetzt rot mit „Token abgelehnt" markiert statt nur als offline, sodass das Problem sofort auffällt. *(Server-Dienste)*

- **Neue Aktion „Token neu ausstellen" je Client** — In der Clients-Übersicht lässt sich für einen einzelnen Client ein neues Authentifizierungs-Token ausstellen; der Client übernimmt es beim nächsten Kontakt, ohne andere Clients zu beeinflussen. *(Server-Dienste)*

- **VPN-Einrichtung: nicht-funktionaler „Anleitung"-Link entfernt** — Auf der VPN-Seite wurde der „Anleitung"-Button entfernt, der auf eine noch nicht vorhandene Dokumentationsseite verwies. *(Server-Dienste)*

- **Sicherheits-Härtung der Update- und Zertifikatsverteilung** — Der Download von Betriebssystem-Updates (Deltas) ist jetzt fest an genau das Update gebunden, für das ein Client berechtigt wurde — fremde Update-Dateien lassen sich nicht mehr abrufen. Operator-hinterlegte Vertrauens-Zertifikate werden vor dem Einspielen signiert und vom Client kryptografisch geprüft, und die Fernwartungs-Steuerung wurde gegen manipulierte Eingaben abgesichert. *(Server-Dienste, Agent)*

## 2026-05-31

- **Schwachstellen-Bericht priorisiert jetzt nach realer Dringlichkeit** — Die verbleibenden Schwachstellen im Bericht werden jetzt nach Ausnutzungs-Wahrscheinlichkeit und Behebbarkeit sortiert: bekannt aktiv ausgenutzte Lücken (CISA „Known Exploited") stehen zuoberst und sind markiert, danach folgt der Risiko-Wert, und pro Eintrag ist sichtbar, ob ein Fix verfügbar ist. Die Bewertung der einzelnen Schwachstellen ändert sich dadurch nicht. *(Server-Dienste)*

- **Schwachstellen-Bericht: über das VPN erreichbare Dienste werden gesondert als „External" ausgewiesen** — Über ThinVPN von außerhalb des lokalen Netzes erreichbare Dienste erhalten im Schwachstellen-Bericht jetzt die eigene, höchste Erreichbarkeits-Stufe „External" statt pauschal „LAN". Die Einstufung greift nur bei eingerichtetem VPN und macht deutlicher, welche Komponenten vorrangig zu behandeln sind; die Bewertung der einzelnen Schwachstellen bleibt unverändert. *(Server-Dienste)*

## 2026-05-30

- **Image-/Klon-Löschung während eines laufenden Rollouts blockiert** — Ein Image bzw. Klon kann nicht mehr gelöscht werden, solange ein laufender Rollout ihn noch verwendet; der Löschversuch wird mit einem Hinweis abgewiesen, statt den Vorgang zu stören. *(Server-Dienste)*

- **Zuverlässigeres Anmelden bei kurzzeitigen Netzwerkstörungen** — Anmeldung und Sitzungs-Wiederherstellung gehen robuster mit kurzen Verbindungsabbrüchen um: Ein vorübergehender Fehler beim Laden des Profils meldet nicht mehr fälschlich „abgemeldet", und eine erneut gesendete Anfrage löst keine doppelte Token-Erneuerung mehr aus. *(Server-Dienste, Verwaltungsoberfläche)*

- **Bedienkomfort in der Weboberfläche** — Im Konfigurationsdialog der Cloning-VM werden Eingaben nicht mehr alle 10 Sekunden vom automatischen Status-Abruf überschrieben. Ein manuell ausgelöstes Ping-Ergebnis überschreibt den echten Gerätestatus nur noch kurz statt dauerhaft, und eine zuvor exportierte Geräteliste lässt sich auch bei englischer Spracheinstellung wieder fehlerfrei importieren. *(Server-Dienste, Verwaltungsoberfläche)*

- **Korrekte Versionsnummern auch ab der 100. Aufnahme pro Tag** — Werden an einem Tag sehr viele Image-Stände unter demselben Namen erzeugt, wird der Tageszähler ab 100 jetzt korrekt fortgeführt statt zurückzuspringen. Betrifft nur Installationen mit sehr häufigen Aufnahmen. *(Server-Dienste)*

- **Wake-on-LAN über die richtige Netzwerkkarte** — Auf Servern mit mehreren Netzwerkkarten wird das Aufweck-Signal jetzt gezielt über die Rollout-Netzwerkkarte gesendet statt über eine vom Betriebssystem zufällig gewählte. *(Server-Dienste)*

- **Weitere interne Absicherungen** — Zusätzliche Prüfungen gegen ungültige Eingaben (DNS-Einstellungen, Datei-/Pfadangaben, CSV-Export) sowie kleinere Korrekturen an der internen Aufgabenverarbeitung. Keine sichtbare Änderung im Betriebsablauf. *(Server-Dienste)*

- **Administratoren können Sicherheitsmerkmale anderer Administratoren nicht mehr zurücksetzen** — Das Zurücksetzen der Zwei-Faktor-Anmeldung (TOTP) eines Kontos verhält sich jetzt wie das Zurücksetzen des Passworts: Konten mit der Rolle „Administrator" sind davon ausgenommen, das eigene Konto wird über die regulären Selbstbedienungs-Wege geändert. Damit kann ein Administrator einem anderen nicht mehr die zweite Sicherheitsstufe entfernen. *(Server-Dienste)*

- **Stabilität und Absicherung (Sammel-Aktualisierung aus einer internen Code-Durchsicht)** — Mehrere selten auftretende Fehlersituationen werden jetzt sauber behandelt statt unbemerkt zu scheitern: Ein Gerät ohne zugewiesene Adresse wird bei einem Rollout übersprungen statt hängenzubleiben, die Abbruch-Schwelle eines Rollouts rechnet nur noch über bereits abgeschlossene Geräte, ein Image-Versand kann nicht mehr versehentlich doppelt starten, und die VPN-Einrichtung bricht bei kurzzeitigen Störungen nicht mehr ab. Zusätzlich wurden mehrere mögliche Programmabstürze bei ungewöhnlichen Ausgaben abgefangen. Rein absichernde Änderungen ohne veränderten Ablauf. *(Server-Dienste)*

- **Geräte-Agent: stabiler bei der Update-Vorbereitung** — Schlägt das Vorbereiten eines Geräte-Updates unerwartet fehl, beendet das den laufenden Agenten nicht mehr — er meldet sich weiterhin regulär beim Server. Zusätzlich prüft der Agent die Versionsangabe strenger, bevor alte Sicherungspunkte aufgeräumt werden. *(Agent)*

- **Update-Rollout: Starten genügt — kein separater „Freigeben"-Schritt mehr nötig** — Beim Starten eines Update-Rollouts wird das zugehörige Delta-Update jetzt automatisch zur Auslieferung freigegeben; die zugewiesenen Geräte ziehen es beim nächsten Kontakt. Zuvor konnte ein gestarteter Rollout ohne vorherige manuelle Freigabe wirkungslos bleiben, weil die Geräte nichts erhielten. *(Server-Dienste)*

- **Zusätzliche Absicherung der auf den Geräten ausgeführten Skripte** — Die Wartungs- und Einrichtungsskripte, die der Agent mit erhöhten Rechten ausführt, werden jetzt zusätzlich kryptografisch signiert und vor jeder Ausführung gegen den hinterlegten Signaturschlüssel geprüft — dieselbe Absicherung wie bei Agent-Software und Update-Paketen. Bisher schützte hier allein die verschlüsselte Verbindung; ein manipuliertes Skript wird jetzt erkannt und nicht ausgeführt. *(Server-Dienste, Agent)*

- **Image-Verteilung: Lese-Zugriff eines Geräts endet sofort nach dessen Abschluss** — Beim Ausrollen eines Images auf mehrere Geräte blieb die Lese-Freigabe auf die Image-Ablage (NFS) bisher für alle beteiligten Geräte offen, bis der gesamte Vorgang abgeschlossen war. Jetzt wird sie für jedes Gerät einzeln entzogen, sobald genau dieses Gerät fertig ist, ohne die übrigen laufenden Geräte zu stören. Engerer Zugriff bei unverändertem Ablauf. *(Server-Dienste)*

- **Aktualisierung sehr alter Datenbestände schlägt klar fehl statt in einer Neustart-Schleife** — Startet der Server gegen ein sehr altes Datenverzeichnis (aus einer Version vor der VPN-Funktion), brach der Datenbank-Schritt bisher mit einem internen Fehler ab und der Dienst lief in eine Neustart-Schleife. Jetzt wird dieser Fall erkannt und mit einer eindeutigen Meldung samt Handlungsanweisung beendet. Ein direktes In-Place-Upgrade solch alter Stände wird bewusst nicht unterstützt — der vorgesehene Weg ist eine frische Initialisierung des Datenverzeichnisses. Betrifft nur sehr alte Installationen. *(Server-Dienste)*

- **Lizenz-Plätze werden konsistent und stabil zugewiesen** — Die Zuteilung der „Full"-Lizenzplätze auf die Geräte war inkonsistent: Aktive Geräte konnten fälschlich auf „Light" zurückgestuft werden, während offline/stillgelegte Geräte einen bezahlten Platz blockierten, und einzelne Geräte konnten zwischen „Full" und „Light" hin- und herspringen. Jetzt zählen auf Lager gebuchte Geräte nicht in die Lizenz, alle übrigen teilen sich die Plätze stabil (bei Überbelegung behalten die ältesten ihren Platz). *(Server-Dienste)*

- **Schwachstellen-Bericht: eine echte Schwachstelle in einem erreichbaren Container wird nicht mehr durch einen abgeschotteten Container verdeckt** — War dieselbe Schwachstelle (CVE) in einem abgeschotteten Container als „nicht betroffen" eingestuft, wurde sie bisher auch in einem aus dem LAN erreichbaren Container ausgeblendet — der Bericht konnte fälschlich „bestanden" anzeigen, obwohl dort eine echte, kritische Schwachstelle vorlag. Die Einstufung „nicht betroffen" gilt jetzt nur noch für genau den betroffenen Container; in jedem anderen erreichbaren Container erscheint die Schwachstelle weiterhin korrekt. *(Server-Dienste)*

## 2026-05-29

- **Mehrere Image-Aufnahmen gleichzeitig stören sich nicht mehr** — Wurden zwei oder mehr Geräte gleichzeitig für eine Image-Aufnahme gestartet, konnte sich die Schreibfreigabe gegenseitig verdrängen — das erste fertige Gerät konnte den noch laufenden Aufnahmen die Freigabe entziehen, sodass diese abbrachen. Die Schreibfreigabe wird jetzt für alle laufenden Aufnahmen zuverlässig offen gehalten und erst geschlossen, wenn die letzte fertig ist. *(Server-Dienste)*

- **Lizenzstufe wird auf den Geräten zuverlässiger durchgesetzt** — Die Geräte prüfen die hinterlegte Lizenz beim Start jetzt kryptografisch und auf das Gültigkeitsdatum. Eine manipulierte oder abgelaufene „Full"-Markierung fällt automatisch auf „Light" zurück — auch ohne Verbindung zum Server. *(Agent)*

- **ISO per URL herunterladen: besserer Schutz gegen interne Ziele** — Beim Herunterladen einer ISO über eine angegebene Web-Adresse wird jetzt bei jeder Weiterleitung erneut geprüft, dass das Ziel keine interne/private Adresse ist. Zuvor konnten bestimmte Weiterleitungen und Adress-Schreibweisen diese Prüfung umgehen. Reine server-seitige Absicherung. *(Server-Dienste)*

- **2FA: erneutes Einrichten schaltet bestehendes 2FA nicht mehr versehentlich ab** — Beim erneuten Aufrufen der 2FA-Einrichtung wurde ein bereits aktives 2FA bisher sofort deaktiviert, noch bevor ein neuer Code bestätigt war — ein abgebrochener Vorgang ließ das Konto ohne 2FA zurück. Jetzt bleibt das bestehende 2FA aktiv, bis ein neuer Code erfolgreich bestätigt wurde. *(Server-Dienste)*

- **Passwortänderung meldet bestehende Anmeldungen ab** — Nach einer Passwortänderung oder einem Passwort-Reset werden alle zuvor ausgestellten Anmeldungen des Kontos jetzt ungültig — auch auf anderen Geräten oder in anderen Browsern; man meldet sich anschließend mit dem neuen Passwort neu an. Bisher blieben alte Anmeldungen bis zu ihrem natürlichen Ablauf gültig. *(Server-Dienste)*

- **VPN „Trennen & löschen": ein fehlgeschlagener Entzug wird jetzt gemeldet** — Konnte beim „Trennen & löschen" eines VPN-Geräts die Löschung auf dem VPN-Server nicht durchgeführt werden, meldete ThinForge bisher trotzdem „erledigt", obwohl das Gerät noch VPN-Zugriff hatte. Jetzt wird ein solcher Fehlschlag als Fehler angezeigt und der Vorgang kann erneut ausgelöst werden. *(Server-Dienste)*

- **Remote-Desktop: Sitzungs-Limit und Leerlauf-Abschaltung greifen jetzt** — Die Einstellungen „maximale gleichzeitige Sitzungen pro Gerät" und „Leerlauf-Zeitlimit" wurden bisher nicht angewendet. Jetzt werden zu viele parallele Remote-Desktop-Sitzungen auf ein Gerät abgewiesen, und eine Sitzung ohne Aktivität wird nach Ablauf des Leerlauf-Zeitlimits automatisch beendet. *(Server-Dienste)*

- **Lizenz-Limit wird zuverlässiger durchgesetzt** — Das Geräte-Limit der Lizenz ließ sich in zwei Sonderfällen umgehen: durch nachträgliches Umstellen eines Geräts von „Lager" auf „aktiv" sowie durch mehrere exakt gleichzeitige VPN-Aktivierungen. Beide Wege werden jetzt korrekt gegen das Limit geprüft. *(Server-Dienste)*

- **Fernzugriff nur noch für Administratoren und Operatoren** — Das eingebaute Geräte-Terminal und die Remote-Desktop-Fernsteuerung lassen sich jetzt nur noch von Konten mit der Rolle Administrator oder Operator öffnen. Konten mit reiner Leserolle sowie bereits abgemeldete oder deaktivierte Konten werden zuverlässig abgewiesen — dieselbe Rechteprüfung wie bei den übrigen Geräte-Aktionen. *(Server-Dienste)*

- **Schwachstellen-Bericht zeigt lokale Schwachstellen wieder vollständig** — Nur lokal bzw. aus dem direkt benachbarten Netz ausnutzbare Schwachstellen konnten unter bestimmten Umständen fälschlich als „nicht betroffen" eingestuft und aus dem Bericht ausgeblendet werden, sodass dieser zu Unrecht „bestanden" anzeigte. Die Einstufung wurde korrigiert — solche Schwachstellen erscheinen wieder korrekt im Bericht. *(Server-Dienste)*

- **System-Wiederherstellung meldet Datenbank-Fehler jetzt als Fehler** — Schlug beim Einspielen eines System-Backups der Datenbank-Teil fehl, meldete die Wiederherstellung bisher trotzdem „erfolgreich". Jetzt wird ein solcher Fehler klar als Fehlschlag gemeldet, und der Datenbank-Teil wird entweder vollständig oder gar nicht eingespielt — kein halb-wiederhergestellter Stand. *(Server-Dienste)*

- **Defekte Klon-Stände können nicht mehr ausgerollt werden** — Ein als defekt markierter Klon lässt sich nicht mehr für ein neues Ausrollen auswählen, damit sich der Defekt nicht auf weitere Geräte überträgt. *(Server-Dienste)*

- **Mehr Stabilität bei Update-Downloads und Fernbefehlen** — Mehrere interne Absicherungen verhindern, dass ein abgebrochener Update-Download oder ein nicht antwortendes Gerät dauerhaft Server-Ressourcen belegt: Zeitlimit für Fernbefehle, sauberes Beenden unterbrochener Downloads, geringerer Arbeitsspeicher-Bedarf bei großen ISO- und Backup-Vorgängen. *(Server-Dienste)*

- **VPN-Tab: Aktualisieren-Buttons zeigen wieder eine Lade-Animation** — In den Bereichen „Konfiguration", „Ressourcen" und „Gruppen" des VPN-Tabs drehte das Aktualisieren-Symbol beim Klick keinen Ladekreis, obwohl im Hintergrund tatsächlich neu geladen wurde. Das Symbol zeigt den Ladevorgang jetzt einheitlich an. Reine Anzeige-Korrektur, die geladenen Daten waren immer aktuell. *(Verwaltungsoberfläche)*

## 2026-05-28

- **Interne Aufräumarbeiten am Server-Code** — Umfangreiche Vereinfachung und Entfernung von ungenutztem Code im Backend, ohne Änderung an Verhalten oder Funktionen. Keine Auswirkung auf den Betrieb. *(Server-Dienste)*

- **Zertifikate für Clients hochladen (z. B. für Citrix)** — Im Bereich „Clients" gibt es den neuen Tab „Zertifikate": Dort lassen sich vertrauenswürdige Zertifikate (CA- oder Server-Zertifikat, PEM/DER) hochladen — für alle Geräte oder gezielt für eine Gruppe. Die Geräte übernehmen die zugeordneten Zertifikate automatisch in ihren System-Zertifikatsspeicher, sodass z. B. die Citrix-Workspace-App einem selbstsignierten Server vertraut, ohne manuelle Einrichtung an jedem Gerät. Wird ein Zertifikat in der Oberfläche gelöscht, entfernen es die Geräte beim nächsten Abgleich ebenfalls. *(Server-Dienste, Agent)*

- **VPN: Abgleich und „Trennen & löschen" arbeiten zuverlässiger** — Mehrere interne Verbesserungen am automatischen Abgleich der VPN-Konfiguration: Der Server-Eintrag wird auch bei mehreren gleichnamigen Einträgen im VPN-Dienst eindeutig dem richtigen (tatsächlich verbundenen) Gerät zugeordnet. Doppelt angelegte Zugriffsregeln aus abgebrochenen Vorgängen werden beim nächsten Abgleich automatisch bereinigt. Beim „Trennen & löschen" werden Ressourcen und Routing jetzt auch bei intern uneindeutiger VPN-Netzwerk-Zuordnung zuverlässig entfernt, sodass keine Reste das Löschen von Gruppen blockieren. *(Server-Dienste)*

- **VPN: Ändern des lokalen Gateways löst keinen falschen Abgleich des Server-Eintrags mehr aus** — Der Abgleich wollte bisher den VPN-Eintrag des ThinForge-Servers (samt DNS-Eintrag) auf die Gateway-Adresse umstellen, sobald sich im lokalen Netz das Gateway änderte — fälschlich, denn das Gateway ist der Router, nicht der Server. Der Server-Eintrag richtet sich jetzt nach der tatsächlichen Adresse des Servers im lokalen Netz (vorrangig die eingestellte „Server-IP", sonst die echte Netzwerkschnittstellen-Adresse); lässt sich keine Adresse ermitteln, bricht der Vorgang mit einem Hinweis ab, statt zu raten. *(Server-Dienste)*

- **VPN: Zwei Standard-Zugriffsregeln zielen jetzt auf die Gruppe statt direkt auf den Server** — Die beiden Regeln, über die VPN-Geräte den ThinForge-Server erreichen (Namensauflösung/DNS und Weboberfläche), verweisen jetzt auf die Gruppe „thinforgeTarget" statt direkt auf den Server-Eintrag. Diese Gruppe umfasst den Server über VPN- und lokale Netzadresse, sodass der Zugriff auf beiden Wegen greift und die zuvor angezeigte Abweichung im Tab „Konfiguration" verschwindet. *(Server-Dienste)*

## 2026-05-26

- **VPN: „Verbindung trennen" heißt jetzt „Trennen & löschen" und räumt vollständig auf** — Die Schaltfläche im VPN-Konfigurationsbereich wurde umbenannt und entfernt beim Betätigen jetzt zuerst alle vom ThinForge-Server angelegten Objekte auf dem VPN-Dienst (Zugriffsregeln, Ressourcen, Routing, DNS-Eintrag, Server-Zugang, Gruppen), bevor die Verbindung lokal gelöscht wird. Bisher konnten dabei Reste zurückbleiben, etwa nicht löschbare Gruppen wegen noch verweisender Zugriffsregeln. *(Server-Dienste, Verwaltungsoberfläche)*

- **VPN: drei Standard-Zugriffsregeln werden zentral verwaltet** — Der ThinForge-Server legt jetzt drei Standard-Zugriffsregeln selbst an und hält sie im gewünschten Stand: DNS-Auflösung und Zugriff auf die Weboberfläche der Geräte zum Server sowie Fernwartung (SSH) vom Server zu den Geräten. Damit bleiben diese Regeln auch nach erneutem Einrichten konsistent. *(Server-Dienste)*

- **VPN-Bereich vollständig zweisprachig (Deutsch/Englisch)** — Der gesamte VPN-Bereich (Übersicht, Geräte, Konfiguration, Gruppen, Aufgaben und alle zugehörigen Dialoge) folgt jetzt der Sprachumschaltung und liegt vollständig auf Deutsch und Englisch vor, statt fest deutschsprachig zu sein. Zusätzlich wurden nicht mehr genutzte Überbleibsel der früheren VPN-Technik entfernt, ohne Änderung am sichtbaren Funktionsumfang. *(Server-Dienste, Verwaltungsoberfläche)*

- **VPN: kleinere Bedien-Verbesserungen** — Beim Aktivieren des VPN für ein Gerät oder eine Gruppe ist die Gruppe „Clients" jetzt vorausgewählt. Die Schaltfläche zum Anwenden des gewünschten Konfigurationsstands heißt jetzt „Konfig anwenden" (vorher „Reconcile jetzt"). *(Verwaltungsoberfläche)*

- **VPN „Lokale Ressourcen": gezielte Host-Freigaben wirken jetzt sofort** — Der frühere Bereich „Host-Zugriffs-Module" heißt jetzt „Lokale Ressourcen" (Anlegen über „Neue Ressource") und bündelt ein Ziel-Gerät plus erlaubte Dienste/Ports, etwa für die Fernwartung eines bestimmten Geräts. Beim Anlegen oder Löschen wird die Freigabe jetzt unmittelbar in den VPN-Dienst übernommen bzw. entfernt — der frühere separate Schritt „Reconcile jetzt" ist dafür nicht mehr nötig. Die erzeugte Zugriffsregel trägt einen sprechenden Namen aus Ressourcenname, Protokoll und Port (z. B. „w22 TCP 5900"). *(Server-Dienste, Verwaltungsoberfläche)*

## 2026-05-25

- **VPN-Netzwerkkonfiguration wird zentral verwaltet und automatisch mit dem VPN-Dienst abgeglichen** — Der ThinForge-Server richtet die VPN-Struktur (Netzwerk, Server-Zugang, DNS, Zugriffsregeln) jetzt selbst ein und hält sie automatisch im gewünschten Stand. Der neue VPN-Tab „Konfiguration" zeigt den tatsächlichen Stand, markiert Abweichungen und bietet eine Schaltfläche zum erneuten Anwenden des gewünschten Stands; zusätzlich lassen sich dort gezielte Host-Zugriffe als wiederverwendbare Module anlegen, die beim Abgleich automatisch in den VPN-Dienst übernommen werden. Der bisherige Bereich „Zielnetze" entfällt, seine Aufgabe übernimmt das neue Modell. *(Server-Dienste, Verwaltungsoberfläche)*

- **Korrektur: Geräte mit aktivem VPN werden in der Geräteliste wieder als „VPN" statt „LAN" angezeigt (Agent v2.14.14)** — Bei Geräten, die ihren Status über die VPN-Verbindung meldeten, stand in der Geräteliste fälschlich „LAN" als Verbindungsweg — Ursache war ein interner Namensunterschied der VPN-Netzwerkschnittstelle, der die Erkennung ins Leere laufen ließ. Der Verbindungsweg wird jetzt wieder korrekt erkannt und angezeigt. Greift, sobald ein Gerät die neue Agent-Version übernommen und sich danach einmal neu am VPN angemeldet hat (VPN am Gerät einmal aus- und wieder einschalten); neu eingerichtete Geräte sind sofort korrekt. *(Agent)*

- **VPN-Geräte halten ihren VPN-Dienst zuverlässig im gewünschten Zustand — und schalten ihn nie mehr selbsttätig ab** — Ob ein Gerät VPN haben soll, wird jetzt dauerhaft auf dem Gerät hinterlegt: Beim Aktivieren merkt es sich „VPN an" und sorgt bei jedem Start selbst dafür, dass der Dienst läuft (auch nach Neustart oder System-Update); beim Deaktivieren merkt es sich „VPN aus" und hält den Dienst gestoppt. Die frühere automatische Abschaltung im lokalen Netz entfällt — ein Gerät schaltet seinen VPN-Dienst nur noch auf ausdrückliche Anweisung ab, nie von sich aus. *(Agent)*

- **VPN-Bereich: Ein Gerät zeigt „installiert" erst, wenn es die VPN-Einrichtung tatsächlich bestätigt hat** — Bisher sprang der Status direkt nach dem Aktivieren auf „installiert", obwohl das Gerät die Einrichtung noch gar nicht durchgeführt hatte, etwa bei einem noch vorhandenen älteren Eintrag desselben Geräts. Jetzt zeigt die Liste zunächst „wird installiert" und wechselt erst bei tatsächlicher Rückmeldung des Geräts in einen bestätigten Zustand — danach „pausiert" (eingerichtet, Verbindung gerade aus) bzw. „aktiv" (verbunden). Schlägt die Einrichtung fehl, bleibt der Status „wird installiert"; Einzelheiten und die Möglichkeit zum erneuten Versuch stehen im Untertab „Tasks". *(Server-Dienste, Agent)*

## 2026-05-24

- **Neu installierte Geräte führen den VPN-Tunnel von Anfang an über den Relay-Server und schalten IPv6 im Tunnel ab** — Bei der Erst-Installation über das Tools-Medium wird der VPN-Dienst jetzt direkt so eingestellt, dass der Tunnel grundsätzlich über den Relay-Server läuft (statt zunächst eine bei manchen Firewalls unzuverlässige Direktverbindung auszuhandeln) und IPv6 im Tunnel deaktiviert ist. Bisher wurde der Relay-Zwang erst bei der VPN-Anmeldung des Geräts gesetzt; jetzt steht die Einstellung schon ab der Installation fest. Am sichtbaren Verhalten ändert sich nichts, die VPN-Verbindung wird nur robuster. *(Tools-ISO)*

- **VPN-Mesh-Dienst des Servers nutzt jetzt das offizielle NetBird-Abbild und lässt sich einfach aktuell halten** — Der VPN-Mesh-Dienst auf dem ThinForge-Server lief bisher aus einem selbstgebauten Abbild mit fest eingebauter, älterer NetBird-Version und erforderte für Updates einen Neubau. Er bezieht jetzt das offizielle NetBird-Abbild direkt, sodass ein einfaches Aktualisieren der Abbilder immer die neueste Version bringt; am Verhalten ändert sich nichts. Hinweis beim Update einer bestehenden Installation: Der Mesh-Dienst muss danach einmalig neu eingebunden werden (im VPN-Bereich die Verbindungs-Konfiguration einmal speichern). *(Netzwerk-Dienste)*

## 2026-05-23

- **Korrektur: VPN kommt nach einem System-Update jetzt wirklich von selbst wieder hoch (Agent v2.14.11)** — Die in der Vorversion eingeführte automatische Wiederherstellung der VPN-Verbindung nach einem Update griff in der Praxis nicht: Eine interne Prüfung suchte die VPN-Anmeldedaten am falschen Ort und übersprang das Wiedereinschalten. Bereits fürs VPN aktivierte Geräte schalten ihren VPN-Dienst nach einem Update jetzt wieder selbst ein, sobald sie die neue Agent-Version übernommen haben. *(Agent)*

- **VPN-Bereich: Geräte nach Gruppen sortiert, korrekter Status und Aktivieren im Hintergrund** — Die Geräteliste im VPN-Bereich ist jetzt nach den für VPN freigeschalteten Gruppen gegliedert, mit aufklappbaren Gruppen-Überschriften (Geräteanzahl, Aktivierungsstand) sowie Aktivieren einzeln oder über „Ganze Gruppe aktivieren". Geräte, die noch nie fürs VPN aktiviert wurden, zeigen jetzt korrekt „nicht aktiviert" statt fälschlich „installiert"; die Aktualisieren-Schaltflächen holen den Stand jetzt direkt vom VPN-Server. Das Aktivieren läuft als Hintergrund-Aufgabe: Ein neuer Untertab „Tasks" zeigt die laufenden Aktivierungen je Gerät mit Status, Fehlern und Wiederholen-Option. *(Server-Dienste, Verwaltungsoberfläche)*
## 2026-05-22

- **Geräte verbinden sich nach einem System-Update von selbst wieder mit dem VPN (Agent v2.14.10)** — Nach einem System-Update war der VPN-Dienst zunächst deaktiviert, weil das frische Abbild ihn standardmäßig ausgeschaltet mitbringt; bisher kam die Verbindung erst nach erneuter Anweisung durch den Server zustande. Jetzt schaltet das Gerät seinen VPN-Dienst beim ersten Hochfahren nach dem Update selbst wieder ein, sofern es zuvor angemeldet war — die Anmeldedaten bleiben über das Update hinweg erhalten. Geräte ohne VPN bleiben unverändert. *(Agent)*

- **Geräte melden ihren Status jetzt alle 10 statt 60 Sekunden (Agent v2.14.8)** — Das Melde-Intervall wurde verkürzt, sodass Online-/Offline-Status und Geräte-Infos im Dashboard deutlich schneller aktualisieren. Auch bei vorübergehenden Verbindungsproblemen melden sich Geräte weiterhin konstant im 10-Sekunden-Takt statt sich automatisch zu verlangsamen. Das Intervall bleibt zentral in den Agent-Einstellungen änderbar. *(Agent)*

- **Geräte behalten nach einem Update Namen und VPN-Anmeldung — ohne zusätzlichen Neustart (Agent v2.14.7)** — Der korrekte Gerätename wird bei einem System-Update jetzt direkt ins neue Abbild geschrieben, sodass das Gerät schon beim ersten Hochfahren richtig benannt ist (vorher war dafür ein zusätzlicher automatischer Neustart nötig). Die VPN-Anmeldung bleibt ebenfalls über das Update hinweg erhalten, und der ausgelöste Befehl wird exakt befolgt (Neustart startet neu, Herunterfahren fährt herunter). *(Agent)*

- **Geräte starten nach einer Namensänderung automatisch einmal neu (Agent v2.14.6)** — Setzt oder ändert der Agent den Gerätenamen — beim ersten Start eines frisch ausgerollten Geräts, beim Übergang von der Vorlage-VM auf echte Hardware oder bei einer Namenskorrektur —, startet das Gerät jetzt sofort ohne Rückfrage einmal neu, damit der neue Name überall greift (vorher konnten Dienste und Sitzungen noch den alten Namen verwenden). Eine Sicherung verhindert wiederholte Neustarts, falls der Name bei jedem Start zurückgesetzt wird. *(Agent)*

- **Kern-Server-Dienste starten jetzt unabhängig vom VPN- und Fernwartungs-Dienst** — Der zentrale Dienst wartet beim Hochfahren nicht mehr darauf, dass VPN und Fernwartung als „betriebsbereit" gemeldet werden — sind diese optionalen Zusatzdienste gestört, kommt der Kern trotzdem normal hoch. Beim regulären Hochfahren des Gesamtsystems werden beide weiterhin mitgestartet; ein gezielter Start nur des Kerndienstes startet sie aber nicht mehr automatisch mit. *(Server-Dienste, Deploy-Repo)*

- **Setup-Assistent: neue Vorgaben für Domain, DHCP-Bereich und Weiterleitungs-Timer** — Die voreingestellte Domain heißt jetzt thinforge.lan statt thinforge.org, der DHCP-Adressbereich beginnt jetzt ab der zehnten Netzadresse statt ab der 100. (die Adressen davor bleiben für feste Zuweisungen frei), und die automatische Weiterleitung zur Anmeldeseite wartet jetzt 15 statt 10 Sekunden, damit der Webserver sein Zertifikat sicher übernimmt. Bestehende Installationen sind nicht betroffen — die Werte gelten nur für Neu-Einrichtungen und bleiben im Assistenten frei überschreibbar. *(Backend, Verwaltungsoberfläche)*

- **VPN ist jetzt eigener Hauptmenüpunkt zwischen „Cloning" und „Netzwerk"** — Der VPN-Bereich war bisher ein Unterpunkt von „Netzwerk" und ist jetzt eine Ebene höher direkt in der Hauptnavigation erreichbar. Inhaltlich ändert sich nichts, „Netzwerk" behält die übrigen Tabs (Lokales Netzwerk, DHCP/DNSMASQ, DNS, PXE). *(Verwaltungsoberfläche)*

- **VPN-Tab: Verbindungsstatus und Client-Zähler kommen jetzt vom ThinVPN-Mesh-Server statt von der Selbsteinschätzung der Geräte** — Der Server fragt den Mesh-Status jetzt minütlich direkt ab; ein Gerät gilt nur dann als „verbunden", wenn diese Abfrage es innerhalb der letzten 3 Minuten so gemeldet hat, sonst als „getrennt". Vorher konnten sich Server-Sicht und Geräte-Selbstmeldung widersprechen; betroffen ist ausschließlich der VPN-Tab, der allgemeine Online-/Offline-Status bleibt unberührt. *(Backend, Verwaltungsoberfläche)*

- **VPN: Geräte erkennen jetzt korrekt LAN- vs. VPN-Verbindung, aktivierte Geräte laufen fest über den Relay** — Bisher zeigte die Übersicht immer „LAN", auch bei über VPN verbundenen Geräten, weil die nötige Standort-Prüfung serverseitig nie konfiguriert war. Jetzt weist der Server jedem aktivierten Gerät eine Prüfmethode zu (Erreichbarkeit des Servers im lokalen Netz, abgesichert per Zertifikats-Fingerabdruck gegen vorgetäuschte Server), sodass Geräte im LAN ihren Tunnel selbst abschalten und entfernte Geräte ihn halten. Zusätzlich läuft der VPN-Tunnel aktivierter Geräte jetzt immer über den Relay statt zunächst eine direkte Verbindung auszuhandeln, die hinter manchen Firewalls unzuverlässig ist. *(Backend, Agent)*

## 2026-05-21

- **VPN-Tab: neuer Status „wird installiert" nach dem Aktivieren** — Bisher sprang der Status direkt nach Klick auf „Aktivieren" sofort auf „installiert", obwohl das Gerät die VPN-Konfiguration noch gar nicht durchgeführt hatte. Jetzt zeigt die Tabelle zunächst „wird installiert" (blau) und wechselt erst nach der tatsächlich gemeldeten erfolgreichen VPN-Anmeldung auf „aktiv" (grün, jetzt auch „installiert" grün). Bleibt ein Gerät länger auf „wird installiert", hat es die Anmeldung noch nicht abgeschlossen. *(Backend, Verwaltungsoberfläche)*

- **Interne Konsolidierung des Datenbank-Schemas auf eine einzige Initialdatei** — Die bisher getrennten Schema-Bausteine sind zu einer einzigen Datei zusammengefasst, die bei einer frischen Datenbank eingespielt wird. Reine interne Aufräumarbeit ohne funktionale Auswirkung — das resultierende Schema ist nachweislich identisch. *(Backend)*

- **Netzwerk-Trennung des Webservers verschärft: Admin-Oberfläche nur noch aus dem Management-Netz erreichbar** — Der Webserver bedient Client-LAN, VPN-Tunnel und Management-Netz jetzt mit jeweils eigener, genau abgestimmter Pfadliste statt pauschaler Freigabe. Aus Client-LAN und VPN sind nur noch die vom Gerät benötigten Pfade erreichbar (Heartbeat, Selbst-Update, Zertifikats-/Token-Recovery, Delta-Downloads) — Admin-API und Oberfläche sind aus diesen Netzen unsichtbar (404); umgekehrt sind dieselben Geräte-Pfade aus dem Management-Netz gesperrt (403), sodass ein Angreifer dort auch mit gültigem Heartbeat-Token keine gefälschten Heartbeats oder Delta-Downloads mehr auslösen kann. *(Backend)*

- **VPN-Tab: neue Bereiche „Zielnetze" und „Gruppen", plus Gruppen-Auswahl beim Aktivieren** — Unter „Zielnetze" lassen sich Subnetze definieren, die ein VPN-Client über den Tunnel erreichen soll (CIDR, Routing-Peer, Gruppen-Zugriff); der ThinForge-Server wird dabei automatisch als Routing-Peer für sein LAN eingerichtet. Unter „Gruppen" lassen sich eigene Gruppen anlegen, und beim Aktivieren eines Geräts wählt ein Dialog jetzt die Ziel-Gruppe statt immer die System-Standardgruppe zu verwenden. Operatoren sehen beides nur lesend, Anlegen/Bearbeiten bleibt Admins vorbehalten. *(Backend, Verwaltungsoberfläche)*

- **VPN-Mesh-Backend (ThinVPN-Container) auf Version 0.71.3 aktualisiert** — Der lokale Server-Peer-Container war noch auf der über ein Jahr alten Version 0.30.0, während Endgeräte bereits auf 0.71.2 liefen; diese Versions-Spreizung führte gelegentlich zu unauffälligen Sync-Problemen bei Routen-Updates. Beide Seiten laufen jetzt synchron. *(Server-Dienste, Deploy-Repo)*

- **Agent v2.14.2/v2.14.3: klare Heartbeat-Reihenfolge und harter Timeout beim VPN-Beitritt** — Die Verarbeitung der Heartbeat-Antwort läuft jetzt in vier klaren Phasen (Konfig-Sync → Lizenz → Update → VPN) statt organisch gewachsener Reihenfolge, und der Agent wartet aktiv bis 15 s auf den VPN-Daemon-Socket und bricht einen hängenden Beitritts-Versuch nach 60 s sauber ab statt endlos zu blockieren. Vorher konnte ein Gerät dem Server minutenlang als „hängend" erscheinen, obwohl es nur in einer internen Retry-Schleife steckte. *(Agent)*

- **VPN: Remote-Geräte bekommen automatisch lokalen DNS, Trennen räumt jetzt alle VPN-Objekte vollständig auf** — Ist eine lokale Domain im DNS-Setup gesetzt, bekommen Remote-Geräte automatisch den ThinForge-Server als DNS-Server für lokale Namen zugewiesen (Split-DNS). Beim Trennen der VPN-Verbindung am Server werden jetzt zusätzlich alle automatisch angelegten Objekte entfernt (Server-Peer, LAN-Route, DNS-Eintrag, ThinForge-Gruppen, aktivierte Client-Geräte) — es bleiben keine Karteileichen mehr zurück. *(Backend, Verwaltungsoberfläche)*

- **VPN: Server-DNS-Name „thinforge-server" ist jetzt vom DHCP-Gateway entkoppelt** — Bisher zeigte der DNS-Eintrag fest auf die im DHCP konfigurierte Gateway-Adresse; wich das Gateway von der echten Server-IP ab, zeigte der Name ins Leere und Geräte erreichten den Server nicht mehr. Der Eintrag wird jetzt aus der tatsächlich gebundenen Server-IP abgeleitet, ebenso der Webserver-Listener. *(Backend)*

## 2026-05-20

- **VPN-Funktion grundlegend überarbeitet — sicherer, einfacher zu bedienen** — Die bisherige VPN-Anbindung wurde durch eine Ende-zu-Ende-verschlüsselte Lösung ersetzt; der Verwaltungs-Server kann den Inhalt der VPN-Pakete jetzt nicht mehr einsehen. Statt der bisherigen Sub-Tabs gibt es jetzt einen klaren Setup-Assistenten (URL + Token, Verbindung testen) und danach eine einzige Geräte-Tabelle mit Aktivieren/Deaktivieren; Aktivierungs-Schlüssel laufen nicht mehr ab, und Geräte schalten den Tunnel abhängig vom Standort automatisch ein/aus, ohne Zutun der Nutzer. Lizenzlimits werden weiterhin beim Aktivieren geprüft. Bestehende Klon-Images der Endgeräte müssen einmal aktualisiert werden, damit die neue VPN-Lösung dort ankommt. *(Backend, Verwaltungsoberfläche, Agent)*

## 2026-05-19

- **Lizenz-Status zieht nach Ablauf jetzt automatisch nach (vorher erst beim Server-Neustart)** — Lief der Server über das Lizenz-Ablaufdatum hinaus, blieb der intern gespeicherte Status auf dem Stand vom Start hängen und neu zugewiesene Geräte wurden fälschlich weiter als Voll-Lizenz markiert. Der Server prüft den Lizenz-Status jetzt stündlich neu und gleicht die Geräte-Tier-Zuteilung an — Übergänge Lizenziert → Gnadenfrist → Free wirken damit auch ohne Neustart innerhalb einer Stunde; das 60-Tage-Gnadenfrist-Verhalten selbst bleibt unverändert. *(Backend)*

- **Neue Dashboard-Karte „Lizenz" — Status auf einen Blick** — Die Karte zeigt Status-Chip (Lizenziert/Gnadenfrist/Abgelaufen/Free), Lizenzinhaber, verbleibende Tage sowie die Geräte-Auslastung als Balken, der bei über 90 % gelb und bei 100 % rot wird. Klick führt direkt zu Einstellungen → Lizenz; die Karte ist standardmäßig sichtbar und wie alle Dashboard-Karten aus- und anpassbar. *(Verwaltungsoberfläche)*

## 2026-05-18

- **Clients-Übersicht zeigt jetzt eine Spalte „Aktuelle IP"** — Zwischen Status und Version erscheint die aktuelle Erreichbarkeits-IP jedes Geräts, mit Icon für LAN- oder VPN-Verbindung. VPN-only-Geräte zeigen die WireGuard-Adresse, LAN-Geräte die lokale IP; die Spalte aktualisiert sich automatisch beim nächsten Heartbeat, nicht erreichbare Geräte werden ausgegraut. *(Verwaltungsoberfläche)*

- **VPN-Geräte werden zuverlässig als „online" markiert, auch ohne regulären Heartbeat** — Der Hintergrund-Abgleich, der den Online-Status von VPN-only-Geräten anhand des WireGuard-Handshakes nachziehen sollte, brach bisher mit einem Datenbank-Fehler ab, weil Spalten- und übergebenes Format nicht zusammenpassten — betroffene Geräte blieben fälschlich „offline", und der Fehler stoppte auch die Prüfung nachfolgender Geräte im selben Lauf. Der Wert wird jetzt im richtigen Format übergeben, der Abgleich läuft sauber durch. *(Backend)*

- **Signatur-Fehler bei Delta-Update wird im Update-Tab jetzt rot angezeigt** — Ein Client mit ungültiger Delta-Signatur wurde vom Backend zwar korrekt als endgültig fehlgeschlagen markiert, die Übersicht zeigte aber nur ein graues Chip ohne Text. Der Status erscheint jetzt in Rot mit dem Klartext „Signatur ungültig". *(Verwaltungsoberfläche)*

- **Agent wendet Delta-Updates wieder an** — Der Agent verweigerte das Herunterladen von Delta-Updates komplett, weil eine veraltete Vorab-Prüfung ein längst durch die interne Anwende-Logik ersetztes Shell-Skript suchte und beim Nicht-Finden den Download blockierte. Die Vorab-Prüfung ist entfernt; der Agent lädt Deltas wieder herunter und wendet sie beim Herunterfahren wie vorgesehen an. *(Agent)*

- **Lizenz-Limit wird jetzt verlässlich eingehalten, auch bei gleichzeitigen Erst-Anmeldungen** — Meldeten sich mehrere Geräte gleichzeitig zum ersten Mal, konnte die Zuteilung eines vollen Lizenz-Platzes eine Race Condition auslösen und mehr Geräte als lizenziert als Voll-Lizenz markieren. Die Zuteilung läuft jetzt unter einer exklusiven Sperre; zusätzlich räumt das Backend bei Start, Lizenz-Einspielung und -Löschung die Tier-Verteilung auf (überzählige Voll-Plätze werden auf Light heruntergestuft, älteste Geräte behalten Vorrang) — auch ein Lizenz-Downgrade wirkt damit sofort statt erst nach vielen Heartbeats. *(Backend)*

- **Schwachstellen-Ausnahmenliste nach dem Sammel-Update aufgeräumt** — Nach den Bibliotheks-Updates (siehe folgender Eintrag) wurde die Liste akzeptierter Schwachstellen bereinigt: 24 nicht mehr zutreffende Einträge entfernt, 12 auf die verbleibenden CVEs geschrumpft, ein neuer Block für Funde im Drittanbieter-Container guacamole/guacd (Alpine-3.18-EOL-Basis) ergänzt. Die Liste ist per Bind-Mount eingebunden, ein Backend-Neustart genügt. *(Backend)*

- **Sammel-Update aller Container-Bibliotheken — viele bekannte Schwachstellen verschwinden auf einen Schlag** — Reverse-Proxy und Datenbank wurden auf die jeweils neueste Stable-Version gehoben, die selbst gebauten Container von Alpine 3.22 auf 3.23 (frische SQLite-, QEMU/OVMF-, GLib- und OpenSSL-Stände), und die eingebaute Docker-Befehlszeile auf Version 29.5 mit reparierter Go-Laufzeit — zusammen verschwinden über 30 bisher akzeptierte CVE-Ausnahmen. Nicht behoben werden konnte der Drittanbieter-Container guacamole/guacd, der seit Juni 2025 ohne Upstream-Update auf einem alten Alpine hängt; die verbleibenden Befunde betreffen aber nur den internen Container-Verbund, kein LAN-Zugang. *(Backend, Verwaltungsoberfläche, Server-Dienste, Deploy-Repo)*

- **Schwachstellen-Bewertung erkennt Container mit „Hersteller/Name"-Bezeichnung jetzt korrekt** — Alle 84 Funde des Containers guacamole/guacd landeten in „Bedarf manueller Prüfung", weil die Namens-Heuristik bei der Form „Hersteller/Name:Version" keinen Treffer in der Container-Liste fand und die Erreichbarkeits-Prüfung deshalb nicht greifen konnte. Eine zusätzliche direkte Zuordnung aus den Compose-Container-Definitionen behebt das; die Funde durchlaufen jetzt wieder den normalen Erreichbarkeits-Filter, zwei fälschlich rot markierte Critical-Funde verschwinden. *(Backend)*

- **Sicherheits-Scan-Übersicht zeigt Container nicht mehr doppelt** — Dieselben Container tauchten unter kurzem Namen und vollem Registry-Pfad zweimal in der Übersicht auf, weil beide Namen nach einem Image-Pull auf dieselbe Image-ID zeigen und der Scan beide separat prüfte. Der Scan dedupliziert jetzt nach interner Image-ID; Bewertung und Akzeptanz-Status bleiben gleich, nur die Übersicht wird übersichtlicher. *(Backend)*

## 2026-05-17

- **Wiederherstellung großer Daten-Backups belastet die Festplatte nur noch einmal statt dreimal** — Bisher lag ein Daten-Backup während der Wiederherstellung bis zu dreimal auf der Platte (Upload, entpackter Zwischenstand, finale Position) — bei 50 GB waren zeitweise 150 GB frei nötig. Das Archiv wird jetzt beim Hochladen direkt entpackt und landet unmittelbar an seiner Zielposition, die am Ende atomar per Umbenennen aktiv geschaltet wird; der Platzbedarf sinkt auf die einfache Backup-Größe, die Wiederherstellung läuft spürbar schneller. *(Backend)*

- **Daten-Backup-Wiederherstellung trägt wiederhergestellte Deltas jetzt auch in die Übersicht ein** — Delta-Dateien wurden beim Restore korrekt auf die Platte zurückgeschrieben, tauchten aber nicht in der Delta-Übersicht auf, weil diese aus der Datenbank gelesen wird und die passenden Einträge fehlten (insbesondere bei reinem Daten-Restore ohne System-Backup). Die Wiederherstellung scannt jetzt am Ende den Delta-Ordner nach und trägt fehlende Einträge nach, ohne bestehende zu überschreiben. *(Backend)*

- **Maximale Backup-Dateigröße beim Wiederherstellen von 60 auf 120 GB angehoben** — Reverse-Proxy und Backend erlauben jetzt Backup-Uploads bis 120 GB — Vorbereitung für Daten-Backups mit umfangreicheren Clone-Beständen. *(Backend)*

- **Hochladen großer Backup-Dateien bricht nicht mehr mitten im Upload ab** — Das Backend sammelte die hochgeladene Datei bisher komplett im Arbeitsspeicher, bevor sie auf Platte geschrieben wurde — bei mehreren Gigabyte reichte das, um die Verbindung auf speicherschwachen Maschinen stillschweigend platzen zu lassen, zusätzlich griff ein separates Größenlimit der Multipart-Bibliothek. Der Datei-Inhalt wird jetzt direkt beim Hochladen stückweise auf Platte geschrieben; Backups im zweistelligen Gigabyte-Bereich lassen sich damit zuverlässig wiederherstellen. *(Backend)*

- **Backup-Wiederherstellung nimmt jetzt mehrere Dateien gleichzeitig an und zeigt Upload-Fortschritt** — System- und Daten-Backup lassen sich in einem Schritt hochladen; pro Datei erscheint eine Fortschritts-Karte, danach die Validierungs-Details. Die Reihenfolge ist erzwungen (Daten zuerst, System danach, da Letzteres das Backend neu startet); die serverseitige Upload-Grenze wurde zusätzlich von 10 MiB auf 60 GB angehoben. *(Backend, Verwaltungsoberfläche)*

- **VPN-Konfiguration ist nach einer Wiederherstellung wieder in der Oberfläche sichtbar** — Nach einem System-Backup-Restore blieb der VPN-Einstellungsbereich leer, obwohl der WireGuard-Container korrekt lief — die Einstellungen lagen in der ThinForge-Einstellungstabelle, die absichtlich nicht Teil des Backups ist (wegen host-spezifischer Werte). Das Backup legt jetzt eine separate Datei mit genau den VPN-Einstellungen an, die beim Restore vor dem WireGuard-Start zurückgeschrieben wird — wirkt nur, wenn *beide* Seiten (Quelle und Ziel) die neue Backend-Version haben. *(Backend)*

- **System-Backup-Wiederherstellung setzt private Schlüssel jetzt mit korrekten Berechtigungen zurück** — Sensitive Schlüsseldateien (SSH-Provisioning-Key, Signing-Key, Krypto-Salt, Heartbeat-Token) landeten nach einem Restore weltlesbar auf der Zielmaschine, weil die Wiederherstellung die Archiv-Mode-Bits übernahm — SSH-Verbindungen des Backends zu den Geräten (Terminal, Remote-Desktop, Provisioning) schlugen danach mit „Permissions too open" fehl. Die Wiederherstellung erzwingt jetzt für jede Schlüsseldatei den restriktiven Modus; bereits betroffene Boxen brauchen einen Restore-Wiederholungslauf oder eine manuelle Rechte-Korrektur. *(Backend)*

- **Backup merkt sich den DNS-Namen des Quell-Servers, Restore ergänzt ihn am neuen Server** — Nach einem Server-Umzug auf einen neuen Host konnten bereits ausgerollte Geräte den Server unter seinem alten Hostnamen nicht mehr finden. Das System-Backup speichert jetzt die selbst-referenzierenden Hostnamen der Quellbox und trägt sie beim Restore zusätzlich zu den eigenen Einträgen der neuen Box ins DNS ein — bestehende Geräte brauchen keine Anpassung; wirkt nur, wenn beide Seiten die neue Backend-Version haben. *(Backend)*

- **Client-Anlage schreibt jetzt auch die PXE-Boot-Konfiguration mit** — Beim Anlegen eines Clients (Dialog oder CSV-Import) wurde bisher nur die DHCP-Reservierung geschrieben, nicht aber die per-Gerät-Boot-Konfiguration für PXE — beim ersten Boot kam ein 404 beim Abruf der Boot-Datei und das Gerät fiel ins Firmware-Menü zurück statt zu starten. Beide Anlage-Wege schreiben die PXE-Konfiguration jetzt mit dem korrekten „von Festplatte booten"-Default direkt mit. *(Backend)*

- **System-Backup-Wiederherstellung räumt alte DHCP-/PXE-Reservierungen auf und vergibt frische Werte** — Beim Restore auf einen Server mit anderer Netzwerk-Topologie blieben alte IP-Reservierungen und veraltete PXE-Boot-Dateien stehen — der DHCP-Server verwarf Anfragen der Geräte still, und selbst danach fielen sie beim PXE-Boot ins Firmware-Menü zurück. Der Restore durchläuft jetzt pro Client denselben Provisionierungspfad wie eine manuelle Client-Anlage (alte Werte weg, frische IP, neue PXE-Konfiguration); auch der DHCP-Knopf „Leases zurücksetzen" räumt jetzt zusätzlich die Reservierungen mit auf. *(Backend)*

- **„Schlüssel exportieren"-Knopf aus dem Backup-Tab entfernt** — Der separate Sicherheits-Schlüssel-Export war ein Notfall-Werkzeug für die alte Backup-Architektur; da das neue System-Backup (Encryption-Key, Signing-Key, SSH-Hostkeys, WireGuard, TLS, Lizenz) bereits alle Schlüssel enthält, ist die Funktion entfallen — Kachel und zugehöriger Backend-Endpunkt sind entfernt. *(Backend, Verwaltungsoberfläche)*

- **Setup-Wizard-Abschluss ist jetzt idempotent — kein Lockout mehr nach abgebrochenem Vorversuch** — Brach ein vorheriger Wizard-Durchlauf zwischen Admin-Anlage und finalem Speichern ab, schlug ein erneuter Versuch mit demselben Konto bisher an einem Eindeutigkeits-Konflikt fehl und erforderte manuelles Eingreifen. Der Wizard-Abschluss räumt betroffene Nutzerdaten jetzt selbst auf, bevor der Admin-Benutzer neu angelegt wird — sicher, weil der Wizard ohnehin nur vor Abschluss der Einrichtung erreichbar ist. *(Backend)*

- **System-Backup-Format v4.0: nur portable Daten, keine host-gebundenen Configs mehr** — Das System-Backup enthält jetzt nur noch das, was bei einem Server-Umzug sinnvoll ist (kryptografische Schlüssel, WireGuard-Konfiguration, TLS-Zertifikat, Lizenz, bereinigte Kern-Datenbestände) — Reverse-Proxy-, DNS- und weitere host-spezifische Konfiguration inklusive der Netzwerk-IPs des Quell-Servers sind **nicht** mehr enthalten. **Wichtig:** Alte v2.0/v3.0-Backups werden mit klarer Fehlermeldung abgewiesen; vor einem Umzug muss auf dem Quellsystem ein frisches v4.0-Backup gezogen werden. Auf einem neuen Server läuft zuerst der reguläre Setup-Wizard (Netzwerk, TLS, Admin-Account), erst danach wird das Backup unter Einstellungen → Backup & Restore eingespielt — der Wizard selbst hat keinen Restore-Schritt mehr. *(Backend, Verwaltungsoberfläche)*

- **Backend kann die zentrale Host-Konfigurationsdatei nicht mehr überschreiben (Sicherheit)** — Der Backend-Container hatte bisher Schreibrechte auf die zentrale Host-Konfigurationsdatei, weil die Backup-Wiederherstellung den darin abgelegten Encryption-Key aktualisieren musste — ein kompromittierter Container hätte damit auch andere dort liegende Passwörter verändern können. Der Encryption-Key lebt jetzt in einer eigenen, vom Container beschreibbaren Datei; die Host-Konfiguration ist nur noch read-only eingehängt. Bestehende Systeme migrieren beim ersten Start automatisch, kein Eingriff nötig. *(Backend)*

- **Setup-Wizard nach System-Backup-Restore lässt sich wieder bis zum Ende durchlaufen** — Ein Restore brachte versehentlich auch das Flag „Setup abgeschlossen" zurück, wodurch das Backend ab dem nächsten Wizard-Schritt alle weiteren Aktionen verweigerte — genau in dem Moment, in dem der Operator die Netzwerk-Werte für den neuen Server anpassen wollte. Das Flag wird nach einem Restore jetzt explizit zurückgesetzt und am Wizard-Ende regulär neu gesetzt. *(Backend)*

- **Caddy verträgt jetzt IP-Wechsel durch Backup-Restore, ohne die Oberfläche unerreichbar zu machen** — Wich die Netzwerk-Topologie des neuen Servers von der des Backups ab, versuchte der Reverse-Proxy auf eine nicht-existente IP zu binden und fiel dadurch komplett aus — die Verwaltungsoberfläche war von außen nicht mehr erreichbar (Lockout). Jede IP wird jetzt vor dem Binden gegen die tatsächlich vorhandenen Host-Adressen geprüft; fehlende Bindings werden übersprungen (mit Log-Warnung), im Notfall lauscht die Verwaltungsoberfläche auf allen Interfaces, damit der Setup-Wizard immer erreichbar bleibt. *(Backend)*

- **System-Backup-Wiederherstellung schlägt nicht mehr mit einem Sperrfehler auf der Host-Konfigurationsdatei fehl** — Unterschied sich der Encryption-Key zwischen Backup und Zielserver, brach der Restore am Ende mit einem internen Fehler ab, weil das alte Aktualisierungs-Muster (Temp-Datei schreiben, dann umbenennen) auf einer in den Container eingehängten Datei von Linux verweigert wird. Der neue Inhalt wird jetzt direkt in die Datei geschrieben, ohne Umbenennen — der Restore läuft wieder bis zum Ende durch. *(Backend)*

- **Backup-Wiederherstellung nimmt die ausgewählte Datei in Setup-Wizard und Backup-Tab wieder an** — Nach Auswahl einer Datei erschienen weder Validierung noch Wiederherstellen-Knopf — Ursache war eine Verhaltensänderung der Datei-Auswahl-Komponente, die an zwei Stellen im Code noch nicht nachgezogen war. Validierungs-Anzeige (Version, Datum, Inhalt, Größe) und Wiederherstellen-Knopf erscheinen jetzt wieder wie vorgesehen. *(Verwaltungsoberfläche)*

- **Setup-Wizard leitet nach abgeschlossenem Setup zur Backup-Wiederherstellung weiter** — Rief man den Setup-Wizard nach bereits abgeschlossenem Setup direkt auf, ließ sich zwar eine Backup-Datei auswählen, ein Importieren-Knopf erschien aber nie, weil das Backend in diesem Zustand alle Wizard-Aktionen ablehnt, ohne dass das Frontend das klar anzeigte. Der Wizard leitet jetzt sofort mit Hinweis aufs Dashboard um; der reguläre Wiederherstellungs-Pfad liegt unter Einstellungen → Backup & Restore. Ein Werkseinstellungen-Reset landet weiterhin korrekt im frischen Wizard. *(Verwaltungsoberfläche)*

- **Daten-Backup (Clones + Deltas) lässt sich wieder herunterladen** — Der Download-Knopf lud die komplette Archiv-Datei zunächst in den Tab-Speicher des Browsers, bevor sie gespeichert wurde — bei mehreren Gigabyte sprengte das die Speicher-Grenze und der Download blieb hängen. Der Knopf stößt jetzt einen normalen Browser-Download mit „Speichern unter"-Dialog an, ohne die Datei komplett im Speicher zu halten; auch System-Backup-Downloads laufen jetzt über denselben Pfad. *(Verwaltungsoberfläche)*

- **BitTorrent-Cache räumt sich nach gelöschten Clones jetzt selbst auf** — Reste des Slice-Caches blieben zurück, wenn das Backend zwischen den Lösch-Schritten neu startete oder ein Clone direkt auf dem Dateisystem entfernt wurde — solche Reste sammelten sich unbemerkt an und konnten zweistellige Gigabyte belegen. Die Lösch-Reihenfolge wurde gedreht (Cache zuerst), und ein Abgleich beim Backend-Start räumt verwaiste Verzeichnisse automatisch auf. *(Backend)*

## 2026-05-16

- **Agent v2.9.0: Remote-Sitzungs-Anzeige wird jetzt vom Agent selbst verwaltet** — Die Statusbox „Remote-Sitzung aktiv" am Client-Bildschirm wird jetzt vom Agent-Binary selbst gezeichnet statt aus einem Shell-Skript heraus; Verhalten (Position, Größe, Verschiebbarkeit, automatisches Verschwinden) bleibt gleich. Künftige Verbesserungen am Indikator lassen sich damit per normalem Selbst-Update ausrollen, statt jeden Client neu provisionieren zu müssen. *(Agent)*

- **Cloning-VM-Start funktioniert wieder (Hotfix zur Dienste-Panel-Umsortierung von heute)** — Nach der Umsortierung von Caddy, thinVPN und Guacamole ins Dienste-Panel „Netzwerk" ließ sich die Cloning-VM wegen einer übersehenen Docker-Compose-Validierungsregel nicht mehr starten. Eine kleine Backend-Korrektur stellt Start, Stopp und Image-Bau der Cloning-VM wieder her. *(Backend)*

- **Remote Desktop: Sitzungs-Anzeige am Client wird jetzt verlässlich angezeigt** — Die bisherige System-Benachrichtigung war je nach Desktop-Konfiguration kaum oder gar nicht sichtbar. Jetzt erscheint eine verschiebbare Box oben rechts mit „Remote-Sitzung aktiv", die für die gesamte Sitzungsdauer bestehen bleibt und danach automatisch verschwindet — neu provisionierte Clients bekommen das automatisch, bestehende Clients müssen das Remote-Desktop-Provisioning einmal erneut ausführen. *(Agent)*

- **Dienste-Panel: Caddy, thinVPN und Guacamole sortieren sich jetzt unter „Netzwerk"** — Reine Anzeige-Sortierung im Einstellungen-Dienste-Panel, am Laufzeitverhalten ändert sich nichts. *(Backend)*

- **Dienste-Panel: Guacamole-Karte zeigt jetzt korrekten Status** — Der Guacamole-Container wurde durch einen internen Namensabgleich fälschlich als „nicht gefunden" angezeigt, obwohl er lief. Er erscheint jetzt korrekt mit Status, Uptime und Bedienknöpfen. *(Backend)*

- **Agent v2.8.1: Folge-Fix zum Self-Heal-Mechanismus** — Beim Live-Test des zuvor ausgerollten VPN-Self-Heal löschte ein automatischer TPM-Reset versehentlich die frisch ausgespielte Tunnel-Konfiguration und der Agent landete in einer Endlos-Retry-Schleife. Clients mit v2.8.0 werden vom Backend ohne dauerhaften Schaden so lange retried, bis sie per Selbst-Update auf v2.8.1 gehoben sind — kein manuelles Eingreifen nötig. *(Agent)*

- **VPN-Self-Heal: Tunnel reparieren sich automatisch nach Schlüssel-Drift** — Der Server kann einem Client per Heartbeat sagen, den TPM-versiegelten VPN-Schlüssel zu verwerfen und sich neu zu enrollen. Das löst zwei bisher manuell zu behebende Probleme automatisch: ein deaktiviertes und wieder aktiviertes Gerät, das am alten Schlüssel hing, und einen nach interner Server-Wartung entstandenen Schlüssel-Drift — die Ausfallzeit ist auf ein Heartbeat-Intervall begrenzt. Voraussetzung ist Agent v2.8.0 oder neuer; das manuelle Reset-Skript auf dem Client ist nur noch Notfall-Werkzeug. *(Backend, Agent)*

## 2026-05-15

- **Agent v2.7.2: VPN-Selbstheilung wirkt jetzt auf mehr Linux-Varianten** — Der TPM-Tunnel funktioniert jetzt auch auf Distributionen mit anderen Programm-Pfaden (Ubuntu 24.04+, Arch mit /usr-Merge), und stehengebliebene Tunnel-Konfigurationen werden beim Agent-Start jetzt zuverlässig aufgeräumt. *(Agent)*

- **Agent: VPN-Routen-Updates kommen auf TPM-Clients jetzt zuverlässig an** — Änderungen der gerouteten Netze im VPN-Tab wurden bei TPM-versiegelten Clients in die falsche Konfigurationsdatei geschrieben und erreichten den laufenden Tunnel nicht; zusätzlich konnte ein Tunnel-Neustart in einer Restart-Schleife hängenbleiben. Der Agent erkennt jetzt zuverlässig die aktive Konfiguration, räumt liegengebliebene Interfaces ab und repariert typische Drift-Zustände beim Start automatisch; für bereits feststeckende Clients steht ein manueller Notfall-Reset zur Verfügung. Rollout zunächst 24 h auf einem Test-Client, danach breit per Selbst-Update. *(Agent)*

- **VPN: Fehler beim Synchronisieren der Routen werden jetzt sichtbar** — War der VPS beim Speichern der VPN-Routen nicht erreichbar, wurde das bisher nur geloggt und der lokale Stand lief unbemerkt vom VPS-Stand auseinander. Jetzt erscheint ein Warn-Hinweis, und ein dauerhaft ausgegrauter „VPS Sync"-Button bei Nichterreichbarkeit wurde durch einen roten Alert mit Refresh-Möglichkeit ersetzt. *(Verwaltungsoberfläche)*

- **Remote Desktop: Guacamole auf Version 1.6.0 angehoben** — Der vermittelnde Guacamole-Daemon läuft jetzt in Version 1.6.0 statt 1.5.5, ohne Änderungen an der Bedienung. Installationen ohne Internetzugang müssen das neue Container-Image einmal manuell beziehen und auf den Server bringen. *(Server-Dienste, Deploy-Repo)*

- **System-Backup: TLS-Zertifikate werden jetzt vollständig mitgesichert** — Das Backup packte Konfigurationsverzeichnisse bisher nicht rekursiv ein, sodass z. B. die TLS-Zertifikate des Reverse-Proxys nach einem Restore fehlten und neu ausgestellt werden mussten — explizit hinterlegte eigene Server-Zertifikate wären verloren gegangen. Backup und Restore steigen jetzt rekursiv in Unterordner ab. **Achtung:** Vor diesem Update erstellte Backups enthalten die Zertifikats-Unterordner weiterhin nicht — wer auf ein älteres Backup angewiesen ist, sollte umgehend ein frisches ziehen. *(Backend)*

- **Sicherheits-Scan-Panel: überflüssiger Hinweistext entfernt** — Ein technischer Hinweis auf interne Abläufe wurde aus dem Vulnerability-Scan-Panel entfernt, das Panel wirkt aufgeräumter. *(Verwaltungsoberfläche)*

- **Updates-Tab: Fortschrittsbalken für Merge-Vorgänge wieder lesbar** — Der Fortschrittsbalken für Merged-Deltas brach seinen Text bei langen Bezeichnungen auf zwei Zeilen um und schnitt ihn oben/unten ab. Der Balken passt sich jetzt der Spaltenbreite an, der Text bleibt einzeilig und wird bei Bedarf gekürzt. *(Verwaltungsoberfläche)*

- **Reboot-Aufforderung auf Clients: „Jetzt neustarten"-Button erscheint wieder** — Im Standard-Dialog fehlte der „Jetzt neustarten"-Button, nur „Abbrechen" war sichtbar, wegen eines Verhaltensunterschieds zwischen den zwei genutzten Dialog-Werkzeugen. Beide Schaltflächen sind jetzt sichtbar; neue Clients bekommen zusätzlich das komfortablere Werkzeug mit Live-Countdown, bestehende Clients erhalten das korrigierte Skript automatisch per Heartbeat-Sync, ohne Agent-Rebuild. *(Agent)*

## 2026-05-14

- **Remote Desktop neu auf Apache-Guacamole-Basis** — Die seit Anfang Mai deaktivierte Remote-Desktop-Funktion wurde auf Basis des etablierten Open-Source-Stacks Apache Guacamole neu aufgesetzt und löst den bisherigen eigenständigen Stream-Mechanismus ab. Neu: drei Qualitäts-Voreinstellungen (DSL/VDSL/LAN, auch live umschaltbar), ein Tray-Hinweis für den angemeldeten Nutzer, zwei gleichzeitige Admin-Zuschauer; Wayland-Sitzungen werden noch mit klarer Fehlermeldung abgelehnt. **Voraussetzung:** Installationen ohne Internetzugang müssen das Guacamole-Image einmalig manuell beziehen, und bestehende Clients müssen einmal neu provisioniert werden, damit die nötigen Werkzeuge installiert sind — ohne das zeigt das System eine klare Fehlermeldung; alte Pakete der Vorgänger-Lösung dürfen liegenbleiben. *(Backend, Verwaltungsoberfläche, Agent)*

## 2026-05-13

- **Klon-Import: Fehler „Linienname bereits vergeben" auf sauberen Systemen behoben** — Der Import verglich sich versehentlich mit seinem eigenen temporären Arbeitsverzeichnis und meldete dadurch selbst auf einem System ohne andere Klone und leerer Datenbank fälschlich eine Namens-Kollision. Der Import läuft jetzt wieder durch. *(Backend)*
## 2026-05-12

- **Datenbank: Migrationen wieder zu einer Datei zusammengeführt** — Zwei kürzlich eingeführte Migrationen wurden in die Basis-Migration eingearbeitet; das Migrations-Verzeichnis enthält wieder nur eine Datei. Fresh-Installationen laufen dadurch in einer einzigen Transaktion durch und können nicht mehr in einen halb-migrierten Zustand geraten. **Achtung bei laufenden Installationen mit der alten Migrationsreihe:** Das Backend lehnt beim nächsten Start die Migrations-Prüfung mit einem Mismatch ab; Recovery erfordert manuellen Eingriff an der Migrationstabelle in der Datenbank oder einen Wipe (nur Dev-Setups) — betroffene Installationen vorher ankündigen. *(Server-Dienste)*

- **Agent: TLS-Verbindung repariert sich nach Zertifikatsfehlern in einer Runde** — Scheiterte die TLS-Verifikation zum Server, blieb der intern zwischengespeicherte Zertifikats-Pool unter Umständen veraltet und der Agent hing in einer Endlos-Schleife bis zum manuellen Neustart. Der Agent verwirft den zwischengespeicherten Pool jetzt nach jeder Recovery-Runde unbedingt — der nächste Heartbeat baut ihn aus der aktuellen Zertifikatsdatei neu auf. *(Agent)*

- **Signing-Schlüssel-Rotation: korrekt formatierter Pubkey wird signiert** — Nach einer Rotation des Signing-Schlüssels lehnten Clients den neuen Schlüssel als ungültig signiert ab, obwohl formal alles stimmte — Ursache war ein überflüssiger Zeilenumbruch am Ende der signierten Schlüsseldatei. Generierungs- und Rotationsskript normalisieren die Datei jetzt vor dem Signieren, neue Rotationen werden von den Clients sauber akzeptiert. *(Server-Dienste)*

- **Signing-Schlüssel-Rotation: bestehende Deltas werden direkt mit-signiert** — Bisher signierte die Schlüssel-Rotation nur Agent-Binary und Sidecar-Caches; bereits vorhandene Update-Deltas blieben mit dem alten Schlüssel signiert und wurden von Agents danach als ungültig verworfen, Updates kamen nicht mehr durch. Die Rotation signiert jetzt automatisch auch alle vorhandenen Deltas mit dem neuen Schlüssel nach; bei sehr großen Delta-Beständen kann das einige Minuten dauern. *(Server-Dienste)*

- **TLS-Zertifikat-Rotation: Reverse-Proxy wird zuverlässig neu geladen** — Nach dem Erzeugen oder Hochladen eines neuen Server-TLS-Zertifikats wurde der Reverse-Proxy nur neu geladen statt neu gestartet; da sich die Konfigurationsdatei selbst nicht ändert, las er das neue Zertifikat nicht von der Platte. Der HTTPS-Endpoint antwortete dadurch weiter mit dem alten Zertifikat. Die Rotation startet den Proxy-Container jetzt sauber neu, damit das neue Zertifikat sofort wirksam ist. *(Server-Dienste)*


## 2026-05-11

- **SSH-Schlüssel-Rotation läuft jetzt live über die Clients** — Das Rotieren des SSH-Schlüssels, mit dem Clients verwaltet werden, erforderte bisher einen Master-Image-Neubau und die Neu-Provisionierung aller Clients. Der neue Schlüssel wird jetzt signiert beim nächsten Heartbeat (Standard 60 s) an alle Online-Clients ausgespielt — die Rotation läuft im laufenden Betrieb, ohne Eingriff am einzelnen Client. Sicherheits-Begleitfix: Ein ungenutzter Agent-Codepfad, der einen ungeprüften Server-SSH-Pubkey übernommen hätte, wurde entfernt; zudem wird ein nach Signing-Schlüssel-Rotation zuvor veraltet bleibender Zertifikats-Begleiteintrag jetzt automatisch erneuert. *(Agent, Server-Dienste)*


## 2026-05-10

- **Update-Ketten: zusammengeführte Deltas werden korrekt der richtigen Linie zugeordnet** — Ein automatisch zusammengeführtes Delta (z. B. v001→v003 statt über v002) wurde fälschlich als „Ohne Linie" statt unter dem Image-Namen angezeigt. Das zusammengeführte Delta erbt die Zuordnung jetzt vom Ausgangs-Delta; bestehende Einträge wurden per einmaligem Datenbank-Update nachgezogen. *(Server-Dienste, Verwaltungsoberfläche)*

- **Cloning-Bereich: interne Aufräumarbeiten** — Strukturelle Bereinigung in den Cloning-Tabs (VM erstellen, Captures, Klone, Deployments, Updates, Rollback): gemeinsame Logik wurde zentralisiert, Anzeige-Formate vereinheitlicht. Keine sichtbare Änderung an der Bedienung und kein Handlungsbedarf; lediglich Größenangaben in Gigabyte erscheinen jetzt mit zwei statt einer Nachkommastelle. *(Verwaltungsoberfläche)*

- **Defekt-Markierung für Update-Versionen wirkt jetzt zuverlässig** — Versionen, die nur als Update (Delta) ohne eigene Baseline existieren, wurden von der „als defekt markieren"-Funktion nicht überall korrekt erfasst: Sie ließen sich im Update-Zuweisungs-Dialog weiter als Ziel wählen, und ein Rollout über eine defekte Zwischenversion erzwang kein automatisches Zusammenführen. Beide Fälle sind jetzt behoben — defekte Update-Versionen werden im Zuweisungs-Dialog ausgeblendet, betroffene Deltas automatisch zusammengeführt. Die nötige Datenbank-Schema-Erweiterung läuft beim nächsten Backend-Start automatisch durch. *(Server-Dienste, Verwaltungsoberfläche)*

- **Rollback / Defekt-Markierung: Folgekorrekturen aus Lab-Test** — Beim ersten Live-Test der „defekte Version markieren"-Funktion in einem Gruppen-Rollback fielen vier Probleme auf: ein 500-Fehler im Rollback-Endpoint, eine fälschlich als defekt markierte Rollback-Zielversion (statt der Version, von der weggerollt wird — auf einem Test-Client löschte das den benötigten Snapshot und ließ den Rollback mit „nicht genug Snapshots" abbrechen), ein gruppenübergreifend statt gruppenspezifisch wirkender Rollback sowie eine Defekt-Markierung, die nur in der Datenbank landete und nicht in den Klon-Metadaten auf der Platte. Alle vier sind behoben: die richtige Version wird markiert, Rollback bleibt auf die gewählten Clients begrenzt, und Datenbank sowie Klon-Metadaten werden synchron aktualisiert. *(Server-Dienste)*

- **Update-Klone: Linien-Name wird zuverlässig vererbt** — Ein neuer Update-Klon (z. B. v003) erschien im Klone-Tab fälschlich als „Basis" statt unter seiner Image-Linie (z. B. Manjaro), weil sein interner Linien-Name generisch „Update v…" lautete. Der Name des Linien-Wurzelklons wird jetzt sauber bis zum jüngsten Update vererbt, zusätzlich mit einer Absicherung im Hintergrund. *(Server-Dienste, Verwaltungsoberfläche)*

- **Klon löschen räumt zugehörige Markierungen mit auf** — Löschte man einen als defekt markierten Klon und legte ihn mit gleicher Version neu an, blieb die Defekt-Markierung in der Datenbank hängen und wurde vom neuen Klon fälschlich übernommen. Zudem konnten geplante Snapshot-Löschungen für die Version weiterlaufen und bei einem späteren Neuaufbau einen inzwischen nicht mehr obsoleten Snapshot löschen. Beide Aufräumarbeiten laufen jetzt beim Klon-Löschen automatisch mit. *(Server-Dienste)*

- **Updates-Tab: Deltas nach Linien gruppiert** — Update-Kette und zusammengeführte Deltas standen bisher in einer flachen Liste mit dem Linien-Namen nur als kleinem Chip, sodass bei mehreren parallelen Linien (z. B. Manjaro + Debian) schwer erkennbar war, welches Delta wohin gehört. Jetzt steht eine Überschrift pro Linie über den zugehörigen Deltas; Einträge ohne Linien-Namen landen unter „Ohne Linie" am Ende. *(Verwaltungsoberfläche)*

- **Agent: Bestätigungen gehen bei Heartbeat-Ausfall nicht mehr verloren** — Schlug der Heartbeat eines Clients fehl, wurden bereits erledigte Bestätigungen (z. B. „Snapshot gelöscht") trotzdem aus dem Puffer entfernt und gingen verloren. Der Puffer wird jetzt erst nach erfolgreichem Heartbeat geleert — sonst werden die Bestätigungen beim nächsten Versuch erneut mitgeschickt. *(Agent)*

- **Neue Funktion: Defekte Versionen beim Rollback sauber rausnehmen** — Im Rollback-Dialog gibt es jetzt die Checkbox „Version als defekt markieren" (standardmäßig aktiv). Aktiviert, wird die Version systemweit als defekt markiert und verschwindet aus der Auswahl für neue Rollouts, laufende oder geplante Rollouts mit dieser Zielversion werden abgebrochen und laufende Downloads gestoppt. Pro Client wird der zugehörige Snapshot der defekten Version nach erfolgreichem Rollback automatisch gelöscht — Clients, die noch auf der defekten Version laufen, werden dabei geschont; ein neuer Rollout-Pfad, der eine defekte Zwischenversion überspringen müsste, erzwingt automatisch das Zusammenführen der Deltas. Damit gibt es erstmals einen sauberen „Version raus, alle Spuren weg"-Pfad, der vorher pro Maschine von Hand nötig war. *(Server-Dienste, Verwaltungsoberfläche)*

- **Backend: Absturz nach Rollout-Abbruch behoben** — Beim Abbrechen eines laufenden Rollouts erschien im UI gelegentlich der generische Fehler „An error occurred", während intern ein Backend-Prozess abstürzte und parallele API-Aufrufe abbrachen. Ursache war eine Race-Condition im Datenstrom von Delta-Download und Delta-Zusammenführung; beide Datenströme sind jetzt robust gegen Doppel-Polling. Abbrechen funktioniert jetzt sauber, ohne parallele Anfragen zu stören. *(Server-Dienste)*


## 2026-05-09

- **Rollout abbrechen stoppt jetzt auch den laufenden Download am Client** — „Abbrechen" setzte bisher nur den Status im Backend, der Agent lud den Delta-Block trotzdem bis zum letzten Byte herunter. Die Übertragung lässt sich jetzt direkt im laufenden Stream stoppen, der Abbruch wirkt innerhalb von Sekundenbruchteilen und wird nicht erneut versucht. Der „Löschen"-Button für eine Zuweisung ist zusätzlich gesperrt, solange mindestens ein Client noch lädt. *(Agent, Verwaltungsoberfläche)*

- **Updates-Tab: alle Client-Aktionen direkt in der Zuweisungs-Zeile** — Die separate „Client-Status"-Sektion filterte bereits bestätigte Clients heraus, sodass z. B. „alle markierten Clients neustarten" für die Hauptzielgruppe nicht funktionierte. Sie ist entfernt; stattdessen bietet die ausgeklappte Zuweisungs-Zeile jetzt sortierbare Spalten, Auswahl-Checkboxen und Download-Fortschritt pro Client (Prozent / Mbit/s / Bytes). Eine Aktionsleiste „Neustarten / Herunterfahren" erscheint, sobald mindestens ein Client markiert ist, und wirkt zuweisungsübergreifend. *(Verwaltungsoberfläche)*

- **Image-Linien: Doppelte Namen werden früh abgefangen** — Zwei verschiedene Image-Linien konnten bisher denselben Namen tragen und im Hintergrund Versions-Kollisionen verursachen. Beim Speichern eines neuen Updates und beim Klon-Import wird der Name jetzt gegen alle bestehenden Linien geprüft (ohne Rücksicht auf Groß-/Kleinschreibung oder Leerzeichen); bei einer Kollision bleibt der Dialog mit rotem Hinweis offen. Beim Import lässt sich der Name zusätzlich per Feld „Umbenennen" direkt überschreiben; bestehende Duplikate bleiben unangetastet und müssen bei Bedarf manuell aufgelöst werden. *(Server-Dienste, Verwaltungsoberfläche)*

- **Update speichern: sichtbarer Fortschritt in zwei klar benannten Schritten** — Der Dialog „Update-Delta speichern & Klon erstellen" hing vorher minutenlang ohne erkennbares Feedback. Jetzt zeigt er zunächst einen Spinner mit „Layout wird geprüft" (10–15 s), schließt sich danach automatisch und im Tab „VM erstellen" erscheint ein Fortschrittsbalken mit „Schritt 1/2: Delta wird erstellt" und „Schritt 2/2: VM-Klon wird erstellt". Abbrechen ist während Schritt 1 gesperrt (Delta-Erzeugung lässt sich nicht sauber unterbrechen), in Schritt 2 verfügbar. *(Server-Dienste, Verwaltungsoberfläche)*

- **Klon-Löschung räumt nur noch das eigene Linien-Delta** — Beim Löschen eines Klons konnte unter bestimmten Umständen versehentlich auch ein Delta einer anderen Image-Linie mit-gelöscht werden, wenn beide am selben Tag dieselbe Versionsnummer trugen. Maßgeblich für die Zuordnung ist jetzt die Linien-Zugehörigkeit des Klons, fremde Deltas werden nicht mehr mitgelöscht. **Hinweis:** Bereits gelöschte Deltas lassen sich nicht byte-genau rekonstruieren — Betroffene können den zugehörigen Klon wiederherstellen und ein neues Update auf den nächsten Snapshot als Baseline erzeugen. *(Server-Dienste)*


## 2026-05-08

- **Update-Deltas: Folge-Korrekturen rund um die neue Versions-Logik** — Nach Einführung der Datumsversionen fielen zwei Folgefehler auf: Ein per Delta erzeugter Klon landete im Katalog mit einer abwegigen Versionsnummer und blieb beim Löschen als Waise zurück, weil er nicht in der Bestätigungsliste auftauchte; die Versions-Erkennung greift jetzt sauber. Zusätzlich zeigt die Deltas-Liste im Updates-Tab den Image-Linien-Namen jetzt fett vor dem Versions-Pfeil, damit bei mehreren parallelen Linien sofort klar ist, welches Delta zu welcher Linie gehört. *(Server-Dienste, Verwaltungsoberfläche)*

- **VPN-Tab vorne in der Netzwerk-Sektion, Auto-Refresh, NTP-Server zuverlässiger gefunden** — Der VPN-Tab steht jetzt an erster Stelle im Netzwerk-Bereich und aktualisiert sich automatisch alle 10 Sekunden, sodass TPM-Enrollment-Hinweise sowie Handshake- und Traffic-Werte ohne manuelles Nachladen aktuell bleiben. Der „Remote Desktop öffnen"-Button im Client-Detail ist vorübergehend ausgeblendet, und neue Clients bekommen die Remote-Desktop-Abhängigkeiten nicht mehr automatisch beim Setup installiert. Bei der Client-Installation wird der NTP-Server jetzt zuverlässig vom ThinForge-Server bezogen — vorher konnten Clients in NAT-Umgebungen versehentlich auf eine ungültige Adresse zeigen. *(Server-Dienste, Verwaltungsoberfläche)*

- **Image-Linien können selbst benannt werden, Versionszähler pro Linie** — Beim Speichern eines neuen Image-Stands (Baseline) gibt es jetzt ein Pflichtfeld „Image-Name", mit dem sich mehrere parallele Image-Linien unterscheiden lassen. Jede Linie hat einen unabhängigen Tages-Zähler, sodass am selben Tag keine zwei kollidierenden Versionen entstehen. Im Delta-Modus (kein neuer Wurzel-Klon) wird der Linien-Name automatisch vom Basis-Klon übernommen. *(Server-Dienste, Verwaltungsoberfläche)*

- **Cloning-VM: Snapshot-Namen jetzt im Datumsformat** — Der interne Snapshot der Cloning-VM folgte noch dem alten Versionsschema; er nutzt jetzt konsistent zur Versions-Umstellung das neue Datumsformat. Für die Bedienung ändert sich nichts. *(Server-Dienste)*

- **Hotfix: Heartbeats vom Rollout-Netz kamen nicht mehr durch** — Vorangegangene Umbauten am Reverse-Proxy hatten den HTTPS-Listener vom Rollout-Netz versehentlich abgehängt — Clients ohne VPN-Tunnel im Rollout-Netz erschienen alle als offline, obwohl sie liefen. Der Reverse-Proxy hat jetzt einen eigenen Block speziell für das Rollout-Netz, der nur die API beantwortet; Heartbeats kommen wieder an. *(Server-Dienste)*

- **Agent v2.6.6: interne Effizienz-Aufräumarbeiten** — Reines Aufräumen ohne Verhaltensänderung; bestehende Agents holen die Version automatisch per Selbst-Update. Spürbar nur als geringere Hintergrund-CPU-Last und weniger Netzwerk-Aktivität während laufender Update-Downloads. Kein Eingriff nötig. *(Agent)*


## 2026-05-07

- **Admin-Oberfläche nicht mehr über VPN erreichbar (Sicherheit)** — Der HTTPS-Listener horchte bisher auf allen Interfaces, wodurch die Admin-Oberfläche auch über das VPN-Overlay erreichbar war, obwohl das VPN ausschließlich für Agent-Heartbeats gedacht ist. Der Reverse-Proxy ist jetzt explizit gebunden: voller Admin-Zugriff nur über die Management-IP des LAN, über VPN ist ausschließlich die API erreichbar. **Hinweis für bestehende Installationen:** Die Listener-Konfiguration wird beim nächsten Backend-Neustart automatisch neu geschrieben; wer den Stack manuell abweichend konfiguriert hat, sollte alte Listener-Reste entfernen, um Port-Konflikte zu vermeiden. *(Server-Dienste)*

- **Image-Versionierung: Wechsel auf Datumsformat** — Image-Versionen werden jetzt im Format „vYYYY.MM.DD-NNN" vom System vergeben, mit einem Tageszähler pro Image-Linie, der täglich neu bei 001 beginnt — keine manuelle Eingabe mehr. Der Capture-Import-Dialog hat dafür ein neues Feld „Image-Name" (mit optionaler Beschreibung), um mehrere parallele Image-Linien sauber zu trennen. **Achtung:** Bestehende Versionen im alten Format werden auf „veraltet" gesetzt und nicht mehr als Update-Ziel angeboten (bleiben aber in der Historie sichtbar); die Umstellung ist nicht reversibel, vor dem Anwenden sollte ein Datenbank-Backup gezogen werden. *(Server-Dienste, Verwaltungsoberfläche)*

- **Agent v2.6.4: erkennt das neue Datums-Versions-Format** — Ältere Agents hätten das neue Datums-Versionsformat nicht erkannt und wären vom Update-Mechanismus abgehängt worden. Ab v2.6.4 versteht der Agent beide Formate und sortiert korrekt zwischen ihnen. **Wichtig:** Vor dem ersten Rollout im neuen Format müssen alle Ziel-Clients mindestens auf v2.6.4 sein — das Selbst-Update bringt sie automatisch hoch, bei länger offline gewesenen Clients sollte der Heartbeat-Status vorher geprüft werden. *(Agent)*

- **Agent v2.6.3: Hotfix — Update kommt am Client an** — Beim ersten End-to-End-Test des neuen Download-Pfads lief der Download sauber durch, wurde beim nächsten Reboot aber nicht angewendet, weil eine zugehörige Metadaten-Datei nicht mit-heruntergeladen wurde. Der Agent zieht sie jetzt automatisch mit — Updates werden beim Reboot korrekt eingespielt. *(Agent)*

- **Agent v2.6.2: schlankerer Heartbeat während Download + Crash-Erkennung** — Beim ersten Live-Test fielen drei Probleme auf: Der Agent sendete während eines laufenden Downloads unnötig „vollständige" Heartbeats (CPU-/IO-Last genau dann, wenn der Client ohnehin ausgelastet ist), Heartbeats stockten während des minutenlangen Downloads (leerer Fortschrittsbalken im UI), und ein Absturz oder Reboot während des Downloads blockierte den Download-Slot 15 Minuten lang. Der Agent sendet während des Downloads jetzt schlanke Heartbeats mit Fortschrittswert; bricht der Download durch Crash/Reboot ab, erkennt das Backend das im nächsten Heartbeat, gibt den Slot frei und startet automatisch einen Wiederholungsversuch (Anzahl einstellbar, Default 3), der am letzten heruntergeladenen Byte fortsetzt statt von vorne. *(Agent, Server-Dienste)*

- **Bandbreiten-Steuerung für Delta-Updates** — Zogen viele Clients gleichzeitig ein großes Update, lief der Internet-Uplink voll und andere Nutzer verloren Bandbreite — bisher gab es kein Limit und keine Drosselung. Die Auslieferung läuft jetzt über HTTPS statt NFS mit sauberer Authentisierung und nahtlos fortsetzbarem Download; ein global einstellbares Limit begrenzt standardmäßig 10 parallele Downloads. Jeder Client misst zusätzlich die Latenz zum Server und drosselt sich automatisch, wenn die Leitung voll wird (Standard maximal 10 Mbit/s pro Client, einstellbar, 0 = unbegrenzt). Der Wechsel ist verbindlich — Agents ziehen das nötige Selbst-Update automatisch beim nächsten Heartbeat. *(Agent, Server-Dienste, Verwaltungsoberfläche)*

- **Backend kann VPN-Clients direkt pingen / per Terminal erreichen** — Das Backend erreicht jetzt auch reine VPN-Clients (Homeoffice ohne LAN-Pfad) direkt für Ping und Terminal, ohne Umweg über den VPN-Container. Dafür wurde die Firewall-Logik erweitert, damit Antwort-Pakete auf backend-initiierten Verbindungen durchkommen. **Sicherheitsmodell unverändert:** Neue Verbindungen werden weiterhin gefiltert, nur Antworten auf bereits akzeptierte Verbindungen passieren — kein Filter-Downgrade. *(Server-Dienste)*

- **Datenbank-Migrationen laufen automatisch beim Container-Start** — Neue Schema-Migrationen mussten bisher manuell eingespielt werden, was bei Vor-Ort-Installationen untragbar war. Der Backend-Container ruft die Migrationsprüfung jetzt vor jedem Start selbst auf, erkennt bestehende Schemas automatisch und entwickelt sie sauber weiter; im Fehlerfall startet das Backend nicht, um einen inkonsistenten Zustand zu vermeiden. Updates spielen sich künftig durch ein normales Herunterladen und Neustarten der Container ein, ohne Handarbeit an der Datenbank. *(Server-Dienste)*

- **VPN-Routen: sichere Live-Anwendung mit Rollback und Status-Rückmeldung** — Ändert man im UI die Liste der über VPN gerouteten Netze, prüft der Agent vor dem Scharfschalten zunächst, ob eine Route das lokale Heimnetz des Geräts überdeckt; im Konfliktfall lehnt er ab, meldet das zurück und der angemeldete Nutzer bekommt einen Hinweisdialog — kein Selbst-Aussperren. Geht der Tunnel nach dem Apply nicht wieder hoch, spielt der Agent automatisch die alte Konfiguration zurück und meldet den Status „rolled_back". Jedes Apply-Ergebnis erscheint im nächsten Heartbeat im VPN-Tab als farbiges Symbol pro Client (rot bei Heimnetz-Konflikt, orange bei Rollback oder Fehler), sodass sichtbar ist, ob die Änderung auf der ganzen Flotte angekommen ist. *(Agent, Verwaltungsoberfläche)*

- **VPN-Clients-Tab: „letzter Handshake" wird wieder gefüllt** — Die Spalte zeigte wegen eines Format-Unterschieds im Datum der zentralen VPN-API für alle Einträge nur „—" an, weil die Werte nie geparst wurden. Behoben — beim nächsten minütlichen Sync-Lauf füllen sich die Werte korrekt. *(Server-Dienste, Verwaltungsoberfläche)*


## 2026-05-06

- **Terminal-Button erreicht auch reine VPN-Clients (Zwischenlösung)** — Der Terminal-Knopf blieb beim Verbinden hängen oder schlug fehl, vor allem bei reinen VPN-Clients (Homeoffice): Die VPN-IP wurde mit Präfix-Länge an SSH übergeben und löste als Hostname nicht auf, und die Verbindung wurde aus dem Backend-Container aufgebaut, der keinen Weg ins VPN-Netz hat. Als Zwischenlösung läuft SSH jetzt über den VPN-Container, der direkten Zugriff auf alle Netze hat; eine saubere Lösung über Bridge-Weiterleitung folgte einen Tag später. *(Server-Dienste)*

- **Ping-Button erreicht VPN-Clients wieder** — Analog zum Terminal-Problem blieb der Ping-Button für reine VPN-Clients ohne Reaktion, weil das ICMP-Paket im Backend-Container ohne Forwarding zum VPN-Interface entstand. Pings laufen jetzt über den VPN-Container und erreichen LAN- wie VPN-Clients zuverlässig. *(Server-Dienste)*

- **Agent v2.5.21: „VPN verbunden"-Anzeige im Dashboard wieder korrekt** — Roaming-Clients zeigten im Dashboard fälschlich „verbunden (LAN)" statt „verbunden (VPN)", obwohl der Heartbeat durch den Tunnel lief — Ursache war eine separate Route-Abfrage, die bei mehreren Server-Adressen (LAN + VPN) nicht zuverlässig die richtige Antwort lieferte. Der Agent ermittelt den Verbindungsweg jetzt direkt aus der tatsächlich genutzten Verbindung. *(Agent)*

- **Agent v2.5.20: angezeigte Client-IP stimmt mit dem tatsächlichen Heartbeat-Pfad überein** — Hatte ein Client zwei Wege zum Server (LAN und VPN) und fiel einer kurzfristig aus, konnte die im Dashboard angezeigte IP von der tatsächlich genutzten Verbindung abweichen. Der Agent ermittelt seine IP jetzt über denselben Probiervorgang wie die Heartbeat-Verbindung selbst. *(Agent)*


## 2026-05-05

- **Agent erreicht den Server jetzt automatisch über LAN ODER VPN** — Bei gleichzeitigem LAN- und VPN-Tunnel erreichte der Agent den Server bisher nur über die LAN-Adresse; Roaming-Clients außerhalb des LANs hatten dadurch keinen Pfad. Der Server liefert dem Agent jetzt beide Adressen (LAN bevorzugt, VPN als Reserve); der Agent versucht die erste mit 3-Sekunden-Timeout und schwenkt bei Bedarf automatisch auf die zweite, innerhalb des 10-Sekunden-Heartbeat-Budgets. Bestehende Clients werden beim nächsten VPN-Re-Deploy automatisch migriert; ohne Re-Deploy lässt sich die zweite Server-Adresse auch manuell nachtragen. *(Agent, Server-Dienste)*

- **Agent v2.5.18: Sicherheits- und Robustheits-Sammelrelease** — Ein umfangreicher Code-Review (über 4000 Zeilen mit Root-Rechten) schloss vier Sicherheitslücken: ein Signatur-Check beim Selbst-Update, der eine falsch signierte Agent-Binary akzeptiert hätte; ein Recovery-Pfad nach Zertifikatsfehlern, der im engen Zeitfenster ungeprüfte Server-Felder (SSH-Schlüssel, Token, VPN-Routen) übernahm; ein über den angemeldeten Benutzernamen ausnutzbarer Befehlsausführungs-Pfad als Root; sowie ungeprüft in Root-Operationen einfließende Server-Werte (Dateinamen, SSH-Schlüssel, VPN-Routen). Alle vier sind nur über lokalen Einbruch oder einen LAN-Angreifer im sehr engen Recovery-Zeitfenster ausnutzbar und auf LAN-only-Deployments unkritisch, wurden aber vorsorglich geschlossen. Zusätzlich schreibt der Agent kritische Dateien jetzt atomar, das TPM-Enrollment kann nicht mehr in einen nicht wiederherstellbaren Hybridzustand geraten, und Heartbeats nutzen bei Server-Fehlern jetzt eine schrittweise Verlängerung mit Zufalls-Streuung. *(Agent)*


## 2026-05-04

- **Dashboard: neue Kachel „Garantie bereits abgelaufen"** — Das Dashboard zeigt jetzt eine fünfte Kachel mit der Anzahl der Geräte, deren Garantie bereits abgelaufen ist (rot bei mehr als null, sonst grau). Sie ergänzt die bestehende Kachel „Garantie läuft bald ab". *(Verwaltungsoberfläche)*

- **Agent v2.5.17: Versions-Hochzählung, damit das Selbst-Update wirklich ausrollt** — Der Selbst-Update-Mechanismus vergleicht Versionsnummern als Text; nach einem Hotfix-Tag-Wechsel trugen Server- und Client-Binary kurzzeitig dieselbe Versionsnummer trotz unterschiedlichen Inhalts, wodurch das Selbst-Update übersprungen wurde. Mit v2.5.17 ist die Version sauber hochgezählt, das Update läuft auf den Clients jetzt durch. *(Agent)*

- **Dashboard: „Alle anzeigen" im Meldungen-Bereich öffnet den richtigen Tab** — Der Link landete bisher auf dem Standard-Einstellungen-Tab (Benutzer-Verwaltung) statt auf dem Meldungen-Tab. Der Klick öffnet jetzt direkt den richtigen Tab. *(Verwaltungsoberfläche)*

- **Agent-Hostname: Cloning-Artefakt wird beim Erststart still ersetzt** — Auf jedem neu installierten Gerät löste der von der Cloning-VM mitgebrachte Hostname-Marker (basierend auf der QEMU-Standard-MAC) alle 24 Stunden einen „MAC geändert"-Alarm aus, der jedes Mal manuelle Auflösung im Dashboard erforderte. Der Agent erkennt diesen einmaligen Übergang vom Cloning-Artefakt zur echten Hardware jetzt und ersetzt den Hostnamen still, ohne Alarm — der eigentliche Identitätsschutz (Alarm bei Hostnamen-Wechsel auf bereits produktiver Hardware) bleibt vollständig erhalten. *(Agent)*


## 2026-05-03

- **Remote-Desktop: Codec-Wechsel auf H.264, mit Hardware-Beschleunigung, wenn vorhanden** — Der Codec für die Remote-Desktop-Übertragung wechselt zurück auf H.264, das bei Homeoffice-Verbindungen über VPN (~2 Mbit/s) bei 1080p deutlich sauberere Bilder liefert als der vorherige Codec. Der Agent wählt pro Sitzung automatisch den besten verfügbaren Encoder (Intel-/AMD-Hardware, dann NVIDIA-Hardware, als Rückfall die Software-Variante); Tooling und Treiber werden bei der Client-Provisionierung passend zur Distribution mit-installiert. Ergebnis: weniger CPU-Last auf dem Client und eine deutlich flüssigere Übertragung. Hinweis: H.264 ist patentpflichtig — auf Hardware-Pfaden ist die Lizenz über den Hersteller abgedeckt, beim Software-Fallback gilt der übliche Lizenzrahmen. *(Agent)*

- **Info-Bereich: neuer Tab „Lizenz"** — Der Info-Bereich hat jetzt einen dritten Tab „Lizenz" mit den hinterlegten Lizenz-Texten (LICENSE, NOTICE, Drittanbieter-Lizenzen, schriftliches Angebot zur Quellcode-Bereitstellung), aufklappbar pro Eintrag und ohne Internetzugriff nutzbar. *(Verwaltungsoberfläche)*

- **Info-Bereich: Link zur Webseite ergänzt** — Im Info-Tab erscheint neben der E-Mail-Adresse jetzt ein Webseiten-Link auf thinforge.org, der in einem neuen Tab öffnet. *(Verwaltungsoberfläche)*

- **Agent: Server-TLS-Zertifikat wird auch im System-Vertrauensspeicher des Clients aktualisiert** — Nach einer Rotation des Server-TLS-Zertifikats aktualisierte der Agent bisher nur seinen eigenen Vertrauensanker; System-Werkzeuge auf dem Client (z. B. Browser) misstrauten dem neuen Zertifikat weiterhin, bis ein separater Pflege-Lauf nachzog. Der Agent aktualisiert nach jeder Zertifikats-Rotation jetzt auch den System-Vertrauensspeicher (Arch/Manjaro, RHEL, Debian) — Browser und System-Tools vertrauen dem neuen Zertifikat sofort. *(Agent)*
## 2026-05-02

- **Backup & Restore neu strukturiert (System- und Daten-Backup)** — Backup ist jetzt in zwei Typen aufgeteilt: ein kleines, synchrones System-Backup (Datenbank, Konfiguration, VPN-Schlüssel) und ein großes Daten-Backup als Hintergrund-Job (Klone und Update-Deltas). Beide lassen sich im Backup-Tab erzeugen, herunterladen und löschen; der Setup-Wizard akzeptiert nur System-Backups. Restore läuft jetzt sauber getrennt ab — Dateien und Datenbank werden atomar zurückgespielt, laufende Daten werden nie vor Abschluss gelöscht, danach starten die betroffenen Container in fester Reihenfolge neu. Das Delta-Verzeichnis wird ab jetzt erstmals mitgesichert; die zuvor deaktivierten Backup-Karten sind wieder nutzbar.
  *(Backend, Verwaltungsoberfläche)*


## 2026-05-01

- **Speichern von Updates: Mehrfach-Subvolume-Layout wird automatisch konsolidiert** — Cloning-VMs, die ohne den Vorbereitungsschritt installiert wurden, hatten Home, Cache und Log in getrennten Btrfs-Subvolumes — Updates enthielten dadurch nur das Hauptverzeichnis, z. B. fehlten angelegte Desktop-Verknüpfungen auf den Clients. Das System erkennt das jetzt vor dem Snapshot und bietet im Dialog eine Konsolidierung an, die Inhalte zusammenführt und die separaten Subvolumes entfernt. Danach läuft das Update normal weiter und folgende Updates sind vollständig.
  *(Backend, Verwaltungsoberfläche)*

- **Agent: VPN-Adresse löst keinen „Hardware-MAC-Änderung"-Alarm mehr aus** — Auf manchen Geräten meldete der Agent fälschlich einen MAC-Änderungs-Alarm, sobald der VPN-Tunnel aktiv wurde, weil der VPN-Adapter versehentlich als physische Netzwerkkarte galt. Die Erkennung fragt jetzt direkt beim Kernel nach echter Hardware und sortiert die Karten in fester Reihenfolge (kabelgebunden vor WLAN) — die Geräte-Identität ist damit stabil. **Migration:** Geräte mit mehreren Kabel-Netzwerkkarten melden nach dem Update einmalig einen MAC-Änderungs-Alarm, der einmal im Dashboard aufgelöst werden muss; auch bestehende Alarme der alten Fehlerklasse müssen manuell auf „gelöst" gesetzt werden.
  *(Agent)*

- **Dashboard: interner Fehler beim Anzeigen von MAC-Änderungs-Alarmen behoben** — Meldete ein Client einen MAC-Wechsel, schlug der Dashboard-Aufruf mit einem internen Serverfehler fehl, weil die Alarm-Kategorie dem Server unbekannt war. Behoben — MAC-Änderungen erscheinen jetzt korrekt im Dashboard, ebenso der Alarm „Versions-Abweichung", der denselben Fehler hatte.
  *(Backend, Verwaltungsoberfläche)*


## 2026-04-29

- **Cloning-VM: einheitliches Wurzel-Subvolume statt getrennter Layouts** — Neu installierte Cloning-VMs legten Home, Cache und Log in eigenen Btrfs-Subvolumes an, wodurch Updates nur das Hauptverzeichnis enthielten und Home bei den Clients fehlte. Die Installations-Vorbereitung schreibt jetzt ein einheitliches Wurzel-Subvolume vor, in dem Home, Cache und Log als normale Verzeichnisse liegen und bei jedem Update mit erfasst werden. **Migration:** Cloning-VMs mit dem alten Layout müssen einmal neu installiert oder die Subvolumes manuell zusammengeführt werden; auf End-Clients greift die Korrektur automatisch beim nächsten Update.
  *(Tools-ISO)*

- **Cloning-VM-Setup: Agent-Binary wird jetzt zuverlässig aktualisiert** — Lief das Vorbereitungs-Skript auf einer VM mit bereits aktivem Agenten erneut, blieb die alte Agent-Version stehen, obwohl eine Erfolgsmeldung erschien — die laufende Datei ließ sich nicht überschreiben, der Fehler wurde verschluckt. Die neue Binary wird jetzt daneben abgelegt und atomar getauscht, der Agent-Dienst bei Bedarf neu gestartet.
  *(Tools-ISO)*

- **Tools-ISO: Agent-Binary kommt jetzt zuverlässig aus dem aktuellen Build** — Beim Neuerstellen der Tools-ISO wurde versehentlich eine alte, eingecheckte Agent-Version statt der frisch gebauten mitgenommen — neu installierte Clients liefen dadurch teils mit deutlich älteren Ständen. Die ISO-Erstellung nutzt jetzt verbindlich die zuletzt gebaute Binary samt Signatur und Versions-Datei.
  *(Deploy-Repo)*

- **Client-Installation: Größe der Daten-Partition kommt vollständig aus dem UI** — Die Installations-Skripte fragten die Größe der Daten-Partition bisher zusätzlich vor Ort ab, obwohl sie schon im UI-Wizard „Basis HD erstellen" festgelegt wird. Die doppelte Abfrage ist entfernt; das Partitions-Skript erkennt den vorhandenen Festplattenzustand selbst und legt nur an, was fehlt — bestehende Daten-Partitionen bleiben unangetastet.
  *(Tools-ISO, Verwaltungsoberfläche)*

- **„Basis HD erstellen": Distributions-Auswahl entfällt** — Das bisherige Distributions-Dropdown im Wizard passte nach der Installation oft nicht zum tatsächlich vom Installer gewählten Btrfs-Layout, wodurch die Snapshot-Erstellung fehlschlug. Das Feld ist entfernt; das System erkennt das angelegte Wurzel-Subvolume jetzt automatisch aus der Datei-Struktur nach der OS-Installation. Ändert sich der Festplatten-Zustand, läuft die Erkennung erneut — hängengebliebene Installationen heilen sich beim nächsten Versuch selbst.
  *(Verwaltungsoberfläche, Backend)*

- **Versionsanzeige zeigt wieder die echte Version statt „vdev"** — Auf frisch aufgesetzten Servern stand rechts oben in der Kopfleiste „vdev" statt der Datums-Version, weil dem Frontend-Build die Quelle für die Versionsnummer fehlte. Behoben — nach dem nächsten Frontend-Rebuild zeigt die Kopfleiste wieder die korrekte Version.
  *(Verwaltungsoberfläche, Deploy-Repo)*

- **Release-Server: Compose-Pfadfehler behoben (Restart-Loops)** — Auf frisch ausgerollten Release-Servern liefen Backend und Worker in einer Restart-Schleife, die Datenbank blieb ohne Schema und der Setup-Wizard hing — Ursache waren drei nicht angepasste Pfadfehler in der Compose-Datei aus dem Entwickler-Setup. Beide betroffenen Compose-Varianten sind korrigiert. **Hinweis:** Bei betroffenen Installationen muss vor dem nächsten Deploy eventuell ein versehentlich angelegter Phantom-Ordner entfernt und die Datenbank einmal neu initialisiert werden.
  *(Deploy-Repo)*

- **Sicherheits-Audit aller Container-Images, Basis-Images angehoben** — Ein umfassendes Sicherheits-Audit aller Container-Images deckte kritische Schwachstellen in älteren Docker-Werkzeugen und Python-Paketen auf. Behoben durch eine neuere Rust-Toolchain und aktualisierte System-Pakete im Backend-Image (behebbare Schwachstellen von 43 auf 3 reduziert, alle kritischen Treffer weg), angehobene Paket-Versionen in Cloning-VM- und BT-Seeder-Images sowie frisch gezogene externe Basis-Images (Postgres, Redis, Caddy, Node, Alpine, Go). Verbleibende Treffer in Build-only-Komponenten der Python-Toolchain werden zur Laufzeit nicht genutzt und sind als bekannt/akzeptabel dokumentiert.
  *(Deploy-Repo)*

- **Debian-Clients: Rollback-Einträge im Bootloader funktionieren wieder** — Auf Debian-Clients fehlten die Snapshot-Einträge im Bootloader-Menü, ein Rollback auf einen früheren Snapshot war darüber nicht auswählbar — Ursache war ein Unterschied im Standard-Textwerkzeug zwischen Debian und Arch/Manjaro. Behoben: Beim nächsten Update laufen die Snapshot-Einträge im Bootloader-Menü wieder korrekt auf.
  *(Agent)*

- **Agent-Selbst-Update funktioniert wieder zuverlässig** — Das Agent-Selbst-Update war kurzzeitig blockiert, weil Anfragen ohne Authentifizierungs-Token gesendet und vom Server mit 403 abgelehnt wurden — sichtbar nur im Debug-Log. Betroffene Clients blieben auf der zur Installation eingespielten Version stehen. Selbst-Update und das Nachladen der Helfer-Skripte senden den Heartbeat-Token jetzt korrekt mit. **Migration:** Geräte mit sehr alter Agent-Version brauchen einmal einen manuellen Push der neuen Binary oder ein Re-Provisioning, danach läuft das Selbst-Update wieder eigenständig.
  *(Agent)*

- **Terminal und Remote-Desktop erkennen das Login-Cookie wieder** — Nach der Umstellung auf cookie-basierte Anmeldung öffneten sich die Terminal- und Remote-Desktop-Dialoge nicht mehr und meldeten „nicht authentifiziert". Beide Dialoge erkennen das Login-Cookie jetzt zuverlässig.
  *(Verwaltungsoberfläche)*

- **Klon-Export: Btrfs-Layout-Infos werden mitgesichert** — Beim Export eines Klons werden jetzt die Btrfs-Layout-Informationen (Distribution, Wurzel-Subvolume) mit ins Archiv geschrieben. Beim Restore findet das System dadurch sofort das richtige Wurzel-Subvolume, sodass der erste Update-Speichern-Vorgang danach ohne manuelles Eingreifen läuft. Ältere Klone ohne diese Info fallen weiterhin auf die automatische Erkennung zurück.
  *(Backend)*

- **Single-Root-Layout: Folgekorrekturen aus dem Code-Review** — Mehrere Aufräumarbeiten rund um die Umstellung auf ein einzelnes Wurzel-Subvolume: alte Hilfsdateien für die früher getrennten Subvolumes werden beim Agent-Update automatisch entfernt, das Nachsignier-Skript räumt liegengebliebene alte Delta-Dateien mit auf, und das manuelle Snapshot-Verwaltungs-Skript schützt jetzt zusätzlich vor versehentlichem Löschen des aktiven Wurzel-Subvolumes auf Debian-Clients. Veraltete Kommentare und Konfigurationsreste in den Installations-Skripten sind aufgeräumt.
  *(Agent, Tools-ISO)*


## 2026-04-28

- **Cloning-VM: korrektes Layout pro Distribution, Updates wieder mit Inhalt** — Bei Debian-basierten Cloning-VMs erzeugte das System durch einen Layout-Mismatch zwischen vorbereiteter Festplatte und dem tatsächlich vom Debian-Installer angelegten Layout nahezu leere Update-Dateien, obwohl mehrere hundert MB neu installiert waren. Behoben durch eine Distributions-Auswahl (Debian/Ubuntu/Mint/Sonstige) im „Basis HD erstellen"-Wizard, die das passende Wurzel-Subvolume anlegt, sowie ein einheitliches Wurzel-Subvolume-Modell in Backend und Agent, in dem das Home-Verzeichnis automatisch mit erfasst wird. Zusätzlich sind Festplatten-Größenangaben jetzt durchgängig auf 1024-Basis vereinheitlicht, sodass eine im Wizard mit 60 GB angelegte Festplatte auch als 60 GB im Klon-Katalog erscheint.
  *(Backend, Verwaltungsoberfläche, Agent)*

- **VPN-Firewall: Peer-Isolation funktioniert jetzt verlässlich** — Die Regel „Peer-Isolation" (VPN-Geräte sehen sich nicht gegenseitig) wurde in einer Form geschrieben, die das Firewall-Backend ablehnte; der Fehler wurde verschluckt, sodass die Oberfläche „an" zeigte, obwohl VPN-Peers sich tatsächlich noch erreichen konnten. Die Regel ist jetzt sauber aus zwei Einzel-Einträgen gebaut und wirkt wie angezeigt. Firewall-Befehle laufen zudem strikt nacheinander und brechen bei einem Fehler sofort ab statt ihn stillschweigend zu verschlucken; die Regeln werden nach jedem Container-Neustart automatisch neu angewendet.
  *(Server-Dienste)*

- **VPN-Firewall: Live-Log im UI** — Im VPN-Tab gibt es jetzt ein „Firewall Live-Log" mit Zeit, Aktion (Akzeptiert/Verworfen/Peer-Isolation), Regel, Quelle, Ziel, Protokoll und Port. Es aktualisiert sich alle 5 Sekunden, mit Pause-Knopf und manuellem Refresh, und lässt live nachvollziehen, welche Pakete welche Regel treffen.
  *(Server-Dienste, Verwaltungsoberfläche)*

- **Firewall-Log: keine doppelten Einträge mehr nach Tunnel-Neustart** — Nach einem Neustart des VPN-Containers erschien der komplette alte Log-Puffer erneut im Firewall-Log, wodurch Einträge sich vervielfachten. Behoben: Der Mitschnitt erfasst jetzt nur noch neue Meldungen nach dem Start, jedes Ereignis erscheint genau einmal.
  *(Server-Dienste)*

- **VPN-Einstellungen: Peer-Isolation nicht mehr abschaltbar** — Der Schalter für „Peer-Isolation" ist aus den VPN-Einstellungen entfernt. Der Schutz ist fest verdrahtet und kann nicht mehr versehentlich deaktiviert werden.
  *(Server-Dienste, Verwaltungsoberfläche)*

- **VPN: Firewall schaltet sich beim Tunnel-Import automatisch ein** — Nach dem Importieren einer Tunnel-Konfiguration musste die Firewall bisher zusätzlich im UI aktiviert werden, sonst lief der Tunnel ungeschützt. Das passiert jetzt automatisch — Peer-Isolation und Live-Log sind ab dem ersten Tunnel-Import direkt aktiv.
  *(Server-Dienste)*

- **Heartbeat-Token: kontrolliertes Rotations- und Recovery-Verhalten** — Der Heartbeat-Token, mit dem sich ein Agent beim Server ausweist, wird jetzt zentral validiert; nach einer Rotation werden ältere Token noch eine konfigurierbare Karenzzeit (Standard 96 Stunden) akzeptiert. Der Server liefert den nächsten gültigen Token im Heartbeat mit, der Agent speichert ihn atomar, und ein neuer Recovery-Endpunkt erlaubt das gezielte Nachholen eines Tokens. Die internen Agent-Endpunkte hängen jetzt durchgängig hinter der Token-Prüfung — einzig der Endpunkt zur TLS-Zertifikats-Wiederherstellung bleibt bewusst offen.
  *(Backend, Agent)*


## 2026-04-27

- **Geplante Deployments mit BitTorrent: Status-Updates kommen jetzt an** — Beim Vorlauf-Mechanismus für geplante Deployments (der Seeder startet schon 10 Minuten vor dem geplanten Zeitpunkt) verwarf der Server Status-Meldungen des Seeders, solange das Deployment noch nicht „aktiv" war — das UI zeigte dadurch weiterhin „Vorbereiten", obwohl der Seeder bereits lief. Status-Meldungen werden jetzt auch während der Vorlauf-Phase angenommen.
  *(Backend)*

- **Geplante Deployments: dreistufiger Ablauf mit Vorlauf und Wake-on-LAN** — Geplante Deployments laufen jetzt automatisch in drei Phasen: 10 Minuten vorher werden Seeder und Torrent im Hintergrund vorbereitet, 1 Minute vorher werden PXE-, NFS- und Netzwerk-Vorbereitungen scharfgeschaltet, und zum geplanten Zeitpunkt werden Wake-on-LAN-Pakete verschickt — bewusst erst nach der Aktivierung, damit aufwachende Clients nicht ins alte Boot-Ziel laufen. Im Dialog ist „Wake-on-LAN beim Start senden" jetzt ein einfacher Schalter statt eines Vorlauf-Zeitfelds, und der Worker erkennt Konfigurationsfehler schon beim Start statt erst im laufenden Betrieb.
  *(Backend, Verwaltungsoberfläche)*

- **Geplante Deployments: Datum und Uhrzeit getrennt, immer Server-Zeitzone** — Der Plan-Dialog hat jetzt einen separaten Datums- und Uhrzeit-Picker (24-Stunden-Format). Die Eingabe wird immer als Server-Zeitzone interpretiert, unabhängig davon, wo der Browser läuft, und ein Hinweis zeigt live die resultierende UTC-Zeit — das vermeidet Zeitzonen-Verwechslungen.
  *(Verwaltungsoberfläche)*

- **Server-Setup: Zeitzone wird interaktiv abgefragt, Zeit-Synchronisation sichergestellt** — Das Setup-Skript setzte bisher fest die Berliner Zeitzone; jetzt wird sie interaktiv abgefragt und gegen die Linux-Zeitzonenliste validiert, mit der aktuellen Einstellung als Vorschlag. Automatisierte Setups ohne Terminal behalten die bestehende Zeitzone oder setzen sie per Umgebungsvariable. Das Setup schaltet außerdem die automatische Zeit-Synchronisation ein, falls sie noch nicht aktiv ist — ohne korrekte Uhrzeit kann die TLS-Verbindung zum Agenten fehlschlagen.
  *(Server-Dienste)*

- **Client-Installation: ISO-Skripte werden zuverlässig gefunden, Fehler brechen die Installation hart ab** — Das Folge-Skript der Tools-ISO wurde je nach Pfad oder Aufrufweise manchmal nicht gefunden — die Installation lief scheinbar durch, das Ergebnis war aber nicht funktionstüchtig. Die Suche prüft jetzt drei Wege (eigenes Verzeichnis, gemountete ISO-Pfade, automatisches Mounten der CD-Laufwerke) und bricht bei Fehlschlag mit klarer Meldung ab. Zusätzlich bricht die Installation jetzt hart ab, wenn die Daten-Partition nicht eingehängt oder kein Btrfs ist — sonst hätten Token, Zertifikat und Agent-Binary versehentlich im Wurzel-Dateisystem landen und beim nächsten Boot vom echten Daten-Mount verdeckt werden können, sodass der Agent ohne gespeicherten Zustand gestartet wäre.
  *(Tools-ISO)*

- **Neues Diagnose-Skript für Clients** — Auf der Tools-ISO gibt es jetzt ein Diagnose-Skript, das eine installierte Client-VM umfassend prüft: Mounts, Agent-Binary, Konfiguration, TLS-Zertifikat, Tokens und Berechtigungen, Update-Skripte, relevante Systemd-Units, SSH-Setup, installierte Version und einen Verbindungstest zum Server. Am Ende steht eine Pass/Warn/Fail-Bilanz mit passendem Exit-Code für die Skript-Nutzung.
  *(Tools-ISO)*


## 2026-04-26

- **Client-Installation: doppelte Layout-Prüfung entfernt** — Die Tools-ISO hatte neben der UI-gesteuerten Festplatten-Vorbereitung eine zweite, redundante Prüfschicht, die in bestimmten Konstellationen sogar falsche Fehler auslöste. Sie ist entfernt — das UI ist jetzt die alleinige Quelle für das Layout.
  *(Tools-ISO)*

- **Cloning-VM: Festplatten-Größenanzeige stimmt jetzt mit der UI-Eingabe überein** — Die im Wizard eingegebene Festplattengröße wurde im Status-Panel abweichend berechnet — 60 GB erschienen dort als 54 GB. Beide Stellen rechnen jetzt einheitlich, auch die „Vergrößern"-Funktion wendet den UI-Wert korrekt an.
  *(Backend, Verwaltungsoberfläche)*

- **„Basis HD erstellen": Festplatten-Vorbereitung lief im falschen Verzeichnis** — Die Festplatten-Vorbereitung im Wizard schrieb versehentlich in ein leeres Container-Verzeichnis statt in das echte Datenverzeichnis auf dem Server — der Wizard meldete Erfolg, im Klon-Bereich tauchte aber nichts auf. Behoben: Die Vorbereitung schreibt jetzt zuverlässig ins Storage-Verzeichnis. **Hinweis:** Betroffene „nichts ist da"-Stände müssen einmal manuell aufgeräumt und die Festplatte neu angelegt werden.
  *(Backend)*

- **Cloning-VM: keine versehentliche Festplatten-Vergrößerung mehr beim Container-Start** — War eine vorhandene Festplatte beim Start des Cloning-VM-Containers etwas kleiner als erwartet, wurde sie bisher automatisch vergrößert — die Partitionstabelle blieb dabei aber unverändert, sodass der OS-Installer die Platte fälschlich als leer ansah und einen Neuanfang vorschlug. Die automatische Vergrößerung beim Start ist entfernt; Festplatten werden ausschließlich über den UI-Wizard angelegt, eine fehlende Festplatte bricht den Container jetzt mit klarer Fehlermeldung ab.
  *(Server-Dienste)*

- **VPN-Firewall: Peer-Isolation als feste Grundregel eingeführt** — Neue Grundregel: Geräte hinter dem VPN sehen sich gegenseitig nicht mehr (Client-zu-Client-Verkehr im VPN-Overlay wird gesperrt). Die Regel steht ganz vorne in der Firewall-Kette, sodass eine später zu weit gefasste „Erlauben"-Regel den Schutz nicht aushebeln kann; die Appliance selbst bleibt weiterhin erreichbar. Ein Schalter im VPN-Einstellungs-Dialog (Standard: an) wurde zwei Tage später wieder entfernt — der Schutz ist seither fest verdrahtet.
  *(Server-Dienste)*

- **Neuer „Basis HD erstellen"-Wizard im UI** — Im Cloning-Bereich gibt es einen neuen Wizard, mit dem sich die Festplatte der Cloning-VM direkt aus dem UI partitionieren, formatieren und mit den nötigen Subvolumes anlegen lässt — vorher ein manueller Schritt im Rescue-Modus. Eingaben werden gegen sinnvolle Mindestgrößen geprüft (System ≥ 4 GB, EFI ≥ 100 MB, Daten ≥ 1 GB).
  *(Verwaltungsoberfläche, Backend)*

- **Vulnerability-Scan: Zahlen in Übersicht und Detail stimmen jetzt überein** — Die Übersichts-Zelle pro Image zeigte teils andere Zahlen als die zugehörige Detail-Liste, etwa „12 Kritisch" gegenüber „1 Kritisch (11 akzeptiert)" im Detail. Beide rechnen jetzt aus derselben Quelle, und technische Duplikate (dieselbe Schwachstelle in derselben Paket-Version an verschiedenen Pfaden) werden nicht mehr mehrfach gezählt — die Zahlen sind konsistent.
  *(Backend, Verwaltungsoberfläche)*

- **Vulnerability-Scan: Postgres und Redis werden wieder korrekt eingestuft** — Schwachstellen-Befunde für die Postgres- und Redis-Images landeten fälschlich im Topf „benötigt Bewertung", weil der Image-Name aus dem Dateinamen falsch abgeleitet wurde. Der Scan liest den Image-Namen jetzt direkt aus der Scan-Ausgabe; die betroffenen CVEs werden beim nächsten Scan korrekt eingeordnet.
  *(Backend)*

- **Vulnerability-Scan: zwei Schwachstellen als bekannt eingetragen** — Ein Verfügbarkeits-Befund in einer Telemetrie-Bibliothek im Caddy-Image (DoS über manipulierte Header) ist im LAN-only-Betrieb ohne Datenabfluss, nur potenzieller Verfügbarkeitsverlust; der Fix wartet auf ein Caddy-Upstream-Update. Ein gRPC-Befund im BT-Seeder-Image ist ein False-Positive, da er nur die Go-Implementierung betrifft, während das Image die C++/Python-Variante enthält.
  *(Deploy-Repo)*

- **Tools-ISO: zusätzlicher Installationsweg für Debian-Netinst** — Für die schlanke Debian-Netinst-ISO gibt es jetzt ein eigenes Begleit-Skript. Anders als bei der Live-Variante läuft die Installation im Standard-Debian-Installer, die Subvolumes werden im Vorbereitungsschritt manuell angelegt; der Abschluss-Schritt ist identisch zur Live-Variante.
  *(Tools-ISO)*


## 2026-04-25

- **Navigation: „Lizenz" und „Lokales Netzwerk" erscheinen jetzt in der Seitenleiste** — Zwei Tabs, die bereits existierten aber im Seitenmenü fehlten, sind jetzt sichtbar: Einstellungen → „Lizenz" und Netzwerk → „Lokales Netzwerk". Ein Klick in der Seitenleiste landet jetzt zuverlässig auf dem gewünschten Tab.
  *(Verwaltungsoberfläche)*

- **Cloning-Konsole: Reload-Knopf für die VM-Ansicht** — Die Konsolen-Ansicht im „VM erstellen"-Tab hat jetzt einen kleinen Refresh-Knopf, der eine frische Verbindung zur Konsole aufbaut — gelegentlich leere Konsolen-Anzeigen lassen sich damit ohne kompletten VM-Neustart beheben.
  *(Verwaltungsoberfläche)*

- **Klon-Liste: klarere Aktions-Bezeichnung** — Der „Wiederherstellen"-Knopf in der Klon-Liste heißt jetzt „Wiederherstellen zur VM" — damit ist klar, dass die laufende Cloning-VM-Disk das Ziel ist und nicht ein ausgewählter Client.
  *(Verwaltungsoberfläche)*

- **Frontend: Build-Pipeline strikter, Production-Image korrekt** — Der Frontend-Build prüft jetzt vor jeder neuen Version strikt alle TypeScript-Fehler; über Monate angesammelte Warnungen wurden dabei aufgeräumt. Die Production-Compose-Variante baut das Frontend-Image jetzt aus dem echten Production-Pfad statt aus dem Entwicklungs-Pfad — zuvor konnten Container-Neustarts in seltenen Fällen offene Browser-Tabs auf nicht mehr existierende Modul-URLs laufen lassen.
  *(Deploy-Repo, Verwaltungsoberfläche)*

- **Update-Speichern: Versionsvorschlag berücksichtigt jetzt vorhandene Klone** — Der Versionsvorschlag beim Speichern eines Updates kam bisher rein aus dem letzten Snapshot der laufenden VM — war der Snapshot-Stapel geleert, aber Klone mit alten Versionen lagen noch vor, schlug der Speichern-Vorgang mit einem Versionskonflikt fehl. Der Vorschlag berücksichtigt jetzt auch vorhandene Klone und wählt die nächste freie Nummer.
  *(Backend)*

- **Dienste-Panel: BT-Seeder und Multicast-Sender werden angezeigt** — Im Dienste-Panel und unter Einstellungen → Logs tauchen jetzt der BitTorrent-Seeder und alle aktiven Multicast-Sender auf, dynamisch je nach laufenden Deployments. Damit lassen sich Status und Logs dieser Hilfs-Container ohne Umweg über die Konsole einsehen.
  *(Verwaltungsoberfläche, Server-Dienste)*

- **Reverse-Proxy: PXE-Pfade nur noch im Client-Netz erreichbar** — Der Reverse-Proxy für PXE- und Klon-Deploy-Pfade auf Port 80 bindet jetzt gezielt nur an die im Setup-Wizard konfigurierte Client-Netz-IP statt an alle Netzwerk-Karten. PXE-Clients funktionieren weiterhin wie gewohnt, das Management-Netz sieht auf Port 80 aber nichts mehr — der Admin-Zugriff über HTTPS auf Port 443 bleibt unverändert.
  *(Server-Dienste)*

- **BitTorrent-Seeder bindet nur noch ans Client-Netz** — Der Seeder-Container für BitTorrent-Deployments öffnete seine Peer- und Tracker-Ports bisher auf allen Netzwerk-Karten; beide binden jetzt strikt nur an die Client-Netz-IP. Ändert sich das Client-Netz im Setup-Wizard, wird der Seeder-Container automatisch mit der korrigierten IP neu angelegt.
  *(Server-Dienste)*

- **Deployments-Tab: neue Deployments erscheinen sofort in der Liste** — Beim Anlegen eines BitTorrent-Deployments dauerte die Torrent-Erzeugung einige Sekunden, in denen der neue Eintrag in der Liste noch fehlte — der Operator musste manuell neu laden. Der Eintrag erscheint jetzt sofort oben in der Liste, das Nachladen läuft im Hintergrund.
  *(Verwaltungsoberfläche)*


## 2026-04-22

- **Agent-Heartbeat: das im UI eingestellte Intervall wirkt jetzt dauerhaft** — Der Agent schaltete intern nach zwei erfolgreichen Heartbeats fest auf 120 Sekunden um und überschrieb damit die UI-Einstellung — wer „alle 10 Sekunden" einstellte, sah nach kurzer Zeit trotzdem wieder 120 Sekunden. Die feste Logik ist entfernt; der Agent richtet sich jetzt dauerhaft nach dem Server-Wert innerhalb sinnvoller Grenzen (10–3600 Sekunden).
  *(Agent)*

- **BitTorrent-Deployments: mehrere Deployments parallel möglich** — Der BT-Seeder läuft jetzt als langlebiger Dienst, der mehrere Klon-Torrents gleichzeitig anbieten kann — mehrere BitTorrent-Deployments mit verschiedenen Klonen an unterschiedliche Gruppen laufen jetzt problemlos parallel (Multicast bleibt aus Protokoll-Gründen weiterhin auf eines pro Server begrenzt). Ist kein BitTorrent-Deployment mehr aktiv, stoppt der Seeder automatisch, sodass Peer- und Tracker-Ports außerhalb von Rollouts geschlossen bleiben. Deployments desselben Klons teilen sich denselben Schwarm für schnellere Wiederholungsstarts, und Klon-Löschungen räumen den zugehörigen Cache mit auf.
  *(Server-Dienste, Backend)*

- **Ein Deployment kann jetzt mehrere Gruppen gleichzeitig versorgen** — Der „Deployment anlegen"-Dialog hat einen neuen Ziel-Modus „Mehrere Gruppen": Die ausgewählten Gruppen werden zu einer Client-Menge zusammengefasst und in einem einzigen Deployment ausgeliefert — bei Multicast wird das Image dadurch nur einmal übertragen, egal wie viele Gruppen daranhängen. Die Deployment-Liste zeigt den gemeinsamen Eintrag mit allen beteiligten Gruppen-Namen.
  *(Backend, Verwaltungsoberfläche)*

- **Deployments: keine Geister-Einträge mehr bei Aktivierungsfehlern** — Schlug das Aktivieren eines Deployments fehl (z. B. weil PXE-Setup nicht möglich war), blieb der Eintrag bisher trotzdem als „aktiv" stehen und blockierte spätere Deployments. Bei einem Fehler wird der Eintrag jetzt sauber entfernt und die Ursache im UI angezeigt; ein fehlgeschlagener Restart belässt das Deployment entsprechend in seinem alten Zustand.
  *(Backend, Verwaltungsoberfläche)*


## 2026-04-21

- **Neues Lizenzsystem** — ThinForge unterstützt jetzt ein Lizenzsystem mit Free-Tier bis 50 aktive Geräte ohne Lizenzschlüssel und vollem Funktionsumfang. Lizenzschlüssel werden als signiertes, verschlüsseltes Bundle im neuen Tab „Einstellungen → Lizenzierung" hochgeladen; bei Überschreitung des Geräte-Limits werden nur neue Registrierungen abgewiesen (HTTP 403), bereits registrierte Geräte laufen unverändert weiter. Nach Ablauf der Lizenz gibt es eine 60-Tage-Karenzzeit, danach Rückfall auf den Free-Tier; die Limit-Prüfung greift sowohl bei Einzelanlage als auch beim CSV-Bulk-Import.
  *(Backend, Verwaltungsoberfläche)*

- **Setup-Wizard wird nicht mehr automatisch erzwungen** — Der Setup-Wizard wurde bisher bei jedem Seitenaufruf automatisch erzwungen, sobald das Backend ihn als unvollständig meldete — kombiniert mit dem unten beschriebenen Datenbank-Persistenz-Fehler konnte das ungewollt Produktionsdaten überschreiben. Der Auto-Redirect ist entfernt; der Wizard bleibt weiterhin manuell aufrufbar.
  *(Verwaltungsoberfläche)*

- **Dashboard: Festplatten-Belegung wird wieder korrekt angezeigt** — Nach der Umstellung des Backend-Images auf eine schlankere Basis zeigte das Dashboard die Festplatten-Belegung mit Nullwerten an, weil der intern genutzte Systembefehl ein bestimmtes Format dort nicht unterstützte. Auf ein portables Format umgestellt — die Werte werden wieder korrekt angezeigt.
  *(Backend, Verwaltungsoberfläche)*

- **Klone wiederherstellen: Größen-Anzeige stimmt jetzt mit der Quelle überein** — Beim Wiederherstellen eines über die Tools-ISO aufgenommenen Basis-Klons wurde die Ziel-Festplatte fälschlich auf 60 GB voreingestellt, obwohl die echte Größe in den Klon-Metadaten lag — die erzeugte Festplatte passte dann nicht zur Partitionstabelle der Quelle. UI-Anzeige und tatsächliche Erstellung greifen jetzt zuerst auf die echte Disk-Größe aus dem Klon zurück.
  *(Backend, Verwaltungsoberfläche)*

- **Datenbank-Persistenz korrigiert (Wichtig)** — Nach einem harten Cache-freien Rebuild oder einer Volume-Bereinigung war die Datenbank leer und der Setup-Wizard lief erneut, weil die Postgres-Daten in einem anonymen, nicht sichtbaren Docker-Volume statt im gemounteten Datenverzeichnis landeten. Korrigiert: Die Daten liegen jetzt an einer festen, sichtbaren Stelle im Datenverzeichnis und überleben Container-Neuanlagen. **Migration bestehender Installationen:** Die Daten müssen einmalig aus dem alten anonymen Volume in das neue Verzeichnis kopiert und die Postgres-Berechtigungen angepasst werden — ohne diesen Schritt drohen bei einem künftigen harten Neuaufbau Datenverluste.
  *(Backend, Deploy-Repo)*

- **Sicherheits-Befunde werden präziser nach Erreichbarkeit gefiltert** — Die Schwachstellen-Übersicht unterscheidet jetzt strikt zwischen „nicht betroffen" (Erreichbarkeits-Filter, z. B. isolierter Container) und „betroffen, aber als akzeptiert markiert" (bewusste Entscheidung, z. B. wartender Fix). Pro Image und Schweregrad steht die ursprüngliche Zahl durchgestrichen neben der tatsächlich relevanten, ein Symbol zeigt die Erreichbarkeit (LAN/intern/isoliert), und das Detail-Popup schlüsselt nach Angriffsvektor auf. Die Bewertung erfolgt vollständig automatisch durch das System.
  *(Backend, Verwaltungsoberfläche)*


## 2026-04-20

- **Dienste-Panel wird automatisch aus der Compose-Konfiguration aufgebaut** — Welche Container im Dienste-Panel erscheinen, wird jetzt direkt aus der Compose-Konfiguration abgeleitet; Anzeigename, Icon und Markierungen wie „kritisch" kommen über Labels am Container. Neue Dienste tauchen dadurch automatisch auf, sobald sie in der Compose-Datei eingetragen sind, ohne Backend-Code-Änderung.
  *(Backend, Deploy-Repo)*

- **Sicherheits-Scan: Container-Basis-Images aktualisiert** — Erste Vorbereitungsrunde für das umfassendere Schwachstellen-Audit am Folgetag: externe Image-Versionen wurden flexibler verwaltet und kritische Python-Bibliotheken im Cloning-VM-Image auf gefixte Versionen angehoben. Die Liste der dauerhaft akzeptierten, bekannten Befunde wurde deutlich ausgebaut.
  *(Deploy-Repo)*

- **Backend-Container auf schlankere Basis umgestellt (Alpine)** — Der Backend-Container basiert jetzt auf Alpine statt Debian, die Image-Größe sinkt um rund ein Drittel (691 MB → 497 MB). Alle weiteren ThinForge-Container nutzen dieselbe schlankere Basis; funktional ändert sich nichts.
  *(Deploy-Repo)*

- **Komplette Ablösung des alten Python-Backends** — Der noch im Repository liegende Python/FastAPI-Backend-Baum ist endgültig entfernt, da der Rust-Nachfolger seit längerem der einzige produktive Stack ist. Die alte Produktions-Compose-Variante und ein paar tote Skripte sind mit entfernt worden; Bedienung und Funktionsumfang bleiben unverändert.
  *(Deploy-Repo, Backend)*

- **Monitoring (Prometheus, Grafana) und Ansible-Runner (Semaphore) abgeschaltet** — Prometheus, Grafana und Semaphore sind in allen Compose-Varianten deaktiviert, da sie im laufenden Betrieb nicht regulär genutzt wurden und das Semaphore-Image zudem viele nicht selbst behebbare kritische Schwachstellen trug. Die Datenverzeichnisse bleiben unangetastet, eine spätere Reaktivierung ist jederzeit möglich.
  *(Deploy-Repo, Server-Dienste)*

- **Vulnerability-Scan: nur noch über UI auslösbar, läuft komplett im Backend** — Der Schwachstellen-Scan läuft jetzt vollständig aus dem Backend heraus, ohne zusätzliches Setup auf dem Host. Einziger Auslöse-Weg ist der „Scan starten"-Knopf im Sicherheits-Tab — das hält den Zustand der Scan-Daten konsistent und vereinfacht Erst-Installationen.
  *(Backend, Verwaltungsoberfläche)*
## 2026-04-19

- **Speicher-Aufräumen: BitTorrent-Daten und alte Scan-Ergebnisse werden mitgeräumt** — Das interne Aufräum-Skript entfernt jetzt zusätzlich verwaiste BitTorrent-Hilfsdaten (mehrere GB nach einem Datenbank-Reset möglich) sowie verlegte Schwachstellen-Scan-Verzeichnisse aus dem alten Projektpfad. Beides geschah bisher nicht automatisch. *(Server-Dienste)*

- **Container-Basis: vollständige Umstellung auf Alpine 3.22** — Alle ThinForge-Container (BitTorrent-Seeder, Cloner, dnsmasq, Multicast-Sender, Cloning-VM sowie Chrony/NFS/WireGuard) laufen jetzt auf der schlankeren Linux-Distribution Alpine 3.22 — deutlich kleinere Images (z. B. Cloner 200→86 MB, Multicast-Sender 138→25 MB, BT-Seeder ~700→242 MB), funktional unverändert. Zusätzlich wurde die Go-Toolchain für den Agent aktualisiert, wodurch alle bekannten Go-Standardbibliotheks-Schwachstellen im Agent-Binary mitbehoben sind. *(Server-Dienste, Agent)*

- **Schwachstellen-Scan: Daten liegen im zentralen Datenverzeichnis** — Die Ergebnisse der Schwachstellen-Scans liegen jetzt im zentralen Datenverzeichnis statt im Projekt-Verzeichnis, passend zur Konvention für Laufzeitdaten. Beim Start eines neuen Scans wird automatisch aufgeräumt, was das beobachtete Wachstum auf mehrere GB verhindert; die Bedienung bleibt unverändert. *(Backend, Server-Dienste)*

- **Frontend: Bibliotheks-Updates (Sicherheit)** — Mehrere Frontend-Bibliotheken (u. a. axios, vue, vuetify, MDI-Font, pinia, vue-router, vue-i18n, jsbarcode, sass) wurden auf neuere Patch-Versionen angehoben, die bekannte Sicherheits-Befunde beheben. Größere Versionssprünge sind bewusst zurückgestellt, um zusätzlichen Testaufwand zu vermeiden. *(Verwaltungsoberfläche)*

- **Reverse-Proxy-Konfiguration: eine einzige Quelle** — Die Reverse-Proxy-Konfiguration konnte bisher von drei Stellen geschrieben werden, zwei davon ohne die nötigen PXE-Pfade — wer nach einem Re-Build den Setup-Wizard durchlief oder das TLS-Zertifikat neu erzeugte, bekam stillschweigend die kaputte Variante, wodurch PXE-Clients mit „BOOT FAILED!" abbrachen. Die Konfiguration kommt jetzt aus genau einer Datei im Repository, wird wie Code reviewt und beim Setup unverändert übernommen; Setup-Wizard und Zertifikats-Generierung schreiben sie nicht mehr selbst. Der „Zertifikat entfernen"-Knopf ist entfernt — TLS ist jetzt immer aktiv. *(Backend, Verwaltungsoberfläche, Server-Dienste)*

- **Deployments-Tab: BitTorrent-Vorbereitungs-Phase ist sichtbar** — Bei einem BitTorrent-Deployment sprang der Status-Chip bisher kurz auf „aktiv", obwohl der Seeder noch Daten extrahierte, Torrents erzeugte und Tracker startete — das flackerte im UI. Der Status zeigt jetzt sauber „Vorbereitung…" mit orangenem Balken, bis der Seeder wirklich verteilt, danach wechselt er auf „Aktiv". *(Verwaltungsoberfläche, Backend)*

- **PXE-Auslieferung: über den zentralen Reverse-Proxy statt Hilfs-Webserver** — Die Auslieferung der PXE-Boot-Dateien (insbesondere die ~400 MB große Boot-Dateisystem-Datei) lief bisher über einen kleinen Hilfs-Webserver im DNS/DHCP-Container, der pro Verbindung einen neuen Prozess startete — bei 100+ parallel bootenden Geräten ein realer Engpass. Der zentrale Reverse-Proxy übernimmt die Auslieferung jetzt effizient asynchron mit Kernel-Optimierungen und RAM-Caching (im Test 50 parallele Anfragen in 35 ms); der Hilfs-Webserver ist entfernt, der DNS/DHCP-Container kümmert sich nur noch um DHCP und TFTP. *(Server-Dienste)*

- **BitTorrent-Deployment: Torrent-Dateien werden für Clients sichtbar abgelegt** — Beim ersten erfolgreichen End-to-End-BitTorrent-Deployment bekamen Clients beim Abruf der Torrent-Datei ein „404 nicht gefunden", weil der Seeder sie in ein anderes Verzeichnis schrieb als das, aus dem die Clients über den Webserver abriefen. Die Datei wird jetzt zusätzlich in das richtige Verzeichnis gespiegelt und nach Ende des Deployments automatisch wieder weggeräumt. *(Server-Dienste)*

- **Sicherheit: neuer SBOM-Download im UI** — Im Sicherheits-Bereich gibt es einen neuen Sub-Tab „SBOM-Download", der alle vorhandenen Scan-Läufe mit Zeitstempel listet und pro Lauf die drei Standard-Software-Bestandslisten (Syft, CycloneDX, SPDX) zum Download anbietet — einzeln pro Container oder als komplettes Archiv. Damit lassen sich Software-Bestandslisten ohne Server-Zugriff erzeugen. *(Verwaltungsoberfläche, Backend)*


## 2026-04-18

- **Agent v2.5.3: TLS-Zertifikat-Sync + Re-Installations-Verbesserungen** — Der Agent zieht das Server-TLS-Zertifikat jetzt regelmäßig vom Server und aktualisiert sein lokales Vertrauens-Verzeichnis automatisch, sodass Zertifikats-Rotationen ohne erneutes Provisionieren wirken. Re-Installations-Aufgaben spielen jetzt zusätzlich zum Agent-Binary auch Server-Zertifikat, Signing-Schlüssel und Heartbeat-Token aus, sodass der Agent sofort einsatzbereit ist. Die Paketeinstallation wurde aus der Startsequenz entfernt, weil ein hängendes Provisionierungs-Skript (z. B. ohne Internet) sonst den gesamten Heartbeat-Loop blockierte; bei einem Skript-Abbruch werden jetzt zudem zuverlässig alle Kind-Prozesse beendet. *(Agent)*

- **Cloning-VM: Fortschritts-Anzeige beim Klonen wieder live** — Beim Erstellen eines Klons stand die Fortschritts-Anzeige minutenlang bei 0 % und sprang dann direkt auf 100 % — ohne Live-Feedback. Der Backend-Service liest jetzt während des Vorgangs einen Status-Indikator aus und spielt den Fortschritt prozentual ans UI weiter, analog zum Wiederherstellungs-Ablauf. *(Backend, Verwaltungsoberfläche)*

- **DHCP-/NFS-Authorisierung: jetzt strikt per IP, ohne Token-Pflicht** — Die Authentifizierung interner DHCP-Lease-Meldungen läuft jetzt rein über die Netzwerk-Topologie statt über den bisherigen Shared-Secret-Token, der entfernt wurde: Das Backend hört nur noch auf Loopback, der Reverse-Proxy blockt den DHCP-Endpunkt von außen, und der DNS/DHCP-Container kann das Backend nur über Loopback ansprechen — Sicherheit kommt jetzt aus der Topologie statt aus Token-Verwaltung. Gleichzeitig wurde der Reverse-Proxy für PXE-Callbacks repariert, sodass zuvor hängengebliebene Multicast-Deployments wieder funktionieren. *(Backend, Server-Dienste)*

- **Sicherheits-Audit: kritische Befunde behoben** — Mehrere kritische Befunde aus dem internen Sicherheits-Audit sind geschlossen: Der öffentlich erreichbare Heartbeat-Token-Endpunkt (jeder im LAN konnte den geteilten Client-Token unauthentifiziert abrufen) ist entfernt — Tools-ISO und Klon-Images sind die offiziellen Provisionierungs-Quellen; Callback-Tokens bei Klon-Deployments werden jetzt strikt geprüft statt leere/fehlende Werte als „kein Token nötig" durchzuwinken (403 ohne gültigen Token). Setup-Wizard-Wiederherstellungs-Pfade sind nach Setup-Abschluss gesperrt und laufen nur noch über den authentifizierten Admin-Pfad, und der Agent verweigert jetzt den Start, wenn Server-Zertifikat oder Signing-Schlüssel lokal fehlen, statt stillschweigend einen vom Server vorgeschlagenen Wert zu übernehmen — Vertrauensanker kommen ausschließlich über Tools-ISO bzw. Klon-Image. Backend und alle Admin-Werkzeuge sind jetzt nur über Loopback bzw. SSH-Tunnel erreichbar, der Changelog-Dialog ist gegen XSS gehärtet, und der curl-basierte Bootstrap-Modus ist aus den Installations-Skripten entfernt. Erfordert einen Pflicht-Rebuild von Backend-Container, Agent-Binary und Tools-ISO. *(Backend, Agent, Verwaltungsoberfläche, Deploy-Repo)*

- **Sicherheits-Audit: weitere Härtungen (Folge-Bundle)** — Weitere Härtungen aus demselben Audit (Schweregrad „hoch"): Login-/Auth-Endpunkte sind jetzt rate-begrenzt (5 Anfragen/Sekunde mit kurzem Burst-Spielraum, aktuell noch als gemeinsame LAN-weite Quote hinter dem Reverse-Proxy). Ausgeloggte Access-Tokens werden sofort gesperrt statt wie bisher bis zu 15 Minuten gültig zu bleiben. Das hartcodierte Semaphore-Admin-Standardpasswort ist entfernt — bei der ersten Umgebungs-Einrichtung wird ein sicheres Zufalls-Passwort generiert. NFS-Freigaben werden jetzt strikt per Client-IP statt subnetzweit vergeben (deny-by-default ohne bekannte Client-IPs). *(Backend, Server-Dienste)*

- **NFS-Freigaben kommen erst beim tatsächlichen Boot** — NFS-Freigaben für anstehende Aufgaben wurden bisher „prophylaktisch" über das gesamte Subnetz angelegt. Jetzt bekommt jeder Client beim Anlegen eine reservierte DHCP-IP, und bei jedem realen DHCP-Lease-Event prüft das Backend, ob für den Client eine Aufgabe (Capture, Deployment, Update) ansteht, und schaltet die passende Freigabe just-in-time nur für diese IP frei — keine Freigabe liegt mehr „auf Vorrat" offen. Beim erneuten Exportieren wird der Container zudem nicht mehr automatisch hart neugestartet (das hätte laufende Übertragungen abgebrochen); der Fehler wird stattdessen protokolliert, der Operator entscheidet manuell. *(Backend, Server-Dienste)*


## 2026-04-17

- **BitTorrent-Daten: eigenes Unterverzeichnis im Speicher** — Die BitTorrent-Hilfsdaten für Klon-Verteilungen liegen jetzt in einem eigenen Unterordner im Datenverzeichnis statt vermischt mit den PXE-Boot-Dateien. Sauberere Trennung, die Bedienung ändert sich nicht. *(Server-Dienste)*

- **VPN-Remote: Schutz gegen versehentliches Löschen des Hauptservers** — Im RemoteSync-Bereich gab es einen „Löschen"-Knopf für jeden Peer auf dem VPN-Server, einschließlich des eigenen Servers — ein Klick darauf hätte die eigene Verbindung gekappt. Der Löschen-Knopf ist beim Hauptserver durch ein Schild-Icon mit Tooltip ersetzt, und das Backend lehnt einen Löschversuch zusätzlich ab. *(Verwaltungsoberfläche, Backend)*

- **Navigation: „Automation"-Eintrag in der Seitenleiste ausgeblendet** — Der „Automation"-Eintrag in der Seitenleiste ist ausgeblendet, passend zum Automation-Tab in der Client-Ansicht, der seit längerem nicht aktiv ist. Der Code bleibt für eine spätere Reaktivierung erhalten. *(Verwaltungsoberfläche)*

- **Clients-Tab: Refresh-Knopf in der Filterzeile** — Ganz rechts in der Filterzeile der Client-Liste gibt es jetzt einen kleinen Refresh-Knopf, mit dem sich die Liste manuell aktualisieren lässt. Die automatische Hintergrund-Aktualisierung läuft unverändert weiter. *(Verwaltungsoberfläche)*

- **Cloning-Tab: Info-Hinweis zum optimierten System** — Neben der Überschrift im Cloning-Tab gibt es jetzt ein Info-Icon mit Tooltip: Das System ist für Debian/Manjaro XFCE optimiert, für produktive Systeme wird eine minimale Installation empfohlen. *(Verwaltungsoberfläche)*

- **Heartbeat-Intervall der Agents zentral einstellbar** — Wie oft sich die Agents beim Server melden, lässt sich jetzt im Agent-Tab zentral einstellen (Bereich 10–3600 Sekunden). Geräte übernehmen den neuen Wert automatisch beim nächsten Heartbeat. *(Verwaltungsoberfläche, Agent)*

- **Signaturen: „Signieren"-Knopf im Agent-Tab + Rotation umfasst Agent-Binary** — Im Agent-Tab steht neben dem Upload-Knopf jetzt ein dedizierter „Signieren"-Knopf, der gezielt nur das Agent-Binary signiert (Label/Farbe zeigen den Signaturstatus). Bei einer Rotation des Signing-Schlüssels wird das Agent-Binary jetzt automatisch mit-signiert — bisher konnte es nach einer Rotation mit veralteter Signatur liegenbleiben, wodurch das Selbst-Update des Agents stumm fehlgeschlagen wäre. Der Signatur-Status zeigt zusätzlich Anwesenheit und Versionsstand des Agent-Binarys. *(Verwaltungsoberfläche, Backend)*

- **Geräte-Hostname auf Clients: einheitliches „TF-<MAC>"-Format** — Der Agent setzt den OS-Hostnamen auf den Geräten jetzt einheitlich auf „TF-<MAC>", abgeleitet aus der physischen LAN-MAC-Adresse. Der kanonische Name liegt im Daten-Verzeichnis des Geräts, überlebt Updates und wird nach jedem Update neu gesetzt; ändert sich die Hardware-MAC (z. B. NIC-Tausch), bleibt der gespeicherte Name stabil und der Agent meldet einen „MAC geändert"-Alarm. Geräte mit dem alten „PC-<MAC>"-Namen werden automatisch beim nächsten Schema-Update umbenannt. *(Agent, Backend)*

- **VPN: TPM-versiegelte WireGuard-Schlüssel (Erstversion)** — Auf Geräten mit TPM 2.0 wird der private WireGuard-Schlüssel jetzt im TPM versiegelt — Klartext existiert nur kurzzeitig im RAM während des Tunnel-Aufbaus, was den VPN-Schlüssel deutlich besser gegen Diebstahl der Festplatte schützt. Der Agent kümmert sich selbst um Versiegelung, Aufhebung und das Nachinstallieren der TPM-Werkzeuge, gesteuert über den Heartbeat; Geräte ohne TPM laufen wie bisher unversiegelt und werden im UI mit einem Warnsymbol markiert. Bewusst ausgeschlossen in dieser ersten Ausbaustufe: PCR-Bindung und LUKS-Festplattenverschlüsselung. *(Agent, Verwaltungsoberfläche)*

- **Sicherheits-Tab: neues Vulnerability-Scan-Panel mit Live-Trigger** — Der Sicherheits-Tab bietet jetzt einen direkten Schwachstellen-Scan im UI: pro Container-Image die Anzahl der Befunde nach Schweregrad, aufklappbar mit CVE-Liste, Fix-Status und betroffenem Paket (CVE-IDs verlinken zur NVD-Datenbank). Ein „Scan starten"-Knopf löst direkt aus dem UI einen neuen Scan aus, zeigt den Fortschritt an und lädt die Tabelle nach Abschluss automatisch neu; es läuft immer nur ein Scan gleichzeitig. *(Verwaltungsoberfläche, Backend)*

- **Datenbank-Migrationen zusammengeführt** — Mehrere inkrementelle Schema-Erweiterungen der letzten Tage (Rechnungs-Felder, TPM-Statusfelder, Hostnamen-Umbenennung, neue Alarm-Kategorie) sind in die ursprüngliche Schema-Datei zusammengeführt, sodass Fresh-Installationen in einer Transaktion durchlaufen. Bestehende Datenbanken sind bereits auf dem aktuellen Stand — kein Eingriff nötig. *(Backend)*


## 2026-04-16

- **Geräte: neue Felder „Rechnungsnummer" und „Lieferant"** — Pro Gerät lassen sich jetzt optional eine Rechnungsnummer und ein Lieferant erfassen, sichtbar im Geräte-Detail und im Anlege-Formular. Der CSV-Import akzeptiert mehrere Spaltennamen, der Export hängt beide Spalten am Ende an; in der Geräte-Liste und der Garantie-Übersicht bleiben die Werte bewusst verborgen und dienen primär der Recherche im Garantiefall. *(Verwaltungsoberfläche, Backend)*

- **Gruppen: Untergruppe auf Wurzelebene zurücksetzen möglich** — Beim Bearbeiten einer Untergruppe ließ sich der Eltern-Bezug bisher nicht entfernen — sie blieb in ihrer Hierarchie hängen. Das Speichern akzeptiert jetzt explizit „kein Eltern-Eintrag", wodurch die Gruppe auf die Wurzelebene wandert; derselbe Fix gilt für das Beschreibungs-Feld. *(Verwaltungsoberfläche, Backend)*

- **Setup-Wizard: Backend und Worker werden nach Abschluss neu gestartet** — Nach dem Setup-Wizard wurde bisher nur der Reverse-Proxy neu gestartet — Backend und Worker liefen mit den noch nicht vorhandenen Schlüsseln weiter, bis der Operator manuell eingriff. Beide werden jetzt automatisch wenige Sekunden nach Wizard-Ende neu gestartet und lesen die frisch erzeugten Schlüssel und Tokens sauber ein. *(Backend, Server-Dienste)*

- **Klone-Baum: Selbst-Reparatur und klarere Baum-Darstellung** — Wurde ein Klon gelöscht, der „Eltern" eines anderen Klons war, blieb der verwaiste Verweis als kaputter Baum-Pfad hängen. Das System erkennt das jetzt automatisch und repariert den Baum, indem pro Versionslinie die kleinste Version zur Basis wird; im Klone-Tab sorgen zusätzlich klassische Baumzeichen für eine klarere Darstellung der Verzweigungen. *(Backend, Verwaltungsoberfläche)*

- **Client-Installation: Tools-ISO wird auch bei KDE-Auto-Mount gefunden** — Auf manchen Linux-Desktops (insbesondere KDE auf Debian) wird die Tools-ISO automatisch an einem Pfad eingehängt, der bisher in der Suchliste der Installations-Skripte fehlte — die Agent-Installation wurde dadurch stumm übersprungen, und das Gerät kam halb-installiert hoch. Der Pfad ist ergänzt; die Installation läuft jetzt auch auf KDE-Hosts zuverlässig durch. *(Agent)*

- **PXE-Server-IP lässt sich zur Laufzeit ändern** — Wer im Setup-Wizard zuerst eine teilweise Konfiguration mit leerer Rollout-IP speicherte und sie später nachreichte, bekam einen stehenbleibenden Cache mit leerer IP — jedes Klon-Deployment wurde danach mit kryptischer Fehlermeldung verworfen, bis das Backend neu gestartet wurde. Die IP lässt sich jetzt zur Laufzeit aktualisieren, leere Werte werden ignoriert und im Log markiert; beim Backend-Start erscheint zusätzlich eine deutliche Warnung, falls noch keine IP gesetzt ist. *(Backend)*

- **Worker-Gesundheitsprüfung wirkt jetzt tatsächlich** — Die Gesundheitsprüfung des Worker-Containers stand seit ihrer Einführung dauerhaft auf „ungesund", weil sie eine Datei prüfte, die niemand schrieb. Der Worker meldet seine Lebendigkeit jetzt durch regelmäßiges Berühren einer Marker-Datei; bleibt sie länger als eine Minute unangetastet, schaltet der Container auf „ungesund" — ein echter Liveness-Indikator statt einer Dauer-Falschmeldung. *(Server-Dienste, Backend)*


## 2026-04-14

- **ISO-Download: zuverlässiger und speichersparender** — Beim Download eines ISO-Image konnte die Adressauflösung bei Mirror-Servern mit mehreren A/AAAA-Records intern fehlschlagen und den Download abbrechen — das ist behoben. Zusätzlich wird das Image jetzt direkt während des Downloads auf die Festplatte gestreamt statt komplett im RAM zwischengespeichert, was den Server-Speicher bei mehreren GB großen Images entlastet; der Fortschrittsbalken aktualisiert sich live, und Teil-Dateien werden bei Fehlern sauber weggeräumt. *(Backend)*

- **Dashboard: bedarfsgesteuerte Container werden nicht mehr als Warnung angezeigt** — Cloning-Container, die nur bei Bedarf laufen (z. B. Cloning-VM, Cloner), wurden auf der Dashboard-Dienste-Karte als „nicht aktiv" unter den Warn-Einträgen gelistet, obwohl ihr Stopzustand der Normalfall ist. Sie sind jetzt als bedarfsgesteuert markiert: In der Dienste-Karte erscheinen sie im Normal-Stopzustand nicht mehr als Warnung, im Dienste-Panel haben sie einen neutralen grauen Rahmen mit „On-Demand"-Markierung; unerwartete Zustände wie „neustartend" werden weiterhin angezeigt. *(Verwaltungsoberfläche, Backend)*

- **Changelog-Anzeige im UI wieder funktional** — Beim Klick auf die Versionsnummer in der Kopfleiste zeigte das System „No changelog available." statt der Änderungsliste, weil die Datei nicht im Backend-Image lag. Der Changelog wird jetzt beim Build des Backend-Images mit eingepackt und ist im UI direkt sichtbar. *(Backend, Verwaltungsoberfläche, Deploy-Repo)*


## 2026-04-13

- **VPN: erste vollständige Funktion (Statistiken, Deploy, Status, Restore)** — Großer Funktions-Schub rund um VPN: neuer Tab für Traffic-Statistiken pro Client mit resilientem Sync; VPN-Deploy/-Undeploy sind durchgängig funktional (Client-Anlegen, Deploy-Knopf, automatischer Tunnel-Neustart nach Konfigurations-Push, Undeploy bei Client-Deaktivierung); detaillierte VPN-Status-Chips in der Client-Tabelle; der Tunnel wird nach einem Delta-Update jetzt zuverlässig wiederhergestellt; die VPN-Erkennung im Agent ist korrigiert (prüft das richtige Interface/die tatsächliche Route), und wiederkehrende „Statistiken noch nicht da"-Meldungen werden nicht mehr als Fehler-Toast angezeigt. Begleitet von Agent v2.5.2 und v2.5.3. *(Backend, Verwaltungsoberfläche, Agent)*

- **Netzwerk: lokales Netzwerk im UI konfigurierbar, dnsmasq pflegt eigene Domain** — Der Netzwerk-Bereich hat jetzt einen Tab „Lokales Netzwerk" zur Konfiguration der Server-Schnittstelle. Die PXE-Server-IP kommt nicht mehr aus einer Konfigurationsdatei, sondern direkt aus der Datenbank (Fallback: Gateway-IP); der Setup-Wizard pflegt zusätzlich eine lokale Domain für den internen DNS-Server, und externe Adressen werden über das Management-Gateway aufgelöst statt über eine fest hinterlegte externe Adresse. *(Verwaltungsoberfläche, Backend, Server-Dienste)*

- **Werksreset: vollständig statt selektiv** — Der Werksreset hatte bisher sieben Tabellen rund um Update-Rollouts und Rollback-Aufgaben nicht zurückgesetzt. Statt einer manuellen Liste löscht der Reset jetzt alle Tabellen dynamisch, bleibt also auch bei künftigen Schema-Erweiterungen automatisch konsistent, und leert zusätzlich Redis-Caches (Token-Sperrliste, Rate-Limiter, Sessions) sowie das komplette Storage-Verzeichnis. Der Server-Schlüssel wird beim ersten Start jetzt automatisch erzeugt und gespeichert, beim Werksreset mit gelöscht und beim nächsten Start frisch generiert; Backup/Restore stellt ihn wieder her. *(Backend)*

- **Diverse kleinere Korrekturen** — Die PXE-Konfiguration eines Geräts wird beim Löschen jetzt sauber mit aufgeräumt (blieb zuvor stehen); VM-Einstellungen werden beim Klon-Capture korrekt übernommen (der 64-GB-Default-Bug ist behoben); das Setup-Skript für Server-Voraussetzungen läuft ohne doppelte Variablen-Definitionen und setzt die Zeitzone auf Berlin; die Zeitzonen-Einstellung ist aus dem UI entfernt, da sie ohnehin nicht auf das Host-System wirkte; die Logs-Ansicht zeigt drei zuvor fehlende Container (Semaphore, Cloning-VM, Cloner); interne Daten-Migrationen sind zur Übersichtlichkeit zusammengeführt. *(Backend, Verwaltungsoberfläche)*


## 2026-04-12

- **Backup-System: Validieren und Wiederherstellen funktional** — Backup-Archive können jetzt vor dem Restore validiert und vollständig wiederhergestellt werden. Das Archiv-Format umfasst Manifest, alle Konfigurationsverzeichnisse (SSH, VPN, dnsmasq, NFS, Chrony, Reverse-Proxy, Signaturen), den Verschlüsselungs-Schlüssel sowie optional Images, Klone und Captures; der Datenbank-Restore läuft über das Standard-Werkzeug, die zugehörigen Pfade sind auch im Setup-Wizard aktiv. *(Backend, Verwaltungsoberfläche)*

- **Wartungsfenster vollständig im neuen Backend** — Die 5 API-Endpunkte zur Verwaltung von Wartungsfenstern sind portiert — damit laufen jetzt alle 41 API-Endpunkte vollständig im neuen Backend. Die separate ältere Kompose-Datei für das alte Backend entfällt; der Standard-Start-Befehl startet direkt das aktuelle Backend. *(Backend, Deploy-Repo)*

- **Klone werden nach Software-Deinstallation tatsächlich kleiner** — Nach dem Entfernen von Software in einem Klon-Snapshot blieben Klone gleich groß, weil die intern freigegebenen Datenblöcke beim Klon-Vorgang noch nicht final als „frei" registriert waren und weiterhin als belegt gezählt wurden. Der Synchronisationsschritt wartet jetzt explizit ab — Klone werden nach Deinstallation auch tatsächlich kleiner. *(Backend, Server-Dienste)*

- **Sicherheit: Signatur-Prüfung lehnt Updates ohne Schlüssel ab** — Fehlte auf einem Gerät der lokale Signatur-Prüfschlüssel, akzeptierte der Agent Updates bisher stillschweigend — jetzt lehnt er sie ab, da ein fehlender Schlüssel ein Fehler ist und kein „durchwinken" sein darf. Zusätzlich stürzt das Backend nicht mehr ab, wenn ein Schlüssel-Pfad fehlerhaft ist, sondern liefert einen sauberen Fehler zurück. *(Agent, Backend)*

- **Stabilität: kein Server-Crash mehr bei internen Sperr-Konflikten** — Eine interne Klasse von Sperr-Mechanismen konnte bei einem Fehler den Server in einen nicht-wiederherstellbaren Zustand bringen. Diese Sperren sind durch eine robustere Variante ersetzt, sodass der Server entsprechende Fehlerpfade jetzt ohne Absturz übersteht; zusätzlich wurde ein langsamer Pfad in der Rollback-Verwaltung von tausenden Datenbank-Abfragen auf eine einzige reduziert. *(Backend)*

- **Interne Verbesserungen** — Globaler Timeout für API-Anfragen (30 Sekunden, mit Ausnahmen für bewusst lange Operationen wie Backup oder Klon-Erstellung); Log-Rotation für Backend- und Worker-Container (50 MB pro Datei, 3 Dateien rollierend); die Größe des Datenbank-Verbindungspools ist über Umgebungsvariablen konfigurierbar; ein automatischer Aufräum-Schritt entfernt nach jedem Re-Build den Docker-Build-Cache; Frontend-Fehler, die bereits vom globalen Fehler-Mechanismus angezeigt werden, sind jetzt einheitlich und nachvollziehbar dokumentiert. *(Backend, Verwaltungsoberfläche, Deploy-Repo)*


## 2026-04-11

- **NFS-Freigaben: Capture-Vorgänge funktionieren wieder, Aufräumen läuft korrekt** — Beim Start eines Klon-Aufnahme-Vorgangs (Capture) blieb die NFS-Freigabe für die Captures aus — Clonezilla meldete „Access denied NFS" und brach ab. Die Freigabe wird jetzt automatisch beim Capture-Start aktiviert und nach Abschluss des Rollouts wieder weggeräumt, der Freigabe-Status überlebt Container-Neustarts; zusätzlich wird der zugehörige Capture-Job korrekt in der Datenbank angelegt, sodass der Fortschritt im UI verfolgbar ist. *(Backend, Server-Dienste)*

- **DNS-Vorschau im UI um die Hosts-Datei erweitert** — Das DNS-Panel zeigt in der Vorschau jetzt neben der Hauptkonfiguration auch die Datei mit den benutzerdefinierten DNS-Einträgen an. Zusätzlich lädt die DHCP-Konfigurations-Vorschau jetzt sofort beim ersten Klick statt leer zu bleiben. *(Verwaltungsoberfläche, Backend)*

- **Sicherheit: Eingaben in Shell-Aufrufe gehärtet, ISO-Downloads gegen SSRF geschützt** — Werte, die intern in Shell-Aufrufe oder PXE-Skripte fließen, werden jetzt streng validiert (zulässige Zeichen, maximale Länge) — manipulierte Eingaben können keine fremden Befehle mehr einschleusen; Versions-Strings werden bereits beim API-Eintritt geprüft. Der Agent verwendet bei Self-Update und Skript-Download nicht mehr „TLS-Prüfung überspringen" als Notlösung, sondern besteht auf dem gepinnten Server-Zertifikat, und der ISO-Download im Backend ist jetzt gegen SSRF-Angriffe geschützt (DNS wird vorab aufgelöst, private Adressen geblockt, Umleitungen auf interne Hosts abgelehnt). *(Backend, Agent)*

- **Agent-Verwaltung: „Re-Installieren"-Knopf** — Im Agent-Tab gibt es einen neuen „Re-Installieren"-Knopf mit Auswahl-Dialog (alle / Gruppe / einzelne Geräte). Der Re-Install überspringt den Offline-Filter und schickt die Aufgabe sofort an die ausgewählten Geräte, ohne auf den nächsten Heartbeat zu warten; derselbe Dialog kommt auch für reguläre Updates zum Einsatz. *(Verwaltungsoberfläche, Backend)*

- **Agent-Binary: korrekte Version wird ausgeliefert** — Der Endpunkt, über den Geräte ihr Agent-Binary nachladen, lieferte fälschlich eine alte Version aus dem Tools-ISO-Verzeichnis statt der aktuellen aus dem Build-Verzeichnis aus — die Folge war eine Endlos-Update-Schleife. Das aktuelle Build-Verzeichnis wird jetzt zuerst durchsucht; zusätzlich wird eine unbekannte Geräte-IP jetzt aus der DHCP-Lease-Datei abgeleitet, bevor auf den Hostnamen zurückgegriffen wird. *(Backend, Agent)*

- **DNS / Docker-Container: Service-Auflösung repariert** — In der internen DNS-Konfiguration wurde ein falsches Feld gelesen, sodass IPv6-Anfragen für lokale Hostnamen an externe Server weitergeleitet statt direkt mit „keine Daten" beantwortet wurden — der Agent hing dadurch in Timeouts; das ist behoben. Außerdem hatten Backend und Worker eine eigene DNS-Direktive, die Dockers internen DNS umging, sodass sich interne Service-Namen nicht mehr auflösen ließen und der Reverse-Proxy auf die externe IP zurückfiel und scheiterte — die Direktive ist entfernt, die interne Auflösung funktioniert wieder. *(Backend, Server-Dienste, Agent)*

- **Client-Migration: Avahi blockiert keine DNS-Anfragen mehr** — Der DNS-Resolver der Clients hatte Avahi (mDNS) in einer Reihenfolge eingehängt, die DNS-Anfragen blockierte. Ein Migrationsschritt im Agent stellt die Reihenfolge jetzt so um, dass DNS Vorrang hat. *(Agent)*

- **BitTorrent-Deployment: korrekte Partitions-Anzahl im UI** — Beim BitTorrent-Deployment zeigte das UI die Partitions-Anzahl als 0, obwohl der Seeder bereits mehrere Torrents bereithielt. Der Wert wird jetzt korrekt vom Seeder mit-übermittelt und im UI angezeigt. *(Verwaltungsoberfläche, Server-Dienste)*

- **Cloning-VM: keine Race-Condition mehr zwischen Klon-Aufnahme und Update-Speichern** — Wurde ein Update gespeichert oder wurden Deltas zusammengeführt, während die Cloning-VM noch lief, kam es zu kryptischen Festplatten-Fehlern. Der Backend-Service prüft jetzt explizit, ob die VM noch läuft, und meldet dann eine klare Fehlermeldung statt eines verwirrenden internen Fehlers. *(Backend, Server-Dienste)*

- **Setup-Wizard: Defaults, automatische DNS-/NTP-Befüllung, sichtbarer Countdown** — Der Setup-Wizard ist deutlich benutzungsfreundlicher: Admin-Konto und Domain sind sinnvoll vorbelegt (Passwort bleibt leer); Upstream-DNS und DHCP-DNS-Server werden erst nach Auswahl des Netzwerk-Interfaces aus den erkannten Standards befüllt statt mit hartkodierten externen Adressen; Upstream-NTP-Server und DHCP-Domain werden automatisch aus vorigen Schritten übernommen. Auf schmalen Bildschirmen ist das Layout aufgeräumter, und nach Setup-Abschluss läuft ein sichtbarer 10-Sekunden-Countdown mit Fortschritts-Ring, bevor auf HTTPS gewechselt wird — das gibt dem Reverse-Proxy Zeit, das frische Zertifikat zu laden. *(Verwaltungsoberfläche, Backend)*

- **Diverse kleine Korrekturen** — Ein Datenbank-Fehler in der Client-Liste einer Gruppe ist behoben (nutzt jetzt denselben sauberen Abfrage-Helfer wie der Haupt-Tab); der Agent-Tab öffnet sich wieder direkt per URL-Parameter; das Löschen eines Klons wird nicht mehr durch eine laufende VM blockiert (die Warnung ist jetzt nur noch informativ, ohne extra Bestätigungs-Checkbox); und beim Agent-Build läuft der Signatur-Schritt jetzt sauber durch (ein Berechtigungs-Problem auf dem Build-Verzeichnis ist behoben). *(Backend, Verwaltungsoberfläche, Deploy-Repo)*


## 2026-04-10

- **Rollback-Funktion: vollständiger Abgleich mit dem bisherigen Backend** — Die Rollback-Funktion ist jetzt vollständig auf dem aktuellen Backend implementiert, mit mehreren Folgefehlern behoben: Die UI-Route entsprach nicht dem Backend, sodass der Rollback-Tab nicht lud; verschiedene Status-Werte hatten Format-Probleme in der Datenbank; eine Race-Condition beim Heartbeat führte dazu, dass Versionswechsel nicht erkannt wurden. Rollback-Aufgaben werden jetzt automatisch als „abgeschlossen" markiert, sobald alle betroffenen Geräte fertig sind, und bei gelöschten Geräten zeigt die Liste sauber „?" statt leerer Felder. *(Backend, Verwaltungsoberfläche)*

- **Rollback: erkennt verfügbare Snapshots auf den Geräten** — Beim Rollback wird beim Boot jetzt ein beschreibbarer Schnappschuss des Home-Verzeichnisses der gewünschten Version erstellt, statt fest ein generisches Home zu mounten, das auf der falschen Version lag. Der Agent meldet im Heartbeat die auf dem Gerät verfügbaren Snapshots; im Rollback-Dialog kann jetzt aus diesen statt nur aus der installierten Version gewählt werden, und verwaiste temporäre Snapshots werden beim Update-Anwenden mit aufgeräumt. *(Agent, Backend, Verwaltungsoberfläche)*

- **Neuer Agent-Management-Tab** — Der Geräte-Bereich hat einen neuen Tab „Agent": ein Upload-Knopf für ein neues Agent-Binary (wird automatisch signiert, Versionsnummer wird ausgelesen), eine Update-Aufgabe an alle Geräte mit veralteter Version (Einspielung per SSH beim nächsten Heartbeat: stoppen, ersetzen, starten), eine Status-Anzeige mit aggregiertem Fortschritt und Pro-Gerät-Status sowie ein neuer „Agent"-Eintrag in der Seitenleiste. *(Verwaltungsoberfläche, Backend)*

- **Klon und Delta werden korrekt miteinander verknüpft** — Wenn beim Speichern eines Updates auch ein Klon erzeugt wurde, wurde die Verknüpfung zwischen Klon und Delta in der Datenbank bisher nicht gesetzt. Jetzt ist die Verknüpfung sauber, und die Lösch-Analyse für einen Klon ist vollständig implementiert: Sie zeigt eingehende/ausgehende Deltas, Geräte auf dieser Version, aktive Rollouts und VM-Status; das Löschen respektiert das Löschen-Deltas-Flag, blockt bei aktiven Rollouts und kann bei Bedarf einen Geräte-Rollback auslösen. *(Backend, Verwaltungsoberfläche)*

- **BitTorrent-Deployment: Seeder-Schlüssel wird erzeugt** — Beim Anlegen eines BitTorrent-Deployments wurde der interne Schlüssel für den Seeder-Container nicht erzeugt, wodurch der Container sofort abstürzte. Der Schlüssel wird jetzt zuverlässig generiert — das Anlegen läuft sauber durch. *(Backend, Server-Dienste)*


## 2026-04-09

- **Update-Roll-outs starten wieder zuverlässig** — Beim Anlegen eines neuen Update-Rollouts stürzte das Backend mit einem internen Typ-Fehler ab, sodass sich Rollouts nicht starten ließen. Die internen Status-Felder nutzen jetzt eine typsichere Darstellung, der Fehler ist behoben; zusätzlich wird ein Gerät, dessen Signatur-Prüfung scheitert, jetzt als Endzustand „Signatur fehlgeschlagen" gezählt — vorher hingen Rollouts in solchen Fällen dauerhaft im Zustand „aktiv". *(Backend)*

- **Schlüssel und Tokens liegen jetzt im Datenverzeichnis (nicht mehr im Repository)** — Mehrere Laufzeit-Schlüssel und Tokens (SSH-Schlüsselpaar, Heartbeat-Token, Signatur-Pubkey) sind aus dem Repository entfernt und werden ausschließlich im Datenverzeichnis verwaltet. Beim Start des Backends wird die Schlüssel-Existenz geprüft und fehlende sofort angelegt, sodass der erste Heartbeat auf einem frischen System sofort einen gültigen Token vorfindet. Ist nur eine Hälfte eines Schlüsselpaars vorhanden (z. B. nach einer Teil-Wiederherstellung), bricht der Start jetzt mit klarer Fehlermeldung ab, statt stillschweigend einen neuen Schlüssel zu erzeugen und die bereits auf den Geräten provisionierte Hälfte zu überschreiben; ein zuvor bestehender Pfad-Mismatch beim Heartbeat-Token ist ebenfalls behoben, Heartbeats werden wieder akzeptiert. *(Backend)*

- **Setup-Wizard erzeugt das Signatur-Schlüsselpaar automatisch** — Der Setup-Wizard erzeugt am Ende jetzt automatisch das Schlüsselpaar für die Update-Signatur und kopiert den öffentlichen Teil in die nächste Tools-ISO-Erzeugung. Voraussetzung: Das nötige Signier-Werkzeug ist jetzt fest im Backend-Image enthalten — vorher schlug das Signieren still fehl, weil das Programm fehlte. *(Backend, Deploy-Repo)*

- **TLS-Zertifikat: rotierbar im laufenden Betrieb** — Neuer Mechanismus für das Server-TLS-Zertifikat: Der Signatur-Schlüssel der Tools-ISO ist die Vertrauens-Wurzel, das TLS-Zertifikat ist daraus delegiert und kann jederzeit rotiert werden. Agents merken sich den Hash des aktuellen Zertifikats und schicken ihn im Heartbeat mit; erkennt der Server ein veraltetes Zertifikat, schickt er das neue signiert mit, der Agent prüft die Signatur und tauscht das Zertifikat atomar aus. Auf einem frisch installierten Gerät bzw. wenn der gepinnte Anker veraltet ist, läuft ein einmaliger Recovery-Pfad, bei dem die Signatur trotzdem verifiziert wird — ein Man-in-the-Middle kann kein gefälschtes Zertifikat einschleusen. *(Agent, Backend)*

- **Cloning: Fortschritts-Anzeige beim Restore + persistente VM-Einstellungen** — Beim Restore eines Klons sprang die Fortschrittsanzeige bisher von 0 % direkt auf 100 %; es gibt jetzt eine laufende Aktualisierung während des Restore-Vorgangs. Zusätzlich werden RAM, CPU-Anzahl, Festplatten-Größe und Virtualisierungs-Beschleunigung der Cloning-VM nach einem erfolgreichen Start jetzt dauerhaft mit dem Klon gespeichert — bisher gingen die Werte bei jedem Backend-Neustart oder Container-Neuaufbau verloren, jetzt überleben sie und greifen automatisch beim nächsten Restore. *(Backend, Verwaltungsoberfläche)*

- **Rust-Migration: Delta-Rollout-Bugfix + Tech-Debt-Refactor** — Interner Nachzieh-Fix zur Rust-Migration: Die Update-Status-Felder nutzen jetzt durchgehend typsichere Aufzählungstypen statt eines Text-Cast-Workarounds, der beim Anlegen eines Rollouts zu einem Absturz führte. Außerdem zählt ein Client, dessen Signaturprüfung fehlschlägt, jetzt korrekt als Endzustand — vorher wurde diese Variante bei der Rollout-Abschlussprüfung ignoriert, wodurch betroffene Rollouts nie als abgeschlossen erkannt wurden und dauerhaft auf „aktiv" hängen blieben. Das Wire-Format bleibt unverändert. *(Backend)*

- **Runtime-Secrets: komplette Umstellung ins Datenverzeichnis** — Interner Nachzieh-Fix: Laufzeit-Geheimnisse (SSH-Schlüsselpaar, Heartbeat-Token, Signatur-Pubkey) sind vollständig aus dem Repository entfernt und liegen kanonisch im Datenverzeichnis. Ihre Erzeugung läuft jetzt direkt beim Backend-Start statt erst bei Bedarf, sodass der erste Client-Heartbeat auf einem frischen System sofort einen gültigen Token vorfindet; existiert nur eine Hälfte eines Schlüsselpaars, wird das jetzt als Fehler behandelt statt stillschweigend neu zu generieren und dabei bereits provisionierte Geräte-Schlüssel zu überschreiben. Ein Pfad-Mismatch beim Heartbeat-Token, der jede Heartbeat-Anfrage mit 403 abgelehnt hatte, ist behoben. *(Backend)*

- **Setup-Wizard: automatische Minisign-Generation** — Interner Nachzieh-Fix: Der Setup-Wizard erzeugt das Signing-Schlüsselpaar jetzt beim Abschluss des Setups automatisch, und der Tools-ISO-Rebuild beim Start der Cloning-VM kopiert den frischen öffentlichen Schlüssel automatisch mit hinein, sodass Clients ihn beim ersten Boot per Trust-on-first-use erhalten. Das nötige Signier-Werkzeug ist jetzt fest in der Backend-Laufzeitumgebung enthalten — vorher schlug die Schlüssel-Erzeugung mit einem „Datei nicht gefunden"-Fehler fehl, und die Delta-Signierung war komplett funktionsunfähig. *(Backend, Deploy-Repo)*

- **Zertifikats-Rotation (neu)** — Neue Vertrauenskette für das Server-Zertifikat: Der Minisign-Schlüssel der Tools-ISO ist die Vertrauens-Wurzel, das TLS-Zertifikat ist davon abgeleitet und rotierbar. Clients pinnen das Zertifikat und schicken dessen Prüfsumme in jedem Heartbeat mit; weicht es vom Server-Zertifikat ab, liefert das Backend das neue Zertifikat signiert mit, der Agent verifiziert die Signatur und tauscht es atomar aus. Beim ersten Heartbeat nach einer Neuinstallation oder wenn der gepinnte Anker veraltet ist, greift ein Fallback, der die Signatur-Prüfung dennoch durchsetzt — ein Man-in-the-Middle kann in dieser Lücke kein ungültiges Zertifikat einschleusen. *(Agent, Backend)*

- **Cloning: Restore-Fortschritt + persistente VM-Einstellungen** — Interner Nachzieh-Fix: Ein Hintergrund-Task liest beim Klon-Restore alle zwei Sekunden den Fortschritt aus und aktualisiert die Anzeige, statt dass die UI-Leiste erst beim Ende des Vorgangs direkt von 0 % auf 100 % springt. Zusätzlich werden RAM, CPU-Anzahl, Festplatten-Größe und die KVM-Beschleunigung nach einem erfolgreichen VM-Start dauerhaft mit dem Klon gespeichert statt nur im flüchtigen Arbeitsspeicher gehalten zu werden — die Werte überleben damit Backend-Neustarts und Container-Neuaufbauten und werden beim nächsten Restore automatisch wieder angewendet. *(Backend, Verwaltungsoberfläche)*
## 2026-04-07

- **Persönliche Einstellungen aus dem Admin-Bereich verschoben** — Passwort ändern und Zwei-Faktor-Authentifizierung (TOTP) sind aus dem Admin-Sicherheits-Tab in eine eigene Profil-Ansicht gewandert, erreichbar über das Account-Menü oben rechts. Damit haben alle Rollen ihre persönlichen Einstellungen an einer Stelle, nicht nur Admins. Der Sicherheits-Tab zeigt jetzt nur noch System-Themen wie TLS, Remote Desktop und Update-Signatur. *(Verwaltungsoberfläche)*

- **Passwort-Reset per E-Mail und Admin-Reset** — Die Login-Seite bietet jetzt „Passwort vergessen?" und verschickt einen 15 Minuten gültigen Reset-Link per E-Mail, sofern SMTP-Versand konfiguriert ist. Der Link ist an den aktuellen Passwort-Hash gekoppelt und dadurch automatisch ein Einmal-Link. Zusätzlich können Admins in der Benutzerverwaltung Passwörter von Operator- und Viewer-Konten zurücksetzen und die Zwei-Faktor-Authentifizierung einzelner Benutzer deaktivieren. *(Backend, Verwaltungsoberfläche)*

- **Cloning: Hänger beim „Update-Delta speichern" behoben** — Der Workflow „Update-Delta speichern & Klon erstellen" konnte das Backend durch eine interne Sperre dauerhaft blockieren (Deadlock). Der Deadlock ist behoben, der Aufruf läuft jetzt zuverlässig durch. *(Backend)*

- **Remote-Desktop: Wechsel des Video-Codecs auf VP8 (lizenzfrei)** — Remote Desktop überträgt jetzt über den lizenzfreien Video-Codec VP8 im WebM-Container, mit auf Echtzeit und niedrige Latenz optimierten Einstellungen. Der Browser wählt automatisch das passende WebM-Format. *(Backend, Server-Dienste)*

- **noVNC läuft über den Reverse-Proxy** — Der Zugriff auf die Cloning-VM-Konsole über noVNC lief bisher über einen separaten, vom Reverse-Proxy nicht abgedeckten Port. Der gesamte noVNC-Verkehr läuft jetzt über den regulären HTTPS-Pfad des Reverse-Proxy — saubere TLS-Terminierung, kein zusätzlicher Port mehr nötig. *(Server-Dienste, Deploy-Repo)*

- **Verwaltete Agent-Skripte: einheitliche Namensgebung nach Kategorie** — Alle vom Agent verwalteten Hilfs-Skripte werden jetzt nach Kategorie unterschieden: operative Skripte, Skripte, die bei jeder Inhalts-Änderung automatisch auf dem Client ausgeführt werden, und Skripte, die nur zum Download bereitstehen, aber nicht automatisch laufen. Dadurch werden künftige Skript-Updates (z. B. der VP8-Codec-Wechsel) automatisch auf bestehenden Clients eingespielt. *(Agent, Deploy-Repo)*

- **UI-Anpassungen** — Der „Wartungsfenster"-Tab ist vorübergehend ausgeblendet (noch nicht produktionsreif). Es gibt einen neuen Sidebar-Eintrag „Rollback" im Cloning-Bereich, und die Einrückung der Sidebar-Unterpunkte wurde für bessere Lesbarkeit angepasst. *(Verwaltungsoberfläche)*

- **Gerätedaten-Import per CSV: Gruppenzuordnung wird übernommen** — Die exportierte `clients.csv` enthielt die Gruppenspalte bereits; beim Re-Import wird sie jetzt ausgewertet und erkennt gängige Bezeichnungen wie gruppe, group oder groups. Referenziert die CSV Gruppen, die im System nicht existieren, fragt ein Dialog, ob diese automatisch angelegt werden sollen — bei Zustimmung sind die Geräte direkt zugewiesen. *(Backend, Verwaltungsoberfläche)*


## 2026-04-06

- **Geräte bleiben während eines Rollbacks bedienbar (Overlay-Boot)** — Während eines Rollbacks bootet das System auf den Geräten jetzt mit einem temporären Schreib-Overlay, sodass der Nutzer weiterarbeiten kann, während der Rollback im Hintergrund das Wurzel-Subvolume tatsächlich auf den gewünschten Snapshot zurücksetzt. Funktioniert auf Manjaro und Debian; der Agent meldet den Boot-Modus („overlay" oder „normal") per Heartbeat. Das Home-Verzeichnis bleibt im Overlay-Boot beschreibbar eingebunden, damit der Login nicht an fehlenden Schreibrechten scheitert. *(Agent)*

- **Installations-Skripte: Image-Rebuild läuft erst am Ende** — Die Installations-Skripte für Cloning-VMs bauen die initrd-Datei jetzt erst am Ende, nach allen Paket-Updates und Aufräumarbeiten — damit sind alle Kernel-Updates korrekt enthalten. *(Deploy-Repo)*

- **Cloning: keine NBD-Kollision mehr zwischen parallelen Operationen** — Mehrere Cloning-Operationen (Zusammenführen von Deltas, Update speichern) nutzten intern dasselbe Block-Device ohne gegenseitige Sperre, was bei gleichzeitiger Klon-Erstellung zu undefinierten Festplatten-Fehlern führen konnte. Die Operationen sind jetzt sauber serialisiert; läuft bereits eine Klon-Operation, wird eine zweite mit klarer Meldung sofort abgebrochen. *(Backend)*

- **VPN: Tunnel wird nach einem Delta-Update wieder hergestellt** — Ein Delta-Update ersetzt den Wurzel-Snapshot und damit alle VPN-Spuren dort (Symlinks, systemd-Override, NetworkManager-Konfiguration, DNS-Eintrag) — die Konfiguration im Daten-Verzeichnis überlebte zwar, der Tunnel kam aber nicht wieder hoch. Der VPN-Deploy liefert jetzt ein idempotentes Wiederherstellungs-Skript mit; der Agent erkennt beim Start eine vorhandene, aber inaktive VPN-Konfiguration und stellt den Tunnel automatisch wieder her. *(Backend, Agent)*

- **Setup-Wizard: Reverse-Proxy-Neustart läuft im Hintergrund** — Der Reverse-Proxy wurde bisher noch während der laufenden Setup-Anfrage neugestartet, was die HTTPS-Verbindung kappte, bevor das Login-Token den Browser erreichte. Der Neustart läuft jetzt im Hintergrund nach Antwort und Datenbank-Commit; der Browser überbrückt den kurzen Ausfall. *(Backend, Server-Dienste)*


## 2026-04-05

- **Cloning-VM: bleibt nach „Update speichern" weiterhin lauffähig** — Nach „Update-Delta speichern & Klon erstellen" wurde die VM-Festplatte bisher zurückgesetzt, sodass vor dem nächsten Update manuell ein Klon zurückgespielt werden musste. Die VM bleibt jetzt mit dem frisch erzeugten Klon-Stand aktiv, das nächste Update kann direkt darauf aufbauen. *(Backend)*

- **VM-Einstellungen überleben Container-Neustarts** — Die Konfiguration der Cloning-VM (RAM, CPUs, Festplatten-Größe, Virtualisierungs-Beschleunigung) ging bisher bei jedem Backend-Neustart oder Container-Rebuild verloren. Die Werte werden jetzt zusammen mit dem aktiven Klon dauerhaft gespeichert und beim nächsten Start wieder eingelesen. *(Backend)*

- **Tools-ISO: wird beim VM-Start automatisch neu gebaut** — Beim Klick auf „VM starten" wird die Tools-ISO jetzt automatisch frisch erstellt und enthält damit immer die neuesten Skripte, den aktuellen Heartbeat-Token, den Signatur-Schlüssel, das TLS-Zertifikat und die Server-URL. Ein manueller Re-Build ist nicht mehr nötig. *(Backend, Deploy-Repo)*

- **Installations-Skripte: Daten-Partitionsgröße interaktiv** — Die Installations-Skripte für Cloning-VMs fragen jetzt die gewünschte Größe der dauerhaften Daten-Partition ab — Eingabe in GB (z. B. 5, 10G) oder Prozent der Festplatte (z. B. 10%), Standard 5 GB. *(Deploy-Repo)*

- **Update-Deltas: schneller komprimiert, gleiche Größe** — Die Delta-Kompressionsstufe wurde von 9 auf 3 reduziert, da die Datenblöcke bereits vorkomprimiert sind und eine höhere Stufe kaum Größenvorteil bringt, aber spürbar CPU-Zeit kostet. Ergebnis: schnellere Updates bei fast gleicher Dateigröße. *(Backend)*

- **UI: Knöpfe während Klon-Operation deaktiviert** — „VM zurücksetzen" und „Update-Delta speichern" sind während einer laufenden Klon-Operation jetzt deaktiviert, um versehentliches Auslösen mitten im Vorgang zu verhindern. *(Verwaltungsoberfläche)*


## 2026-04-04

- **Ansible-Automatisierung mit Semaphore integriert** — ThinForge bringt jetzt einen integrierten Ansible-Runner („Semaphore") mit, über den sich wiederkehrende Konfigurations-Aufgaben automatisiert auf verwaltete Geräte ausrollen lassen. Beim Setup wird Semaphore automatisch konfiguriert (Admin-Konto, API-Token, Projekt, Provisionierungs-Schlüssel); Schlüssel-Rotationen und Admin-Passwort-Änderungen werden automatisch übernommen, und alle Geräte werden gruppiert nach ThinForge-Gruppen als dynamisches Inventar synchronisiert (stündlich, auch manuell auslösbar). Erreichbar über den Server auf Port 8443. *(Backend, Server-Dienste, Deploy-Repo)*

- **Neuer Tab „Automation": Playbook-Pakete verwalten** — Im Geräte-Bereich gibt es jetzt neben „Liste" und „Garantie" einen Tab „Automation", über den sich Ansible-Playbook-Pakete als ZIP-Archiv mit Beschreibungsdatei hochladen, exportieren und entfernen lassen; beim Upload entsteht automatisch eine passende Semaphore-Vorlage zum Ausführen. Ein erstes Paket (XFCE-Desktop-Konfiguration) ist bereits enthalten. *(Backend, Verwaltungsoberfläche)*

- **Teil-Backup nur für Schlüssel** — Ein neuer Knopf „Schlüssel exportieren" in den Backup-Einstellungen liefert SSH-Schlüssel, Signatur-Schlüssel, Heartbeat-Token und TLS-Zertifikat als ZIP; im Setup-Wizard lassen sich Schlüssel entsprechend direkt aus einem solchen ZIP importieren, fehlende Dateien werden automatisch generiert. Der separate Setup-Wizard-Schritt „Signatur-Schlüssel" entfällt dadurch — der Schlüssel wird automatisch erzeugt oder aus dem Teil-Backup übernommen. *(Backend, Verwaltungsoberfläche)*

- **Diverse Korrekturen rund um Semaphore** — Der Reverse-Proxy leert seinen Zertifikat-Cache jetzt beim Neuladen (verhindert veraltete Zertifikate nach Container-Neustart), die Erst-Konfiguration ist nach einem Teilfehler wiederholbar, und der Passwort-Sync zu Semaphore feuert nur noch beim Admin-Account. *(Backend, Server-Dienste)*


## 2026-04-03

- **Update mit Nutzer-Benachrichtigung und automatischem Reboot** — Beim Erstellen einer Update-Zuweisung gibt es jetzt den Schalter „Nutzer benachrichtigen": Ist er aktiv, zeigt der Agent dem angemeldeten Nutzer nach Bereitstellung einen 15-Minuten-Countdown-Dialog mit „Jetzt neustarten" und „Abbrechen" — ohne Reaktion erfolgt der Neustart automatisch, bei Abbruch wird das Update beim nächsten regulären Herunterfahren angewendet. Ist kein Nutzer angemeldet, wird sofort ohne Dialog neugestartet. *(Backend, Agent)*

- **Debian-Unterstützung für Cloning-VMs** — Eine neue Installations-Routine erlaubt jetzt auch Debian-basierte Cloning-VMs analog zur bestehenden Manjaro-Variante, zweistufig aus Vorbereitung (Festplatten-Aufteilung, Calamares) und Abschluss (Boot-Loader, Agent, Zeit-Sync, SSH, Pakete). Agent und Hilfs-Skripte erkennen dabei automatisch, welchen Namen das Wurzel-Subvolume auf Manjaro/Arch bzw. Debian trägt, inklusive Schutz vor versehentlichem Löschen für beide Varianten. *(Agent, Deploy-Repo)*

- **Boot-Loader: Debian-kompatibler Aufruf** — Beim Anwenden von Updates und im Agent wird jetzt zuerst der Debian-übliche Boot-Loader-Befehl probiert und nur bei Bedarf auf den Arch/Manjaro-Befehl zurückgegriffen — kein manueller Eingriff mehr je nach Distribution nötig. *(Agent)*

- **Zeit-Synchronisation: Chrony als Standard auf den Clients** — Beide Installations-Routinen (Manjaro und Debian) installieren jetzt Chrony als Zeit-Synchronisations-Dienst und richten den ThinForge-Server als Zeit-Quelle ein — das verhindert TLS-Fehler durch verstellte Uhren auf den Geräten. *(Deploy-Repo)*

- **SSH-Absicherung läuft erst nach Agent-Installation** — SSH wurde bisher schon vor der Agent-Installation gehärtet (Passwort-Login deaktiviert); brach die Installation zwischen Härtung und Schlüssel-Übertragung ab, war das Gerät danach nicht mehr erreichbar. Die Härtung läuft jetzt erst nach erfolgreicher Schlüssel-Installation, auf Debian wird der SSH-Server bei Bedarf automatisch nachinstalliert. *(Deploy-Repo)*

- **NFS-Server: Endlos-Neustart behoben** — Der NFS-Server-Container lief in einer Neustart-Schleife, weil ein veralteter Aufruf-Parameter („NFSv2 deaktivieren") von der neueren Server-Version nicht mehr unterstützt wird. Der Parameter wurde entfernt, der Container läuft jetzt stabil. *(Server-Dienste)*

- **Anleitungen zweisprachig (Deutsch + Englisch) auf der Tools-ISO** — Die Tools-ISO und die Dokumentations-Sammlung enthalten jetzt vollständige Installations-Anleitungen für Debian und Manjaro in Deutsch und Englisch; frühere Manjaro-spezifische Texte wurden allgemein formuliert, damit sie für beide Distributionen passen. *(Deploy-Repo)*


## 2026-04-02

- **Sicherheit: Container-Images aufgeräumt** — Mehrere Container-Images laufen jetzt auf neueren, schlankeren Basen: Der NFS-Server ist komplett durch ein eigenes, schlankes Alpine-Image ersetzt (vorher ein veraltetes Drittanbieter-Image mit 13 kritischen und 72 hohen Schwachstellen), Chrony und WireGuard laufen jetzt ebenfalls auf Alpine, das Cloner-Image ist mehrstufig gebaut ohne Build-Werkzeuge im Endergebnis, und noVNC auf der Cloning-VM läuft als statische Dateien ohne zusätzliche Node.js-Abhängigkeit. Versionen externer Images (Postgres, Redis, Caddy, Prometheus, Grafana) sind eingefroren, dazu gibt es eine dokumentierte Akzeptanzliste für verbleibende, nicht behebbare Schwachstellen sowie einen wöchentlichen automatischen Scan bei jedem Image-Build. *(Server-Dienste, Deploy-Repo)*

- **Zeit-Einstellungen: zentral konfigurierbar und an Clients verteilt** — Unter Einstellungen → Allgemein lassen sich jetzt Upstream-NTP-Server und globale Zeitzone konfigurieren; die Zeitzone wird per Heartbeat an alle verwalteten Geräte ausgespielt und dort vom Agent gesetzt. Funktioniert auf Manjaro/Arch und Debian/Ubuntu. *(Backend, Verwaltungsoberfläche, Agent)*

- **Update-Zuweisung: Geräte mit aktueller Version werden automatisch ausgeschlossen** — Beim Anlegen einer Update-Zuweisung werden Geräte mit bereits aktueller oder neuerer Version automatisch übersprungen; die Status-Tabelle zeigt bestätigte und höher-versionierte Geräte nicht mehr an und konzentriert sich auf das tatsächlich Ausstehende. *(Backend, Verwaltungsoberfläche)*

- **Klone importieren: vor einen bestehenden Klon einordnen** — Importierte Klone lassen sich jetzt vor einen bereits vorhandenen Klon in der Versions-Kette einordnen; die Original-Version wird aus dem Klon-Namen erkannt und gegen die Ziel-Position validiert, um falsche Reihenfolgen zu verhindern. Im Zuordnungs-Dialog erscheinen dafür gruppierte „Vor Klon einordnen"-Optionen für nicht-zugeordnete Klone mit erkennbarer Version. *(Backend, Verwaltungsoberfläche)*

- **Update-Deltas: Export und Import** — Einzelne Update-Deltas lassen sich jetzt als 7z-Archiv exportieren und auf einer anderen Installation importieren; der Import erkennt die Version aus dem Dateinamen, validiert sie gegen die bestehende Kette und lehnt Duplikate ab. *(Backend, Verwaltungsoberfläche)*

- **Klon-Import: nutzt die im Klon hinterlegte Version** — Beim Import eines Klons wird die Version jetzt aus dem Namen erkannt, statt eine neue Wurzelnummer zu vergeben; Klone ohne erkennbare Version im Namen bekommen weiterhin eine neue Wurzelnummer. *(Backend)*

- **Rollback-Tab: persistente Zuweisungen mit Pro-Gerät-Status** — Der Rollback-Tab im Cloning-Bereich funktioniert jetzt analog zu Update-Zuweisungen — persistente Zuweisungen mit Pro-Gerät-Status (ausstehend/vorbereitet/erledigt), aufklappbare Detail-Zeilen, automatische Status-Aktualisierung per Heartbeat sowie Sammel-Aktionen für Neustart/Herunterfahren. *(Backend, Verwaltungsoberfläche)*

- **Update-Ketten: Auf-/Zugeordnet-Status statt Freigabe-Häkchen** — Die Freigabe-Häkchen an Update-Deltas entfallen — alle Deltas sind nach Erstellung oder Import sofort verfügbar, die tatsächliche Verteilung wird ausschließlich über Zuweisungen (Rollouts) gesteuert. Die Update-Kette sortiert jetzt nach Version statt Erstellungsdatum, die automatische Übernahme von Deltas beim Klon-Löschen in den Nachfolger entfällt (Deltas bleiben beim Klon-Löschen erhalten), und das frühere „Konflikt-Geräte"-Feature in der Seitenleiste ist zugunsten des dedizierten Rollback-Tabs entfernt. *(Backend, Verwaltungsoberfläche)*


## 2026-04-01

- **Klon-Löschen: optionaler Rollback der betroffenen Geräte** — Wird ein Klon gelöscht, auf dem noch Geräte laufen, fragt der Bestätigungs-Dialog jetzt, ob für diese Geräte automatisch ein Rollback ausgelöst werden soll (Server-Hinweis → Heartbeat → lokaler Marker → Wechsel auf den vorherigen Snapshot beim nächsten Herunterfahren). Eine dynamische „Konflikt-Geräte"-Gruppe in der Seitenleiste listet betroffene Geräte mit Status und Rollback-Knopf, einzeln oder gesammelt auslösbar. *(Backend, Verwaltungsoberfläche, Agent)*

- **Update-Zuweisung: erst Gruppe wählen, dann Geräte** — Die Geräte-Auswahl in der Update-Zuweisung folgt jetzt demselben Kaskaden-Schema wie die Deployment-Erstellung — erst Gruppe, dann Geräte innerhalb der Gruppe — statt vorher alle Geräte ungefiltert anzuzeigen. *(Verwaltungsoberfläche)*

- **Update-Deltas: einzeln exportieren** — Einzelne Update-Deltas lassen sich jetzt als 7z-Archiv herunterladen, optional mit AES-256-Passwort geschützt; das Archiv enthält Delta, Signatur und Metadaten, der Knopf sitzt direkt neben jedem Delta in der Update-Kette. *(Backend, Verwaltungsoberfläche)*

- **Klon intelligent löschen** — Klone lassen sich jetzt „intelligent" löschen: Beim letzten Klon der Kette wird das zugehörige Delta mit-gelöscht (Versionsnummer wird beim nächsten Speichern wiederverwendet), bei einem Klon in der Mitte wird das eingehende Delta automatisch mit dem Delta des Nachfolgers zusammengeführt. Vor dem Löschen prüft das System, ob die VM gerade mit dieser Version läuft (mit Warnung), und der Bestätigungs-Dialog zeigt alle Seiteneffekte an. *(Backend, Verwaltungsoberfläche)*

- **Diverse Korrekturen** — Agent-interne Pfade (Konfiguration, Token, Versionsdateien, Signatur-Schlüssel) liegen jetzt einheitlich auf der persistenten Daten-Partition statt in einem flüchtigen System-Verzeichnis, damit sie Reboots überstehen; die Signatur-Prüfung des Update-Schlüssels extrahiert jetzt zuverlässig nur die eigentliche Schlüssel-Zeile. Außerdem: korrekte Zuordnung von Geräten auf Basis-Version, eine behobene Race-Condition beim Anlegen eines Update-Rollouts mit Merge, ein entfernter doppelter Bestätigungs-Dialog beim Löschen eines Rollouts, eine behobene doppelte Seitenöffnung im Cloning-Menü, ein neuer Knopf zum Zurücksetzen aller DHCP-Leases sowie eine IP-Reservierung für Geräte direkt bei der Genehmigung. *(Backend, Agent, Verwaltungsoberfläche)*


## 2026-03-31

- **Update-Zusammenführungen: Echtzeit-Fortschritt + Klon-Wiederherstellung im Hintergrund** — Das Erzeugen zusammengeführter Update-Deltas zeigt jetzt einen echten Fortschrittsbalken mit benannten Schritten statt eines unbestimmten Spinners, sichtbar in mehreren offenen Browser-Tabs gleichzeitig. „Klon wiederherstellen" blockiert die Oberfläche nicht mehr — der Dialog schließt sofort, der Fortschritt läuft über den üblichen Status-Mechanismus, und bei Abschluss wechselt die Ansicht automatisch zum VM-Tab. *(Backend, Verwaltungsoberfläche)*


## 2026-03-30

- **Zusammengeführte Update-Deltas nur für tatsächlich zugewiesene Geräte** — Zusammengeführte Deltas wurden bisher pauschal für alle Geräte in der Datenbank berechnet, auch wenn nur ein Bruchteil in der konkreten Update-Zuweisung saß. Jetzt berücksichtigt das System ausschließlich die installierten Versionen der wirklich zugewiesenen Geräte, bereits vorhandene Deltas werden weiterhin wiederverwendet. Die alte Ansible-Integration ist komplett entfernt und durch den Agent-basierten Verwaltungs-Pfad abgelöst. *(Backend, Deploy-Repo)*


## 2026-03-29

- **Update-Deltas werden jetzt signiert (kryptografisch geprüft)** — Alle Update-Deltas (einzelne, zusammengeführte, Home-Deltas) werden ab jetzt automatisch mit minisign (Ed25519) signiert. Geräte prüfen die Signatur vor jeder Anwendung; eine ungültige Signatur führt zum harten Abbruch, eine zweite Prüfung im Anwende-Skript schützt zusätzlich. Der öffentliche Schlüssel wird per Heartbeat verteilt, bei einer Rotation übernimmt das System die Vertrauenskette automatisch (Verwaltung unter Einstellungen → Sicherheit). Damit ist die Auslieferung über NFS, Multicast und BitTorrent gegen Manipulation und Übertragungsfehler abgesichert. *(Backend, Agent, Verwaltungsoberfläche)*

- **Update-Mechanismus: zusammengeführte Deltas + automatische Pakete-Updates auf Manjaro** — Geräte, die mehrere Versionen hinterherhinken, lassen sich jetzt in einem Schritt statt sequentiell aktualisieren (ein Reboot statt mehrerer) — das System erzeugt dafür „zusammengeführte" Deltas auf einer temporären Disk und wählt automatisch den größten verfügbaren Versions-Sprung. Eine Checkbox „Zusammengeführte Deltas erzeugen" startet den Merge im Hintergrund; Geräte warten automatisch, bis die Deltas vorliegen, und die Freigabe lässt sich pro Merge einzeln steuern. *(Backend, Verwaltungsoberfläche)*

- **Agent v2.4.1: VPN-Routen werden live aktualisiert** — Werden im VPN-Netzwerke-Tab die gerouteten Netze geändert (z. B. beim Full-Tunnel-Routing), erhalten alle VPN-Clients die neue Liste automatisch beim nächsten Heartbeat; der Agent vergleicht mit der lokalen Konfiguration und startet den Tunnel bei Änderung neu — kein manuelles Re-Deployment mehr nötig. *(Backend, Agent)*

- **Update-Anwende-Mechanismus überarbeitet** — Geänderte Snapshot-Berechtigungen hatten das interne Datenformat der Snapshots beschädigt, sodass die System-Tools den Eltern-Snapshot nicht mehr fanden; empfangene Snapshots werden jetzt nicht mehr nachträglich verändert, die Boot-Konfiguration entsteht vor dem Subvolume-Tausch, und im Boot-Menü erscheint nur noch der unmittelbar vorherige Snapshot als Rollback-Option. Agent v2.4.0 lädt zusätzlich bei jedem Start ein Migrations-Skript und führt es idempotent aus, das nach einem Subvolume-Tausch fehlende Dienste automatisch nachinstalliert. *(Agent)*

- **Diverse Korrekturen** — Mehrere Bugfixes im „Update speichern"-Flow (Snapshot-Filter, Doppel-Erzeugung, sauberere Versions-Prüfung, Absicherung gegen Nebenläufigkeits-Fehler); der Tunnelstatus aktualisiert sich nach Import oder Speichern einer VPN-Konfiguration automatisch, hängende „Zusammenführen läuft"-Markierungen werden beim Backend-Start zurückgesetzt, und die Deltas-Liste lädt nach Abschluss eines Merges automatisch neu. *(Backend)*
## 2026-03-28

- **Klone und Deltas: „veraltet"-Markierung für überholte Stände** — Vollständige Klone und Update-Deltas, die von allen aktiven Geräten bereits überholt sind, werden jetzt durchgestrichen und als „veraltet" markiert. Aufklappbare Detail-Zeilen zeigen pro Klon/Delta, welche aktiven und Lager-Geräte den Stand noch nicht haben. Erleichtert das Erkennen nicht mehr benötigter Stände. *(Backend, Verwaltungsoberfläche)*

- **PXE-Boot funktioniert auf allen Geräten + GRUB-EFI-Verbesserungen** — Alle registrierten Geräte erhalten bei jedem Start ein PXE-Boot-Image vom Server; die geräteindividuelle Konfiguration steuert lokalen oder Clonezilla-Start, OS-unabhängig. GRUB scannt zusätzlich lokale EFI-Partitionen und lädt den Boot-Loader per Chainload direkt — das behebt eine Endlos-Schleife, wenn PXE als erste UEFI-Boot-Option eingestellt war. *(Server-Dienste, Deploy-Repo)*

- **Updates-Tab: Sammel-Aktionen direkt in der Status-Tabelle** — Die Geräte-Status-Tabelle im Updates-Tab hat jetzt Auswahl-Boxen sowie Sammel-Aktionen „Neustart" und „Herunterfahren", analog zum Haupt-Geräte-Tab. *(Verwaltungsoberfläche)*

- **Agent: automatische Skript- und Versionsaktualisierung, Snapshot-Aufräumen** — Der Agent aktualisiert beim Start per Hash-Vergleich automatisch nicht nur sich selbst, sondern auch seine Hilfs-Skripte, und räumt alte btrfs-Snapshots auf (zwei aktuelle plus ein Pre-Update-Paar bleiben) — spart dauerhaft Plattenplatz. Selbst-Update läuft jetzt bei jedem Heartbeat statt nur beim Start, neue Versionen sind binnen 60 Sekunden aktiv. Beim Rollback wird zusätzlich das Home-Verzeichnis vom passenden Snapshot eingebunden, und GRUB wird direkt nach dem Subvolume-Tausch beim Herunterfahren aktualisiert, damit Rollback-Einträge sofort im nächsten Boot verfügbar sind. *(Agent)*

- **VPN-Firewall: persistent und gehärtet** — Firewall-Regeln werden jetzt persistent gespeichert und beim Container-Start automatisch neu geladen (vorher gingen sie bei jedem Neustart verloren); beim Backend-Start werden sie vorsichtshalber zusätzlich neu angewendet. System-Regeln (DNS, HTTPS) lassen sich nur noch an-/ausschalten statt inhaltlich verändern, und Eingaben werden streng validiert (verhindert Befehls-Einschleusung). **Sicherheitshinweis:** Die VPN-Management-API ist nicht mehr aus dem LAN erreichbar, sondern nur noch über die interne Docker-Bridge. *(Backend)*


## 2026-03-27

- **Agent-Selbst-Update und Snapshot-Verwaltung** — Der Agent prüft beim Start seine Version gegen den Server, aktualisiert sich automatisch (Backup vor dem Tausch, systemd-Neustart danach) und konfiguriert nach einem Delta-Update den Boot-Loader neu, damit alle Snapshots im Boot-Menü erscheinen. Ein erfolgreicher Boot auf neuer Version wird automatisch bestätigt, alte Snapshots werden aufgeräumt. Zusätzlich: Inventarnummer als Spalte in den Update-Ansichten (Standard-Sortierung), Refresh-Knöpfe und aufklappbare Update-Zuweisungen mit Geräte-Details. *(Agent, Verwaltungsoberfläche)*

- **Versions-Schema: einheitlich „vMAJOR.MINOR" mit dreistelliger Minor** — Versions-Strings werden automatisch mit „v"-Präfix normalisiert, die Minor-Version ist dreistellig (z. B. `v1.001`), damit Dateinamen und Snapshot-Listen alphabetisch korrekt sortieren. Im „Update speichern"-Dialog lässt sich zwischen Delta-Update (Minor-Bump) und neuem Basis-Image (Major-Bump, neue Versionskette) wählen; ohne vorhandene Klone wird immer eine frische Baseline `v1.000` erzwungen. *(Backend, Verwaltungsoberfläche)*

- **Update-Anwendung beim Herunterfahren statt im laufenden Betrieb** — Delta-Updates werden jetzt per systemd-Dienst beim Herunterfahren angewendet statt im laufenden System — verhindert ein Einfrieren des Desktops während des internen Subvolume-Tauschs. Der Agent legt das Delta lokal ab, der eigentliche Wechsel erfolgt beim nächsten Herunterfahren. Vor einem neuen Basis-Image werden alte Snapshots in der Cloning-VM automatisch gelöscht; die Geräte-Provisionierung liefert jetzt zusätzlich den Anwende-Dienst und das Snapshot-Verwaltungs-Skript mit aus. *(Agent, Deploy-Repo)*

- **Diverse Korrekturen** — Desktop-Einfrieren nach Delta-Update behoben (Subvolume-Tausch nur noch beim Herunterfahren, GRUB-Snapshot-Daemon deaktiviert); doppelter Delta-Download durch zusätzliche lokale Markierung verhindert; Pre-Update-Snapshots wachsen nicht mehr unbegrenzt; Multicast-Import-Fehler durch fehlerhaften internen Import behoben. *(Agent, Backend)*


## 2026-03-26

- **Cloning-VM: Daten-Partition wird automatisch angelegt** — Das Manjaro-Installations-Skript legt jetzt automatisch eine ca. 5 GiB große btrfs-Daten-Partition (`@data`-Subvolume) an, die unter `/data` eingehängt wird und alle Updates übersteht; die System-Partition wird dafür live online verkleinert. *(Server-Dienste, Deploy-Repo)*

- **Tools-ISO aufgeräumt + Versionierungs-Konsistenz** — Die Tools-ISO enthält nur noch drei Haupt-Skripte, Helfer liegen in einem Unterordner. Beim Klon-Erstellen wird die Version automatisch auf der Disk hinterlegt, sodass frisch ausgerollte Geräte sie ab dem ersten Boot korrekt melden. Update-Zuweisungen lassen sich im Updates-Tab löschen (laufende werden sauber abgebrochen), und die VM-Festplatte wird nach erfolgreichem Klon automatisch zurückgesetzt. *(Backend, Deploy-Repo)*

- **Update-Deltas: mehrere Subvolumes + automatischer Subvolume-Tausch + WireGuard persistent** — Snapshots und Deltas erfassen jetzt sowohl `@root` als auch `@home`, wodurch Desktop-Anpassungen automatisch vom Master-System zu den Geräten fließen; der Subvolume-Tausch beim nächsten Boot läuft ohne manuellen GRUB-Eingriff. Die WireGuard-Konfiguration liegt auf der Daten-Partition und übersteht damit alle Updates. Zusätzlich wird das VPN-Subnetz automatisch in alle NFS-Freigaben eingetragen, und ein DNS-Override mappt den Server-Hostnamen auf die interne IP, damit Heartbeats und Downloads korrekt durch den Tunnel laufen. *(Agent, Server-Dienste)*

- **Diverse Korrekturen** — „Installiertes Image" zeigt die richtige sichtbare Version statt der internen Nummer; doppeltes „v" in der Geräte-Liste behoben; Absturz bei Klon-Wiederherstellung mit führendem „v" in der Version gefixt; VM-Start stabilisiert (ungültige MAC, UEFI-Boot-Reihenfolge bei eingelegter ISO); Capture mit Leerzeichen im Namen funktioniert; mehrere Capture-Folgefehler sowie VPN-NFS-Zugriff und VPN-Routing über den Tunnel behoben. *(Backend, Verwaltungsoberfläche)*

- **Sicherheit (Hinweis)** — Als wichtiges Vor-Produktiv-TODO dokumentiert: WireGuard-Schlüssel liegen aktuell im Klartext auf der Daten-Partition. Vor dem produktiven Betrieb soll die Daten-Partition mit LUKS verschlüsselt und per TPM-2.0-Auto-Entriegelung (oder Hardware-ID-Fallback) abgesichert werden; Datenbank-Schema und UI-Vorbereitung dafür sind bereits vorhanden. *(Agent, Backend)*


## 2026-03-25

- **Erstes vollständiges Delta-Update auf echter Hardware** — Erster kompletter Durchlauf auf einem echten Gerät: Baseline v1.0 → Update v1.1, Delta 1,6 GB, in 2 Sekunden per NFS gezogen und in 26 Sekunden angewendet, GRUB automatisch konfiguriert — ohne Nutzer-Eingriff und ohne erzwungenen Neustart. Der End-zu-End-Pfad ist damit funktional bestätigt. *(Agent, Server-Dienste)*

- **Automatische Versions-Nummerierung + Boot-Loader als Standard-Manjaro-Logik** — Versionen werden automatisch hochgezählt (v1.0 → v1.1 → …) statt manuell eingegeben, optional mit Kommentar statt Versionsnummer. Der eigene GRUB-Mechanismus ist abgelöst durch Manjaros natives `grub-mkconfig` plus `grub-btrfs`: Snapshots erscheinen automatisch bootbar im GRUB-Menü, Rollback heißt nur noch „Snapshot wählen"; „Timeshift" wird nicht mehr benötigt, rund 300 Zeilen Code sind weggefallen. *(Backend, Deploy-Repo)*

- **Manjaro-Installations-Skript zweistufig + diverse Korrekturen** — Neues zweistufiges Installations-Skript (Phase „prepare" für Calamares, Phase „finish" für GRUB + Agent) mit dynamischer Kernel-Erkennung; zusätzlich ein separates Skript für schnellen SSH-Zugriff auf die VM. Aus Live-Tests behoben: NBD-Schreib-Fehler, fehlender Heartbeat-Token beim Python-Agenten (führte zu 403), fehlende Basis-Version bei frisch ausgerollten Geräten, fehlerhaftes Snapshot-Listen-Parsing sowie Sichtbarkeit des Deltas-Verzeichnisses im Backend-Container. *(Server-Dienste, Deploy-Repo)*

- **Cloning-VM-Info: MAC + IP + Fortschrittsbalken** — Der VM-Tab zeigt MAC-Adresse und IP der VM im Info-Panel; beim „Update speichern" gibt es jetzt einen prozentualen Fortschrittsbalken, analog zum Klon-Erstellen. *(Verwaltungsoberfläche)*


## 2026-03-23

- **Großes Feature: Delta-Update-System für Klone** — Erste Ausbaustufe des Delta-Update-Mechanismus: Statt vollständiger Re-Deployments (15+ GB) genügt jetzt ein Delta zwischen zwei Versionen (typisch 50–200 MB). Dafür gibt es ein neues Partitionsschema (EFI + btrfs-System mit Snapshots + btrfs-Daten), einen „Update speichern"-Knopf im VM-Tab (Snapshot + Delta + voller Klon in einem Schritt) sowie einen neuen Updates-Tab für Delta-Liste und Rollout-Verwaltung. Der Agent bestätigt erfolgreiche Update-Boots ans Backend, die Auslieferung läuft über NFS mit Beschränkung auf berechtigte Geräte, ohne automatischen Neustart, und funktioniert distributionsneutral auf Debian- und Arch/Manjaro-Systemen. *(Backend, Agent, Verwaltungsoberfläche)*

- **Update-Freigabe, Update-Kette und Gruppen-Zuweisungen** — Updates müssen jetzt explizit freigegeben werden (Rollout startet als „Entwurf", wird per Klick „aktiv", automatisch „abgeschlossen" wenn alle Geräte fertig sind). Die Update-Kette wird als erzwungene Reihenfolge im UI angezeigt (z. B. v1.1 nur freigebbar, wenn v1.0 bereits aktiv ist), Gruppen können unterschiedliche Ziel-Versionen haben, und Geräte durchlaufen die Kette pro Heartbeat automatisch Schritt für Schritt. Beim Löschen eines Deltas warnt das System, falls Geräte oder die Versions-Kette betroffen sind. *(Backend, Verwaltungsoberfläche)*

- **Neues Festplatten-Schema kann aus dem UI angewendet werden** — Ein neuer Knopf „Festplatten-Schema anwenden" im VM-Tab erstellt die Disk bei Bedarf und partitioniert sie neu (EFI + System-btrfs + Daten-btrfs). Ein Warn-Dialog zeigt das Layout und weist ausdrücklich auf Datenverlust hin; bei wiederhergestellten Klonen ist der Knopf deaktiviert. *(Backend, Verwaltungsoberfläche)*

- **Agent-Refactoring (v2.0)** — Der Python-Agent wurde grundlegend überarbeitet: Wiederholungsversuche pro Delta sind auf maximal 3 begrenzt, ein neues Delta wird erst nach erfolgreichem Boot des vorherigen angenommen, die installierte Version wird dauerhaft in einer eigenen Datei getrackt, und die Installation läuft jetzt sauber über Tools-ISO und Provisionierungs-Skript. *(Agent)*


## 2026-03-22

- **Setup-Wizard: Wiederherstellung aus Backup als Einstiegs-Option** — Der Setup-Wizard fragt jetzt zuerst: Neuinstallation oder Wiederherstellung aus Backup? Bei Wiederherstellung wird das Backup hochgeladen, validiert und vollständig zurückgespielt (Datenbank, VPN-/DHCP-/NFS-/Chrony-/Reverse-Proxy-Konfiguration, Verschlüsselungs-Schlüssel); bei Bedarf werden Dienste neu gestartet, damit der importierte Schlüssel wirksam wird. *(Backend, Verwaltungsoberfläche)*

- **VPN: FullVPN-Subnetz-Verwaltung** — ThinForge unterstützt jetzt die FullVPN-Endpunkte des thinVPN-Servers; geroutete Netzwerke werden automatisch als individuelle Subnetze des Haupt-Servers auf dem VPN-Server synchronisiert. Damit ist ein bisheriges Routing-Problem gelöst: Das lokale Subnetz wird automatisch in die Routen des Haupt-Server-Peers eingetragen (sofern `fullvpn: true` auf dem VPN-Server aktiv ist). Der FullVPN-Status ist im VPN-Netzwerke-Panel sichtbar, ein „VPS Sync"-Knopf gleicht manuell ab. *(Backend, Verwaltungsoberfläche)*

- **Diverse Korrekturen** — PXE-Konfiguration eines Geräts wird beim Capture nicht mehr fälschlich zurückgesetzt; neuer Deployment-Dialog wählt automatisch den jüngsten Klon vor; VPS-Statusanfragen liefern bei nicht erreichbarem VPS einen leeren Standard statt Fehlermeldung; Tools-ISO wird vor jedem VM-Start automatisch neu gebaut; CSV-Import-Dialog schließt nach Erfolg automatisch; WireGuard-Container hängt nach Werksreset nicht mehr im „ungesund"-Status. *(Backend, Verwaltungsoberfläche)*

- **Geräte-spezifische SSH-Schlüssel entfernt** — Die individuelle SSH-Schlüssel-Verwaltung pro Gerät entfällt vollständig; für alle SSH-Verbindungen wird nur noch der zentrale Provisionierungs-Schlüssel verwendet. Mehrere zugehörige API-Endpunkte und UI-Bereiche wurden entfernt — schlanker, weniger Fehlerquellen, ohne Funktionsverlust im Betrieb. *(Backend, Verwaltungsoberfläche)*

- **Geräte: neues Feld „Verbindungsart" (LAN / VPN / VPN-Sync)** — Jedes Gerät führt jetzt eine Verbindungsart mit: `lan`, `vpn` (Heartbeat über VPN) oder `vpn_sync` (nur per VPN-API-Sync erkannt, kein Heartbeat). Die Status-Anzeige nutzt passende Symbole, dazu ein neuer Filter „Verbindung" in der Geräte-Liste sowie Anzeige im Detail und auf der Dashboard-Karte. *(Backend, Verwaltungsoberfläche)*

- **VPN: neuer Tab „VPN-Netzwerke" und sauberes Deaktivieren** — Neuer Tab mit Checkboxen für erkannte Host-Interfaces und manueller CIDR-Eingabe. Bei VPN-Deaktivierung löst das System automatisch einen Aufräum-Job auf dem Gerät aus (WireGuard stoppen, Konfiguration entfernen); beim Deploy wird zusätzlich eine systemd-Override-Datei installiert, die die Routen-Metriken beim Systemstart fixiert. *(Verwaltungsoberfläche, Agent)*


## 2026-03-21

- **Setup-Skripte konsolidiert, Host-Abhängigkeiten reduziert** — Zwei separate Setup-Skripte sind zu einem zusammengeführt; die Host-Abhängigkeiten sind auf Docker, Git, OpenSSL und wenige Kernel-Module reduziert. Pakete wie qemu-kvm, NFS-Server, WireGuard-Tools und libvirt werden nicht mehr auf dem Host installiert (Kernel-Module sind unter Ubuntu 24.04 bereits enthalten), der KVM-Vendor wird automatisch erkannt, und konfligierende Host-NFS-Dienste werden nur noch gewarnt statt abgeschaltet. *(Server-Dienste, Deploy-Repo)*

- **Versionsanzeige + Changelog-Dialog in der Kopfleiste** — Die ThinForge-Versionsnummer wird oben rechts angezeigt; ein Klick öffnet einen Dialog mit dem aktuellen, als Markdown gerenderten Changelog. *(Verwaltungsoberfläche)*

- **Großer Codebase-Bereinigungs-Lauf** — Umfangreiche interne Aufräumarbeiten in rund 40 Bereichen ohne Funktionsänderungen: weniger doppelter Code, schnellere Datenbank-Abfragen (mehrere „N+1"-Muster eliminiert, an einer Stelle rund 700 Abfragen pro Zyklus eingespart) und insgesamt stabilerer Betrieb. *(Backend)*


## 2026-03-20

- **Großes Bündel an Verbesserungen rund um Deployment, VPN und Tasks** — Alle Deploy-Wege (Unicast, Multicast, BitTorrent) prüfen jetzt vor dem Restore die Ziel-Festplattengröße und brechen bei zu kleiner Disk mit klarer Fehlermeldung sauber ab, statt mitten im Restore zu scheitern. Neu sind ein Einstellungs-Tab „Allgemein" mit konfigurierbarer Sitzungsdauer (1 h–30 Tage), ein VPN-Tasks-Tab mit Live-Status/Retry/Cancel für VPN-Hintergrundaufgaben, ein VPN-Remote-Sync-Tab (zeigt Clients auf dem VPN-Server, verwaiste Einträge rot markiert), erneutes Pushen der VPN-Konfiguration ohne Schlüssel-Neuerzeugung, zeitgesteuerte Aufgaben-Vorlagen sowie ein einheitlicher Gruppen-Filter für die Geräte-Auswahl. VPN-Clients mit Schlüssel-Entschlüsselungs-Problemen werden beim nächsten Konfigurations-Abruf automatisch neu provisioniert, und Lager-Geräte werden visuell markiert (ausgegraut, oranger Status) mit automatischer IP-Freigabe bzw. -Neuzuweisung. Dazu zahlreiche kleinere Korrekturen (Metriken, Race-Conditions bei Rate-Limiter und IP-Vergabe, Provisionierungs-SSH-Schlüssel im Worker-Container, N+1-Abfragen). *(Backend, Verwaltungsoberfläche)*


## 2026-03-19

- **Großes Feature: VPN-Integration auf Basis von thinVPN (Cloud)** — Das bisherige lokale WireGuard-VPN-System ist durch eine Cloud-basierte thinVPN-Integration ersetzt: Der ThinForge-Server verbindet sich als WireGuard-Client zu einem externen thinVPN-Server und verwaltet die VPN-Profile der Geräte über eine REST-API. Die Tunnel-Konfiguration wird im neuen VPN-Tab per Import eingerichtet und ist mit Bestätigung wieder löschbar; VPN-Konfigurationen werden jetzt über Gruppen gesteuert (Toggle „VPN aktiv", Bulk-Generierung inkl. Schlüssel-Rotation), Schlüssel können optional im TPM der Geräte gespeichert werden, dazu periodischer Sync, Traffic-Monitoring und eine optionale Firewall für VPN→LAN-Verkehr. Begleitend wird die WireGuard-Konfiguration automatisch per SSH auf die Geräte ausgerollt (inkl. Auto-Installation der WireGuard-Tools). *(Backend, Verwaltungsoberfläche)*

- **Profil-Funktion entfernt** — Die separate „Konfigurationsprofil"-Funktion wurde komplett entfernt, da im Betrieb ungenutzt; Gruppen tragen die zugehörigen Einstellungen jetzt direkt, die Datenmigration läuft automatisch. *(Backend, Verwaltungsoberfläche)*

- **Diverse VPN- und TLS-Korrekturen** — Tunnel-Status wird im UI korrekt angezeigt (vorher dauerhaft „getrennt"); Firewall-Toggle überschreibt nicht mehr die übrigen VPN-Einstellungen; DNS-Auflösung des Backends nach WireGuard-Start funktioniert wieder; WireGuard-Container läuft auch ohne anfängliche Konfiguration stabil; TLS-Zertifikate umfassen jetzt alle erkannten Server-IPs und verhindern so Zertifikatsfehler beim Zugriff über die Verwaltungsoberfläche. *(Backend)*


## 2026-03-18

- **BitTorrent-Deployment funktioniert wieder** — Geräte suchten ihre Torrent-Dateien wegen einer falschen Reihenfolge bei der internen Schlüsselerzeugung in einem Verzeichnis, das der Seeder nie befüllte. Behoben: Der Schlüssel wird jetzt vor der Aktivierung erzeugt, die PXE-Konfigurationen passen wieder. *(Backend)*

- **Deployment-Status: Fehler werden korrekt angezeigt** — Bisher zeigte ein Deployment dauerhaft „Abgeschlossen" (grün) an, selbst wenn alle Geräte fehlgeschlagen waren; ein neuer Status „Mit Fehlern abgeschlossen" (rot) macht Fehler jetzt sichtbar. Zusätzlich werden Torrent- und Hilfs-Dateien beim Löschen eines Deployments mit aufgeräumt, und fälschliche Offline-Alarme nach einem Deployment treten nicht mehr auf. *(Backend, Verwaltungsoberfläche)*

- **Aktive Geräte-Prüfung („Ping") und Standard-Sortierung nach Inventarnummer** — Klick auf den grünen „Online"-Status eines Geräts löst zwei parallele Pings aus; reagiert keiner, wird das Gerät sofort als offline markiert (Voraussetzung: ICMP muss in der Geräte-Firewall erlaubt sein). Die Geräte-Liste ist jetzt standardmäßig aufsteigend nach Inventarnummer sortiert. *(Backend, Verwaltungsoberfläche)*

- **Container-Basis auf Debian Trixie + neuere Partclone-Version** — Alle ThinForge-Container nutzen jetzt Debian 13 (Trixie, stabil) statt der unstabilen Entwicklungs-Variante, Partclone ist auf Version 0.3.47 angehoben. Build-Quellen werden lokal zwischengespeichert — schnellere Re-Builds, weniger Netzwerk-Last. *(Server-Dienste)*

- **Verbesserungen rund um Deployment-Wiederholung** — Inventarnummer ist in der Geräte-Liste eines aufgeklappten Deployments sichtbar; der Restart-Knopf erscheint jetzt auch bei abgebrochenen (nicht nur fehlgeschlagenen) Deployments, ein Abbruch räumt den Status sauber zurück. Geräte ohne Rückmeldung nach Abschluss der Multicast-Übertragung (z. B. Neustart während der Übertragung) werden automatisch als fehlgeschlagen markiert (Timeout konfigurierbar, Standard 120 Sekunden); beim Wiederholen fehlgeschlagener Geräte wird die NFS-Freigabe zuverlässig reaktiviert. *(Backend, Verwaltungsoberfläche)*

- **Sicherheit: BitTorrent-Pfade nicht mehr vorhersagbar** — Torrent-Dateien werden jetzt unter einem zufälligen 32-stelligen Pfad statt unter der vorhersagbaren Deployment-ID ausgeliefert. Zusätzlich filtert die DHCP-Konfiguration unbekannte Geräte (`dhcp-ignore=tag:!known`) — nur registrierte Geräte erhalten überhaupt eine IP. *(Backend)*

- **HTTPS von Anfang an + TLS-Zertifikat auf Clients** — Beim ersten Server-Start wird automatisch ein selbstsigniertes TLS-Zertifikat erzeugt; der Reverse-Proxy liefert sofort HTTPS aus und leitet HTTP automatisch um. Der Setup-Wizard ersetzt das Zertifikat im sechsten Schritt durch eines mit korrektem CN/SANs; das Server-Zertifikat wird zudem automatisch in die Tools-ISO eingebettet und vom Client-Installations-Skript in den System-Vertrauensspeicher der Geräte eingetragen, sodass alle Server-URLs (Heartbeat, Agent, ISO) über HTTPS laufen. *(Server-Dienste, Deploy-Repo)*

- **Sicherheit: stärkere Schlüsselableitung + Rate-Limit auf Login** — Die Verschlüsselung der gespeicherten SSH- und WireGuard-Schlüssel nutzt jetzt PBKDF2-HMAC-SHA256 mit 600.000 Iterationen und persistentem Salt; bestehende Daten werden bei Bedarf transparent migriert. Neu: Rate-Limits auf Anmelde-Endpunkte (`/login` 5 Versuche/5 Min, `/totp/login` 3/5 Min, `/change-password` 5/5 Min). **Wichtig:** Ein unauthentifizierter Web-Terminal-Endpunkt, der jedem im LAN eine Root-Shell erlaubte, wurde entfernt — der Terminal-Dialog nutzt nur noch den authentifizierten Endpunkt. *(Backend)*
## 2026-03-17

- **Worker stabilisiert + BitTorrent-Modus erkannt + dauerhafte PXE-Stände** — Der Worker-Container stürzte bei wiederkehrenden Aufgaben ab; das ist behoben. Die Erkennung des BitTorrent-Modus verglich bislang unterschiedliche Bezeichnungen, wodurch Geräte kein Boot-Image erhielten — jetzt werden beide Varianten akzeptiert. Nach einem Backend-Neustart gingen bisher laufende PXE-Konfigurationen verloren; aktive Deployments werden nun aus der Datenbank wiederhergestellt und überleben Backend-Neustarts. *(Backend, Server-Dienste)*

- **VPN-Erweiterungen: Live-Status, Auto-Install, Retry, Revokation** — WireGuard-Handshake-Daten (letzter Kontakt, übertragene Bytes) werden jetzt minütlich synchronisiert, und der Agent meldet den VPN-Status im Heartbeat. WireGuard-Tools werden bei Bedarf automatisch auf dem Gerät installiert; SSH-Fehler beim VPN-Deploy lösen bis zu drei Wiederholungsversuche mit steigendem Abstand aus. Beim Widerrufen eines VPN-Zugangs wird die WireGuard-Konfiguration jetzt auch auf dem Gerät entfernt (Dienst gestoppt, deaktiviert, Datei gelöscht). *(Backend, Agent)*

- **Dashboard: Speicher-Auslastung + neuer Info- und Backup-Bereich** — Eine neue Dashboard-Karte zeigt die Festplatten-Belegung des Servers mit farbcodiertem Balken. Der neue Menüpunkt „Info & Backup" bietet eine vollständige Sicherung und Wiederherstellung — Datenbank und Konfiguration sind immer enthalten, ISOs/Klone/Captures optional zuwählbar, Download als Archiv, Restore per Upload mit Passwort-Bestätigung. Außerdem wurden ThinForge-Logos mit automatischer Dark/Light-Umschaltung ergänzt. *(Backend, Verwaltungsoberfläche)*


## 2026-03-16

- **Neues Feature: Remote Desktop (Live-Bildschirm der Geräte)** — Geräte lassen sich jetzt live im Browser anzeigen und fernsteuern. Die Übertragung läuft komplett über die bestehende SSH-Verbindung — kein VNC, keine zusätzlichen offenen Ports nötig. Unterstützt wird aktuell X11/XFCE, Wayland ist geplant. *(Backend, Verwaltungsoberfläche)*

- **Geräte: Herunterfahren als Bulk-Aktion + Aktions-Dropdown** — Ein neuer „Herunterfahren"-Knopf steht in der Geräte-Detailansicht und als Sammel-Aktion für mehrere Geräte bereit. Wake, Reboot und Shutdown sind jetzt in einem übersichtlichen Aktions-Menü zusammengefasst. *(Verwaltungsoberfläche)*

- **DHCP: feste IP-Vergabe + Mismatch-Erkennung** — Neu angelegte oder importierte Geräte erhalten automatisch eine feste IP aus dem DHCP-Pool, die dnsmasq an die MAC-Adresse bindet. Meldet ein Gerät später eine andere IP (außer bei VPN-IPs in einem anderen Subnetz), warnt die Oberfläche. *(Backend, Verwaltungsoberfläche)*

- **Heartbeat- und Klon-Provisioning, dynamische Server-URL** — Der Heartbeat ist jetzt Token-authentifiziert und meldet MAC-Adresse und IP an den Server. Klon-Provisioning nutzt einen globalen SSH-Schlüssel mit automatischem Provisionierungs-Skript; die Server-URL wird dynamisch in die Tools-ISO eingebettet, und der Server-DNS-Eintrag wird automatisch im Setup-Wizard angelegt. Hardware-Captures werden per zstd komprimiert, was einen passwortlosen Klon-Import ermöglicht; das TLS-Formular im Setup-Wizard ist mit Hostname und IPs vorbelegt. *(Backend, Agent, Deploy-Repo)*

- **Diverse Korrekturen** — Remote Desktop richtet den X11-Zugriff für Root jetzt automatisch korrekt ein, Reboot funktioniert wieder, und ein interner DNS-Loop wurde behoben. PXE-Boot läuft jetzt zuverlässig (Boot-Modus, DHCP-Reload, feste IPs), NFS-Mounts verwenden die fest zugewiesene IP statt der Heartbeat-IP, das Clean-Reset-Skript ist vollständiger, und ältere Hardware-Captures im `.gz.aa`-Format lassen sich wieder wiederherstellen. *(Backend, Agent, Server-Dienste)*


## 2026-03-15

- **Mehrere neue Funktionen rund um Klone, NFS und Wartung** — NFS-Freigaben sind jetzt nur noch für autorisierte Geräte-IPs zugänglich, und die Aktion nach einem Capture ist konfigurierbar. Neu: ein Lager-Modus zum Markieren eingelagerter Geräte, ein Alarm bei Versions-Mismatch der Klon-Version sowie Wartungsfenster für geplante Deployments. TLS-Zertifikate lassen sich jetzt über die Oberfläche verwalten, die Tools-ISO für die Cloning-VM wurde verbessert (CD-ROM-Erkennung, Anzeige, Hostname-Skript), und das Produkt wurde von ThinOS in ThinForge umbenannt. *(Backend, Verwaltungsoberfläche, Deploy-Repo)*


## 2026-03-14

- **Zeit-Synchronisation auf den Clients + UEFI-PXE-Verbesserungen** — Ein neuer Chrony-basierter NTP-Server hält die Uhrzeit der Geräte synchron. Der Setup-Wizard wurde um Capture-Neustart und Netzwerk-Härtung verbessert, und UEFI-Geräte können jetzt per PXE mit lokalem Boot-Fallback starten. *(Backend, Server-Dienste)*


## 2026-03-13

- **Geplante Deployments, BitTorrent-Stabilität, Wake-on-LAN** — Klon-Deployments lassen sich jetzt auf einen geplanten Zeitpunkt terminieren, und der BitTorrent-Seeder wurde stabiler und performanter gemacht. Ein neuer Wake-on-LAN-Knopf steht in der Oberfläche bereit, und die Benutzerführung beim Werks-Reset wurde verbessert. *(Backend, Verwaltungsoberfläche)*


## 2026-03-12

- **BitTorrent- und Multicast-Deployment** — Klon-Images lassen sich jetzt per BitTorrent Peer-zu-Peer an viele gleichzeitig zu klonende Geräte verteilen. Alternativ streamt der Server das Image einmal per Multicast an mehrere Geräte gleichzeitig, mit Countdown-Anzeige, bis alle Empfänger bereit sind. *(Backend, Server-Dienste)*


## 2026-03-11

- **Container-Stabilität + neuer Deployments-Tab** — Alle Docker-Dienste laufen jetzt mit automatischem Neustart und Gesundheitsprüfungen. Ein neuer Tab „Klon-Deployments" verwaltet Deployments, denen sich Klone einzelnen Geräten zuweisen lassen. *(Server-Dienste, Verwaltungsoberfläche)*


## 2026-03-10

- **Capture-Jobs-System und Dashboard-Einstellungen** — PXE-basierte Disk-Captures lassen sich jetzt mit einer Abbruch-Funktion durchführen. Das Dashboard erhielt zudem Layout-Anpassungen und neue Einstellungs-Möglichkeiten. *(Backend, Verwaltungsoberfläche)*


## 2026-03-09

- **Aufgaben-System mit Fortschritt + verschlüsselter Klon-Export** — Laufende Aufgaben zeigen jetzt eine Fortschrittsanzeige, und Aufgaben lassen sich zeitgesteuert planen. Der Klon-Export kann optional passwortverschlüsselt erfolgen, und die Agent-Version der Geräte wird jetzt nachverfolgt. *(Backend, Agent, Verwaltungsoberfläche)*


## 2026-03-08

- **UEFI-Boot, DNS-Weiterleitung, Restore-Fortschritt** — UEFI-Geräte können jetzt per PXE mit GRUB-EFI-Unterstützung booten, und dnsmasq übernimmt die DNS-Weiterleitung mit Konfiguration über die Oberfläche. Beim Wiederherstellen eines Klons wird jetzt eine Fortschrittsanzeige eingeblendet, und externe DNS-Server werden im Setup automatisch erkannt. *(Backend, Server-Dienste, Verwaltungsoberfläche)*
