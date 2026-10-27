# 11 — Abonnement

Das Abonnement bezahlt den gehosteten VPN-Dienst bzw. die Freischaltung von VPN-Plätzen, nicht die Software: ThinForge selbst ist freie Software unter der GPL-3.0-or-later.

ThinForge verwaltet Clients **ohne Abonnement unbegrenzt** und mit vollem Funktionsumfang — Deployments, Delta-Updates und die Snapshot-Verwaltung inklusive. Ein Abonnement braucht es ausschließlich für die **Aktivierung von VPN-Clients**: Eine signierte Abonnementdatei legt fest, wie viele VPN-Clients gleichzeitig aktiviert sein dürfen (VPN-Sitzplätze). Ohne gültiges Abonnement lässt sich kein VPN-Client aktivieren.

## Begriffe

| Begriff | Bedeutung |
|---|---|
| **VPN-Sitzplatz** | Ein VPN-Client, der einem Gerät zugeordnet und aktiviert ist. Deaktivieren gibt den Platz wieder frei. |
| **Kein Abonnement** | Keine Abonnementdatei hinterlegt. Client-Verwaltung unbegrenzt, 0 VPN-Sitzplätze. |
| **Aktiv** | Gültige Abonnementdatei, Ablaufdatum heute oder in der Zukunft. Sitzplätze = `max_vpn_clients` aus der Datei. |
| **Abgelaufen** | Ablaufdatum überschritten. Eine Kulanzfrist gibt es nicht: neue VPN-Clients lassen sich nicht mehr aktivieren, bestehende laufen weiter. |

## Status ansehen

Menü → **Einstellungen** → Tab **Abonnement** (nur Admins, auch lesend).

Die Statuskarte zeigt:

- **Abonnementdaten** (Abonnent, Abonnementnummer, Gültig bis).
- **Belegte VPN-Sitzplätze** gegen das Limit („X von Y VPN-Clients belegt") als Fortschrittsbalken, solange das Abonnement gültig ist (ein abgelaufenes gibt keine Plätze mehr frei, dann fehlt der Balken) — farblich gekennzeichnet:
  - blau bei unter 90 %,
  - orange ab 90 %,
  - rot, sobald das Limit erreicht ist.
- **Banner**, falls das Abonnement abgelaufen ist.

Ohne Abonnement zeigt die Karte nur den Hinweis, dass die Client-Verwaltung unbegrenzt ist und ein Abonnement nur für VPN-Clients gebraucht wird — das ist kein Fehler, sondern der Default-Zustand vieler Installationen.

## Abonnementdatei hochladen

Vom Hersteller erhältst du ein `.7z`-Archiv, das `license.json` und `license.json.minisig` enthält. Archivpasswort und Signaturprüfung laufen intern; du hältst die Datei einfach bereit.

1. Karte **Abonnement hochladen** → Feld **Abonnementdatei (*.7z)** → Datei wählen.
2. **Hochladen und aktivieren**.
3. Server prüft Signatur und Inhalt. Mögliche Fehlermeldungen:
   - „Keine gültige Abonnementdatei" (`bundle_not_7z`) — Datei ist kein 7z (z. B. falsches Format).
   - „Abonnementdatei passt nicht zur Server-Version" (`bundle_wrong_password`) — 7z-Passwort passt nicht zum Backend-Build (wahrscheinlich eine Datei aus einer anderen Version).
   - „Abonnementdatei unvollständig" (`bundle_missing_files`) — Archiv enthält nicht beide erforderlichen Dateien.
   - „Signatur der Abonnementdatei ungültig" (`signature_invalid`) — Minisign-Signatur ist ungültig; häufig Kopierproblem oder manipulierte Datei.
   - „Version der Abonnementdatei nicht mehr unterstützt" (`license_version_unsupported`) — alte Datei ohne VPN-Sitzplätze; eine neue Abonnementdatei (v2) ausstellen lassen.
   - „Inhalt der Abonnementdatei beschädigt" (`payload_malformed`) — JSON-Schema stimmt nicht.
   - „Abonnementdatei kann nicht verarbeitet werden" (`license_invalid`) — jeder andere Fehler, etwa eine Datei über 1 MiB (echte Abonnementdateien haben wenige Kilobyte).
4. Bei Erfolg aktualisiert sich die Karte direkt, das neue Limit ist sofort aktiv.

## Abonnement entfernen

**Abonnement entfernen** (nur sichtbar, wenn ein Abonnement hinterlegt ist; ohne Rückfrage). Die Datei wird vom Server gelöscht, die Installation hat danach 0 VPN-Sitzplätze. Bereits verbundene VPN-Clients werden nicht getrennt — die Deckelung greift erst beim nächsten Aktivieren.

## Verhalten beim Limit

- **VPN-Client aktivieren** ohne gültiges Abonnement oder ohne freien Sitzplatz → der Server lehnt ab; ist das Kontingent voll, nennt die Meldung die belegten Plätze und das Limit. **Ganze Gruppe aktivieren** prüft Gerät für Gerät und bricht am ersten Gerät ohne freien Platz ab; die bis dahin aktivierten Geräte bleiben aktiviert — wie viele es waren, nennt die Meldung dann nicht. Die Aktivierung selbst beschreibt [13 — VPN](13-vpn.md).
- **Client anlegen, CSV-Import, Deployments, Updates** → vom Abonnement unabhängig.
- **Bestehende VPN-Clients** werden nie deaktiviert — auch nicht nach Ablauf oder Entfernen des Abonnements.

## Abonnement verlängern

Rechtzeitig vor dem Ablaufdatum eine neue Abonnementdatei beim Hersteller anfordern. Die neue Datei einfach über die alte hochladen — der Server ersetzt die vorhandene Datei atomar, ohne Neustart.

## Nächste Schritte

- Admin-Tools rund um Benutzer, TLS und Signing: [09 — Einstellungen](09-einstellungen.md).
- Backup: siehe [09 — Einstellungen → Backup & Restore](09-einstellungen.md#backup--restore) — das System-Backup enthält auch die Abonnementdatei.
