# 11 — Lizenzierung

ThinForge ist im **Free-Tier** voll funktional und verwaltet bis zu **50 aktive Clients** ohne Lizenzdatei. Darüber hinaus wird ein signiertes Lizenz-Bundle benötigt — ausschließlich, um den Client-Zähler anzuheben. Es gibt **kein Feature-Gating**: alle Funktionen bleiben in jedem Tier identisch.

## Begriffe

| Begriff | Bedeutung |
|---|---|
| **Aktive Clients** | Clients mit `is_lager = false`. Lager-Geräte zählen explizit nicht mit. |
| **Free-Tier** | Keine Lizenzdatei hinterlegt oder abgelaufen + Grace-Period vorbei. Limit: 50. |
| **Licensed** | Gültiges Bundle, `expires` in der Zukunft. Limit = `max_clients` aus dem Bundle. |
| **Grace** | 60 Tage nach Ablauf. Limit bleibt auf `max_clients`, Warn-Banner. |
| **Expired** | 60+ Tage nach Ablauf. Zurückfall auf Free-Tier (50 Clients). |

## Status ansehen

Menü → **Einstellungen** → Tab **Lizenz** (Admin).

Die Statuskarte zeigt:

- **Lizenzdaten** (Lizenzinhaber, Lizenznummer, Ablaufdatum).
- **Aktive Clients** gegen das Limit als Fortschrittsbalken — farblich gekennzeichnet:
  - grün bei unter 90 %,
  - orange ab 90 %,
  - rot, sobald das Limit erreicht ist.
- **Banner**, falls Grace-Period aktiv oder Bundle abgelaufen ist.

Im Free-Tier zeigt die Karte nur den Hinweis „Free version" — das ist kein Fehler, sondern der Default-Zustand vieler Installationen.

## Lizenz-Bundle hochladen

Vom Hersteller erhältst du ein `.7z`-Archiv, das `license.json` und `license.json.minisig` enthält. Archivpasswort und Signaturprüfung laufen intern; du hältst die Datei einfach bereit.

1. **Bundle auswählen** → Datei mit `.7z`-Endung wählen.
2. **Hochladen**.
3. Server prüft Signatur und Inhalt. Häufige Fehlermeldungen:
   - `bundle_not_7z` — Datei ist kein 7z (z. B. falsches Format).
   - `bundle_wrong_password` — 7z-Passwort passt nicht zum Backend-Build (wahrscheinlich Bundle aus anderer Version).
   - `bundle_missing_files` — Archiv enthält nicht beide erforderlichen Dateien.
   - `signature_invalid` — Minisign-Signatur ist ungültig; häufig Kopierproblem oder manipuliertes Bundle.
   - `payload_malformed` — JSON-Schema stimmt nicht.
4. Bei Erfolg aktualisiert sich die Karte direkt, das neue Limit ist sofort aktiv.

## Lizenz entfernen

**Entfernen** → Bestätigen. Die Datei wird vom Server gelöscht, Installationen fallen in den Free-Tier zurück. Bereits registrierte Clients über dem 50er-Limit bleiben funktional — nur das Anlegen **neuer** Clients wird blockiert, bis wieder Platz ist oder eine neue Lizenz hinterlegt wurde.

## Verhalten beim Limit

- **Neuen Client anlegen** (Einzel-Formular) → 403 mit Dialog „Limit erreicht", kein Insert.
- **CSV-Import** → Import läuft durch; Zeilen, die über dem Limit liegen, werden übersprungen und zählen in der Result-Meldung als `rejected_for_license`.
- **Bestehende Clients** werden nie deaktiviert — Heartbeat, Remote-Zugriff, Rollouts laufen weiter.

> **Soft-Limit:** Wenn zeitgleich per CSV-Import und manuell neue Clients angelegt werden, kann das Limit kurz um 1–2 Einträge überschritten werden (Race-Condition — bewusstes Design). Für praktische Zwecke vernachlässigbar; bei Bedarf lässt sich die Lizenz mit höherem `max_clients` kurzfristig tauschen.

## Lager-Geräte

Ein Client mit gesetztem Flag **is_lager** (Detailformular → „Lager" aktivieren) zählt nicht zum Limit und wird in der Liste halbtransparent mit orangenem Chip angezeigt. Beim Ausrollen an einen Endkunden wird das Flag entfernt; der Client zählt ab dann wieder.

## Lizenzverlängerung

Rechtzeitig vor dem Ablaufdatum ein neues Bundle beim Hersteller anfordern. Das neue Bundle einfach über das alte hochladen — der Server ersetzt die vorhandene Datei atomar, ohne Neustart.

## Nächste Schritte

- Admin-Tools rund um Benutzer, TLS und Signing: [09 — Einstellungen](09-einstellungen.md).
- Backup der Datenbank: siehe [09 — Einstellungen → Backup & Restore](09-einstellungen.md#tab-backup--restore) — enthält auch die Lizenzdatei.
