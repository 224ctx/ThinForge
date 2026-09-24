# Advisories

**Dieses Verzeichnis ist ein Veröffentlichungsort, kein Arbeitsplatz.** Was
hier committet wird, geht beim nächsten Sync-Lauf hinaus — im Dev-Repo über
die Whitelist-Zeile `docs/security/advisories/*` in `PushDevto_git_thinforge.sh`,
im Release-Repo über den Verzeichnis-Spiegel `MIRROR_DIRS` in
`PromoteDevToRelease.sh`. Ein Entwurf, der hier committet wird, wäre eine
veröffentlichte Schwachstelle ohne Fix.

## Wegregel

Ein Advisory entsteht als Entwurf unter `docs/compliance/advisory-drafts/`
(ein interner Pfad — kein Link, da er in diesem veröffentlichten Dokument ins
Leere zeigen würde). Der Umzug hierher erfolgt per `git mv` erst, wenn der Fix
im Release-Kanal steht. **Der Umzug ist die Veröffentlichung** — kein
separater Schritt danach.

## Nummernvergabe

`ThinForge-YYYY-NNNN`, laufend ab `2026-0001`, unabhängig von einer
CVE-ID. Die CVE-ID wird im Kopf zusätzlich geführt, sobald eine vergeben ist.

## Statuswerte

- `veröffentlicht`
- `zurückgezogen`

`entwurf` existiert als Status nur ausserhalb dieses Verzeichnisses, in
`docs/compliance/advisory-drafts/`.

## Wann ein Advisory entsteht

Für jede Schwachstelle in einem ausgelieferten (freigegebenen) Stand mit
Schwere ≥ mittel (Bewertungsmassstab CVSS 4.0) — sowie, unabhängig von der
Schwere, für jede extern gemeldete Schwachstelle in einem ausgelieferten
Stand. Schwachstellen, die nur einen Entwicklungsstand betreffen, lösen kein
Advisory aus.

## Vorlage

[`_vorlage.md`](_vorlage.md) ist die Kopiervorlage für ein neues Advisory und
selbst kein Advisory.
