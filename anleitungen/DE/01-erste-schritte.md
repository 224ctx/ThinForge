# 1 — Erste Schritte

## Installation

ThinForge läuft als Docker-Stack auf einem Server im lokalen Netz (Debian oder Ubuntu). Die Installation erledigt ein Bootstrap-Skript, das einmalig auf dem frischen Server ausgeführt wird:

```bash
./bootstrap-release.sh
```

Es lädt die ThinForge-Komponenten, richtet die Grundkonfiguration samt automatisch erzeugter Zugangs-Geheimnisse ein (kein manuelles Bearbeiten der `.env` nötig) und startet den kompletten Stack. Danach ist die Web-Oberfläche unter der Server-Adresse erreichbar.

> **Hinweis:** Das Bootstrap-Skript liegt im öffentlichen ThinForge-Release-Repository; Repository und Container-Registry sind ohne Zugangsdaten lesbar. `git` muss auf dem Server vorhanden sein; alle weiteren Abhängigkeiten installiert das Skript selbst.

## Server-Adresse aufrufen

Die Web-Oberfläche ist unter der HTTPS-Adresse des ThinForge-Servers erreichbar. Beim Erstaufruf zeigt der Browser eine Zertifikatswarnung, weil die Installation mit einem selbst-signierten Zertifikat ausgeliefert wird. Sobald ein eigenes Zertifikat hinterlegt ist (siehe [09 — Einstellungen](09-einstellungen.md), Abschnitt TLS), verschwindet die Warnung.

```
https://<server-hostname-oder-ip>/
```

## Setup-Wizard

Beim allerersten Aufruf nach einer frischen Installation erscheint der **Setup-Wizard**. Er führt in sechs Schritten durch die Grundkonfiguration:

1. **Admin-Konto anlegen** — Benutzername, E-Mail, Passwort. Das ist der erste Admin-Account; weitere Benutzer werden später in den Einstellungen hinzugefügt.
2. **Server-Identität** — Hostname und lokale Domain für dnsmasq.
3. **DHCP / PXE** — Management-Interface mit Upstream-DNS, Rollout-Interface mit fester IP sowie der DHCP-Modus (eigener DHCP-Server mit IP-Bereich oder Proxy-DHCP neben einem vorhandenen). Wird für das Booten neuer Thin-Clients gebraucht.
4. **NTP** — Upstream-Zeitserver des Servers (vorbelegt mit dem Standard-Gateway) und der NTP-Server, den die Clients per DHCP erhalten (vorbelegt mit der Rollout-IP, sonst `0.pool.ntp.org`). Eine Zeitzone fragt der Wizard nicht ab — es gilt `Europe/Berlin`, änderbar unter [09 — Einstellungen → Zeitzone](09-einstellungen.md#zeitzone).
5. **HTTPS / TLS** — ein selbst-signiertes Zertifikat wird angelegt.
6. **Zusammenfassung** — alle Eingaben prüfen und abschließen.

Nach dem Abschluss leitet der Wizard nach 15 Sekunden auf die **Anmeldeseite** weiter. Konnte ein Teilschritt nicht erledigt werden (etwa das Zertifikat oder ein Schlüssel), listet er die Warnungen auf und geht erst über **„Weiter zur Anmeldung"** weiter. Die Tools-ISO für die initiale Client-Provisionierung wird nicht im Setup gebaut, sondern erst beim ersten Start der Cloning-VM.

> **Hinweis:** Wird der Wizard vor dem Abschließen verlassen, erscheint er beim nächsten Aufruf wieder von vorn — so lange, bis **„Abschließen"** erfolgreich war.

## Anmelden

Nach dem Setup meldet man sich mit den eben angelegten Admin-Zugangsdaten an. Weitere Operator- und Viewer-Konten entstehen in [09 — Einstellungen → Benutzer](09-einstellungen.md#tab-benutzer--rollen).

**Passwort vergessen?** Der E-Mail-Versand eines Reset-Links ist derzeit noch nicht verfügbar. Eine andere Admin-Person setzt das Passwort daher in [09 — Einstellungen → Benutzer](09-einstellungen.md#tab-benutzer--rollen) neu.

## UI-Tour

Das Fenster ist in drei Bereiche geteilt:

```
┌─────────────────────────────────────────────────────────┐
│ TopBar: Version │ Theme │ Sprache │ Benutzer (Logout)   │
├──────────┬──────────────────────────────────────────────┤
│          │                                              │
│ Sidebar  │                   Hauptfläche                │
│          │                                              │
│          │                                              │
└──────────┴──────────────────────────────────────────────┘
```

### TopBar (oben)

- **Menü-Symbol** (ganz links) — blendet die Sidebar ein und aus.
- **Version-Chip** (`v2026-04-14` o. ä.) — Klick öffnet den Changelog-Dialog mit allen Release-Notes.
- **Theme-Schalter** — Dark/Light Mode.
- **Sprachwahl** — Deutsch/Englisch.
- **Benutzer-Menü** (ganz rechts) — zeigt Benutzername und Rolle, öffnet das Profil (dort Passwort ändern und 2FA) und meldet ab.

### Sidebar (links)

Bis auf **Logs** (nur für Admins) ist die Sidebar für alle Rollen gleich — sie zeigt also auch Bereiche, in denen die eigene Rolle nur lesen darf. Was eine Rolle tatsächlich ändern darf, steht in der [Rollenübersicht](README.md#rollen-im-system). Als Operator sichtbar:

- **Dashboard** — Übersicht ([02](02-dashboard.md)); der Unterpunkt **Ersteinrichtung** öffnet einen kurzen Assistenten für erste Gruppe, ersten Client und den Clonezilla-Download
- **Clients** — Geräteverwaltung mit den Unterpunkten Clients, Garantie, Agent und Zertifikate ([03](03-clients.md))
- **Gruppen** — Organisation ([04](04-gruppen.md))
- **Cloning** — Image-Management; Deployments, Updates und Rollback liegen hier als Tabs ([05](05-cloning.md))
- **VPN** — ThinVPN-Verwaltung: Verbindung zur VPN-Instanz, Clients, Freigaben ([13](13-vpn.md))
- **Netzwerk** — Infrastruktur-Einstellungen ([07](07-netzwerk.md))
- **Tasks** — laufende und historische Aufträge sowie geplante Aufgaben ([08](08-tasks-logs.md))
- **Berichte** — Auswertungen und Exporte
- **Einstellungen** — Dienste, Config, Benutzer ([09](09-einstellungen.md))
- **Logs** — Audit-Log und Container-Logs, nur für Admins ([08](08-tasks-logs.md))
- **Info & Backup** — Systeminfo, Backup & Restore und die Lizenztexte

### Hauptfläche (rechts)

Der Inhalt ändert sich je nach ausgewähltem Menüpunkt. Die meisten Ansichten haben oben eine **Aktions-Leiste** (Neu, Import, Export, Refresh) und darunter eine Liste oder ein Detail-Formular.

## Dashboard anpassen

Rechts oben auf dem Dashboard liegt ein **Zahnrad-Icon** — damit lassen sich Kacheln aus- und einblenden, in der Breite ändern und per Drag & Drop sortieren. Die Einstellung wird lokal im Browser gespeichert (pro Gerät).

## Nächste Schritte

- **Du hast noch keine Clients?** → [workflows/erster-client.md](workflows/erster-client.md)
- **Du willst verstehen, was auf dem Dashboard steht?** → [02 — Dashboard](02-dashboard.md)
- **Du willst ein neues Image bauen?** → [workflows/golden-image.md](workflows/golden-image.md)
