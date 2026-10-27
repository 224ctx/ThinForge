# 10 — Profil & Zwei-Faktor-Authentisierung

Jeder angemeldete Benutzer hat über das Benutzermenü oben rechts Zugriff auf sein **Profil**. Dort lassen sich das eigene Passwort ändern, die Rolle einsehen und — falls noch nicht aktiv — eine **Zwei-Faktor-Authentisierung (TOTP)** einrichten.

Admins können zusätzlich in [09 — Einstellungen → Benutzer](09-einstellungen.md#tab-benutzer--rollen) für andere Personen Passwörter und 2FA-Seeds zurücksetzen; bei anderen Admin-Konten geht das nur über **Bearbeiten** mit einem neuen Passwort.

## Profil öffnen

- Klick auf das Konto-Symbol oben rechts (das Menü zeigt Benutzername und Rolle) → **Profil**
- Direkt-URL: `/profile`

Die Ansicht besteht aus drei Karten: **Kontoinformationen** (Benutzername, E-Mail, Rolle), **Passwort ändern**, **Zwei-Faktor-Authentifizierung (2FA)**.

## Eigenes Passwort ändern

Karte **Passwort ändern**:

1. Aktuelles Passwort eingeben.
2. Neues Passwort (mindestens 8 Zeichen) eingeben.
3. Bestätigung wiederholen — muss zeichengenau übereinstimmen.
4. **Passwort ändern** klicken.

Bei Erfolg verschwinden die Eingaben, die Meldung „Passwort wurde erfolgreich geändert" erscheint als Snackbar. Aus Sicherheitsgründen enden dabei alle **anderen** Sitzungen deines Kontos — in anderen Browsern oder auf anderen Rechnern musst du dich mit dem neuen Passwort neu anmelden. Die Sitzung, in der du das Passwort geändert hast, bleibt angemeldet.

Schlägt die Änderung fehl, nennt die Karte den Grund — etwa „Das aktuelle Passwort ist falsch.", ein zu kurzes neues Passwort, einen nicht erreichbaren Server oder zu viele Anfragen; der neue Wert wird dann nicht übernommen. (Bis zum Update vom 2026-09-30 stand dort bei jedem Fehlschlag „Das aktuelle Passwort ist falsch".)

## Zwei-Faktor-Authentisierung aktivieren

TOTP schützt den Account zusätzlich mit einem zeitbasierten 6-stelligen Code aus einer Authenticator-App (z. B. Aegis, FreeOTP, Google Authenticator). Der Server generiert dafür ein Secret und zeigt es als QR-Code.

Ablauf:

1. Karte **Zwei-Faktor-Authentifizierung (2FA)** → **2FA aktivieren**; darunter erscheint die Karte **2FA einrichten**.
2. Der Server liefert QR-Code + Secret (manueller Schlüssel, Base32). QR-Code mit der Authenticator-App scannen **oder** das alphanumerische Secret manuell eingeben (z. B. wenn die App keinen QR-Scan unterstützt). Bis zum Update vom 2026-10-01 erschien an Stelle des QR-Codes nur ein kaputtes Bild; dann blieb nur die manuelle Eingabe.
3. **Weiter** → 6-stelligen Code aus der App in das Eingabefeld übertragen.
4. **2FA aktivieren** bestätigt den Code.

Nach erfolgreicher Aktivierung zeigt die Karte den Status **aktiviert** (grüner Chip) und der nächste Login verlangt nach dem Passwort zusätzlich den 6-stelligen Code.

