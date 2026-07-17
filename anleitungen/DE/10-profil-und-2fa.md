# 10 — Profil & Zwei-Faktor-Authentisierung

Jeder angemeldete Benutzer hat über das Benutzermenü oben rechts Zugriff auf sein **Profil**. Dort lassen sich das eigene Passwort ändern, die Rolle einsehen und — falls noch nicht aktiv — eine **Zwei-Faktor-Authentisierung (TOTP)** einrichten.

Admins können zusätzlich in [09 — Einstellungen → Benutzer](09-einstellungen.md#tab-benutzer) für andere Personen Passwörter und 2FA-Seeds zurücksetzen.

## Profil öffnen

- Klick auf den Benutzernamen oben rechts → **Profil**
- Direkt-URL: `/profile`

Die Ansicht besteht aus drei Karten: **Benutzerinformationen**, **Passwort ändern**, **Zwei-Faktor-Authentisierung**.

## Eigenes Passwort ändern

Karte **Passwort ändern**:

1. Aktuelles Passwort eingeben.
2. Neues Passwort (mindestens 8 Zeichen) eingeben.
3. Bestätigung wiederholen — muss zeichengenau übereinstimmen.
4. **Speichern**.

Bei Erfolg verschwinden die Eingaben, die Meldung „Passwort wurde erfolgreich geändert" erscheint als Snackbar. Aus Sicherheitsgründen werden bestehende Sitzungen beim Passwortwechsel beendet — du musst dich anschließend mit dem neuen Passwort neu anmelden.

Schlägt die Prüfung des alten Passworts fehl, wird genau dieser Fehler gemeldet — der neue Wert wird dann nicht übernommen.

## Zwei-Faktor-Authentisierung aktivieren

TOTP schützt den Account zusätzlich mit einem zeitbasierten 6-stelligen Code aus einer Authenticator-App (z. B. Aegis, FreeOTP, Google Authenticator). Der Server generiert dafür ein Secret und zeigt es als QR-Code.

Ablauf:

1. Karte **Zwei-Faktor-Authentisierung** → **2FA aktivieren**.
2. Der Server liefert QR-Code + Secret. QR-Code mit der Authenticator-App scannen **oder** das alphanumerische Secret manuell eingeben (z. B. wenn die App keinen QR-Scan unterstützt).
3. **Weiter** → 6-stelligen Code aus der App in das Eingabefeld übertragen.
4. **2FA aktivieren** bestätigt den Code.

Nach erfolgreicher Aktivierung zeigt die Karte den Status **aktiviert** (grüner Chip) und der nächste Login verlangt nach dem Passwort zusätzlich den 6-stelligen Code.

> **Tipp:** Den Secret-String oder einen Screenshot des QR-Codes **einmalig** an einem sicheren Ort (Passwort-Manager, verschlüsselter Container) ablegen, damit bei Geräteverlust die Einrichtung auf einem neuen Endgerät möglich bleibt. Die App zeigt das Secret später nicht mehr.

## 2FA deaktivieren

- Karte **Zwei-Faktor-Authentisierung** → **2FA deaktivieren**.
- Dialog fragt nach dem aktuellen Passwort **und** einem gültigen aktuellen TOTP-Code.
- Nach Bestätigung ist der zweite Faktor entfernt.

Ist der Code nicht mehr verfügbar (z. B. verlorenes Smartphone), muss ein Admin in den Einstellungen `/settings?tab=users` den TOTP-Seed des Users zurücksetzen — siehe [09 — Einstellungen → TOTP zurücksetzen](09-einstellungen.md#totp-zurücksetzen).

## Passwort vergessen / Reset-Link

Auf dem Login-Bildschirm steht **Passwort vergessen?** — nur sichtbar, wenn SMTP in den Einstellungen konfiguriert ist.

1. E-Mail-Adresse eintragen → **Anfordern**.
2. Das System versendet eine Mail mit Reset-Link; der Link ist zeitlich begrenzt gültig (Backend-seitig).
3. Link öffnen → neues Passwort + Bestätigung eintragen → **Speichern** → Zurück zum Login.

Ist kein SMTP konfiguriert, erscheint der Link nicht und der Reset muss durch einen Admin ausgelöst werden.

## Wissenswert

- **Rollen-Chip**: Der farbige Chip in der ersten Card zeigt Admin (rot), Operator (orange), Viewer (neutral). Rollen vergibt ein Admin; Benutzer können sich nicht selbst hochstufen.
- **Session-Dauer**: Access-Token 15 min, Refresh-Token 7 Tage. Die UI refresht transparent; bei abgelaufenem Refresh-Token wird auf `/login` umgeleitet.
- **Logout**: Benutzermenü → **Abmelden**. Serverseitig werden die Cookies gelöscht und der Access-Token auf die Redis-Blacklist gesetzt.

## Nächste Schritte

- Admin-Aufgaben rund um Benutzer: [09 — Einstellungen](09-einstellungen.md#tab-benutzer).
- Nach Rotation der Admin-Zugangsdaten: geplante Rollouts prüfen ([06 — Rollouts](06-rollouts.md)).
