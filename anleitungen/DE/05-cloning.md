# 5 — Cloning

Der Cloning-Bereich ist das Herzstück von ThinForge: hier entstehen, pflegst du und verwaltest die Disk-Images (Clones), die später an die Thin-Clients verteilt werden.

Die Ansicht hat mehrere Tabs. Die wichtigsten für den Image-Lifecycle sind **VM erstellen**, **ISOs**, **Captures** und **Clones**.

## Lifecycle im Überblick

```
1. Basis HD erstellen  (ohne dieses Basis-Layout der Festplatte ist
   die Delta-Update-Funktionalität nicht gewährleistet)
       ↓
2. ISO hochladen/herunterladen, Cloning-VM damit booten
       ↓
3. OS installieren → für den Neustart: VM stoppen, prüfen dass die
   ISO abgewählt ist, VM starten → Agent installieren, anpassen
       ↓
4. Basis sichern ("Updatedelta speichern & Klon erstellen", beim
   ersten Mal im Basis-Modus) → Image (v2026.06.22-001)
       ↓
5. Später: VM starten, ändern, erneut "Updatedelta speichern"
   → v2026.06.22-002, v2026.06.22-003, ...
       ↓
6. Rollout → Clients pullen das Image ([06](06-rollouts.md))
```

---

## Tab: VM erstellen

Die Cloning-VM ist eine QEMU/KVM-Instanz, die auf dem Server läuft. Sie hat eine dedizierte qcow2-Disk, die als Vorlage für alle späteren Clones dient.

### VM-Status

Im Kopf der Karte **VM erstellen** zeigt ein Chip den Zustand:

- **Läuft** (grün) — VM läuft
- **Wird heruntergefahren** (orange) — „VM stoppen" läuft, das Gastsystem fährt herunter
- **Gestoppt** (grau) — nicht gestartet

Beim Starten dreht sich der Knopf; beim Stoppen steht der Chip auf „Wird heruntergefahren", bis die VM aus ist. Die Konsole erscheint erst, wenn die Bildschirmübertragung antwortet — bis dahin steht dort „Konsole wird vorbereitet".

### Basis HD erstellen

Ohne virtuelle Festplatte startet die VM nicht. **„Basis HD erstellen"** legt sie neu an und partitioniert sie im ThinForge-Layout: Gesamtgröße (GB), ESP-Partition (MB, Vorgabe 300) und Data-Partition (GB, Vorgabe 20 % der Gesamtgröße); die System-Partition ergibt sich daraus und muss mindestens 4 GB groß sein. Vorhandener Inhalt der Festplatte geht verloren. **„Reset VM"** löscht die virtuelle Festplatte ganz.

### Starten

1. Auf der Karte die ISO wählen (oder **„Ohne ISO (von Festplatte booten)"**, wenn bereits ein OS installiert ist)
2. RAM, CPUs, Festplattengröße und **KVM-Beschleunigung** prüfen oder anpassen
3. **„VM starten"** klicken

Weicht die gewählte Festplattengröße von der vorhandenen Festplatte ab, fragt ein Dialog, ob du sie **behalten** oder **neu erstellen** willst (Neu erstellen führt in **Basis HD erstellen**). Ist ein wiederhergestellter Clone aktiv, bootet die VM von dessen Festplatte; die ISO-Auswahl ist dann gesperrt, und die Festplatte lässt sich nur noch vergrößern.

Nach 10–30 Sekunden ist die VM bootfähig, die Konsole wird aktiv.

### Konsole

- Die VM-Konsole ist direkt im Tab eingebettet; mit **„In neuem Tab öffnen"** lässt sie sich in einem eigenen Fenster anzeigen
- Die Zwischenablage wird durchgereicht
- Die VM ist damit wie ein normaler PC bedienbar: Installation klicken, Software einrichten, Updates laufen lassen

### Stoppen

- **„VM stoppen"** — fährt das Gastsystem sauber herunter: ThinForge drückt für die VM den Ein/Aus-Knopf und wartet bis zu 2 Minuten, bis sie sich selbst ausschaltet. Solange bleibt der Knopf gesperrt, und über den Knöpfen steht ein Hinweis. Danach meldet ThinForge „sauber heruntergefahren" — oder „hart gestoppt", wenn das Gastsystem nicht reagiert hat (etwa im Installer, im Firmware-Menü oder bei einem offenen „Herunterfahren?"-Dialog ohne Countdown); dann ist es wie ein Stromausfall, ungeschriebene Daten fehlen. Bis zum Update vom 2026-10-01 beendete der Knopf die VM immer sofort.
- Wer sichergehen will, fährt das System vorher in der Konsole selbst herunter und stoppt erst danach.
- Das saubere Herunterfahren braucht das cloning-vm-Image ab diesem Update; mit einem älteren meldet der Stopp „Kein QEMU-Monitor erreichbar" und hält die VM sofort hart an.

