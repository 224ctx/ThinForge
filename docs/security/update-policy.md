# Sicherheitsupdates: Bereitstellungsdauer und Update-Pfad

**Stand:** 2026-10-20
**Gilt für:** ThinForge — Server-Stack, Agent, Client-Images
**Rechtsgrundlage:** Pflichtangabe nach Verordnung (EU) 2024/2847 (Cyber Resilience Act), Artikel 13(8); Meldepflichten nach Artikel 14 (Abschnitt 6)

Dieses Dokument sagt, wie lange es Sicherheitsupdates gibt, in welcher Form,
wie ein Betreiber davon erfährt, wie sie auf seine Anlage kommen, woran er
den Stand selbst nachprüfen kann und wie ThinForge aktiv ausgenutzte
Schwachstellen und schwerwiegende Sicherheitsvorfälle meldet.

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
Termin führen, nicht als Reaktion auf eine Nachricht. Ausgenommen sind aktiv
ausgenutzte Schwachstellen und schwerwiegende Sicherheitsvorfälle: über sie
informiert ThinForge die Betroffenen von sich aus (Abschnitt 6).

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

---

## 6. Meldepflichten nach CRA Artikel 14

Seit dem 11. September 2026 gilt Artikel 14 der Verordnung (EU) 2024/2847
(Art. 71 Abs. 2), früher als die übrigen Herstellerpflichten (11. Dezember
2027). Danach meldet ThinForge zwei Arten von Ereignissen an die Behörden und
informiert die Betroffenen. Was hier steht, ist der Ablauf des Herstellers,
keine Rechtsberatung; Stellen, deren Auslegung oder Umsetzung noch nicht
bestätigt ist, tragen den Vermerk **zu prüfen**.

### 6.1 Was gemeldet wird

| | Aktiv ausgenutzte Schwachstelle | Schwerwiegender Sicherheitsvorfall |
|---|---|---|
| Grundlage | Art. 14 Abs. 1 und 2 | Art. 14 Abs. 3 bis 5 |
| Gemeint | eine Schwachstelle in einem ausgelieferten Stand von ThinForge, für die es einen verlässlichen Beleg gibt, dass sie ohne Erlaubnis des Systeminhabers ausgenutzt wurde (Begriffsbestimmung in Art. 3). Ein funktionierender Proof-of-Concept, ein hoher CVSS-Wert oder ein Scanner-Fund allein sind keine Ausnutzung. | ein Vorfall mit Auswirkung auf die Sicherheit von ThinForge, der die Fähigkeit beeinträchtigt oder beeinträchtigen kann, Verfügbarkeit, Authentizität, Integrität oder Vertraulichkeit sensibler oder wichtiger Daten oder Funktionen zu schützen, oder der zum Einschleusen oder Ausführen von Schadcode in ThinForge oder in den Systemen eines Nutzers geführt hat oder führen kann (Art. 14 Abs. 5) — etwa eine kompromittierte Registry, ein abgeflossener Signierschlüssel oder eine Agent-Binary unklarer Herkunft |
| Frühwarnung | unverzüglich, spätestens **24 Stunden** nach Kenntnis | unverzüglich, spätestens **24 Stunden** nach Kenntnis |
| Meldung | unverzüglich, spätestens **72 Stunden** nach Kenntnis | unverzüglich, spätestens **72 Stunden** nach Kenntnis |
| Abschlussbericht | spätestens **14 Tage**, nachdem eine Korrektur oder Abhilfe verfügbar ist | spätestens **einen Monat** nach der 72-Stunden-Meldung |

Die Fristen laufen ab dem Zeitpunkt, zu dem ThinForge von dem Ereignis
Kenntnis erhält; er wird in UTC festgehalten. Es ist Kalenderzeit — Nächte,
Wochenenden und Feiertage zählen mit. Auch die 72 Stunden laufen ab der
Kenntnis, nicht ab der Frühwarnung. Was zur Frühwarnung noch nicht feststeht,
wird als „noch nicht ermittelt“ gemeldet und in der Meldung nachgereicht. Im
Zweifel, ob ein Fall meldepflichtig ist, wird er wie ein meldepflichtiger
behandelt: eine zu früh gestartete Uhr kostet eine Meldung, eine zu spät
gestartete die Frist.

### 6.2 Wohin gemeldet wird

Gemeldet wird über die einheitliche Meldeplattform der ENISA (Art. 16), die
„CRA Single Reporting Platform“. Eingereicht wird dort über den Endpunkt des
als Koordinator benannten CSIRT des Mitgliedstaats, in dem ThinForge seine
Hauptniederlassung hat; dieselbe Einreichung ist gleichzeitig der ENISA
zugänglich (Art. 14 Abs. 1, 3 und 7). ThinForge sitzt in Deutschland;
koordinierendes CSIRT ist CERT-Bund im BSI.

