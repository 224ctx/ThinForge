# 13 — VPN

Diese Anleitung beschreibt das Einrichten von ThinVPN und das Aktivieren von VPN-Clients aus Endkunden-Sicht. Eine technische Tiefenbeschreibung steht in [`docs/reference/Dokumentation-VPN.md`](../../docs/reference/Dokumentation-VPN.md).

Menü: **Navigationspunkt VPN** (in der Seitenleiste).

> **Empfehlung:** Für die VPN-Funktion solltest du die **VPN-Option von ThinForge** buchen. Zur grundsätzlichen Freischaltung erhältst du von [thinforge.org](https://thinforge.org) eine **URL** und einen **Key** (= ThinVPN-URL und Zugangs-Token, siehe Voraussetzungen), mit denen du die VPN-Funktion aktivierst. Konditionen: [Preistabelle](https://thinforge.org/#preise).

## Erster Aufruf — VPN noch nicht eingerichtet

Solange noch keine Verbindung zum ThinVPN-Server eingerichtet ist, zeigt der Tab nur die Karte **„VPN nicht eingerichtet"** mit Setup-Button.

### Voraussetzungen

- **ThinVPN-URL** (z.B. `https://vpn.deinefirma.de`)
- **Zugangs-Token** — der Schlüssel, den du nach Buchung der VPN-Option von thinforge.org erhältst.

> **Achtung:** Verwechsle das nicht mit einem *Aktivierungs-Schlüssel* (Setup-Key). Aktivierungs-Schlüssel sind gerätespezifisch und werden vom Backend automatisch erzeugt, wenn du einen VPN-Client aktivierst — du musst sie nie selbst eintragen.

Hat dir thinforge.org nach Buchung der VPN-Option diese Daten (URL und Key) geliefert? Wenn ja, klicke **„VPN einrichten"**.

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

Nach dem Setup zeigt die Ansicht oben zwei feste Bereiche:

1. **Status-Leiste** (oben): grüner Chip „ThinVPN aktiv" + Anzahl der aktivierten Clients.
2. **ThinVPN-Verbindung**: aktuelle URL + maskierter Token + Status (zuletzt geprüft …). Buttons: „Verbindung testen", „Token rotieren", „Trennen & löschen".

Darunter folgen mehrere Tabs:

- **Clients**: Tabelle aller Geräte, die ThinForge kennt — mit ihrem VPN-Status.
- **Konfiguration**: der abgeglichene VPN-Stand und die Freigaben (Lokale Ressourcen).
- **Gruppen**: die VPN-Gruppen.
- **Tasks**: die laufenden und abgeschlossenen VPN-Aufgaben.

> **„Trennen & löschen"** entfernt nicht nur die gespeicherte ThinVPN-Verbindung, sondern räumt auch alle automatisch am ThinVPN-Server angelegten Objekte wieder ab (Server-Peer, LAN-Route, DNS-Eintrag, ThinForge-Gruppen und alle aktivierten Client-Geräte). Der Schritt ist nicht umkehrbar — eine erneute Einrichtung legt alles sauber neu an.

Sobald die Verbindung eingerichtet ist, lösen interne Namen (z.B. `thinforge-server` oder Hosts der lokalen Domain) auf den Endgeräten automatisch über den Tunnel auf. Voraussetzung ist eine gesetzte lokale Domain unter **Setup → Netzwerk → DNS**.

## Gruppen, Clients und Freigaben konfigurieren

Im Tab **Gruppen** verwaltest du die VPN-Gruppen. Eine Gruppe ist eine benannte Sammlung von Geräten — sie dient dazu, Freigaben gezielt für eine Auswahl von Clients zu vergeben. Über **„Neue Gruppe"** legst du eine Gruppe mit einem Namen an (z.B. „Buchhaltung"). Die Spalte **Peers** zeigt, wie viele Geräte aktuell in der Gruppe sind. Drei Systemgruppen sind fest vergeben und lassen sich nicht löschen; alle weiteren Gruppen kannst du frei anlegen und wieder entfernen.