### Ressourcen

Vorgabe sind 2 GB RAM (erlaubt 1–128 GB), 2 vCPUs (bis 24), 60 GB Festplatte und KVM-Beschleunigung an. RAM, CPUs und Disk-Größe stellst du pro VM direkt beim Start ein; die Vorgaben sind fest im Server hinterlegt und nicht einstellbar. Nach dem Start oder Wiederherstellen übernimmt die Karte die Werte der VM bzw. des Clones.

Fehlt dem Server KVM (etwa weil er selbst eine VM ohne verschachtelte Virtualisierung ist), startet die VM trotz eingeschalteter KVM-Beschleunigung — in Software-Emulation (TCG), deutlich langsamer. Seit dem Update vom 2026-10-08 zeigt die Info-Karte der laufenden VM dann bei KVM **„Nicht verfügbar (TCG)"** mit einem Hinweis; vorher stand dort trotzdem „On".

---

## Tab: ISOs

Verwaltet Installations-ISOs, die als Boot-Medium für die Cloning-VM dienen.

### Liste

Tabelle mit: Dateiname, Größe, Hochgeladen am.

### Upload

Zwei Wege:

1. **„ISO hochladen"** — Datei vom lokalen Rechner. Akzeptiert nur `.iso`, Obergrenze 120 GB; bei > 5 GB ist ein Direkt-Download per URL bequemer.
2. **„ISO von URL herunterladen"** — Dialog mit URL-Feld, optional Dateiname (sonst aus der URL abgeleitet). ThinForge zieht die Datei im Hintergrund und zeigt den Fortschritt live (Balken und Bytes). Ideal für Debian-, Ubuntu-, Manjaro-Images direkt von deren Mirror. Erlaubt sind nur `http`/`https` und öffentliche Adressen — Quellen im eigenen Netz (private, Loopback- oder link-lokale Adressen) lehnt der Server ab. Es läuft immer nur ein Download.

### Löschen

Über das Papierkorb-Symbol, nach Rückfrage. ThinForge prüft dabei nicht, ob die laufende VM die ISO gerade nutzt — lösche eine ISO erst, wenn die VM gestoppt ist.

### Tools-ISO

