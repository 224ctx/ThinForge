# Sicherheitsupdates: Bereitstellungsdauer und Update-Pfad

**Stand:** 2026-09-16
**Gilt für:** ThinForge — Server-Stack, Agent, Client-Images
**Rechtsgrundlage:** Pflichtangabe nach Verordnung (EU) 2024/2847 (Cyber Resilience Act), Artikel 13(8)

Dieses Dokument sagt, wie lange es Sicherheitsupdates gibt, in welcher Form,
wie ein Betreiber davon erfährt, wie sie auf seine Anlage kommen und woran er
den Stand selbst nachprüfen kann.

---

## 1. Bereitstellungsdauer

5 Jahre ab Veröffentlichung einer Version. Sicherheitsupdates werden als Aktualisierung auf den jeweils aktuellen Release-Stand geliefert, nicht als Rückportierung in einen älteren Stand. Wer nicht aktualisiert, ist nicht gepatcht.

Der Grund für diese Form steht offen da: ThinForge wird von einer Person
gepflegt. Zwei Linien parallel zu pflegen — die aktuelle und daneben eine
ältere, in die zurückportiert wird — ist die Zusage, die zuerst bricht. Darum
gibt es nur eine Linie, und sie wird vorwärts gepflegt.

---

## 2. Wie ein Betreiber von einem Patch erfährt

Es gibt heute **keinen Push-Kanal**: keine Mailingliste, keine
Benachrichtigungsmail, keinen Feed. Wer wissen will, ob ein Sicherheitsupdate
vorliegt, sieht an diesen drei Stellen nach:

| Quelle | Ort | Was dort steht |
|---|---|---|
| Changelog | `docs/CHANGELOG.md` (deutsch), `docs/CHANGELOG.en.md` (englisch) im Release-Repository | jede Änderung des freigegebenen Stands, Sicherheitskorrekturen eingeschlossen |
| Release-Marke | unveränderlicher Registry-Tag `vJJJJ.MM.TT` (bei mehreren Freigaben am selben Tag mit angehängter laufender Nummer) und der zugehörige Commit `release: vJJJJ.MM.TT (Source <Quell-Commit>)` im Release-Repository | dass ein neuer Stand freigegeben wurde und welcher |
| Advisories | `docs/security/advisories/` im Release-Repository | Schwachstellen in ausgelieferten Ständen — ab mittlerer Schwere oder extern gemeldet, dann unabhängig von der Schwere: betroffene Stände, Wirkung, der Stand mit dem Fix |

Kommt später ein Push-Kanal dazu, wird er hier geführt. Solange dieser
Abschnitt keinen nennt, gibt es keinen — eine Zusage, benachrichtigt zu werden,
besteht nicht. Ein Betreiber sollte den Abgleich deshalb als wiederkehrenden
Termin führen, nicht als Reaktion auf eine Nachricht.

---

## 3. Wie ein Update auf die Anlage kommt

ThinForge besteht aus drei Teilen, die getrennt aktualisiert werden.

**Server-Stack (Container-Images).** Jeder freigegebene Stand trägt in der
Registry zwei Marken: den unveränderlichen Tag `vJJJJ.MM.TT`, der dauerhaft auf
genau diese Images zeigt und als Rückfallmarke dient, und den mitwandernden Tag
`:release`, der immer auf den aktuellen freigegebenen Stand zeigt. `./deploy.sh`
im Release-Repository zieht `:release` und startet den Stack neu; gebaut wird
dabei nichts. Ein Server-Update ist damit ein Befehl.

**Agent auf den Clients.** Der Go-Agent vergleicht im laufenden Betrieb die vom
Server gemeldete Agent-Version mit der installierten, lädt bei Abweichung das
neue Binary, prüft dessen minisign-Signatur gegen den auf dem Client
hinterlegten öffentlichen Schlüssel und startet sich neu. Ohne gültige Signatur
wird das Binary verworfen. Der Betreiber muss dafür nichts tun; die Verteilung
läuft an, sobald auf dem Server eine neue Agent-Version bereitliegt.

**Client-Images.** Ein neuer Image-Stand entsteht als Baseline oder als Delta,
wird mit demselben Ed25519-Schlüssel minisign-signiert und über eine Zuweisung
unter **Cloning → Updates** an Gruppen oder einzelne Clients verteilt. Der Client
prüft die Signatur, bevor er den Stand anwendet; ohne gültige Signatur wird der
Stand verworfen.
Das ist der einzige der drei Wege, der eine Entscheidung des Betreibers
verlangt: welche Gruppe wann.

Die Bedienschritte stehen in den Anleitungen und werden hier nicht wiederholt:
[6 — Rollouts](../../anleitungen/DE/06-rollouts.md),
[Workflow: Update an Gruppe verteilen](../../anleitungen/DE/workflows/update-verteilen.md),
[12 — Sicherheit und CVE-Scan](../../anleitungen/DE/12-sicherheit-und-cve-scan.md).

---

## 4. Auslaufende Linien (EOL)

ThinForge wird als eine einzige, vorwärts gepflegte Release-Linie geführt. Eine
Linie läuft aus, sobald ein Enddatum an zwei Stellen steht: als Eintrag im
Changelog und in diesem Abschnitt. Der Changelog-Eintrag macht das Datum zum
Ereignis, dieser Abschnitt hält es dauerhaft fest.

**Stand 2026-09-16 ist keine Linie ausgelaufen.**

Ab dem genannten Enddatum bekommt eine ausgelaufene Linie keine
Sicherheitsupdates mehr. Bekannte Schwachstellen darin werden weder behoben noch
in sie zurückportiert. Wer sie weiterbetreibt, betreibt sie ungepatcht.

---

## 5. Prüfbarkeit: SBOM und Schwachstellenlage

Der Paketstand und die bekannte Schwachstellenlage eines Release lassen sich
ohne Rückfrage beim Hersteller nachweisen — im laufenden System:

- **Scan.** Ein Administrator startet ihn in der Oberfläche unter
  **Einstellungen → Sicherheit → Vulnerability-Scan**. Der Lauf erzeugt für
  jedes Container-Image eine Software Bill of Materials (Syft) und einen
  Schwachstellenbericht (Grype) und wertet beides gegen die Akzeptanzliste aus.
- **SBOM-Ausgabe.** Unter **Einstellungen → Sicherheit → SBOM-Download** liegen die
  erzeugten Stücklisten je Image in drei Formaten (Syft-JSON, CycloneDX, SPDX)
  zum Herunterladen — für eigene Compliance-Prüfungen oder zum Archivieren des
  Stands zu einem Zeitpunkt. Beide Bereiche, Scan und SBOM-Download, sind nur
  für Administratoren sichtbar.
- **Bekannte, derzeit nicht behebbare Befunde** stehen mit Begründung und
  Re-Check-Datum in [`vulnerability-acceptance.md`](vulnerability-acceptance.md).
  Der Scan gleicht seine Funde gegen diese Liste ab; was dort nicht steht, ist
  offen.
- Die Bedienung beschreibt
  [12 — Sicherheit und CVE-Scan](../../anleitungen/DE/12-sicherheit-und-cve-scan.md).

Ein Befund, der in keiner dieser Quellen auftaucht, gehört gemeldet. Der
Meldeweg steht in [`security.txt`](security.txt).
