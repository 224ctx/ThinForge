# 9 — Einstellungen

Im Menü **Einstellungen** sind alle administrativen Bereiche gebündelt. Das Menü ist sichtbar, aber viele Aktionen sind **Admins vorbehalten** und für Operator und Betrachter gesperrt: Benutzerverwaltung, Zertifikat-Upload, Factory-Reset und — seit 2026-08-31 — auch das **Starten, Stoppen und Neustarten von Diensten** im Services-Tab.

Gesperrt heißt: der Server weist die Aktion ab. Die Reiter **Benutzer**, **Abonnement** und **Werkeinstellungen** zeigt die Ansicht nur Admins, **Wartungsfenster** und **Remote Desktop** Admins und Operatoren, ebenso den Sub-Tab **SSH-Zugang** unter Sicherheit (diese beiden seit dem Update vom 2026-10-08; vorher sah ein Betrachter sie und bekam beim Öffnen nur Fehlermeldungen); Operator und Betrachter öffnen die Einstellungen auf **Allgemein**. Im Reiter **Dienste** fehlen ohne Admin-Rolle die Knöpfe zum Starten, Neustarten und Stoppen (seit dem Update vom 2026-09-30; vorher waren Abonnement, Werkeinstellungen und diese Knöpfe für alle sichtbar, und ein Klick endete in einer Fehlermeldung). Wo die Oberfläche eine Aktion noch zeigt, die die Rolle nicht erlaubt, weist der Server sie ab (siehe [Rollenübersicht](README.md#rollen-im-system)).

Die Ansicht ist in Tabs aufgeteilt; diese Anleitung behandelt sie in der Reihenfolge, in der sie im Alltag relevant werden.

> **Vertiefung in eigenen Kapiteln:** Abonnement-Verwaltung → [11 — Abonnement](11-lizenz.md). TLS-/SSH-/Signing-Key-/Vulnerability-Scan-Details → [12 — Sicherheit](12-sicherheit-und-cve-scan.md). VPN-Setup für Homeoffice → [13 — VPN](13-vpn.md). Eigenes Profil + 2FA → [10 — Profil & 2FA](10-profil-und-2fa.md).

## Tab: Services (Dienste)

Reiter **Dienste**: Vollansicht der Docker-Container (die Dashboard-Kachel ist eine Zusammenfassung). Gruppiert nach Profil: Core, Network, Testing, Monitoring, dazu eine Gruppe **On-Demand-Container**. Ein Schalter **Auto-Aktualisierung** und das Aktualisieren-Symbol (kreisförmiger Pfeil) halten die Ansicht aktuell.

Pro Container:

- **Label + Container-Name** (z. B. Backend, `thinforge-backend-1`)
- **Status** — Läuft / Gestoppt / Nicht gefunden / Pausiert / Neustart
- **Health** — Gesund / Ungesund / Startet (wenn Healthcheck definiert)
- **Laufzeit**, bei gestoppten Containern Stoppzeit und Exit-Code, bei fehlenden der `docker compose`-Befehl zum Anlegen
- **Starten / Neustarten / Stoppen** — Buttons; „Starten" nur bei nicht laufenden (bei „Nicht gefunden" gesperrt), „Stoppen" immer mit Bestätigungsdialog, bei kritischen Diensten mit Warnung. **Nur für Admins** — Liste und Status sieht dagegen jede Rolle; die Container-Logs stehen im Menü **Logs**, das nur Admins sehen ([08 — Tasks & Logs](08-tasks-logs.md))

Ein **On-Demand-Badge** (grau) kennzeichnet Container, die absichtlich nur bei Bedarf laufen (`cloning-vm`, `cloner`, `multicast-sender`, `bt-seeder`). Deren Leerlauf ist kein Fehler — die Ansicht zeigt sie als neutrales Grau statt Rot.

Welche Profile die Ansicht zeigt, legt `THINFORGE_ENABLED_PROFILES` in der `.env` des Servers fest (kommagetrennt; leer = alle ausgelieferten Profile). Wer etwa auf einem Server ohne KVM das Profil `testing` ausblenden will, trägt dort eine eigene Liste ein — `rebuild.sh` und `deploy.sh` lassen einen eigenen Wert stehen und ergänzen nur, wo die Zeile fehlt oder noch einen früheren Standard trägt. Wirksam, sobald das Backend neu erzeugt wird (z. B. über `./deploy.sh`).

**Typische Aufgaben**: Hängt ein Dienst nach einem Reboot? Hier Start klicken. Will man einen Container sauber neu initialisieren? Restart.

## Sicherheit → HTTPS / TLS

Unter-Tab **HTTPS / TLS** im Reiter **Sicherheit** (siehe unten): das serverseitige HTTPS-Zertifikat. Default nach Installation: selbstsigniert für den Hostname des Servers. Erzeugen und Hochladen sind Admin-Sache; andere Rollen sehen seit dem Update vom 2026-10-08 nur die Statuskarte. **„Selbstsigniertes Zertifikat erstellen"** erzeugt ein neues (Hostname oder IP-Adresse, Gültigkeit 1–3650 Tage, zusätzliche Hostnamen/IPs kommagetrennt). Die Namen dürfen keine Leer- oder Steuerzeichen, `/`, `+` oder `\` enthalten und ein einzelner Name kein Komma — sie würden im Zertifikat zusätzliche Einträge erzeugen. Das Formular markiert solche Namen schon bei der Eingabe, der Server lehnt sie ebenfalls ab. Platzhalter wie `*.firma.de` und IPv6-Adressen sind erlaubt.

### Zertifikat ersetzen

- **„Eigenes Zertifikat hochladen"** → Zertifikat (`.pem`/`.crt`) und privaten Schlüssel (`.pem`/`.key`) einzeln auswählen, dann **„Zertifikat hochladen"**
- Format: PEM, ungeschützt (Key ohne Passphrase — einen passwortgeschützten Schlüssel weist die Prüfung beim Hochladen ab)
- Validierung prüft, dass Zertifikat und Schlüssel zusammenpassen; schlägt sie fehl, bleibt das bisherige Zertifikat aktiv
- Nach Upload: der Caddy-Container wird automatisch neu gestartet (~5 s Downtime für die Web-UI)

### Zertifikats-Info

Die Karte **HTTPS-Status** zeigt CN, Typ (selbstsigniert / eigenes Zertifikat), Gültigkeit, alternative Namen (SAN), Seriennummer und SHA-1-Fingerprint. Solange das Zertifikat gültig ist, werden die verbleibenden Tage angezeigt; nach Ablauf ein roter Hinweis „Abgelaufen".

## Tab: Benutzer & Rollen

Reiter **Benutzer** (nur für Admins sichtbar): Liste aller angelegten Benutzer mit E-Mail, Rolle, Aktiv-Status und Erstelldatum.

### Neuen Benutzer anlegen

- **„Benutzer anlegen"** — Benutzername, E-Mail, Passwort (mindestens 8 Zeichen), Rolle (Vorgabe Betrachter). Eine Einladung per E-Mail gibt es nicht. Die E-Mail-Adresse ist die, an die **Passwort vergessen?** den Link schickt.

### Rollen

| Rolle | Was er darf |
|-------|-------------|
| **Admin** | Alles — Benutzerverwaltung, TLS, Signing-Keys, Factory-Reset |
| **Operator** | Clients, Cloning, Rollouts, Tasks, Remote-Desktop |
| **Betrachter** | Nur lesen: Dashboard, Listen, Berichte |

### Passwort zurücksetzen

In der Zeile des Benutzers das Symbol **„Passwort zurücksetzen"**. Dialog mit neuem Passwort (≥ 8 Zeichen) + Bestätigung. Der Server setzt das Passwort direkt, schaltet eine aktive 2FA ab und beendet alle bestehenden Sitzungen des Kontos; die Person meldet sich danach mit dem neuen Passwort an.

Bei Admin-Konten und beim eigenen Konto ist das Symbol ausgegraut; auch der Server weist die Aktion dort ab. Das Passwort eines anderen Admin-Kontos setzt eine Admin-Person über **Bearbeiten** (Stift-Symbol, Feld Passwort) — mit derselben Wirkung auf 2FA und Sitzungen. Das eigene Passwort ändert jeder im Profil ([10 — Profil & 2FA](10-profil-und-2fa.md)).

Mit eingerichtetem E-Mail-Kanal (Tab **Benachrichtigungen**) kann sich jede Person über **Passwort vergessen?** auf der Login-Seite selbst einen Einmal-Link schicken lassen (siehe [10 — Profil & 2FA](10-profil-und-2fa.md#passwort-vergessen)); ohne Mailversand bleibt dieser Weg über einen Admin.

### TOTP zurücksetzen

Button **„2FA zurücksetzen"** erscheint nur, wenn der Benutzer 2FA aktiv hat. Bestätigungsdialog → der Seed wird gelöscht, ebenso ein angefangener, nie bestätigter Einrichtungsversuch; alle bestehenden Sitzungen des Kontos enden dabei (seit 2026-09-15). Die Person meldet sich wieder allein mit Passwort an und kann TOTP im Profil neu einrichten. Auf den **eigenen** User ist der Button deaktiviert — die eigene 2FA schaltest du im Profil ab ([10 — Profil & 2FA](10-profil-und-2fa.md)). Bei **Admin-Konten** ist der Button ebenfalls deaktiviert, weil der Server die Aktion dort abweist (bis zum Update vom 2026-10-01 war er klickbar und endete in einer Fehlermeldung); die 2FA eines anderen Admin-Kontos entfällt, wenn eine Admin-Person dort über **Bearbeiten** ein neues Passwort setzt (siehe oben).

### Benutzer deaktivieren / löschen

- **Deaktivieren** (Schalter **Aktiv** im Bearbeiten-Dialog) — Login gesperrt, Konto und Historie bleiben.
- **Löschen** — endgültig entfernt. Aufgaben-Vorlagen, die der Benutzer angelegt hat, bleiben erhalten — der Verweis auf den Ersteller entfällt dann lediglich; ebenso bleiben die Protokolle seiner SSH-Befehle und seine Einträge im Audit-Log stehen. Auf den eigenen Account greift der Button nicht.

Am eigenen Konto lassen sich außerdem Rolle und Aktiv-Schalter nicht ändern, damit sich niemand selbst aussperrt.

## Tab: Sicherheit

Sammelt alle kryptografischen Bereiche. Sub-Tabs:

- **HTTPS / TLS** — Web-Zertifikat (Status, selbstsigniert erstellen, eigenes hochladen; siehe oben).
- **SSH-Zugang** (Admins und Operatoren) — Server-Schlüssel (Provisioning) + Heartbeat-Token (Generieren / Rotieren / vorherige Schlüssel und Tokens). Rotieren und Löschen nur Admins.
- **Minisign-Schlüssel** — Minisign-Ed25519-Paar für Delta- und Agent-Binary-Signatur. Public-Key-Anzeige, **Key rotieren**, Zähler unsignierter Deltas mit **Alle nachsignieren**, Signaturstatus des Agent-Binarys. Generieren, Rotieren und Nachsignieren nur Admins. Beim Rotieren signiert der alte Schlüssel den neuen; die Clients übernehmen ihn automatisch per Heartbeat.
- **Vulnerability-Scan** (nur Admins) — syft + grype über alle Container-Images, Severity-Übersicht (raw vs. VEX-effective), Per-Image-CVE-Liste.
- **SBOM-Download** (nur Admins) — Download der SBOM-Artefakte pro Scan-Lauf (syft, cyclonedx, spdx).

Detaillierte Beschreibungen aller Aktionen samt Fallstricken: [12 — Sicherheit](12-sicherheit-und-cve-scan.md).

## Tab: Benachrichtigungen

Incident-Management für Client-Warnungen: Client offline, CPU, RAM oder Festplatte über dem Schwellenwert, Garantie läuft ab, Versions-Abweichung, MAC-Adresse geändert, Heartbeat abgewiesen, seit dem Update vom 2026-10-21 Agent-Integrität und Agent stumm. (Die Bedingung „Client-Fehler" ist seit dem Update vom 2026-10-01 weg — sie hing an einem Geräte-Status, den nie etwas gesetzt hat.)

**Heartbeat abgewiesen** (seit dem Update vom 2026-10-08): Der Server hat den letzten Heartbeat eines angelegten Geräts abgewiesen — zum Beispiel, weil es sich mit dem Install-Token meldet, obwohl es schon angemeldet ist (etwa nach einem Neuaufspielen außerhalb eines Deployments), oder weil eine Anmeldung von seiner Netzwerk-Herkunft aus nicht erlaubt ist, oder weil es sich mit einem Token meldet, das der Server nicht kennt (etwa nach einer abgebrochenen Neubespielung — dann hilft erst Neubespielen, **Reset auf Install Token** allein genügt nicht). Solange das anhält, meldet das Gerät keine Werte, und was der Server ihm über den Heartbeat aufträgt (etwa Updates), kommt nicht an; in der Geräteliste steht **„Install Token erkannt!"** bzw. beim unbekannten Token seit dem Update vom 2026-10-08 **„Token unbekannt!"** ([03 — Clients](03-clients.md)). Die Details des Vorfalls nennen Zeitpunkt und Grund der letzten Abweisung — auf Englisch, wie die übrigen Vorfall-Details. Der Server prüft alle fünf Minuten: der Vorfall löst sich von selbst, sobald der Server wieder einen Heartbeat des Geräts angenommen hat oder ein Admin **Reset auf Install Token** gewählt hat. Wie bei den übrigen Bedingungen unterdrückt ein Wartungsfenster nur die Benachrichtigung, und Geräte im Lager lösen keinen Vorfall aus. Heartbeats unbekannter MAC-Adressen erzeugen keinen Vorfall.

**MAC-Adresse geändert** (seit dem Update vom 2026-10-08 mit beiden Adressen): Ein Gerät meldet eine andere MAC-Adresse als die registrierte — meist nach dem Tausch der Netzwerkkarte. Admins übernehmen die neue Adresse mit **MAC übernehmen** direkt am Vorfall oder in der Detailansicht des Geräts; DHCP-Reservierung, PXE-Startdateien und Wake-on-LAN ziehen mit, der Hostname bleibt ([03 — Clients](03-clients.md#neue-netzwerkkarte)). Der Vorfall löst sich mit der Übernahme und von selbst, sobald das Gerät wieder die registrierte Adresse meldet. Er entsteht auch, wenn der Agent meldet, dass der auf dem Gerät gespeicherte Hostname von einer anderen Netzwerkkarte stammt (etwa eine Festplatte aus einem anderen Gerät) — dann gibt es nichts zu übernehmen, und ein Admin bestätigt stattdessen mit **MAC bestätigen** die registrierte Adresse, wenn der Stand so gewollt ist (am Vorfall heißt der Knopf seit dem Update vom 2026-10-08 in diesem Fall ebenfalls **MAC bestätigen**, vorher immer **MAC übernehmen**). Übernehmen und Bestätigen merken sich Adresse und gespeicherten Hostnamen: derselbe Stand öffnet danach keinen Vorfall mehr (der Hostname bleibt nach einer Übernahme der alte), eine andere Adresse oder ein anderer gespeicherter Hostname schon. Wie die übrigen Bedingungen prüft der Server alle fünf Minuten: der Vorfall erscheint spätestens fünf Minuten nach der ersten Meldung des Geräts und benachrichtigt über die eingerichteten Kanäle, ein Wartungsfenster unterdrückt nur die Benachrichtigung, und Geräte im Lager lösen keinen Vorfall aus.

**Agent-Integrität** (seit dem Update vom 2026-10-21, Agent 2.27.0): Der Agent eines Geräts hat etwas abgewiesen oder repariert — etwa ein Update, ein Zertifikat oder einen Schlüssel mit ungültiger Signatur, oder eine veränderte systemd-Unit —, oder der Server hat beim Abgleich festgestellt, dass Agent-Binary, Agent-Version oder Signierschlüssel des Geräts nicht seinem Stand entsprechen ([03 — Clients](03-clients.md#agent-ereignisse)). Der Vorfall steht, solange das Gerät offene Agent-Ereignisse hat; die Details nennen das jüngste als englischen Katalogsatz (auf Englisch wie die übrigen Vorfall-Details; die Karte der Geräteansicht formuliert einige Ablehnungen ausführlicher) und die Zahl der übrigen. Einmalige Ereignisse schließt ein Admin mit **Quittieren** in der Karte „Agent-Ereignisse“ der Geräteansicht, anhaltende Zustände enden, sobald das Gerät sie nicht mehr meldet; ist nichts mehr offen, löst sich der Vorfall bei der nächsten Prüfung. **Lösen** hier schließt die Ereignisse nicht — solange eines offen ist, öffnet die nächste Prüfung einen neuen Vorfall. Den Weg zur Geräteansicht zeigt der Knopf **Zum Gerät** am Vorfall. Eine Unit, die direkt nach einer Neubespielung, einem Rollback oder einem Agent-Update repariert wurde, öffnet keinen Vorfall.

**Agent stumm** (seit dem Update vom 2026-10-21): Das Gerät schickt keinen Heartbeat mehr, antwortet aber auf Ping — der Agent ist gestoppt, entfernt oder hängt, oder er erreicht den Server nicht. Nach fünf Minuten ohne Heartbeat markiert der Server das Gerät als stumm (Chip „Agent stumm“ in der Geräteliste, der Status steht auf „Offline“), nach weiteren 15 Minuten öffnet er den Vorfall; die 15 Minuten fangen ein Gerät ab, das beim Herunterfahren noch ein Update anwendet. Einen Vorfall „Client offline“ gibt es für ein stummes Gerät nicht. Der Vorfall löst sich mit dem nächsten Heartbeat oder wenn das Gerät auch auf Ping nicht mehr antwortet (dann ist es ein gewöhnliches Offline-Gerät). Auch hier führt **Zum Gerät** in die Geräteansicht; **Lösen** allein bringt den Vorfall bei der nächsten Prüfung zurück. Weist der Server die Heartbeats eines Geräts ab („Heartbeat abgewiesen“), gilt es nicht als stumm — es meldet sich ja, wird nur abgewiesen: es geht wie jedes Gerät ohne Heartbeat nach fünf Minuten auf „Offline“, aber ohne Chip „Agent stumm“ und ohne diesen Vorfall, und eine schon gesetzte Stumm-Markierung fällt weg (seit dem Nachtrag vom 2026-10-21; vorher standen beide Vorfälle nebeneinander).

Für beide gilt wie für die übrigen Bedingungen: der Server prüft alle fünf Minuten und benachrichtigt über die eingerichteten Kanäle, ein Wartungsfenster unterdrückt nur die Benachrichtigung, Geräte im Lager lösen keinen Vorfall aus. Einen Schwellenwert haben die beiden nicht — in der Konfiguration ist für sie nichts einzustellen.

- **Aktive Vorfälle** — offene Vorfälle. Pro Zeile: Client, Bedingung, Details, Status, Aufgetreten, Zahl der Benachrichtigungen. **Bestätigen** (bleibt offen) oder **Lösen** (schließen mit optionalem Hinweis) — Admin oder Operator; Betrachter sehen die Knöpfe seit dem Update vom 2026-10-08 nicht mehr. Seit dem Update vom 2026-10-21 heißt bestätigt auch „gesehen“: für einen bestätigten Vorfall kommen keine weiteren Benachrichtigungen, solange er steht — vorher meldete ihn jeder Benachrichtigungs-Cooldown erneut. Einzige Ausnahme ist „Agent-Integrität“: kommt nach der Bestätigung ein neues Agent-Ereignis dazu, ist der Vorfall wieder aktiv und meldet sofort. An den Vorfällen „Agent-Integrität“ und „Agent stumm“ führt **Zum Gerät** in die Geräteansicht (jede Rolle).
- **Verlauf** — geschlossene Vorfälle mit Zeitpunkt der Lösung.
- **Konfiguration** (die Schwellenwerte sieht jede Rolle, die Kanäle Admins und Operatoren; Speichern und Testen nur Admins — seit dem Update vom 2026-10-08 sind die Felder ohne Admin-Rolle schreibgeschützt, Speichern und Testen fehlen, und Betrachter sehen statt der Kanäle einen Hinweis):
  - **Schwellenwerte**: CPU, RAM und Festplatte in Prozent, Garantie-Vorwarnung in Tagen, „Offline nach" und Benachrichtigungs-Cooldown in Minuten. Die **Garantie-Vorwarnung** (1–36 500 Tage, Vorgabe 30) gilt seit dem Update vom 2026-10-03 überall, wo „Garantie läuft ab" steht: beim Alarm, auf dem Dashboard, in der Geräteliste (Reiter Garantie) und im Lebenszyklus-Bericht — vorher rechneten Dashboard und Geräteliste fest mit 30 Tagen. Die Garantiedauer selbst steht je Gerät unter „Garantie (Monate)". Werte außerhalb der erlaubten Bereiche (Prozent über 0 bis 100, Garantie-Vorwarnung und Minuten als ganze Zahl) markiert das Formular rot, gespeichert wird dann nicht.
  - **E-Mail-Kanal** (einschaltbar): SMTP-Host, -Port, -Benutzername, -Passwort, Absender-Adresse, TLS/STARTTLS, Empfänger; ohne TLS/STARTTLS (und nicht über Port 465) dazu **Anmeldung ohne Verschlüsselung erlauben** — verlangt der Mailserver Benutzername und Passwort, schickt ThinForge sie unverschlüsselt nur mit diesem Haken, sonst schlägt der Versand fehl (**Testen** nennt dann die beiden Haken, die das beheben: **TLS/STARTTLS verwenden** oder **Anmeldung ohne Verschlüsselung erlauben**); ist er gesetzt, warnt die Karte, denn wer im LAN mitliest, kann sich mit den Zugangsdaten am Mailserver anmelden (seit dem Update vom 2026-10-08, vorher ließ sich die Freigabe nicht setzen); ein Port außerhalb 1–65535 wird beim Speichern abgewiesen; steht aus früheren Versionen noch ein solcher Wert in der Datenbank, zeigt die Karte den Port, über den tatsächlich versendet wird (587), und das nächste Speichern schreibt ihn fest. Ein hinterlegtes Passwort zeigt das Feld nur maskiert und schreibgeschützt, mit **Ändern** (leert das Feld für ein neues Passwort — bleibt es leer, gilt beim Speichern weiter das gespeicherte), **Entfernen** (löscht es beim Speichern) und **Abbrechen**; seit dem Update vom 2026-10-16, vorher ließ es sich ersetzen, aber nicht entfernen. Steht danach noch ein SMTP-Benutzername da, versendet der Kanal nichts, **Testen** sagt, dass das Passwort fehlt, und der Login-Bildschirm bietet **Passwort vergessen?** nicht mehr an — nimmt der Mailserver Mails ohne Anmeldung an, auch den Benutzernamen leeren. **Testen** versendet eine Testnachricht. Ist der Kanal eingeschaltet, nennt einen SMTP-Host und — mit Benutzername — ein Passwort, und verbindet er dann mit TLS/STARTTLS (oder über Port 465) oder ist **Anmeldung ohne Verschlüsselung erlauben** gesetzt, verschickt der Server darüber auch die Links von **Passwort vergessen?** ([10 — Profil & 2FA](10-profil-und-2fa.md#passwort-vergessen)); sonst verschwindet der Link vom Login-Bildschirm (die Bedingung zur Verschlüsselung seit dem Update vom 2026-10-18 — vorher erschien der Link, und der Versand schlug fehl).
  - **Webhook-Kanal** (einschaltbar): URL, HTTP-Methode, Secret (Header `X-ThinForge-Secret`), weitere HTTP-Header. **Testen** schickt einen Testaufruf. Die URL muss direkt auf den Empfänger zeigen: Weiterleitungen (HTTP 3xx) werden nicht verfolgt und gelten als Fehlschlag, damit das Webhook-Geheimnis nie an einen anderen Rechner geht. Seit dem Update vom 2026-10-14 liegt die URL verschlüsselt in der Datenbank wie das Secret — bei Slack, Microsoft Teams und ähnlichen Diensten trägt sie das Zugangs-Token. Eine gespeicherte URL zeigt das Feld deshalb nur mit Schema und Host (etwa `https://hooks.slack.com/…`) und schreibgeschützt: **Ändern** leert das Feld für eine neue Adresse (bleibt es leer, gilt beim Speichern weiter die gespeicherte), **Entfernen** löscht sie beim Speichern, **Abbrechen** nimmt beides zurück. Eine neue URL muss vollständig mit `http://` oder `https://` und Hostnamen eingegeben werden, sonst weist **Speichern** sie ab und speichert nichts. Das Secret zeigt das Feld ebenso nur maskiert, mit denselben drei Knöpfen (seit dem Update vom 2026-10-16); ohne Secret geht der Aufruf ohne den Header `X-ThinForge-Secret` hinaus. Die Werte der weiteren HTTP-Header erscheinen als `••••`: leer gelassen oder unverändert gilt weiter der gespeicherte Wert, das Papierkorb-Symbol entfernt den Header samt Wert.
  - Jedes Speichern der Schwellenwerte oder Kanäle, das etwas ändert, steht seit dem Update vom 2026-10-16 im Audit-Log (**Alarm-Schwellenwerte geändert** bzw. **Benachrichtigungskanäle geändert**, [08 — Tasks & Logs](08-tasks-logs.md)) — mit Konto, Absenderadresse und den Namen der geänderten Felder, nie mit ihren Werten. Speichern ohne Änderung schreibt keinen Eintrag.

Lassen sich die gespeicherten Schwellenwerte oder Kanäle beim Öffnen nicht abrufen (etwa während das Backend neu startet), zeigt die Konfiguration einen Fehlerhinweis mit dem Grund und dem Knopf **Erneut abrufen**; das zugehörige **Speichern** bleibt gesperrt, bis ein Abruf gelingt (seit dem Update vom 2026-10-08). Vorher standen in den Feldern dann nur Vorgabewerte, und Speichern ersetzte die gespeicherte Konfiguration durch sie — bei den Kanälen hieß das: beide ausgeschaltet, SMTP-Host und -Benutzer, Absender, Empfänger, URL und Webhook-Header weg.

**Testen** verschickt über den zuletzt **gespeicherten** Stand des Kanals, nicht über das, was gerade im Formular steht — erst speichern, dann testen. Scheitert der Versand, nennt die Meldung seit dem Update vom 2026-10-08 den Grund: etwa „Im E-Mail-Kanal ist kein Empfänger eingetragen“, die Antwort des Mailservers, den HTTP-Status des Webhook-Empfängers oder die Ursache eines gescheiterten Aufrufs wie `Connection refused`. Passwort, Secret, Header-Werte und die Webhook-URL stehen nicht darin. Derselbe Grund steht als Warnung im Server-Log. Vorher hieß es nur „Senden fehlgeschlagen — Logs prüfen“, und im Log stand nichts.

Passwort, Secret und die Werte der Header speichert ThinForge seit dem Update vom 2026-10-10 verschlüsselt ([14 — Datenschutz](14-datenschutz.md#vorfälle-und-benachrichtigungen)). Lässt sich ein gespeicherter Wert nicht mehr entschlüsseln — etwa nach einer Wiederherstellung, deren Umschlüsselung scheiterte —, nennt **Testen** das betroffene Feld, und der Kanal sendet keine Alarme, bis du den Wert neu eingibst und speicherst.

Ohne eingeschalteten Kanal werden Incidents nur in der UI sichtbar — keine Push-Benachrichtigung.

## Tab: Wartungsfenster

Seit dem Update vom 2026-09-30 in der Oberfläche; sichtbar für **Admin und Operator** (auch das Lesen verlangt eine dieser Rollen). Während ein Wartungsfenster greift, unterdrückt ThinForge die Alarme für die betroffenen Geräte, und das Dashboard zeigt es als Hinweis über den Kacheln.

- **Liste** — Name, Geltungsbereich (alle Geräte oder eine Auswahl), Beginn, Ende, Wiederholung und Status (**Aktiv**, **Bevorstehend** — bei wiederkehrenden Fenstern bis zum Ende der Wiederholung —, **Vergangen**). Je Zeile **Bearbeiten** und **Löschen**.
- **Anlegen / Bearbeiten** — Name, Beschreibung, Beginn und Ende, Geltungsbereich (**Alle Clients** oder **Bestimmte Clients** mit Geräteauswahl, filterbar nach Gruppe) und optional eine **Wiederholung**: täglich, wöchentlich (Wochentage) oder monatlich (Tage im Monat), mit optionalem Ende. Alle Zeiten gelten in der Server-Zeitzone (Tab **Allgemein**), auch Wochentage und Wiederholungen.
- Ein gespeichertes **Wiederholungsende** lässt sich beim Bearbeiten nur verschieben, nicht entfernen — soll das Fenster unbegrenzt weiterlaufen, es neu anlegen und das alte löschen.

## Tab: Remote Desktop

Vorgaben für Remote-Desktop-Sitzungen. Den Reiter sehen Admins und Operatoren (Betrachter seit dem Update vom 2026-10-08 nicht mehr — sie dürfen die Werte nicht lesen). Ändern dürfen nur Admins; Operatoren sehen die Werte schreibgeschützt — die Standard-Qualität gilt auch für die Sitzungen, die sie öffnen (seit dem Update vom 2026-09-30; vorher bekamen sie hier einen Ladefehler, und ihre Sitzungen starteten immer mit VDSL):

- **Standard-Qualität** — mit welcher Voreinstellung (DSL, VDSL oder LAN) eine Sitzung startet
- **Idle-Timeout** — nach so vielen Sekunden ohne Eingabe wird eine Sitzung getrennt; erlaubt sind 30 bis 86400 Sekunden (24 Stunden)
- **Max. parallele Sitzungen / Client** — erlaubt sind 1 bis 50 Sitzungen je Gerät

Neue Werte gelten ab der nächsten Sitzung. Bis zum Update vom 2026-09-23 bedeutete 0 „unbegrenzt" — wer mit 0 sperren wollte, hob die Grenze in Wahrheit auf. Heute weist das Feld 0 ab. Eine früher gespeicherte 0 zeigt die Seite als wirksamen Wert an — beim Idle-Timeout 86400 (24 Stunden), bei den Sitzungen die Vorgabe 5 —, bis du einmal speicherst.

Lassen sich die gespeicherten Werte beim Öffnen nicht abrufen (etwa während das Backend neu startet), zeigt der Reiter einen Fehlerhinweis mit dem Grund und dem Knopf **Erneut abrufen**. In den Feldern stehen dann nur Vorgabewerte (VDSL, 900 Sekunden, 5 Sitzungen). **Speichern** bleibt deshalb gesperrt, bis ein Abruf gelingt: Speichern schickt immer alle Werte auf einmal und würde die gespeicherten sonst durch die Vorgaben ersetzen.

## Tab: Abonnement

Admin-Ansicht des aktuellen Abonnementstatus + Upload (**„Hochladen und aktivieren"**) oder **„Abonnement entfernen"** einer `.7z`-Abonnementdatei. Abonnementdateien kommen vom Hersteller.

Detailbeschreibung (Zustände, VPN-Sitzplätze, Fehlercodes): [11 — Abonnement](11-lizenz.md).

## Tab: General (Allgemein)

Einstellungen, die woanders keinen guten Platz hatten. Der Tab hat zwei Karten, jede mit eigenem **Speichern**. Lesen darf jede Rolle, speichern nur Admins; ohne Admin-Rolle sind beide Karten seit dem Update vom 2026-10-08 schreibgeschützt und ohne Speichern-Knopf.

Lassen sich die gespeicherten Werte einer Karte beim Öffnen nicht abrufen (etwa während das Backend neu startet), zeigt sie einen Fehlerhinweis mit dem Grund und dem Knopf **Erneut abrufen**; ihr **Speichern** bleibt gesperrt, bis ein Abruf gelingt (seit dem Update vom 2026-10-08). Vorher standen in den Feldern dann nur Vorgabewerte, und wer danach eine Einstellung änderte, überschrieb beim Speichern auch die übrigen der Karte mit ihnen — etwa die Aufbewahrung des Audit-Logs mit 365 Tagen oder die Zeitserver mit den beiden Pool-Servern.

### Karte „Allgemeine Einstellungen"

- **Sitzungsdauer** — nach welcher Inaktivität eine Anmeldung abläuft (gleitendes Zeitfenster; 1 Stunde bis 30 Tage, Standard 7 Tage)
- **Aufbewahrung des Audit-Logs** — nach wie vielen Tagen Einträge des Audit-Logs gelöscht werden (Vorgabe 365, erlaubt 30 bis 3650; außerhalb davon ist **Speichern** gesperrt, und der Server weist den Wert ab). Der Worker löscht einmal täglich und bei jedem Neustart; ein Lauf, der etwas gelöscht hat, steht selbst im Audit-Log (siehe [08 — Tasks & Logs](08-tasks-logs.md#audit-log-aufbewahrung)). Ändern dürfen nur Admins. Die Aufbewahrung kam mit dem Update vom 2026-09-15 hinzu; der erste Worker-Start danach löscht sofort alle Einträge, die älter als 365 Tage sind — vorher löschte ThinForge nie etwas aus dem Audit-Log.
- **Aufbewahrung weiterer Verlaufsdaten** — nach wie vielen Tagen der Worker drei weitere Verläufe löscht, jeweils erlaubt 30 bis 3650 Tage (außerhalb davon ist **Speichern** gesperrt, und der Server weist den Wert ab):
  - **SSH-Befehlsprotokolle** — Befehl, Ausgabe und auslösendes Konto jedes Befehls, den der Server per SSH auf einem Gerät ausgeführt hat; gezählt ab der Ausführung, Vorgabe 90 Tage.
  - **Gelöste Vorfälle** — gezählt ab der Lösung, Vorgabe 365 Tage. Offene und quittierte Vorfälle bleiben, gleich wie alt. Seit dem Update vom 2026-10-21 gilt dieselbe Dauer für geschlossene Agent-Ereignisse (quittiert oder nicht mehr gemeldet, gezählt ab dem Schließen; offene bleiben); ein Lauf, der welche gelöscht hat, steht als „Alte geschlossene Agent-Ereignisse gelöscht“ im Audit-Log.
  - **Beendete DHCP-Leases** — der Verlauf der Adressvergaben, gezählt ab dem Ende der Lease, Vorgabe 90 Tage. Aktive Leases bleiben.

  Gelöscht wird wie beim Audit-Log einmal täglich und bei jedem Neustart; jeder Lauf, der etwas gelöscht hat, steht als „Alte SSH-Befehlsprotokolle gelöscht", „Alte gelöste Vorfälle gelöscht" bzw. „Alte DHCP-Leases gelöscht" mit Anzahl und Stichtag im Audit-Log. Berichte über ältere Zeiträume (Aktivität, Vorfälle, DHCP, Nutzung) zählen danach nur noch, was aufbewahrt ist. Ändern dürfen nur Admins. Die Aufbewahrung kam mit dem Update vom 2026-10-09 hinzu; der erste Worker-Start danach löscht sofort, was älter als die Vorgaben ist — vorher löschte ThinForge nichts davon.
- **Sprache der Geräte-Dialoge** — in welcher Sprache die Geräte ihre eigenen Hinweise zeigen: den Countdown vor dem Neustart nach einem Update (Titel, Text und die Knöpfe **Jetzt neu starten** und **Abbrechen**) und die Anzeige „Remote-Sitzung aktiv“ während einer Fernsteuerung. **Deutsch** (Vorgabe) oder **Englisch**; die Geräte übernehmen die Wahl mit ihrem nächsten Heartbeat, ein schon angezeigter Dialog bleibt in seiner Sprache. Die Sprache dieser Oberfläche ist davon unabhängig (Umschalter in der Kopfleiste). Ändern dürfen nur Admins; eine Änderung steht als „Allgemeine Einstellungen geändert“ im Audit-Log. Die Einstellung kam mit dem Update vom 2026-10-10 hinzu — vorher waren die Dialoge immer deutsch. Titel und Neustart-Knopf des Countdowns übersetzen erst Agenten ab Version 2.26.0; ältere zeigen dort in beiden Sprachen „ThinForge Update“ und „Reboot Now“.

### Karte „Zeitserver (NTP)"

Einen eigenen Tab „NTP" gibt es nicht — die Zeitquellen und die Zeitzone stehen in dieser Karte. Chrony läuft im `network`-Profil und stellt sicher, dass der Server-Host (und daraus abgeleitet alle Clients) auf der korrekten Zeit liegen.

- **Upstream NTP-Server** — Liste von NTP-Servern (z. B. `0.pool.ntp.org`, interne Server). Mindestens einer muss eingetragen sein, sonst ist **Speichern** gesperrt.
- **Zeitzone** — die Betriebszeitzone, siehe unten.

Speichern dürfen nur Admins.

Uhr-Qualität (Stratum) oder Abweichung (Offset) zeigt die Karte nicht an. Haben sich beim Speichern die Server geändert, schreibt ThinForge die Chrony-Config neu und startet den Chrony-Container neu; eine reine Zeitzonen-Änderung lässt Chrony unberührt. Scheitert der Neustart, wird trotzdem „gespeichert" gemeldet — die neuen Server greifen dann erst nach einem Neustart von Hand (Tab Dienste, Chrony).

### Zeitzone

Zu den NTP-Einstellungen gehört die **Betriebszeitzone** (Vorgabe `Europe/Berlin`). In ihr gelten:

- Uhrzeit und Wochentage von Aufgaben-Vorlagen,
- Beginn, Ende, Wochentage und Monatstage wiederkehrender Wartungsfenster,
- die Uhrzeit geplanter Deployments (Eingabe und Anzeige),
- „heute" bei Garantie-Alarmen und die Tages- und Wochenraster der Berichte,
- seit dem Update vom 2026-10-01 alle Zeitangaben der Oberfläche (Protokolle, Aufträge, Berichte, Zeitpunkte an Geräten und Sicherungen). Läuft der Browser in einer anderen Zeitzone, steht hinter jeder Uhrzeit das Kürzel der Server-Zone (etwa „MESZ"); vorher zeigten diese Stellen die Zeit des Browsers.

Eingestellt wird sie hier im Feld **Zeitzone** (IANA-Name wie `Europe/Vienna`; unbekannte Namen weist der Server beim Speichern ab). Die Geräte übernehmen die Zone mit dem nächsten Heartbeat. Die Zeitzone des Server-Wirts selbst setzt `install-deps.sh`; das Feld ändert sie nicht. Die erste Wahl trifft der Setup-Assistent (Schritt NTP, vorbelegt mit `Europe/Berlin`); hier lässt sie sich jederzeit ändern.

Zeitumstellung: Eine Vorlage um 02:30 läuft am Tag der Umstellung auf Sommerzeit um 03:00, am Tag der Umstellung auf Winterzeit genau einmal.

Bis zum Update vom 2026-09-15 rechneten Aufgaben-Vorlagen ungewollt in UTC und liefen im Sommer zwei Stunden später als eingetragen; seitdem laufen sie zur eingetragenen Ortszeit — also früher als gewohnt. Wiederkehrende Wartungsfenster verschoben sich über die Zeitumstellung um eine Stunde und lagen nachts teils am falschen Wochentag; auch sie gelten jetzt in Ortszeit.

## Backup & Restore

Backup & Restore liegt **nicht** unter Einstellungen, sondern im Bereich **Info & Backup**, Tab **Backup & Restore**. Dort erzeugst du Sicherungen des ThinForge-Zustands für Disaster-Recovery. Alle Aktionen dort — auch das Anzeigen der vorhandenen Sicherungen — sind Admins vorbehalten; seit dem Update vom 2026-10-08 sehen andere Rollen den Tab gar nicht mehr (vorher endete schon sein Öffnen in einer Fehlermeldung).

- **„System-Backup erstellen"** — Datenbank, Konfiguration und Schlüssel; klein, in Sekunden fertig, als Datei zum Download. Der Dialog fragt nach einem **Passwort für die Sicherung (optional)**, mindestens 8 Zeichen: mit Passwort wird das ganze Archiv verschlüsselt (`system-<Zeit>.tar.gz.enc`, Schloss-Symbol in der Liste). Ohne Passwort entsteht wie bisher ein offenes `system-<Zeit>.tar.gz` — es enthält **alle Schlüssel der Anlage im Klartext** (Verschlüsselungsschlüssel der Datenbank, Anmelde-, Signier-, SSH- und TLS-Schlüssel); wer die Datei bekommt, hat die Schlüssel. Ablage und Transport dann entsprechend schützen. Ein vergessenes Passwort lässt sich nicht wiederherstellen — die Sicherung ist dann nicht mehr zu öffnen.
- **„Daten-Backup starten"** — Clones und Deltas; läuft im Hintergrund und kann je nach Datenmenge Stunden dauern. Daten-Sicherungen enthalten keine Schlüssel und haben keine Passwortoption.
- **„Backup wiederherstellen"** — eine oder beide Dateien wählen, Überschreiben bestätigen und mit dem eigenen Passwort freigeben. Ist eine System-Sicherung verschlüsselt, fragt ihre Karte nach dem **Passwort der Sicherung** und prüft sie damit vollständig, bevor etwas zurückgespielt wird; ein falsches Passwort meldet sie am Feld. Sicherungen ohne Passwort — auch alle älteren — spielen sich wie bisher zurück. **Vorsicht**: überschreibt die laufende Installation. Nach dem Wiederherstellen eines System-Backups starten alle Geräte wieder lokal; Deployments und Aufnahmen, die zum Zeitpunkt der Sicherung liefen oder geplant waren, werden dabei beendet (Hinweis „durch Wiederherstellung ungueltig" am Gerät) und müssen bei Bedarf neu angestoßen werden.

Automatische, zeitgesteuerte Backups gibt es nicht — jede Sicherung entsteht auf Knopfdruck.

### Aufbewahrung

Ältere Sicherungen räumt ThinForge selbst weg: in der Karte **„Aufbewahrung"** stellst du getrennt für System- und Daten-Sicherungen ein, wie viele der neuesten bleiben — Vorgabe je **3**, erlaubt 0 bis 100, **0 = unbegrenzt** (nichts wird gelöscht).

- Gelöscht wird direkt nach jeder **erfolgreichen** Sicherung, und zwar nur Sicherungen derselben Art; die eben erstellte bleibt immer. Die Meldung nach dem Erstellen nennt, wie viele ältere dabei gelöscht wurden. Eine fehlgeschlagene oder abgebrochene Sicherung löscht nichts.
- Setzt du einen Wert **herab**, löscht ThinForge die überzähligen älteren Sicherungen dieser Art **sofort beim Speichern** — vorher fragt die Seite nach und nennt die Zahl. Heraufsetzen oder 0 löscht nichts.
- Gezählt und gelöscht werden nur Dateien mit ihrem ursprünglichen Namen (`system-<Zeit>.tar.gz`, `system-<Zeit>.tar.gz.enc`, `data-<Zeit>.tar`). Eine Sicherung, die du dauerhaft behalten willst, benennst du im Sicherungsordner um (etwa `system-vor-update.tar.gz`) — sie bleibt dann in der Liste, zählt aber nicht mit und wird nie gelöscht. Wichtige Sicherungen gehören ohnehin zusätzlich auf ein anderes Medium.
- Jede automatische Löschung steht im Audit-Log (**„Sicherung durch Aufbewahrung gelöscht"**, mit Dateiname und Größe), eine Änderung des Werts als **„Aufbewahrung der Sicherungen geändert"**.
- Nach dem Update gilt die Vorgabe 3 auch für eine bestehende Anlage: lagen mehr Sicherungen einer Art im Ordner, löscht die nächste Sicherung dieser Art die älteren. Wer mehr behalten will, stellt den Wert vorher hoch oder auf 0.
- Die Einstellung gehört zur Anlage selbst; das Wiederherstellen einer System-Sicherung ändert sie nicht.

### Abgebrochene Sicherungen

Eine Sicherung schreibt zuerst in eine Zwischendatei (`<Name>.tmp`) und benennt sie erst am Ende um. Wird ThinForge mitten in einer Sicherung neu gestartet (Update, Neustart des Servers, Speichermangel), bleibt diese unfertige Datei im Sicherungsordner liegen — bei Daten-Sicherungen oft viele Gigabyte. Sie erscheint nicht in der Liste und zählt nicht zur Aufbewahrung. ThinForge räumt solche Reste selbst weg:

- Reste von Daten-Sicherungen (`data-<Zeit>.tar.tmp`) beim Start des Worker-Dienstes und unmittelbar vor jeder neuen Daten-Sicherung — aber nur, solange keine andere Daten-Sicherung läuft.
- Reste von System-Sicherungen (`system-<Zeit>.tar.gz.tmp`, `system-<Zeit>.tar.gz.enc.tmp`) beim Start des Servers, bevor er Anfragen annimmt.
- Gelöscht werden nur unfertige Dateien mit dem ursprünglichen Namen und der Endung `.tmp`; fertige Sicherungen, umbenannte Dateien und alles andere im Ordner bleiben.
- Jede Löschung steht im Audit-Log (**„Rest einer abgebrochenen Sicherung gelöscht"**, mit Dateiname, Größe und Anlass). Beim ersten Start nach dem Update verschwinden so auch Reste, die schon länger im Ordner liegen.
- Eine abgebrochene Sicherung lässt sich nicht fortsetzen — sie muss neu gestartet werden.

## Tab: Werkeinstellungen

Reißt den gesamten ThinForge-Zustand ab: Postgres-Tabellen (auch alle Benutzerkonten), Redis, Storage-Dir, Secrets. **Nicht rückgängig zu machen.** Erforderlich sind das Kontrollkästchen, das eigene Passwort und ein Bestätigungsdialog; danach führt der Setup-Assistent durch die Neueinrichtung.

Einsatzfall: Test-Server zurück auf Auslieferungszustand, bevor dieser ausgeliefert wird.

## Nächste Schritte

- [08 — Tasks & Logs](08-tasks-logs.md) — wenn Einstellungs-Änderungen nicht so wirken wie erwartet
- [workflows/golden-image.md](workflows/golden-image.md) — nach Zertifikats-Erneuerung die Cloning-VM neu starten, damit die Tools-ISO neu gebaut wird