- **Plattform:** seit dem 11. September 2026 in Betrieb, erreichbar unter
  `https://portal.cra-srp.enisa.europa.eu/`. Der Zugang setzt ein
  EU-Login-Konto mit Mehr-Faktor-Authentisierung voraus. Als Vertreter des
  Herstellers registriert man sich dort erst im Bedarfsfall; die Prüfung dieser
  Vertretung durch das koordinierende CSIRT läuft parallel und hält eine
  Meldung nicht auf.
- **Koordinierendes CSIRT:** Die Verordnung meint das CSIRT, das nach Art. 12
  Abs. 1 der Richtlinie (EU) 2022/2555 (NIS 2) als Koordinator benannt ist
  (Art. 3 Nr. 51). In Deutschland ist das BSI nach § 5 Abs. 1 Satz 2 BSIG der
  nationale Koordinator für die koordinierte Offenlegung von Schwachstellen;
  die ENISA führt CERT-Bund im BSI als koordinierendes CSIRT für Deutschland,
  und das BSI bezeichnet es selbst so.
- **Ausnahme:** Ist die Plattform vorübergehend nicht erreichbar, geht die
  Meldung auf Hinweis des BSI innerhalb derselben Fristen per E-Mail an
  CERT-Bund. Sobald die Plattform wieder erreichbar ist, reicht ThinForge die
  Meldung dort nach. Das ist eine eigene Zusage, keine Vorgabe des BSI; Grund:
  Art. 14 Abs. 1 und 3 nennen die Plattform als Meldeweg.
- Eine Adresse, die nicht belegt ist, wird nicht benutzt. Eine Meldung an eine
  falsche Stelle gilt als nicht abgesetzt.

Belege, alle abgerufen am 2026-10-20:
ENISA, „The CRA Single Reporting Platform is launched“ (11.09.2026),
<https://www.enisa.europa.eu/news/the-cra-single-reporting-platform-is-launched>;
ENISA, „CRA SRP Guidance - AR User Registration“,
<https://www.enisa.europa.eu/topics/product-security/single-reporting-platform-srp/cra-srp-guidance-ar-user-registration>;
ENISA, „List of CSIRTs Designated as Coordinators“,
<https://www.enisa.europa.eu/topics/product-security/vulnerability-services/eu-incident-response-and-cyber-crisis-management/single-reporting-platform-srp/list-of-csirts-designated-as-coordinators>;
BSI, „Cyber Resilience Act: Meldepflicht startet“ (11.09.2026),
<https://www.bsi.bund.de/DE/Service-Navi/Presse/Pressemitteilungen/Presse2026/260911_CRA_Meldepflicht_Schwachstellen.html>;
BSI, „CRA Single Reporting Platform“,
<https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Informationen-und-Empfehlungen/Cyber_Resilience_Act/Single_Reporting_Platform-CRA/single_reporting_platform-cra_node.html>;
§ 5 BSIG, <https://www.gesetze-im-internet.de/bsig_2025/__5.html>.

### 6.3 Was eine Meldung enthält

Die Angaben folgen Art. 14 Abs. 2 und 4; was in einer früheren Stufe schon
gemeldet ist, wird nicht wiederholt, sondern nur ergänzt.

- **Frühwarnung:** dass eine aktiv ausgenutzte Schwachstelle bzw. ein
  schwerwiegender Vorfall vorliegt, das betroffene Produkt und — soweit
  bekannt — die Mitgliedstaaten, in denen ThinForge bereitgestellt wurde; beim
  Vorfall zusätzlich, ob rechtswidriges oder böswilliges Handeln vermutet wird.
- **Meldung (72 Stunden):** allgemeine Angaben zum Produkt und zu den
  betroffenen Ständen, zur Art der Ausnutzung und der Schwachstelle bzw. zur
  Art des Vorfalls samt erster Bewertung, die ergriffenen Korrektur- oder
  Abhilfemaßnahmen, die Maßnahmen, die Nutzer selbst ergreifen können, und wie
  vertraulich die Angaben aus Sicht von ThinForge sind.
- **Abschlussbericht:** bei einer Schwachstelle ihre Beschreibung mit
  Schweregrad und Auswirkung, Angaben zu einem Angreifer, soweit verfügbar, und
  das bereitgestellte Sicherheitsupdate bzw. die Abhilfe; bei einem Vorfall
  eine ausführliche Beschreibung mit Schweregrad und Auswirkung, die
  wahrscheinliche Art der Bedrohung bzw. die Ursache und die ergriffenen und
  laufenden Abhilfemaßnahmen.

