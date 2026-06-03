# 13 — VPN

Diese Anleitung beschreibt das Einrichten von ThinVPN und das Aktivieren von VPN-Clients aus Endkunden-Sicht. Eine technische Tiefenbeschreibung steht in [`docs/Dokumentation-VPN.md`](../../docs/Dokumentation-VPN.md).

Menü: **Netzwerk → Tab VPN**.

## Erster Aufruf — VPN noch nicht eingerichtet

Solange noch keine Verbindung zum ThinVPN-Server eingerichtet ist, zeigt der Tab nur die Karte **„VPN nicht eingerichtet"** mit Setup-Button.

### Voraussetzungen

- **ThinVPN-URL** (z.B. `https://vpn.deinefirma.de`)
- **Zugangs-Token**, generiert in der ThinVPN-Verwaltungsoberfläche unter **Settings → Users → Personal Access Tokens** (bzw. „API-Tokens"). Den dort angezeigten Token-String einmalig kopieren.

> **Achtung:** Verwechsle das nicht mit einem *Aktivierungs-Schlüssel* (Setup-Key). Aktivierungs-Schlüssel sind gerätespezifisch und werden vom Backend automatisch erzeugt, wenn du einen VPN-Client aktivierst — du musst sie nie selbst eintragen.

Hat dir dein ThinForge-Reseller diese Daten geliefert? Wenn ja, klicke **„VPN einrichten"**.

## Setup-Assistent

Der Assistent läuft in drei Schritten:

### Schritt 1 — Verbindung

| Feld | Eingabe |
|---|---|
| ThinVPN-URL | Vollständige Adresse mit `https://`-Prefix |
| Zugangs-Token | Aus der ThinVPN-Verwaltungsoberfläche kopieren |

Klick auf **„Verbindung testen & weiter"** prüft die Daten. Bei Erfolg wechselt der Assistent zu Schritt 2.

### Schritt 2 — Server registrieren

Hier wird der ThinForge-Server selbst beim ThinVPN-Server angemeldet. Der erkannte Hostname und das LAN-Subnetz werden angezeigt. Klick auf **„Anmelden"** schließt den Schritt ab.

### Schritt 3 — Fertig

Bestätigung, dass die Einrichtung abgeschlossen ist. **„Fertig"** schließt den Assistenten.

## Normaler Tab-Inhalt (nach Einrichtung)

Nach dem Setup zeigt der Tab drei Karten:

1. **Status-Leiste** (oben): grüner Chip „ThinVPN aktiv" + Anzahl der aktivierten Clients.
2. **ThinVPN-Verbindung**: aktuelle URL + maskierter Token + Status (zuletzt geprüft …). Buttons: „Verbindung testen", „Token rotieren", „Verbindung trennen".
3. **VPN-Clients**: Tabelle aller Geräte, die ThinForge kennt — mit ihrem VPN-Status.

> **„Verbindung trennen"** entfernt nicht nur die gespeicherte ThinVPN-Verbindung, sondern räumt auch alle automatisch am ThinVPN-Server angelegten Objekte wieder ab (Server-Peer, LAN-Route, DNS-Eintrag, ThinForge-Gruppen und alle aktivierten Client-Geräte). Der Schritt ist nicht umkehrbar — eine erneute Einrichtung legt alles sauber neu an.

Sobald die Verbindung eingerichtet ist, lösen interne Namen (z.B. `thinforge-server` oder Hosts der lokalen Domain) auf den Endgeräten automatisch über den Tunnel auf. Voraussetzung ist eine gesetzte lokale Domain unter **Setup → Netzwerk → DNS**.

## VPN für ein Endgerät aktivieren

In der Tabelle **VPN-Clients** den gewünschten Client suchen, in der Aktions-Spalte auf **„Aktivieren"** klicken. ThinForge erzeugt einen Aktivierungs-Schlüssel und sendet ihn beim nächsten Status-Abgleich ans Endgerät. Sobald der Client sich angemeldet hat, wechselt der Status auf **„aktiv"**.

Wichtig: Der Aktivierungs-Schlüssel **läuft nicht ab**. Du kannst Geräte schon einmal vorbereiten, auch wenn sie erst Wochen später ins Homeoffice gehen.

## VPN für ein Endgerät deaktivieren

In der Tabelle auf **„Deaktivieren"** klicken — Bestätigungsdialog erscheint. Bei Bestätigung wird der VPN-Eintrag des Geräts beim ThinVPN-Server entfernt und die lokalen Anmeldedaten am Gerät gelöscht.

Eine erneute Aktivierung ist jederzeit möglich (erstellt einen neuen Aktivierungs-Schlüssel).

## FAQ

**Muss der Mitarbeiter im Homeoffice etwas tun?**
Nein. Der VPN-Client startet automatisch, sobald das Gerät außerhalb des Büros läuft. Im Büro schaltet er sich automatisch ab.

**Was passiert, wenn ich ein Gerät verloren habe?**
Im VPN-Tab den Client deaktivieren — der VPN-Zugang ist sofort entzogen.

**Kann ich mehrere Mitarbeiter gleichzeitig aktivieren?**
Ja, die Aktivierungen laufen unabhängig voneinander.

**Was passiert, wenn der ThinVPN-Server kurz nicht erreichbar ist?**
Bereits aktive VPN-Verbindungen laufen weiter. Neue Aktivierungen sind erst möglich, wenn der ThinVPN-Server wieder antwortet.

**Warum sehe ich „VPN-Lizenz-Limit erreicht"?**
Dein Lizenz-Tier erlaubt nur eine bestimmte Anzahl aktivierter Clients. Lösung: einen nicht mehr benötigten Client deaktivieren oder Lizenz upgraden.

## Weiterführende Doku

- Technische Details (für IT-Personal): [`docs/Dokumentation-VPN.md`](../../docs/Dokumentation-VPN.md)
- Übersicht der Komponenten: [`docs/Komponenten.md`](../../docs/Komponenten.md)
