# 11 — Lizenzierung

ThinForge verwaltet Clients **ohne Lizenzdatei unbegrenzt** und mit vollem Funktionsumfang — Delta-Updates, Rollouts und die Snapshot-Verwaltung inklusive. Lizenzpflichtig ist ausschließlich die **Aktivierung von VPN-Clients**: Ein signiertes Lizenz-Bundle legt fest, wie viele VPN-Clients gleichzeitig aktiviert sein dürfen (VPN-Sitzplätze). Ohne gültige Lizenz lässt sich kein VPN-Client aktivieren.

## Begriffe

| Begriff | Bedeutung |
|---|---|
| **VPN-Sitzplatz** | Ein VPN-Client, der einem Gerät zugeordnet und aktiviert ist. Deaktivieren gibt den Platz wieder frei. |
| **Keine Lizenz** | Keine Lizenzdatei hinterlegt. Client-Verwaltung unbegrenzt, 0 VPN-Sitzplätze. |
| **Lizenziert** | Gültiges Bundle, Ablaufdatum heute oder in der Zukunft. Sitzplätze = `max_vpn_clients` aus dem Bundle. |
| **Abgelaufen** | Ablaufdatum überschritten. Eine Kulanzfrist gibt es nicht: neue VPN-Clients lassen sich nicht mehr aktivieren, bestehende laufen weiter. |

## Status ansehen

Menü → **Einstellungen** → Tab **Lizenz** (nur Admins, auch lesend).

Die Statuskarte zeigt:

- **Lizenzdaten** (Lizenzinhaber, Lizenznummer, Gültig bis).
- **Belegte VPN-Sitzplätze** gegen das Limit („X von Y VPN-Clients belegt") als Fortschrittsbalken — farblich gekennzeichnet:
  - blau bei unter 90 %,
  - orange ab 90 %,
  - rot, sobald das Limit erreicht ist.
- **Banner**, falls die Lizenz abgelaufen ist.

Ohne Lizenz zeigt die Karte nur den Hinweis, dass die Client-Verwaltung unbegrenzt ist und eine Lizenz nur für VPN-Clients gebraucht wird — das ist kein Fehler, sondern der Default-Zustand vieler Installationen.

## Lizenz-Bundle hochladen

Vom Hersteller erhältst du ein `.7z`-Archiv, das `license.json` und `license.json.minisig` enthält. Archivpasswort und Signaturprüfung laufen intern; du hältst die Datei einfach bereit.

1. Karte **Lizenz hochladen** → Feld **Lizenzdatei (*.7z)** → Datei wählen.
2. **Hochladen und aktivieren**.
3. Server prüft Signatur und Inhalt. Mögliche Fehlermeldungen:
   - „Keine gültige Lizenzdatei" (`bundle_not_7z`) — Datei ist kein 7z (z. B. falsches Format).
   - „Lizenzdatei passt nicht zur Server-Version" (`bundle_wrong_password`) — 7z-Passwort passt nicht zum Backend-Build (wahrscheinlich Bundle aus anderer Version).
   - „Lizenzdatei unvollständig" (`bundle_missing_files`) — Archiv enthält nicht beide erforderlichen Dateien.
   - „Lizenzsignatur ungültig" (`signature_invalid`) — Minisign-Signatur ist ungültig; häufig Kopierproblem oder manipuliertes Bundle.
   - „Lizenz-Version nicht mehr unterstützt" (`license_version_unsupported`) — altes Bundle ohne VPN-Sitzplätze; eine neue Lizenz (v2) ausstellen lassen.
   - „Lizenz-Inhalt beschädigt" (`payload_malformed`) — JSON-Schema stimmt nicht.
4. Bei Erfolg aktualisiert sich die Karte direkt, das neue Limit ist sofort aktiv.

## Lizenz entfernen

**Lizenz entfernen** (nur sichtbar, wenn eine Lizenz hinterlegt ist; ohne Rückfrage). Die Datei wird vom Server gelöscht, die Installation hat danach 0 VPN-Sitzplätze. Bereits verbundene VPN-Clients werden nicht getrennt — die Deckelung greift erst beim nächsten Aktivieren.

## Verhalten beim Limit

- **VPN-Client aktivieren** ohne gültige Lizenz oder ohne freien Sitzplatz → der Server lehnt ab; ist das Kontingent voll, nennt die Meldung belegte und verfügbare Plätze. Die Aktivierung selbst beschreibt [13 — VPN](13-vpn.md).
- **Client anlegen, CSV-Import, Deployments, Rollouts, Updates** → von der Lizenz unabhängig.
- **Bestehende VPN-Clients** werden nie deaktiviert — auch nicht nach Ablauf oder Entfernen der Lizenz.

## Lizenzverlängerung

Rechtzeitig vor dem Ablaufdatum ein neues Bundle beim Hersteller anfordern. Das neue Bundle einfach über das alte hochladen — der Server ersetzt die vorhandene Datei atomar, ohne Neustart.

## Nächste Schritte

- Admin-Tools rund um Benutzer, TLS und Signing: [09 — Einstellungen](09-einstellungen.md).
- Backup: siehe [09 — Einstellungen → Backup & Restore](09-einstellungen.md#backup--restore) — das System-Backup enthält auch die Lizenzdatei.