Vorlage (Frühwarnung; Meldung und Abschlussbericht übernehmen sie und ergänzen
die Punkte 5 bis 9):

```text
Betreff: <Frühwarnung | Meldung | Abschlussbericht> nach Art. 14 CRA — <Vorgangsnummer> — ThinForge

1. Hersteller: ThinForge, Andreas Christ — Kontakt: security@thinforge.org
2. Produkt: ThinForge <Komponente: Server-Stack | Agent | Client-Image>,
   betroffene Stände: <vJJJJ.MM.TT> bis <vJJJJ.MM.TT>
3. Art: [ ] aktiv ausgenutzte Schwachstelle  [ ] schwerwiegender Sicherheitsvorfall
4. Kenntnis: <JJJJ-MM-TT hh:mm UTC>, Quelle: <Meldung | eigener Fund | Fremdbericht>
5. Beschreibung: <Wirkung, betroffene Funktion, Voraussetzungen; Ursache, soweit ermittelt>
6. Beleg bzw. Verdacht: <Beleg der Ausnutzung | Verdacht auf böswilliges Handeln: ja/nein>
7. Bereitgestellt in: <Mitgliedstaaten, soweit bekannt, sonst „noch nicht ermittelt“>
8. Maßnahmen: ergriffen: <…>; für Nutzer: <Update, Behelfslösung oder „keine“>
9. Vertraulichkeit der Angaben: <Einschätzung>
10. Nächste Stufe: <Meldung bis … | Abschlussbericht bis …>
```

### 6.4 Information der Nutzer

Nach Kenntnis einer aktiv ausgenutzten Schwachstelle oder eines
schwerwiegenden Vorfalls informiert ThinForge die betroffenen Nutzer — wo
angebracht alle — über das Ereignis und über Maßnahmen, die sie selbst
ergreifen können (Art. 14 Abs. 8). Wege:

- ein Advisory in `docs/security/advisories/` im Release-Repository mit
  betroffenen Ständen, Wirkung, Behelfslösung und dem Stand mit dem Fix,
- ein Eintrag im Changelog, sobald der Fix freigegeben ist,
- eine direkte Nachricht an die Betreiber, deren Kontakt ThinForge vorliegt.

**Zu prüfen, mit Empfehlung:** Art. 14 Abs. 8 verlangt die Information der
Nutzer „gegebenenfalls in einem strukturierten, maschinenlesbaren Format, das
leicht automatisch zu verarbeiten ist“. Die Advisories liegen heute nur als
Markdown vor. Ob die Verordnung von ThinForge ein solches Format verlangt, legt
diese Seite nicht aus. Empfohlen — und noch nicht umgesetzt — ist, zusätzlich
CSAF 2.0 zu liefern (Common Security Advisory Framework, OASIS-Standard vom
18. November 2022): ein offener, internationaler Standard für genau diesen
Zweck, den das BSI Unternehmen empfiehlt und dessen Anwendung auf
Sicherheitshinweise es in der Technischen Richtlinie TR-03191 beschreibt; ein
CSAF-Dokument werten die Werkzeuge der Betreiber ohne Handarbeit aus. CSAF 2.1
ist noch ein Entwurf (Committee Specification Draft 03 vom 11. September 2026).

Die Spezifikation (Abschnitt 7) kennt drei aufeinander aufbauende Rollen für
den Herausgeber; jede ist für sich ein gültiger Stand:

| Stufe | Was dazukommt | Aufwand (Schätzung) |
|---|---|---|
| 1 — *CSAF publisher* (Anforderungen 1–4) | je Advisory ein CSAF-Dokument im Profil „Security Advisory“ als JSON neben dem Markdown in `docs/security/advisories/`, Dateiname nach Abschnitt 5.1 der Spezifikation (`thinforge-jjjj-nnnn.json`), gekennzeichnet TLP:WHITE und wie das Markdown frei über TLS abrufbar; vor der Veröffentlichung gegen das Schema geprüft | einmalig etwa ein Arbeitstag (Vorlage neben `_vorlage.md`, Prüfschritt im Veröffentlichungsablauf), danach etwa eine Stunde je Advisory |
| 2 — *CSAF provider* (zusätzlich 5–7, eine aus 8–10, 11–14) | `provider-metadata.json` unter `https://thinforge.org/.well-known/csaf/`, die Dokumente dort in Jahresordnern mit `index.txt`, `changes.csv` und Verzeichnisansicht, ohne Weiterleitungen | einmalig ein bis zwei Arbeitstage, je Advisory ein zusätzlicher Upload auf die Website |
| 3 — *CSAF trusted provider* (zusätzlich 18–20) | je Dokument eine Prüfsumme (SHA-256 oder SHA-512) und eine OpenPGP-Signatur, dazu der öffentliche Schlüssel | einmalig wenige Stunden, etwa mit dem vorhandenen Schlüssel aus der `security.txt`; je Advisory ein Signierschritt von Hand |

