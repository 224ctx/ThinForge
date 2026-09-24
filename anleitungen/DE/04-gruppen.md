# 4 — Gruppen

Gruppen sind das primäre Organisations-Werkzeug für die Client-Flotte. Typische Gründe, Clients zu gruppieren:

- **Standort** — Filiale A, Filiale B, Zentrale
- **Rolle** — Kasse, Schulung, Backoffice, Info-Kiosk
- **Hardware-Generation** — unterschiedliche Image-Varianten für alte vs. neue Geräte
- **Rollout-Wellen** — Pilot, Early Adopter, Breitband
- **VPN-Anbindung** — Clients im lokalen LAN vs. Clients, die über das VPN reinkommen (Außendienst, Home-Office, Außenstellen-Kioske). Der VPN-Haken der Gruppe entscheidet, welche Geräte sich im Menü VPN aktivieren lassen ([13](13-vpn.md)); Clone-Deployments laufen nur im LAN, VPN-Clients erhalten Delta-Updates ([06](06-rollouts.md#rollouts-und-vpn)).

Ein Client gehört zu **höchstens einer** Gruppe. Gruppen können geschachtelt sein (Elterngruppe / Untergruppe), was z. B. „Filiale A → Kassen" ermöglicht.

## Gruppen-Übersicht

Menüpunkt **Gruppen** zeigt eine Baumansicht:

```
Zentrale (42 Clients)
├── Backoffice (12)
└── Schulung (8)
Filiale Nord (25)
├── Kassen (15)
└── Info-Kiosk (10)
Filiale Süd (18)
```

Jede Zeile zeigt Gruppenname, Anzahl direkt zugewiesener Clients und die Zahl der Untergruppen; die Verschachtelung zeigt der Einzug, beliebig tief. Der Stift am Zeilenende öffnet das Bearbeiten-Formular.

### Aktionen pro Gruppe

- **Details anzeigen** (Klick auf die Zeile) — Kennzahlen (Clients, übergeordnete Gruppe, Untergruppen), das jüngste Clone-Deployment dieser Gruppe mit Fortschritt und Knöpfen zum Abbrechen, Neustarten fehlgeschlagener Clients und Löschen, darunter die Tabelle **Enthaltene Clients** (Inventarnummer, Hostname, MAC-Adresse, Status, Raum; Klick öffnet das Gerät)
- **Image verteilen** — einen eigenen Knopf dafür hat die Gruppenansicht nicht mehr. Ein Deployment für die Gruppe legst du unter **Cloning → Deployments** mit dem Ziel „Gruppe" an ([06](06-rollouts.md)); die Gruppenansicht zeigt es dann an.
- **Bearbeiten** — Namen, Beschreibung, übergeordnete Gruppe ändern
- **Löschen** (nur Admins, Knopf im Bearbeiten-Formular) — klappt nur, solange die Gruppe keine Untergruppen und keine Clients hat; sonst lehnt der Server mit einer Meldung ab. Hängen noch Aufgabenvorlagen oder hochgeladene Zertifikate an der Gruppe, fragt die Oberfläche, ob erzwungen gelöscht werden soll — die Vorlagen werden dann abgeschaltet, die Zertifikate gelöscht. Ist die Gruppe Ziel eines Rollouts im Entwurf, aktiv oder pausiert, lässt sie sich gar nicht löschen. Gruppen mit aktiviertem VPN löscht der Dialog nach eigener Rückfrage erzwungen: Untergruppen rücken eine Ebene hoch, Clients werden „ungruppiert".

## Neue Gruppe anlegen

1. In der Gruppen-Übersicht oben rechts auf **„+ Gruppe erstellen"**
2. **Name** (eindeutig), **Beschreibung** (optional)
3. **Übergeordnete Gruppe** wählen — keine, wenn Top-Level. Eine bestehende Untergruppe lässt sich über **Bearbeiten** → übergeordnete Gruppe leeren → Speichern wieder auf Root-Ebene verschieben.
4. **Speichern**

Die Gruppe ist leer. Clients fügst du über die Clients-Liste zu (Bulk-Aktion → Gruppe zuweisen) oder direkt in der Client-Detailansicht.

## Clients zuweisen

Zwei Wege:

### Aus der Clients-Liste

1. Menü → **Clients**
2. Clients per Checkbox markieren (auch „alle auswählen" für gefilterte Ergebnisse)
3. In der Leiste über der Tabelle im Feld **„Gruppe zuweisen"** die Gruppe wählen
4. **Zuweisen**

### Aus der Client-Detailansicht

1. Menü → **Clients** → Gerät anklicken
2. Im Feld **Gruppen** die Gruppe wählen
3. **Speichern**

Beim Anlegen lässt sich die Gruppe gleich mitgeben — im Formular **„Client registrieren"** oder beim CSV-Import über die Spalte `gruppe_name` (fehlende Gruppen legt der Import auf Nachfrage an).

## Filter in anderen Ansichten

Die Gruppen-Zuordnung ist überall filterbar:

- **Clients-Liste** — Dropdown „Gruppen" in der Filterzeile
- **Deployments, Updates und Rollouts** — Ziel-Auswahl: Gruppe statt Client-Liste
- **Berichte** — Spalte Gruppe im Compliance-Bericht, Auslastung und Verteilung pro Gruppe im Bericht „Nutzung"

## Unter-Gruppen

Untergruppen dienen der **Organisation** (Baumansicht, Filterung). Eine Aktion — etwa ein Rollout — wirkt **nur auf die direkt zugewiesenen Clients der gewählten Gruppe** und wird **nicht** auf Untergruppen übertragen.

Um eine übergeordnete Gruppe samt Untergruppen zu erreichen, wählst du die Gruppen einzeln aus oder nutzt eine Client-Liste.

## Best Practices

- **Gruppennamen kurz halten** — sie tauchen in vielen Dropdowns auf, zu lange Namen werden abgeschnitten.
- **Konsistente Benennung** — z. B. immer `Standort / Rolle`. Spart Suchen und Tippfehler.
- **Nicht zu flach, nicht zu tief** — 2–3 Ebenen reichen meist (Standort → Rolle). Mehr wird unübersichtlich.
- **„Quarantäne"-Gruppe** — praktisch für neu provisionierte Clients, die erst getestet werden sollen bevor sie in Produktionsgruppen landen.

## Nächste Schritte

- [06 — Rollouts](06-rollouts.md) — Deployments auf Gruppen starten
- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Wellenartiges Ausrollen
