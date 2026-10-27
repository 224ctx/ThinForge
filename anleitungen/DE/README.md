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
| Abonnement verlängern / hochladen | [11 — Abonnement](11-lizenz.md) |
| CVE-Status / TLS / Signing-Key prüfen | [12 — Sicherheit](12-sicherheit-und-cve-scan.md) |
| VPN für Homeoffice-Zugriff einrichten | [13 — VPN](13-vpn.md) |
| Datenschutz-Angaben zusammenstellen (Verzeichnis der Verarbeitungstätigkeiten, Auskunft) | [14 — Datenschutz](14-datenschutz.md) |
| Firmenfirewall für ThinForge einrichten (Ports, Hostnamen) | [15 — Firewall-Regeln](15-firewall.md) |

## Inhaltsverzeichnis

**Voraussetzungen**

15. [Firewall-Regeln](15-firewall.md) — Ports, Richtungen und Hostnamen für Verwaltungsnetz, Client-Netz, Internet und VPN; vor der Installation an der Firmenfirewall freischalten

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
9. [Einstellungen](09-einstellungen.md) — Dienste, TLS, Benutzer, Signierung, Abonnement-Überblick

**Erweitert (Admin)**

10. [Profil & 2FA](10-profil-und-2fa.md) — Eigenes Passwort, TOTP-Setup, Passwort vergessen
11. [Abonnement](11-lizenz.md) — VPN-Sitzplätze, Upload der Abonnementdatei, Limit-Verhalten
12. [Sicherheit](12-sicherheit-und-cve-scan.md) — TLS, SSH-Provisioning-Keys, Signing-Key, Vulnerability-Scan, SBOMs, ausgehende Verbindungen
13. [VPN](13-vpn.md) — ThinVPN-Setup, Aktivierung von Homeoffice-Clients
14. [Datenschutz](14-datenschutz.md) — Gespeicherte Daten, Aufbewahrung, Sichtbarkeit, Löschen und Export

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

- **Admin** — voller Zugriff. Zusätzlich zum Operator: Benutzerverwaltung, TLS, Signing-Keys, Abonnement, Backup & Restore, Factory-Reset, das Speichern der Einstellungen (Wartungsfenster pflegt auch der Operator), das Löschen von Clients und Gruppen, **die gesamte Netzwerk-Infrastruktur** (DHCP, DNS, PXE, Server-Interfaces), **die Steuerung der Dienste** (Container starten/stoppen/neu starten) und das Menü **Logs** (Audit-Log und Container-Logs, [08](08-tasks-logs.md))
- **Operator** — alltägliche Arbeit: Clients, Gruppen, Cloning, Capture-Jobs, Images, Rollouts, Tasks
- **Betrachter** — nur Lesen: Dashboard, Listen, Berichte

Jeder darf für sich selbst das Passwort ändern und die Zwei-Faktor-Anmeldung ein- oder ausschalten — unabhängig von der Rolle ([10 — Profil & 2FA](10-profil-und-2fa.md)).

Diese Anleitung geht von der **Operator**-Sicht aus. Admin-spezifische Tätigkeiten sind in [09 — Einstellungen](09-einstellungen.md) zusammengefasst; die Netzwerk-Einstellungen in [07 — Netzwerk](07-netzwerk.md) sind seit 2026-08-31 ebenfalls Admin-Sache.

> **Menü sichtbar heißt nicht Aktion erlaubt.** Die Rollenprüfung sitzt seit 2026-08-31 durchgängig auf dem Server. Die reinen Admin-Aktionen blendet die Oberfläche seit dem Update vom 2026-09-30 für andere Rollen aus: die Netzwerk-Ansicht ist dann schreibgeschützt, in den Diensten fehlen Start/Stopp, die Reiter Abonnement und Werkeinstellungen fehlen, und im Ersteinrichtungs-Assistenten übernimmt nur ein Admin den Clonezilla-Download (Betrachter sehen den Assistenten gar nicht). Seit dem Update vom 2026-10-08 fehlen außerdem die Reiter, deren Inhalt die Rolle nicht einmal lesen darf: **Backup & Restore** (Info & Backup) und **Zertifikate** (Clients) für alle außer Admins, **Remote Desktop** und **SSH-Zugang** (Einstellungen) sowie **Agent** (Clients) für Betrachter. Ebenso sind ohne Admin-Rolle die Einstellungen **Allgemein** und **Benachrichtigungen** schreibgeschützt, und Erzeugen, Hochladen, Rotieren und Nachsignieren von Zertifikaten und Schlüsseln fehlen; Betrachter sehen auch keine Knöpfe zum Bestätigen oder Lösen von Vorfällen. Clients und Gruppen löschen, **Token neu ausstellen**, **Reset auf Install Token** und **Agent signieren** zeigt die Oberfläche nur Admins, und die Agent-Einstellungen sind für Operatoren schreibgeschützt. Wo die Oberfläche eine Aktion noch zeigt, die die Rolle nicht erlaubt, weist der Server sie ab und die Oberfläche zeigt eine Fehlermeldung — das ist kein Defekt, sondern die Rollenprüfung.
