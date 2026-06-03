# 1 — Erste Schritte

## Server-Adresse aufrufen

Die Web-Oberfläche ist unter der HTTPS-Adresse des ThinForge-Servers erreichbar. Beim Erstaufruf zeigt der Browser eine Zertifikatswarnung, weil die Installation mit einem selbst-signierten Zertifikat ausgeliefert wird. Sobald ein eigenes Zertifikat hinterlegt ist (siehe [09 — Einstellungen](09-einstellungen.md), Abschnitt TLS), verschwindet die Warnung.

```
https://<server-hostname-oder-ip>/
```

## Setup-Wizard

Beim allerersten Aufruf nach einer frischen Installation erscheint der **Setup-Wizard**. Er führt in fünf Schritten durch die Grundkonfiguration:

1. **Admin-Benutzer anlegen** — E-Mail, Anzeigename, Passwort. Das ist der erste Admin-Account; weitere Benutzer werden später in den Einstellungen hinzugefügt.
2. **DNS-Konfiguration** — Upstream-DNS (Default: Management-Gateway), lokale Domain für dnsmasq.
3. **DHCP / PXE** — Subnetz und Rollout-IP-Range. Wird für das Booten neuer Thin-Clients gebraucht.
4. **NTP** — Chrony-Upstream-Server. Standard ist `pool.ntp.org`; intern meist ein Management-NTP.
5. **Tools-ISO** — ISO für die initiale Client-Provisionierung wird gebaut. Das dauert 1–2 Minuten.

Nach Abschluss des Wizards landet man auf dem **Dashboard**.

> **Hinweis:** Wird der Wizard abgebrochen, erscheint er beim nächsten Login erneut, bis alle Schritte einmal vollständig durchlaufen sind.

## Anmelden

Nach dem Setup meldet man sich mit den eben angelegten Admin-Zugangsdaten an. Weitere Operator- und Viewer-Konten entstehen in [09 — Einstellungen → Benutzer](09-einstellungen.md#benutzer--rollen).

**Passwort vergessen?** Die „Passwort zurücksetzen"-Funktion im Login-Screen schickt einen Reset-Link — dafür muss in den Einstellungen ein SMTP-Server eingetragen sein. Ohne SMTP muss eine andere Admin-Person das Passwort in [09 — Einstellungen → Benutzer](09-einstellungen.md#benutzer--rollen) neu setzen.

## UI-Tour

Das Fenster ist in drei Bereiche geteilt:

```
┌─────────────────────────────────────────────────────────┐
│ TopBar: Version │ Benutzer │ Theme │ Sprache │ Logout   │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │                   Hauptfläche                │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### TopBar (oben)

- **Version-Chip** (`v2026-04-14` o. ä.) — Klick öffnet den Changelog-Dialog mit allen Release-Notes.
- **Benutzer-Menü** — Profil-Einstellungen, Passwort ändern, Logout.
- **Theme-Schalter** — Dark/Light Mode.
- **Sprachwahl** — Deutsch/Englisch.

### Sidebar (links)

Menüpunkte richten sich nach Berechtigung. Typisch sichtbar als Operator:

- **Dashboard** — Übersicht ([02](02-dashboard.md))
- **Clients** — Geräteverwaltung ([03](03-clients.md))
- **Gruppen** — Organisation ([04](04-gruppen.md))
- **Cloning** — Image-Management ([05](05-cloning.md))
- **Rollouts** — Deployment-Planung ([06](06-rollouts.md))
- **Netzwerk** — Infrastruktur-Einstellungen ([07](07-netzwerk.md))
- **Tasks** — laufende und historische Aufträge ([08](08-tasks-logs.md))
- **Logs** — Server-Protokolle ([08](08-tasks-logs.md))
- **Einstellungen** — Dienste, Config, Benutzer (Admin-only, [09](09-einstellungen.md))

### Hauptfläche (rechts)

Der Inhalt ändert sich je nach ausgewähltem Menüpunkt. Die meisten Ansichten haben oben eine **Aktions-Leiste** (Neu, Import, Export, Refresh) und darunter eine Liste oder ein Detail-Formular.

## Dashboard anpassen

Rechts oben auf dem Dashboard liegt ein **Zahnrad-Icon** — damit lassen sich Kacheln aus- und einblenden und per Drag & Drop sortieren. Die Einstellung bleibt pro Benutzer gespeichert.

## Nächste Schritte

- **Du hast noch keine Clients?** → [workflows/erster-client.md](workflows/erster-client.md)
- **Du willst verstehen, was auf dem Dashboard steht?** → [02 — Dashboard](02-dashboard.md)
- **Du willst ein neues Image bauen?** → [workflows/golden-image.md](workflows/golden-image.md)
