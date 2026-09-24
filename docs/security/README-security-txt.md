# Pflege der `security.txt`

- Die Datei hier ist **die Quelle**; `Website/.well-known/security.txt` ist eine Kopie und wird nie getrennt bearbeitet. Nach jeder Änderung: kopieren, hochladen, `cmp` prüfen.
- Warum nicht klarsigniert: Nachsignieren bei jeder Textänderung, ohne belastbaren Zugewinn gegenüber HTTPS an drei kanonischen Orten.
- `Expires` gilt knapp unter einem Jahr. Erneuerung ist ein Punkt in `docs/TODO.md`; danach `python3 scripts/check-security-txt.py`.
- Pfad und Dateiname sind fest — sie stehen in drei `Canonical`-Zeilen und in `PushDevto_git_thinforge.sh`.