Schlägt die Aktivierung fehl, nennt die Karte den Grund — ein falscher Code, eine abgelaufene Einrichtung (dann mit **2FA aktivieren** neu beginnen), ein nicht erreichbarer Server oder zu viele Anfragen. (Bis zum Update vom 2026-09-30 stand dort bei jedem Fehlschlag „Ungültiger Code".)

> **Tipp:** Den Secret-String oder einen Screenshot des QR-Codes **einmalig** an einem sicheren Ort (Passwort-Manager, verschlüsselter Container) ablegen, damit bei Geräteverlust die Einrichtung auf einem neuen Endgerät möglich bleibt. Die App zeigt das Secret später nicht mehr.

## 2FA deaktivieren

- Karte **Zwei-Faktor-Authentifizierung (2FA)** → **2FA deaktivieren**.
- Dialog fragt nach dem aktuellen Passwort **und** einem gültigen aktuellen TOTP-Code.
- Nach Bestätigung ist der zweite Faktor entfernt.
- Schlägt es fehl, nennt der Dialog den Grund: falsches Passwort, falscher Code oder ein Server- bzw. Netzfehler; der zweite Faktor bleibt dann aktiv.

Ist der Code nicht mehr verfügbar (z. B. verlorenes Smartphone), muss ein Admin in den Einstellungen `/settings?tab=users` den TOTP-Seed des Users zurücksetzen — siehe [09 — Einstellungen → TOTP zurücksetzen](09-einstellungen.md#totp-zurücksetzen). Für ein Admin-Konto lehnt der Server das ab; dort setzt eine andere Admin-Person über **Bearbeiten** ein neues Passwort, was die 2FA ebenfalls abschaltet.

## Passwort vergessen

Der Link **Passwort vergessen?** erscheint auf dem Login-Bildschirm, sobald der Server Mails verschicken kann — also wenn unter Einstellungen → Benachrichtigungen der **E-Mail-Kanal** eingeschaltet ist, einen SMTP-Host nennt und — ist dort ein SMTP-Benutzername eingetragen — auch ein Passwort hinterlegt hat und entweder **TLS/STARTTLS verwenden** (bzw. Port 465) oder **Anmeldung ohne Verschlüsselung erlauben** gesetzt ist ([09 — Einstellungen → Benachrichtigungen](09-einstellungen.md#tab-benachrichtigungen)). Fehlt zum Benutzernamen das Passwort (seit dem Update vom 2026-10-16) oder fehlen Verschlüsselung und Freigabe (seit dem Update vom 2026-10-18), bietet der Login-Bildschirm den Link nicht an — über den Kanal ginge dann keine Mail hinaus. Über denselben Kanal gehen auch die Alarm-Meldungen hinaus.

1. **Passwort vergessen?** anklicken und die E-Mail-Adresse des Kontos eingeben — genau so, wie sie im Konto hinterlegt ist.
2. Die Seite meldet immer dasselbe: „Falls ein Konto mit dieser E-Mail-Adresse existiert, ist ein Link unterwegs." Ob es das Konto gibt, verrät sie bewusst nicht.
3. Die Mail kommt an die im Konto hinterlegte Adresse. Der Link darin ist **15 Minuten** gültig und nur **einmal** verwendbar; er führt auf **Neues Passwort setzen** (mindestens 8 Zeichen).

Gut zu wissen:

- Je Konto geht höchstens **eine Mail pro Minute** hinaus. Eine zweite Anforderung in dieser Minute verschickt nichts; der schon verschickte Link bleibt gültig.
- Gilt immer nur der **jüngste** Link: wer nach mehr als einer Minute einen neuen anfordert, macht den älteren ungültig.
- Ein **deaktiviertes** Konto bekommt keinen Link, und ein früher ausgestellter Link lässt sich nach dem Deaktivieren nicht mehr einlösen.
- Wie beim Zurücksetzen durch einen Admin schaltet das neue Passwort eine aktive 2FA ab und beendet alle bestehenden Sitzungen des Kontos.
- Jede Anforderung für ein bestehendes Konto steht im Audit-Log als **Zurücksetzen per E-Mail angefordert** — mit Absender-IP und Ausgang, in den Rohdaten des Eintrags als `reason`: `sent` (verschickt), `throttled` (gedrosselt), `inactive` (Konto deaktiviert), `smtp_unavailable` (kein Mailversand), `failed` (fehlgeschlagen). Anforderungen für unbekannte Adressen hinterlassen keine Spur.
- Der Link zeigt immer auf den Namen des Servers aus dem Setup (Schritt „Server-Identität“): `https://hostname.domain`, ohne Domain `https://hostname`; ist keiner hinterlegt, auf die Server-Adresse aus der Konfiguration (`THINOS_SERVER_URL`, Vorgabe `https://thinforge-server`). Der Name muss im Verwaltungsnetz auflösbar sein — er ist derselbe, den das TLS-Zertifikat trägt. Unter welcher Adresse die Anforderung kam, spielt seit dem Update vom 2026-10-03 keine Rolle mehr.

Ohne eingerichteten Mailversand bleibt der Weg über einen Admin — siehe [09 — Einstellungen → Passwort zurücksetzen](09-einstellungen.md#passwort-zurücksetzen). Dabei wird eine aktive 2FA abgeschaltet, und alle bestehenden Sitzungen des Kontos enden.

## Wissenswert

- **Rollen-Chip**: Der farbige Chip in der ersten Card zeigt Administrator (rot), Operator (orange), Betrachter (neutral). Rollen vergibt ein Admin; Benutzer können sich nicht selbst hochstufen.
- **Session-Dauer**: Access-Token 15 min, Refresh-Token so lange wie die eingestellte Sitzungsdauer ohne Aktivität (Standard 7 Tage, [09 — Einstellungen → Allgemein](09-einstellungen.md#tab-general-allgemein)). Die UI refresht transparent; bei abgelaufenem Refresh-Token wird auf `/login` umgeleitet.
- **Logout**: Benutzermenü → **Abmelden**. Serverseitig werden die Cookies gelöscht und Access- und Refresh-Token auf die Redis-Blacklist gesetzt. Ist Redis in diesem Moment gestört, erscheint eine Fehlermeldung: abgemeldet ist der Browser trotzdem, die beiden Tokens gelten dann aber bis zu ihrem Ablauf weiter (Audit-Eintrag `logout` mit `revoked: false`).

## Nächste Schritte

- Admin-Aufgaben rund um Benutzer: [09 — Einstellungen](09-einstellungen.md#tab-benutzer--rollen).
