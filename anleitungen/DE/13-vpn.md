# 13 — VPN

Diese Anleitung beschreibt das Einrichten von ThinVPN und das Aktivieren von VPN-Clients aus Anwendersicht. ThinVPN ist der VPN-Dienst von ThinForge; er meldet sich an einer **VPN-Instanz** an (die Verwaltungsplattform, an der auch die Endgeräte ihren Tunnel aufbauen) und verwaltet dort alles Nötige selbst. Im Dashboard von NetBird, das der VPN-Instanz zugrunde liegt, musst du nichts von Hand anlegen — was dort nicht von ThinForge stammt, räumt der Abgleich beim nächsten Durchlauf wieder ab.

Menü: **Navigationspunkt VPN** (in der Seitenleiste). Einrichten, Aktivieren, Deaktivieren und Freigaben sind Administrator-Sache; Operatoren sehen die Ansicht nur lesend.

> **Empfehlung:** Für die VPN-Funktion solltest du die **VPN-Option von ThinForge** buchen. Zur grundsätzlichen Freischaltung erhältst du von [thinforge.org](https://thinforge.org) eine **URL** und einen **Key** (= URL der VPN-Verwaltung und Zugangs-Token, siehe Voraussetzungen), mit denen du die VPN-Funktion aktivierst. Konditionen: [Preistabelle](https://thinforge.org/#preise).

## Erster Aufruf — VPN noch nicht eingerichtet

Solange noch keine Verbindung zur VPN-Instanz eingerichtet ist, zeigt die Ansicht nur die Karte **„ThinVPN nicht eingerichtet"** mit dem Knopf **„ThinVPN einrichten"** (nur für Administratoren; Operatoren sehen an dieser Stelle einen Hinweis).

### Voraussetzungen

- **URL der VPN-Verwaltung** (z.B. `https://vpn.deinefirma.de`)
- **Zugangs-Token** — der Schlüssel, den du nach Buchung der VPN-Option von thinforge.org erhältst.
- Eine fertige Netzwerk-Konfiguration unter **Netzwerk → Lokales Netzwerk** (die Server-IP im Client-Netz wird für das VPN gebraucht).
- Für das Aktivieren von Geräten: eine Lizenz mit freien VPN-Sitzplätzen ([11 — Lizenzierung](11-lizenz.md)).

> **Achtung:** Verwechsle das nicht mit einem *Aktivierungs-Schlüssel* (Setup-Key). Aktivierungs-Schlüssel sind gerätespezifisch und werden vom Backend automatisch erzeugt, wenn du einen VPN-Client aktivierst — du musst sie nie selbst eintragen.

Hat dir thinforge.org nach Buchung der VPN-Option diese Daten (URL und Key) geliefert? Wenn ja, klicke **„ThinVPN einrichten"**.

## Setup-Assistent

Der Assistent läuft in fünf Schritten: **Verbindung → Bestand → Server registrieren → Baseline anwenden → Fertig**.

### Schritt 1 — Verbindung

| Feld | Eingabe |
|---|---|
| URL der VPN-Verwaltung | Vollständige Adresse mit `https://`-Prefix. Eine `http://`-Adresse wird angenommen, aber mit einem Warnhinweis: das Zugangs-Token ginge dann bei jedem Aufruf unverschlüsselt über das Netz. |
| Zugangs-Token | Der Key aus der Buchung |

Klick auf **„Verbindung testen & weiter"** speichert die Daten und prüft sie gegen die VPN-Instanz. Bei Erfolg wechselt der Assistent zu Schritt 2; bei einem Fehler steht die Meldung im Dialog („Die Instanz antwortet unter dieser Adresse nicht." oder „Die Instanz hat das Token abgelehnt."). Der Token wird nie wieder angezeigt — auch nicht maskiert.

### Schritt 2 — Bestand

Der Assistent liest, was auf der VPN-Instanz bereits liegt, und zeigt es an. Nichts geschieht von selbst — du wählst den Weg:

| Vorgefundener Bestand | Weg |
|---|---|
| Die Instanz ist leer | **„Weiter"** — ThinForge legt seinen Bestand neu an. |
| Bestand dieser ThinForge-Installation (z.B. Server neu aufgesetzt) | **„Wiederherstellen"** — der Bestand wird übernommen, verbundene Geräte arbeiten ohne Unterbrechung weiter. |
| Bestand einer anderen ThinForge-Installation oder aus einer früheren ThinForge-Fassung | **„Übernehmen"** nach Setzen eines Hakens — dieser Server wird alleiniger Verwalter der Instanz. |
| Bestand, der nicht von ThinForge stammt | Nur **„Bereinigen"** (löscht den gesamten Bestand, nach zweiter Rückfrage) oder **„Abbrechen"**. |

**„Bereinigen"** steht bei jedem nicht-leeren Bestand bereit, verlangt aber immer eine zweite Rückfrage samt Haken: Peers, Gruppen, Regeln, Netzwerke, DNS-Gruppen und Setup-Keys der Instanz werden entfernt, verbundene Geräte verlieren ihren Zugang, der Schritt ist nicht umkehrbar.

### Schritt 3 — Server registrieren

Hier wird der ThinForge-Server selbst an der VPN-Instanz angemeldet. Der erkannte Hostname und das LAN-Subnetz werden angezeigt. Klick auf **„Anmelden"** schließt den Schritt ab; das kann bis zu zwei Minuten dauern. Nach einer Wiederherstellung, bei der der Server-Peer schon auf dieser Maschine läuft, überspringt der Assistent den Schritt.

### Schritt 4 — Baseline anwenden

Klick auf **„Anwenden & prüfen"** schreibt die Grundregeln von ThinForge auf die VPN-Instanz und sieht das Ergebnis gleich nach. „Die Instanz stimmt mit dem Soll-Zustand überein." heißt: alles gesetzt. Stehen noch Schritte aus, ist das direkt nach der Einrichtung normal — der Abgleich läuft im Minutentakt weiter, der aktuelle Stand steht im Reiter **Zustand**.

### Schritt 5 — Fertig

**„ThinVPN ist eingerichtet"** — **„Fertig"** schließt den Assistenten.

## Normaler Tab-Inhalt (nach Einrichtung)

Nach dem Setup zeigt die Ansicht oben zwei feste Bereiche:

1. **Status-Leiste** (oben): grüner Chip „ThinVPN aktiv", die Anzahl der aktiven Clients und — nur wenn es welche gibt — die Zahl der Abweichungen zwischen Soll und Ist.
2. **VPN-Verbindung**: die URL der VPN-Verwaltung und der Prüfstatus („Verbunden (zuletzt geprüft …)", „Fehler (…)" oder „Noch nicht geprüft"). Aktionen: „Verbindung testen", „Zugangsdaten neu eintragen", „Verbindung lösen".

Darunter folgen vier Reiter:

- **Clients**: die Geräte je Gruppe mit ihrem VPN-Status, Aktivieren und Deaktivieren (einzeln oder „Ganze Gruppe aktivieren"), dazu „Flotte neu enrollen" für den Wechsel auf eine andere VPN-Instanz.
- **Freigaben**: die von dir angelegten Freigaben und darunter die festen Grundregeln (Baseline), die sich nicht ändern lassen.
- **Zustand**: der Abgleich zwischen Soll und Ist mit „Prüfen" und „Jetzt anwenden", das Abgleichs-Protokoll und die Sicherung (Export/Import der Freigaben).
- **Tasks**: die laufenden und abgeschlossenen VPN-Aufgaben.

> **„Verbindung lösen"** trennt diese ThinForge-Installation von der VPN-Instanz. Lokal fallen dabei die Freigaben samt Regeln und die dazugehörigen DNS-Einträge weg, und der VPN-Dienst dieses Servers wird dauerhaft stillgelegt. **Auf der VPN-Instanz bleibt alles stehen** — Regeln, Netzwerk und die Zugänge aller Geräte —, ist von ThinForge aus aber nicht mehr erreichbar und lässt sich nur noch dort entfernen. Wer die Freigaben behalten will, exportiert sie vorher im Reiter **Zustand**. Die Einrichtung beginnt danach wieder mit dem Assistenten.

> **„Zugangsdaten neu eintragen"** öffnet den Assistenten erneut. Ein unverändertes Token lässt alles stehen; ein **anderes** Token setzt die Einrichtung auf „nicht übernommen" zurück — im Schritt Bestand dann **„Wiederherstellen"** wählen. Eine URL, die auf eine andere VPN-Instanz zeigt, wird abgewiesen, solange Freigaben an der bisherigen hängen: erst „Verbindung lösen", dann neu einrichten.

Sobald die Verbindung eingerichtet ist, lösen interne Namen (z.B. `thinforge-server` oder Hosts der lokalen Domain) auf den Endgeräten automatisch über den Tunnel auf. Voraussetzung ist eine gesetzte lokale Domain unter **Netzwerk → DNS** (Abschnitt „Lokale Domain", Feld „Domain-Name", siehe [07 — Netzwerk](07-netzwerk.md)).

## Clients und Freigaben konfigurieren

Im Reiter **Clients** sind die Geräte nach der ThinForge-Gruppe gegliedert, der sie angehören; angezeigt werden die Gruppen mit gesetztem VPN-Haken ([04 — Gruppen](04-gruppen.md)) und zusätzlich jedes Gerät, das noch einen VPN-Zugang hält. Eigene VPN-Gruppen gibt es nicht: alle aktivierten Geräte gehören zur festen Gruppe „Clients", und über die Freigaben entscheidet sich, was sie erreichen dürfen.

Die eigentlichen **Freigaben** legst du im Reiter **Freigaben** über **„Neue Freigabe"** an. Ein Assistent führt in vier Schritten — **Ziel → Zugriff → Vorschau → Anwenden & prüfen**:

- **Name**: eine Bezeichnung für die Freigabe (z.B. „W22").
- **Ziel-Adresse**: das Ziel, das erreichbar werden soll — entweder eine einzelne IP (ein einzelner Host, z.B. `192.168.20.3`) oder ein ganzer Netzbereich in CIDR-Schreibweise (z.B. `192.168.20.0/24`). Das Ziel muss im Client-Netz liegen.
- **DNS-Name** (optional): ein Hostname, unter dem das Ziel für alle Clients auflöst; braucht eine gesetzte lokale Domain. Der Name `thinforge-server` ist reserviert.
- **Quell-Gruppe**: wer zugreifen darf — derzeit nur „Clients", also alle über ThinForge aktivierten Geräte.
- **Regeln**: je Regel ein Protokoll (TCP, UDP, ICMP oder alle) und die freigegebenen Ports (einzelne Ports, kommasepariert; leer heißt alle Ports). Vorlagen für RDP, VNC, HTTPS und SSH hängen fertige Regelzeilen an.

Die **Vorschau** zeigt, welche Objekte auf der VPN-Instanz entstehen; **„Anwenden & prüfen"** speichert die Freigabe, stößt den Abgleich an und wartet auf sein Ergebnis. Eine gespeicherte Freigabe lässt sich in der Tabelle über das Stift-Symbol bearbeiten, über den Schalter ein- und ausschalten und über das Lösch-Symbol nach Rückfrage entfernen — der Dialog nennt vorher, was auf der VPN-Instanz dabei verschwindet.

> **Standardverhalten:** Ein frisch freigeschalteter Client erreicht von sich aus **nur den ThinForge-Server** (für Namensauflösung und die Verwaltung) — sonst nichts. Jeder weitere Zugriff muss als Freigabe ausdrücklich erlaubt werden. Möchtest du also, dass die Clients einen einzelnen Host oder einen ganzen Netzbereich im Firmennetz erreichen, trägst du dieses Ziel als Freigabe ein. So unterscheidet sich „nur Server" (keine zusätzliche Freigabe) von „Netzbereich" (eine Freigabe mit einer Netzbereich-Adresse).

## VPN für ein Endgerät aktivieren

Im Reiter **Clients** den gewünschten Client suchen, in der Aktions-Spalte auf **„Aktivieren"** klicken. ThinForge prüft den Lizenz-Sitzplatz, erzeugt einen Aktivierungs-Schlüssel und sendet ihn beim nächsten Status-Abgleich ans Endgerät. Solange der Auftrag noch nicht abgeholt ist, steht in der Zeile „Aktivierung ausstehend", danach „wartet auf Erstverbindung"; sobald der Client sich angemeldet hat, wechselt der Status auf **„aktiv"**.

Wichtig: Der Aktivierungs-Schlüssel **läuft nicht ab**. Du kannst Geräte schon einmal vorbereiten, auch wenn sie erst Wochen später ins Homeoffice gehen.

> **Voraussetzung:** Die Konfiguration erhält der Client erst, wenn er eingeschaltet ist und den ThinForge-Server erreicht — in der Regel im LAN. Der Agent holt den Aktivierungs-Schlüssel beim Status-Abgleich ab und richtet den Tunnel ein; hat das Client-Netz keinen Internetzugang, gelingt die Anmeldung an der VPN-Instanz erst am Einsatzort. Das ist kein Fehler und darf beliebig lange dauern.

Danach baut der Client den Tunnel **vollautomatisch** auf, sobald das Gerät die VPN-Instanz erreicht (in der Regel: sobald es Internet hat) — der Mitarbeiter muss dafür nichts starten, anklicken oder eintragen. Im Büro, also im LAN des ThinForge-Servers, bleibt der Tunnel bestehen; das Gerät meldet dann lediglich, dass es lokal angebunden ist, und der Server erreicht es direkt über das LAN.

## VPN für ein Endgerät deaktivieren

In der Tabelle auf **„Deaktivieren"** klicken — Bestätigungsdialog erscheint. Bei Bestätigung wird der Zugang des Geräts auf der VPN-Instanz sofort entfernt; das Gerät legt seinen VPN-Dienst beim nächsten Status-Abgleich still und löscht die lokalen Anmeldedaten. Der Lizenz-Sitzplatz wird frei.

Eine erneute Aktivierung ist jederzeit möglich (erstellt einen neuen Aktivierungs-Schlüssel).

## FAQ

**Muss der Mitarbeiter im Homeoffice etwas tun?**
Nein. Der VPN-Client startet automatisch, sobald das Gerät die VPN-Instanz erreicht (in der Regel: sobald es Internet hat) — im Büro wie zu Hause.

**Was passiert, wenn ich ein Gerät verloren habe?**
Im VPN-Reiter den Client deaktivieren — der VPN-Zugang ist sofort entzogen, auch wenn das Gerät nicht mehr erreichbar ist.

**Kann ich mehrere Mitarbeiter gleichzeitig aktivieren?**
Ja, die Aktivierungen laufen unabhängig voneinander; „Ganze Gruppe aktivieren" erledigt eine Gruppe in einem Schritt.

**Was passiert, wenn die VPN-Instanz kurz nicht erreichbar ist?**
Bereits aktive VPN-Verbindungen laufen weiter. Neue Aktivierungen und der Abgleich sind erst möglich, wenn die VPN-Instanz wieder antwortet; die Status-Leiste meldet solange „VPN-Verwaltung nicht erreichbar".

**Warum sehe ich „VPN-Lizenz-Limit erreicht"?**
Deine Lizenz erlaubt nur eine bestimmte Anzahl aktivierter Clients (VPN-Sitzplätze). Lösung: einen nicht mehr benötigten Client deaktivieren oder eine Lizenz mit mehr Sitzplätzen einspielen ([11 — Lizenzierung](11-lizenz.md)).

**Was passiert beim Neu-Klonen eines aktivierten Geräts?**
Das Deployment setzt die VPN-Zuordnung selbst zurück und stellt einen frischen Aktivierungs-Schlüssel aus — das Gerät meldet sich nach dem Klon von selbst wieder an. Ist die Verbindung zur VPN-Instanz gelöst, geht das nicht; der Warndialog vor dem Deployment sagt das an ([06 — Rollouts](06-rollouts.md#rollouts-und-vpn)).

## Weiterführende Doku

- Lizenz und VPN-Sitzplätze: [11 — Lizenzierung](11-lizenz.md)
- Lokale Domain und DNS: [07 — Netzwerk](07-netzwerk.md)
- Rollouts, Delta-Updates und VPN: [06 — Rollouts](06-rollouts.md#rollouts-und-vpn)
