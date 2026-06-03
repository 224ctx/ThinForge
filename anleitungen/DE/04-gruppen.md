# 4 — Gruppen

Gruppen sind das primäre Organisations-Werkzeug für die Client-Flotte. Typische Gründe, Clients zu gruppieren:

- **Standort** — Filiale A, Filiale B, Zentrale
- **Rolle** — Kasse, Schulung, Backoffice, Info-Kiosk
- **Hardware-Generation** — unterschiedliche Image-Varianten für alte vs. neue Geräte
- **Rollout-Wellen** — Pilot, Early Adopter, Breitband
- **VPN-Anbindung** — Clients im lokalen LAN vs. Clients, die über WireGuard reinkommen (Außendienst, Home-Office, Außenstellen-Kioske). Unterschiedliche Bandbreiten-Charakteristik ist z. B. relevant bei der Deployment-Methode: Multicast nur im LAN, Unicast/BitTorrent für VPN-Clients.

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

Jede Zeile zeigt Gruppenname, Anzahl zugewiesener Clients (inkl. Untergruppen), und eine kompakte Status-Leiste (online/offline/version).

### Aktionen pro Gruppe

- **Details anzeigen** — alle zugeordneten Clients, Tag-Filter, Durchschnitts-Version
- **Rollout starten** — alle Clients dieser Gruppe erhalten ein Image
- **Bearbeiten** — Namen, Beschreibung, Parent-Gruppe ändern
- **Löschen** — Gruppe auflösen (Clients werden „ungruppiert")

## Neue Gruppe anlegen

1. In der Gruppen-Übersicht auf **„+ Neue Gruppe"**
2. **Name** (eindeutig), **Beschreibung** (optional)
3. **Parent-Gruppe** wählen — keine, wenn Top-Level. Eine bestehende Untergruppe lässt sich über **Bearbeiten** → Parent-Gruppe leeren → Speichern wieder auf Root-Ebene verschieben.
4. **Speichern**

Die Gruppe ist leer. Clients fügst du über die Clients-Liste zu (Bulk-Aktion → Gruppe zuweisen) oder direkt aus dem Client-Detail-Tab.

## Clients zuweisen

Zwei Wege:

### Aus der Clients-Liste

1. Menü → **Clients**
2. Clients per Checkbox markieren (auch „alle auswählen" für gefilterte Ergebnisse)
3. Aktionen oben → **„Gruppe zuweisen"**
4. Gruppe wählen, bestätigen

### Aus der Gruppe

1. Menü → **Gruppen** → Gruppen-Detail
2. **„Clients hinzufügen"** → Dialog mit verfügbaren (noch nicht zugewiesenen) Clients
3. Auswählen, bestätigen

## Filter in anderen Ansichten

Die Gruppen-Zuordnung ist überall filterbar:

- **Clients-Liste** — Dropdown „Gruppe" oben rechts
- **Rollouts** — Ziel-Auswahl: „Gruppe" statt Client-Liste
- **Dashboard** — Compliance-Kachel lässt sich pro Gruppe aufschlüsseln

## Vererbung und Unter-Gruppen

Eine Gruppen-weite Aktion (z. B. Rollout) gilt standardmäßig für **alle** Clients in der Gruppe **und allen Untergruppen**. Im Rollout-Dialog lässt sich das per Checkbox auf die direkte Gruppe beschränken.

Untergruppen sind hilfreich, wenn Aktionen mal gemeinsam, mal getrennt laufen sollen (z. B. „Filiale Nord insgesamt update" vs. „nur Info-Kiosks in Filiale Nord update").

## Best Practices

- **Gruppennamen kurz halten** — sie tauchen in vielen Dropdowns auf, zu lange Namen werden abgeschnitten.
- **Konsistente Benennung** — z. B. immer `Standort / Rolle`. Spart Suchen und Tippfehler.
- **Nicht zu flach, nicht zu tief** — 2–3 Ebenen reichen meist (Standort → Rolle). Mehr wird unübersichtlich.
- **„Quarantäne"-Gruppe** — praktisch für neu provisionierte Clients, die erst getestet werden sollen bevor sie in Produktionsgruppen landen.

## Nächste Schritte

- [06 — Rollouts](06-rollouts.md) — Deployments auf Gruppen starten
- [workflows/update-verteilen.md](workflows/update-verteilen.md) — Wellenartiges Ausrollen
