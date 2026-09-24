# ThinForge — Benutzeranleitung

Diese Anleitung richtet sich an **IT-Administrator:innen**, die ThinForge über die Web-Oberfläche bedienen: Thin-Clients verwalten, Images erzeugen, Updates ausrollen und das System im laufenden Betrieb überwachen.

## Wer sollte was lesen?

| Rolle | Startpunkt |
|-------|------------|
| Server frisch installiert, noch kein Setup | [workflows/setup-wizard.md](workflows/setup-wizard.md) |
| Neu bei ThinForge | [01 — Erste Schritte](01-erste-schritte.md) |
| Vertraut mit UI, Fokus Clients | [03 — Clients](03-clients.md) |
| Neuen Client aufnehmen | [workflows/erster-client.md](workflows/erster-client.md) |
| Golden-Image erstellen | [workflows/golden-image.md](workflows/golden-image.md) |
| Update ausrollen | [workflows/update-verteilen.md](workflows/update-verteilen.md) |
| Image an mehrere Gruppen gleichzeitig | [workflows/multi-group-deployment.md](workflows/multi-group-deployment.md) |
| Problem beheben | [workflows/client-rollback.md](workflows/client-rollback.md), [08 — Tasks & Logs](08-tasks-logs.md) |
| 2FA aktivieren / Passwort wechseln | [10 — Profil & 2FA](10-profil-und-2fa.md) |
| Lizenz verlängern / hochladen | [11 — Lizenzierung](11-lizenz.md) |
| CVE-Status / TLS / Signing-Key prüfen | [12 — Sicherheit](12-sicherheit-und-cve-scan.md) |
| VPN für Homeoffice-Zugriff einrichten | [13 — VPN](13-vpn.md) |

## Inhaltsverzeichnis

**Grundlagen**
1. [Erste Schritte](01-erste-schritte.md) — Anmelden, Setup-Wizard, UI-Tour
2. [Dashboard](02-dashboard.md) — Kacheln, Statusampeln, Anpassung

**Kernbereiche**

3. [Clients](03-clients.md) — Liste, Detail, CSV-Import/Export, Boot-Modi, Remote-Zugriff
4. [Gruppen](04-gruppen.md) — Zuordnung und Filterung
5. [Cloning](05-cloning.md) — Cloning-VM, ISOs, Captures, Clones
6. [Rollouts](06-rollouts.md) — Deployments planen und starten

**Infrastruktur**

7. [Netzwerk](07-netzwerk.md) — DHCP/PXE, DNS, VPN (Grundlagen)
8. [Tasks & Logs](08-tasks-logs.md) — Jobs, Protokolle, Diagnose
9. [Einstellungen](09-einstellungen.md) — Dienste, TLS, Benutzer, Signierung, Lizenz-Überblick

**Erweitert (Admin)**

10. [Profil & 2FA](10-profil-und-2fa.md) — Eigenes Passwort, TOTP-Setup, Passwort vergessen
11. [Lizenzierung](11-lizenz.md) — VPN-Sitzplätze, Bundle-Upload, Limit-Verhalten
12. [Sicherheit](12-sicherheit-und-cve-scan.md) — TLS, SSH-Provisioning-Keys, Signing-Key, Vulnerability-Scan, SBOMs
13. [VPN](13-vpn.md) — ThinVPN-Setup, Aktivierung von Homeoffice-Clients

**Workflows (End-to-End)**

- [Erst-Installation per Setup-Wizard](workflows/setup-wizard.md)
- [Neuen Client aufnehmen](workflows/erster-client.md)
- [Golden-Image erstellen](workflows/golden-image.md)
- [Update an Gruppe verteilen](workflows/update-verteilen.md)
- [Image an mehrere Gruppen gleichzeitig ausrollen](workflows/multi-group-deployment.md)
- [Client auf vorherige Version zurücksetzen](workflows/client-rollback.md)

## Grundbegriffe

| Begriff | Bedeutung |
|---------|-----------|
| **Thin-Client** | Physisches Endgerät (PC, Laptop) das mit einem ThinForge-verwalteten OS-Image läuft |
| **Clone** | Ein gespeichertes Disk-Image mit Versionsnummer (z. B. `v2026.06.22-004`), wird auf Thin-Clients ausgerollt |
| **Capture** | Die Aufnahme der Festplatte eines physischen Clients als Image — das Gerät bootet dafür per PXE in eine Capture-Umgebung (Cloning → Captures) |
| **Baseline** | Die erste Version einer Clone-Kette (z. B. `v2026.06.22-001`; ältere Ketten tragen noch `vX.000`), vollständiges Image ohne Delta-Parent |
| **Delta-Update** | Inkrementelles Update vom Vorgänger-Clone zu einer neuen Version (z. B. `v2026.06.22-004 → v2026.06.22-005`) |
| **Rollout** | Verteilung eines Clones an eine Liste oder Gruppe von Thin-Clients |
| **Agent** | Kleiner Dienst auf jedem Thin-Client, der Heartbeat, Updates und Remote-Befehle handhabt |
| **Cloning-VM** | Virtuelle Maschine auf dem Server, in der das Basis-OS installiert und modifiziert wird |
| **Tools-ISO** | Boot-ISO für das initiale Provisioning eines neuen Thin-Clients |

## Rollen im System

- **Admin** — voller Zugriff. Zusätzlich zum Operator: Benutzerverwaltung, TLS, Signing-Keys, Factory-Reset, das Löschen von Clients und Gruppen, **die gesamte Netzwerk-Infrastruktur** (DHCP, DNS, PXE, Server-Interfaces) und **die Steuerung der Dienste** (Container starten/stoppen/neu starten)
- **Operator** — alltägliche Arbeit: Clients, Gruppen, Cloning, Capture-Jobs, Images, Rollouts, Tasks
- **Viewer** — nur Lesen: Dashboard, Listen, Berichte

Jeder darf für sich selbst das Passwort ändern und die Zwei-Faktor-Anmeldung ein- oder ausschalten — unabhängig von der Rolle ([10 — Profil & 2FA](10-profil-und-2fa.md)).

Diese Anleitung geht von der **Operator**-Sicht aus. Admin-spezifische Tätigkeiten sind in [09 — Einstellungen](09-einstellungen.md) zusammengefasst; die Netzwerk-Einstellungen in [07 — Netzwerk](07-netzwerk.md) sind seit 2026-08-31 ebenfalls Admin-Sache.

> **Menü sichtbar heißt nicht Aktion erlaubt.** Die Oberfläche blendet die meisten Schaltflächen nicht rollenabhängig aus. Ein Operator sieht also beispielsweise die Netzwerk- und Dienste-Ansichten samt Buttons; ein Klick darauf wird vom Server abgewiesen und die Oberfläche zeigt eine Fehlermeldung. Das ist kein Defekt, sondern die Rollenprüfung, die seit 2026-08-31 durchgängig auf dem Server sitzt statt nur in der Anzeige.