Werkzeuge, frei unter der Apache-Lizenz 2.0: der Web-Editor „BSI
Secvisogram“ für CSAF-Dokumente und aus `github.com/gocsaf/csaf` die Programme
`csaf_validator` (Prüfung gegen das Schema), `csaf_checker` (Prüfung eines
Anbieters nach Abschnitt 7 der Spezifikation) und `csaf_provider`.

Zwei Punkte reichen über das Repository hinaus: Stufe 2 legt Dateien auf die
Website `thinforge.org`, die getrennt vom Repository gepflegt und von Hand
hochgeladen wird. Und wer zusätzlich das `CSAF:`-Feld in die `security.txt`
aufnimmt (Anforderung 8; für Stufe 2 genügt der feste Pfad aus Anforderung 9),
ändert eine Datei, deren Kopie auf der Website byte-gleich bleiben muss.

Empfehlung: Stufe 1 mit dem ersten Advisory einführen — bisher ist keines
erschienen, es fällt also nur der einmalige Aufwand an. Stufe 2 bald danach
folgen lassen, denn erst die `provider-metadata.json` macht die Dokumente für
Werkzeuge auffindbar; Stufe 1 allein ist maschinenlesbar, aber nicht
auffindbar. Stufe 3 ist eine Option. CSAF kennt
außerdem ein VEX-Profil; derselbe Weg könnte später auch Aussagen tragen,
welche bekannten Schwachstellen ThinForge nicht betreffen. **Die Entscheidung
steht aus.**

Belege, alle abgerufen am 2026-10-20: OASIS, „Common Security Advisory
Framework Version 2.0“, <https://docs.oasis-open.org/csaf/csaf/v2.0/os/csaf-v2.0-os.html>;
OASIS, „Common Security Advisory Framework Version 2.1“ (letzter Stand),
<https://docs.oasis-open.org/csaf/csaf/v2.1/csaf-v2.1.html>;
BSI, „Management Blitzlicht: BSI empfiehlt Einsatz von CSAF“ (02.10.2025),
<https://www.bsi.bund.de/DE/Service-Navi/Presse/Alle-Meldungen-News/Meldungen/CSAF-Management-Blitzlicht_251002.html>;
BSI, „BSI TR-03191 Common Security Advisory Framework (CSAF)“,
<https://www.bsi.bund.de/DE/Themen/Unternehmen-und-Organisationen/Standards-und-Zertifizierung/Technische-Richtlinien/TR-nach-Thema-sortiert/tr03191/tr-03191.html>;
<https://github.com/gocsaf/csaf>; <https://github.com/secvisogram/secvisogram>.

### 6.5 Zuständigkeit

ThinForge wird von einer Person gepflegt (Abschnitt 1): Andreas Christ ist
Hersteller, Entwickler, Freigeber und Meldender zugleich. Kontaktpunkt für
Meldungen von außen und für Rückfragen der Behörden ist
`security@thinforge.org` (siehe [`security.txt`](security.txt)), das Postfach
wird an jedem Werktag gesichtet. Eine Vertretung gibt es derzeit nicht: fällt
der Verantwortliche aus, kann niemand fristgerecht melden. Das ist ein
bekanntes, offenes Risiko und wird hier nicht als gelöst dargestellt.

**Zu prüfen:** ob ThinForge — freie Software unter GPL-3.0-or-later mit
kostenpflichtigem VPN-Abonnement — in vollem Umfang als Hersteller im Sinne der
Verordnung gilt. Bis das geklärt ist, verfährt ThinForge so, als ob. Die Frage
ist rechtlich und lässt sich durch Recherche nicht schließen. Die eigene
Vorarbeit steht in der internen Scope-Analyse
`docs/compliance/cra-scope-analysis.md`, Abschnitt 1.1; die rechtliche Prüfung
ist in der internen Aufgabenliste `docs/TODO.md` als „Geschäftstätigkeit und
Open-Source-Ausnahme rechtlich prüfen lassen“ vorgemerkt. Beide Dateien werden
nicht veröffentlicht, daher hier kein Link.
