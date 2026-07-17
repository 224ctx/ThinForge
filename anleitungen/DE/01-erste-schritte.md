# 1 — Erste Schritte

## Installation

ThinForge läuft als Docker-Stack auf einem Server im lokalen Netz (Debian oder Ubuntu). Die Installation erledigt ein Bootstrap-Skript, das einmalig auf dem frischen Server ausgeführt wird:

```bash
./bootstrap-release.sh
```

Es lädt die ThinForge-Komponenten, richtet die Grundkonfiguration samt automatisch erzeugter Zugangs-Geheimnisse ein (kein manuelles Bearbeiten der `.env` nötig) und startet den kompletten Stack. Danach ist die Web-Oberfläche unter der Server-Adresse erreichbar.

> **Hinweis:** Das Bootstrap-Skript erhältst du von deinem ThinForge-Anbieter. `git` muss auf dem Server vorhanden sein; alle weiteren Abhängigkeiten installiert das Skript selbst.

## Server-Adresse aufrufen

Die Web-Oberfläche ist unter der HTTPS-Adresse des ThinForge-Servers erreichbar. Beim Erstaufruf zeigt der Browser eine Zertifikatswarnung, weil die Installation mit einem selbst-signierten Zertifikat ausgeliefert wird. Sobald ein eigenes Zertifikat hinterlegt ist (siehe [09 — Einstellungen](09-einstellungen.md), Abschnitt TLS), verschwindet die Warnung.

```
https://<server-hostname-oder-ip>/
```

## Setup-Wizard

Beim allerersten Aufruf nach einer frischen Installation erscheint der **Setup-Wizard**. Er führt in sechs Schritten durch die Grundkonfiguration:

1. **Admin-Konto anlegen** — E-Mail, Anzeigename, Passwort. Das ist der erste Admin-Account; weitere Benutzer werden später in den Einstellungen hinzugefügt.
2. **Server-Identität** — Hostname und lokale Domain für dnsmasq.
3. **DHCP / PXE** — Subnetz und Rollout-IP-Range sowie der Upstream-DNS. Wird für das Booten neuer Thin-Clients gebraucht.
4. **NTP** — Upstream-Zeitserver. Standard ist `0.pool.ntp.org`; intern meist ein Management-NTP.
5. **HTTPS / TLS** — ein selbst-signiertes Zertifikat wird angelegt.
6. **Zusammenfassung** — alle Eingaben prüfen und abschließen.

Nach Abschluss des Wizards landet man auf dem **Dashboard**. Die Tools-ISO für die initiale Client-Provisionierung wird nicht im Setup gebaut, sondern erst beim ersten Start der Cloning-VM.

## Anmelden

Nach dem Setup meldet man sich mit den eben angelegten Admin-Zugangsdaten an. Weitere Operator- und Viewer-Konten entstehen in [09 — Einstellungen → Benutzer](09-einstellungen.md#benutzer--rollen).

**Passwort vergessen?** Der E-Mail-Versand eines Reset-Links ist derzeit noch nicht verfügbar. Eine andere Admin-Person setzt das Passwort daher in [09 — Einstellungen → Benutzer](09-einstellungen.md#benutzer--rollen) neu.

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
- **Cloning** — Image-Management; Rollouts/Rollback liegen hier als Tabs ([05](05-cloning.md))
- **VPN** — ThinVPN-Verwaltung
- **Netzwerk** — Infrastruktur-Einstellungen ([07](07-netzwerk.md))
- **Tasks** — laufende und historische Aufträge ([08](08-tasks-logs.md))
- **Berichte** — Auswertungen und Exporte
- **Einstellungen** — Dienste, Config, Benutzer ([09](09-einstellungen.md))
- **Logs** — Server-Protokolle, nur für Admins ([08](08-tasks-logs.md))
- **Info** — Systeminfo und Backup

### Hauptfläche (rechts)

Der Inhalt ändert sich je nach ausgewähltem Menüpunkt. Die meisten Ansichten haben oben eine **Aktions-Leiste** (Neu, Import, Export, Refresh) und darunter eine Liste oder ein Detail-Formular.

## Dashboard anpassen

Rechts oben auf dem Dashboard liegt ein **Zahnrad-Icon** — damit lassen sich Kacheln aus- und einblenden und per Drag & Drop sortieren. Die Einstellung wird lokal im Browser gespeichert (pro Gerät).

## Nächste Schritte

- **Du hast noch keine Clients?** → [workflows/erster-client.md](workflows/erster-client.md)
- **Du willst verstehen, was auf dem Dashboard steht?** → [02 — Dashboard](02-dashboard.md)
- **Du willst ein neues Image bauen?** → [workflows/golden-image.md](workflows/golden-image.md)