Im Tab **Clients** sind die Geräte nach der Gruppe gegliedert, der sie angehören. Beim Freischalten eines Geräts (Aktion **„Aktivieren"**) wählst du im Dialog die **Gruppe**, in die der Client aufgenommen wird — vorbelegt ist die Standardgruppe „Clients". Über diese Gruppenzugehörigkeit entscheidet sich, welche Freigaben für das Gerät gelten. Ein Client bekommt keine eigene Adressregel; seine Zugriffsrechte ergeben sich allein aus der Gruppe.

Die eigentlichen **Freigaben** definierst du im Tab **Konfiguration**. Dort zeigt die obere Karte den abgeglichenen Soll-Zustand (Netzwerk, Routing, Gruppen und bestehende Freigaben) schreibgeschützt an; mit **„Konfig anwenden"** wird ein geänderter Stand sofort auf den ThinVPN-Server übertragen. Darunter, in der Karte **Lokale Ressourcen**, legst du über **„Neue Ressource"** eine Freigabe an. Eine Freigabe besteht aus:

- **Name**: eine Bezeichnung für die Freigabe (z.B. „W22").
- **Host-Adresse**: das Ziel, das erreichbar werden soll — entweder eine einzelne IP (ein einzelner Host, z.B. `192.168.20.3`) oder ein ganzer Netzbereich in CIDR-Schreibweise (z.B. `192.168.20.0/24`).
- **Quell-Group**: die Gruppe, deren Mitglieder das Ziel erreichen dürfen (vorbelegt mit „Clients").
- **Zugriffs-Regeln**: je Regel ein Protokoll (TCP, UDP oder alle) und die freigegebenen Ports (kommasepariert).

Eine Freigabe lässt sich nicht nachträglich bearbeiten — zum Ändern löschst du sie und legst sie neu an. Über das Lösch-Symbol in der Zeile wird eine Freigabe nach Rückfrage entfernt und unmittelbar vom ThinVPN-Server gelöscht.

> **Standardverhalten:** Ein frisch freigeschalteter Client erreicht von sich aus **nur den ThinForge-Server** (für Namensauflösung und die Verwaltung) — sonst nichts. Jeder weitere Zugriff muss als Freigabe ausdrücklich erlaubt werden. Möchtest du also, dass eine Gruppe einen einzelnen Host oder einen ganzen Netzbereich im Firmennetz erreicht, trägst du dieses Ziel als Freigabe mit der passenden Quell-Group ein. So unterscheidet sich „nur Server" (keine zusätzliche Freigabe) von „Netzbereich" (eine Freigabe mit einer Netzbereich-Adresse).

## VPN für ein Endgerät aktivieren

In der Tabelle **VPN-Clients** den gewünschten Client suchen, in der Aktions-Spalte auf **„Aktivieren"** klicken. ThinForge erzeugt einen Aktivierungs-Schlüssel und sendet ihn beim nächsten Status-Abgleich ans Endgerät. Sobald der Client sich angemeldet hat, wechselt der Status auf **„aktiv"**.

Wichtig: Der Aktivierungs-Schlüssel **läuft nicht ab**. Du kannst Geräte schon einmal vorbereiten, auch wenn sie erst Wochen später ins Homeoffice gehen.

> **Voraussetzung:** Die Konfiguration erhält der Client erst, wenn er eingeschaltet und im LAN des ThinForge-Servers erreichbar ist. Der Agent holt den Aktivierungs-Schlüssel beim Status-Abgleich ab und richtet den Tunnel ein — solange der Tunnel noch nicht steht, erreicht das Gerät den Server nur lokal. Danach funktioniert der VPN-Zugang auch von außerhalb.

Danach baut der Client den Tunnel **vollautomatisch** auf, sobald sich das Gerät außerhalb des Firmennetzes befindet — der Mitarbeiter muss dafür nichts starten, anklicken oder eintragen. Im Büro, also im LAN des ThinForge-Servers, trennt der Client den Tunnel von selbst wieder, sodass dort der direkte Netzwerkzugang genutzt wird.

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

**Warum sehe ich „VPN-Tier-Limit erreicht"?**
Dein Lizenz-Tier erlaubt nur eine bestimmte Anzahl aktivierter Clients. Lösung: einen nicht mehr benötigten Client deaktivieren oder Lizenz upgraden.

## Weiterführende Doku

- Technische Details (für IT-Personal): [`docs/reference/Dokumentation-VPN.md`](../../docs/reference/Dokumentation-VPN.md)
- Übersicht der Komponenten: [`docs/reference/Komponenten.md`](../../docs/reference/Komponenten.md)
