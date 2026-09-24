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

Schlägt die Änderung fehl, meldet die Karte „Das aktuelle Passwort ist falsch" — der neue Wert wird dann nicht übernommen.

## Zwei-Faktor-Authentisierung aktivieren

TOTP schützt den Account zusätzlich mit einem zeitbasierten 6-stelligen Code aus einer Authenticator-App (z. B. Aegis, FreeOTP, Google Authenticator). Der Server generiert dafür ein Secret und zeigt es als QR-Code.

Ablauf:

1. Karte **Zwei-Faktor-Authentifizierung (2FA)** → **2FA aktivieren**; darunter erscheint die Karte **2FA einrichten**.
2. Der Server liefert QR-Code + Secret (manueller Schlüssel, Base32). QR-Code mit der Authenticator-App scannen **oder** das alphanumerische Secret manuell eingeben (z. B. wenn die App keinen QR-Scan unterstützt).
3. **Weiter** → 6-stelligen Code aus der App in das Eingabefeld übertragen.
4. **2FA aktivieren** bestätigt den Code.

Nach erfolgreicher Aktivierung zeigt die Karte den Status **aktiviert** (grüner Chip) und der nächste Login verlangt nach dem Passwort zusätzlich den 6-stelligen Code.

> **Tipp:** Den Secret-String oder einen Screenshot des QR-Codes **einmalig** an einem sicheren Ort (Passwort-Manager, verschlüsselter Container) ablegen, damit bei Geräteverlust die Einrichtung auf einem neuen Endgerät möglich bleibt. Die App zeigt das Secret später nicht mehr.

## 2FA deaktivieren

- Karte **Zwei-Faktor-Authentifizierung (2FA)** → **2FA deaktivieren**.
- Dialog fragt nach dem aktuellen Passwort **und** einem gültigen aktuellen TOTP-Code.
- Nach Bestätigung ist der zweite Faktor entfernt.

Ist der Code nicht mehr verfügbar (z. B. verlorenes Smartphone), muss ein Admin in den Einstellungen `/settings?tab=users` den TOTP-Seed des Users zurücksetzen — siehe [09 — Einstellungen → TOTP zurücksetzen](09-einstellungen.md#totp-zurücksetzen). Für ein Admin-Konto lehnt der Server das ab; dort setzt eine andere Admin-Person über **Bearbeiten** ein neues Passwort, was die 2FA ebenfalls abschaltet.

## Passwort vergessen

Der E-Mail-Versand eines Reset-Links ist derzeit noch nicht verfügbar. Der Login-Bildschirm fragt beim Server nach, ob er Mails verschicken kann — die Antwort lautet derzeit immer „nein", deshalb erscheint dort kein Link **Passwort vergessen?**. Die SMTP-Angaben des E-Mail-Kanals unter Einstellungen → Benachrichtigungen gelten nur für Alarm-Meldungen, nicht für diesen Weg.

Wer sein Passwort vergessen hat, bekommt es von einem Admin neu gesetzt — siehe [09 — Einstellungen → Passwort zurücksetzen](09-einstellungen.md#passwort-zurücksetzen). Dabei wird eine aktive 2FA abgeschaltet, und alle bestehenden Sitzungen des Kontos enden.

## Wissenswert

- **Rollen-Chip**: Der farbige Chip in der ersten Card zeigt Admin (rot), Operator (orange), Viewer (neutral). Rollen vergibt ein Admin; Benutzer können sich nicht selbst hochstufen.
- **Session-Dauer**: Access-Token 15 min, Refresh-Token so lange wie die eingestellte Sitzungsdauer ohne Aktivität (Standard 7 Tage, [09 — Einstellungen → Allgemein](09-einstellungen.md#tab-general-allgemein)). Die UI refresht transparent; bei abgelaufenem Refresh-Token wird auf `/login` umgeleitet.
- **Logout**: Benutzermenü → **Abmelden**. Serverseitig werden die Cookies gelöscht und Access- und Refresh-Token auf die Redis-Blacklist gesetzt. Ist Redis in diesem Moment gestört, erscheint eine Fehlermeldung: abgemeldet ist der Browser trotzdem, die beiden Tokens gelten dann aber bis zu ihrem Ablauf weiter (Audit-Eintrag `logout` mit `revoked: false`).

## Nächste Schritte

- Admin-Aufgaben rund um Benutzer: [09 — Einstellungen](09-einstellungen.md#tab-benutzer--rollen).