Die Tools-ISO wird automatisch vom Server gebaut und hängt in der laufenden Cloning-VM als zweites CD-Laufwerk (`THINFORGE_TOOLS`). Sie enthält die Einrichtungs-Skripte samt Client-Provisioning und Agent; damit richtest du im Image-System den Agenten ein, bevor du das Image sicherst ([workflows/golden-image.md](workflows/golden-image.md)). Die Clients erhalten das fertige Image danach per Deployment. In ihrer Wurzel liegen außerdem die Lizenztexte (`LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `WRITTEN_OFFER.md`) — der Agent steht unter der GPL-3.0-or-later.

Die Tools-ISO wird bei jedem Start der Cloning-VM automatisch neu gebaut, außerdem nach jedem Agent-Bau oder -Upload unter **Clients → Agent**. Die VM startet nur mit der frisch gebauten ISO: scheitert der Neubau, startet sie nicht, und die Meldung nennt den Grund. Nach einer Zertifikats-Erneuerung oder Schlüsselrotation genügt es daher, die VM neu zu starten.

Die ISO trägt das Agent-Binary des Servers samt Signatur. Liegt auf dem Server kein gebautes oder kein signiertes Agent-Binary, wird keine ISO gebaut und die Cloning-VM startet nicht; die Meldung nennt den fehlenden Schritt (unter **Clients → Agent** bauen bzw. **Signieren**). Signieren und einen fehlenden Signierschlüssel erzeugen darf nur ein Admin; die Meldung sagt das auch. Beim Einrichten prüft das Provisioning-Script die Signatur und installiert nur einen passend signierten Agenten.

## Tab: VDI-Clients

Hier legst du die Installationspakete der VDI-Clients ab, die ThinForge aus Lizenzgründen nicht mitbringt: Citrix Workspace App, Citrix USB-Support (ctxusb), Parallels Client und Omnissa Horizon Client. Je Client gibt es genau einen Platz; die Tabelle zeigt, ob ein Paket vorhanden ist, mit Datei, Größe und Hochladezeitpunkt.

- **Hochladen** — Citrix, Citrix USB-Support und Parallels nehmen eine `.deb`-Datei, Omnissa eine `.bundle`- oder `.deb`-Datei. Der Server speichert das Paket unter einem festen Namen; ein neuer Upload ersetzt das vorhandene.
- **Löschen** — über das Papierkorb-Symbol, nach Rückfrage.

Hochgeladene Pakete kommen beim nächsten Start der Cloning-VM auf die Tools-ISO (Ordner `DebianVDIClients/`). Am Ende von `install-debian-minimal.sh finish` bietet das Skript an, sie im Image zu installieren; von Hand geht das mit `DebianVDIClients/install-vdi-clients-debian.sh` von der Tools-ISO. Hochladen und Löschen dürfen Admins und Operatoren.

---

## Image aus der VM erstellen

Im Tab **VM erstellen** sicherst du den VM-Stand als ausrollbares Image (die VM muss **gestoppt** sein). Der Dialog wählt automatisch den passenden Modus. Daneben sichert **„Clone erstellen"** die Festplatte ohne Delta als Anfang einer neuen Image-Linie (Name und optionaler Kommentar).

### Basis erstellen

- Legt einen Basis-Snapshot der VM an und startet eine neue Versionskette
- Beim ersten Mal (noch keine Clones oder Snapshots) automatisch gewählt; danach über die Option **„Neues Basis-Image (neue Versionskette)"** jederzeit wählbar
- Verlangt einen **Image-Namen** (Linien-Name, z. B. „Debian Workforce"); jede Image-Linie zählt ihre Versionen getrennt
- **Wann?** Bei Erstinstallation oder für eine saubere neue Kette (z. B. nach großen OS-Upgrades)

### Updatedelta speichern & Klon erstellen

- Erstellt ein Delta gegen die letzte Version **und** ein vollständiges, ausrollbares Clone-Image
- Schnell und klein (nur geänderte Blöcke im Delta)
- **Wann?** Für laufende Updates — Security-Patches, Konfig-Änderungen, neue Software

### Image erstellen

1. Cloning-VM muss **gestoppt** sein (solange sie läuft, ist der Knopf gesperrt)
2. Im Tab **VM erstellen** auf **„Updatedelta speichern & Klon erstellen"**
3. Im Dialog:
   - **„Delta-Update (inkrementell)"** oder **„Neues Basis-Image (neue Versionskette)"** wählen — beim ersten Mal entfällt die Wahl
   - **Image-Name** — nur bei einer neuen Basis, Pflicht
   - **Version** — wird automatisch vergeben im Format `vJJJJ.MM.TT-NNN` (UTC-Datum + fortlaufender Tageszähler pro Image-Linie), z. B. `v2026.06.22-001`
   - **Kommentar** — optional, kurze Notiz, was geändert wurde
4. Speichern

Vorher prüft der Server das Btrfs-Layout der VM. Hat sie noch eigene Subvolumes aus dem Calamares-Standardlayout, fragt der Dialog **„Layout-Konsolidierung erforderlich"** nach; **„Konsolidieren und speichern"** führt sie ins Root-Subvolume zusammen und speichert danach.

Der Vorgang läuft im Hintergrund; der Fortschritt steht in den Tabs **VM erstellen** und **Clones** („Schritt 1/2: Delta wird erstellt", „Schritt 2/2: VM-Klon wird erstellt"). Je nach Disk-Größe dauert ein vollständiges Image 10–30 Minuten, ein Delta meist 1–5 Minuten.

### Abbrechen

Während der Vorgang läuft, erscheint ein **„Abbrechen"**-Button — nicht in der Delta-Phase (Schritt 1/2), die sich nicht mittendrin abbrechen lässt. Abbruch räumt halb-erzeugte Files auf — die VM bleibt unbeschädigt.

---

## Tab: Captures

Der Tab **Captures** erfasst dagegen die Festplatte eines **physischen Clients**: Das Gerät bootet per PXE in eine Capture-Umgebung (Clonezilla), und sein Plattenstand wird als Image gesichert.

1. Client auswählen (optional vorher nach Gruppe filtern)
2. Namen für das Capture vergeben
3. Unter **„Nach Capture"** festlegen, ob das Gerät danach **herunterfährt** oder **neu startet**
4. **„Gerät jetzt neu starten"** (Vorgabe an): Ein online gemeldetes Gerät startet per SSH sofort in die Aufnahme, ein ausgeschaltetes beim nächsten Einschalten. Ohne die Option startest du es selbst neu.
5. **„Capture starten"**

Der Vorgang läuft im Hintergrund; der Stand (Wartend, Läuft, Fertig, Fehlgeschlagen, Abgebrochen) steht in der Liste **Capture-Jobs** daneben. Dort lässt sich ein Job abbrechen, neu starten oder löschen; **Neu starten** bereitet das Gerät erneut vor und startet ein online gemeldetes gleich per SSH in die Aufnahme. Das fertige Capture erscheint im Tab **Clones** mit der Quelle **HW Clone**; **„Importieren"** in der Job-Liste registriert es unter einem Image-Namen (1–80 Zeichen) als ausrollbares Image, die Version wird automatisch vergeben.

Ein Gerät, das in einem laufenden Klon-Deployment steckt, lässt sich nicht aufnehmen — und ein Gerät mit laufender Aufnahme bekommt kein Deployment. Beides würde den Starteintrag des anderen Vorgangs überschreiben; die Oberfläche meldet es, bis der Vorgang fertig oder abgebrochen ist.

---

## Tab: Clones

Die Liste der fertigen Images, bereit zum Ausrollen.

### Versionsbaum

Clones werden hierarchisch dargestellt — Baselines als Root, Deltas als Kinder:

```
v2026.06.22-001 (Baseline)
├─ v2026.06.22-002
├─ v2026.06.22-003
├─ v2026.06.22-004
└─ v2026.06.22-005    ← aktuelle "stable", letzter Update

v2026.06.23-001 (Baseline)
└─ v2026.06.23-002
```

Innerhalb einer Kette sind die Deltas **flach** — sie hängen als Geschwister direkt an der Basis (verknüpft über `parent_id`, nicht über die Versionsnummer), nicht ineinander verschachtelt. Das macht es einfach, einzelne Updates später zu löschen, ohne die Kette zu zerreißen. Falls ein Clone mit defektem `parent_id` auftaucht (z. B. weil der Ur-Quell-Clone gelöscht wurde), repariert ThinForge den Baum beim nächsten Öffnen des Clones-Tabs automatisch.

Die **Basis** einer Kette wird automatisch bestimmt: Es ist die niedrigste Version ihrer Image-Linie (Clones gleichen Namens). Sie trägt die Markierung **Basis**.

### Aktionen pro Clone

Die Tabelle zeigt je Clone Version, Quelle (**VM Clone** oder **HW Clone**), Name, Kommentar, Erstellt am, Festplatten- und Clone-Größe. Markierungen: **Basis**, **Aktiv** (gerade in der VM geladen), **veraltet** (älter als jede auf einem Client installierte Version) und **Defekt** (im Rollback als defekt markiert). Aufgeklappt listet eine Zeile die Clients, die noch unter dieser Version liegen.

- **Zuordnen** — hängt den Clone an eine andere Stelle im Baum (siehe unten)
- **Wiederherstellen zur VM** — spielt den Clone wieder auf die Cloning-VM zurück (die VM muss gestoppt sein). So lässt sich jederzeit zu einer älteren Version zurückwechseln. Achte aber darauf, dass auch die Clients auf der älteren Version landen — entweder über ein neues Deployment oder über den Rollback (der nur die jeweils vorherige Version wiederherstellen kann).
- **Exportieren** — Download als 7z-Archiv, optional mit Passwort verschlüsselt (mindestens 4 Zeichen, nur ASCII-Zeichen — keine Umlaute). Unverschlüsselt sind im Image gespeicherte Anmeldedaten für jeden lesbar, der die Datei erhält.
- **Löschen** — zeigt vorher die Folgen an. Gesperrt, solange ein laufendes Deployment den Clone nutzt oder eine aktive Update-Zuweisung (Tab **Updates**) diese Version als Ziel hat. Laufen Clients auf der Version, musst du die Auswirkung bestätigen; beim letzten Clone einer Kette lassen sich die zugehörigen Deltas mitlöschen.

Über **„Importieren"** im Kopf des Tabs lädst du ein exportiertes 7z-Archiv wieder hoch (Passwort nur bei verschlüsseltem Export); der Clone behält dabei seine Version. Ist der Linien-Name schon vergeben, fragt der Dialog nach einem neuen Namen. Archiv und entpackter Clone liegen während des Imports nebeneinander auf dem Server — gebraucht wird also etwa der doppelte Platz des Archivs plus 2 GB Reserve. ThinForge prüft das zu Beginn des Hochladens und noch einmal vor dem Entpacken; reicht der Platz nicht, bricht der Import mit einer Meldung ab, die freien und nötigen Platz nennt, und es bleibt nichts liegen.

### Zuordnen / Einsortieren

Manchmal sollen Clones im Baum umgeordnet werden — z. B. wenn ein re-importierter Clone an eine andere Position gehört, oder wenn ein Clone ohne Parent als Fortsetzung einer bestehenden Kette einsortiert werden soll.

- **„Als Kind zuordnen"** — hängt den Clone als nächstes Kind an einen gewählten Parent
- **„Vor Clone einordnen"** — fügt den Clone vor einem bestehenden Clone ein. Angeboten wird das nur, wenn im Namen eine Version steht, die vor der Zielversion liegt: eine Datumsversion wie `v2026.05.07-001` oder eine ältere Nummer wie `v1.002`. Bei Datumsversionen geht das nur innerhalb derselben Image-Linie — der Name besteht aus dem Linien-Namen und der Version (z. B. „Manjaro v2026.05.07-001" vor einem Clone der Linie „Manjaro"), und der Clone übernimmt danach den Linien-Namen. Bei älteren Nummern muss die Hauptnummer gleich sein (`v1.…` vor `v1.…`), der Name bleibt.
- **„Zuordnung entfernen"** — nur bei Clones mit Parent: nimmt den Clone aus seiner Kette, macht ihn zu einer neuen eigenständigen Baseline

Diese Operationen sind **rein logisch** — sie ändern nur Metadaten, nicht das Image selbst. Die Delta-Erzeugung folgt weiter der physischen Snapshot-Kette aus dem Capture-Moment.

---

## Speicherplatz im Blick behalten

Clones können groß werden (mehrere GB pro Baseline, einige MB bis GB pro Delta). Auf der Dashboard-Kachel **Server-Speicher** sind die Werte sichtbar. Typisches Aufräumen:

- **Alte, nicht mehr verteilte Baselines löschen** — Achtung: nur wenn keine lebenden Clients sie noch nutzen
- **Alte Deltas zusammenführen** — per „Neues Basis-Image" aus der aktuellen Leaf-Version, dann alte Kette entfernen
- **Nicht benutzte ISOs löschen**

## Nächste Schritte

- [06 — Rollouts](06-rollouts.md) — Clone an Clients verteilen
- [workflows/golden-image.md](workflows/golden-image.md) — Erste Baseline von Grund auf erstellen
- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Delta-Update an eine Gruppe rollen
