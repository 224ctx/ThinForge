#!/bin/bash
#
# Skripttest fuer das Versionstor und die Journal-Migration in
# agent-migrate.sh (Haertungspaket 2, V6/V7/V15; Spec §5.1).
#
#   bash scripts/Tools-ISO/advanced/tests/agent-migrate-unit-gate.sh
#
# Das Skript wird gesourct (main laeuft nur beim Aufruf als Skript), die
# Naehte ETC, JOURNAL_DIR, SYSTEMCTL und JOURNALCTL zeigen auf ein
# Temp-Verzeichnis und einen Zaehler. Geprueft wird:
#   - ohne THINFORGE_AGENT_VERSION (Agent bis v2.27.0): die ALTE Unit, keine
#     Recover-Unit — ein alter Agent darf die Notify-Unit nie bekommen;
#   - mit v2.28.0 (und git-describe-Formen davon): die neue Unit samt
#     Recover-Unit, Markerzeile unit_drift_repaired;
#   - zweiter Lauf: nichts aendert sich, kein daemon-reload, keine Markerzeile;
#   - Rollback auf v2.27.0: alte Unit zurueck, Recover-Unit weg;
#   - Journal: Symlink, Drop-in, Verschieben eines echten Verzeichnisses,
#     Idempotenz.
set -euo pipefail

HIER="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKRIPT="$HIER/../agent-migrate.sh"
REPO="$(cd "$HIER/../../../.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fehler=0
ok()   { echo "  ok   $*"; }
bad()  { echo "  FAIL $*"; fehler=$((fehler + 1)); }
check() { if eval "$1"; then ok "$2"; else bad "$2"; fi; }

# Zaehler fuer systemctl/journalctl-Aufrufe (statt der echten Programme).
CALLS="$TMP/calls"
: > "$CALLS"
fake_ctl() { echo "$*" >> "$CALLS"; }
calls() { grep -cF -- "$1" "$CALLS" || true; }

# Das Skript sourcen: main laeuft nicht, die Funktionen und Texte sind da.
# shellcheck disable=SC1090
source "$SKRIPT"
ETC="$TMP/root"
JOURNAL_DIR="$TMP/data/log/journal"
SYSTEMCTL=fake_ctl
JOURNALCTL=fake_ctl
UNIT="$ETC/etc/systemd/system/thinforge-agent.service"
RECOVER="$ETC/etc/systemd/system/thinforge-agent-recover.service"
mkdir -p "$ETC/etc/systemd/system"

V1="$REPO/scripts/Tools-ISO/advanced/agent-migrate.sh"   # Referenz fuer die alte Fassung: der Heredoc selbst
NEU="$REPO/agent-go/thinforge-agent.service"
REC="$REPO/agent-go/thinforge-agent-recover.service"

echo "Versionstor:"
for v in "" dev v2.27.0 v2.27.9; do
    if unit_hardened_for_version "$v"; then bad "Version '$v' bekommt die gehaertete Unit"; else ok "Version '$v' bekommt die alte Unit"; fi
done
for v in v2.28.0 v2.28.0-7-gabc1234 v2.28.1 v2.29.0 v3.0.0; do
    if unit_hardened_for_version "$v"; then ok "Version '$v' bekommt die gehaertete Unit"; else bad "Version '$v' bekommt die alte Unit"; fi
done

echo "Migration ohne Versionsvariable (Agent bis v2.27.0):"
printf '[Unit]\nDescription=drift\n' > "$UNIT"
AGENT_VERSION=""
out=$(migrate_agent_unit)
check '[ "$(cat "$UNIT")" = "$AGENT_UNIT_CANONICAL" ]' "schreibt die alte Unit"
check 'grep -q "^Type=simple$" "$UNIT" && ! grep -q "WatchdogSec" "$UNIT"' "alte Unit: Type=simple, kein Watchdog"
check '[ ! -e "$RECOVER" ]' "keine Recover-Unit"
check 'grep -q "@@tf-event unit_drift_repaired unit=thinforge-agent.service" <<<"$out"' "Markerzeile unit_drift_repaired"
check '[ "$(calls daemon-reload)" = 1 ]' "ein daemon-reload"

echo "Migration mit v2.28.0:"
: > "$CALLS"
AGENT_VERSION="v2.28.0"
out=$(migrate_agent_unit)
check '[ "$(cat "$UNIT")" = "$AGENT_UNIT_V2_CANONICAL" ]' "schreibt die gehaertete Unit"
check 'cmp -s "$UNIT" "$NEU"' "gehaertete Unit byte-gleich mit agent-go/thinforge-agent.service"
check 'cmp -s "$RECOVER" "$REC"' "Recover-Unit byte-gleich mit agent-go/thinforge-agent-recover.service"
check 'grep -q "@@tf-event unit_drift_repaired unit=thinforge-agent.service" <<<"$out"' "Markerzeile unit_drift_repaired"
check '! grep -q "unit=thinforge-agent-recover.service" <<<"$out"' "Anlegen der Recover-Unit ist keine Drift"
check '[ "$(calls daemon-reload)" = 1 ]' "ein daemon-reload"

echo "Zweiter Lauf mit v2.28.0 (idempotent):"
: > "$CALLS"
vorher_unit=$(stat -c %Y "$UNIT"); vorher_rec=$(stat -c %Y "$RECOVER")
sleep 1
out=$(migrate_agent_unit)
check '[ -z "$out" ]' "keine Ausgabe, keine Markerzeile"
check '[ "$(calls daemon-reload)" = 0 ]' "kein daemon-reload"
check '[ "$(stat -c %Y "$UNIT")" = "$vorher_unit" ] && [ "$(stat -c %Y "$RECOVER")" = "$vorher_rec" ]' "Dateien unberuehrt"

echo "git-describe-Form v2.28.0-7-gabc1234 bleibt bei der gehaerteten Unit:"
AGENT_VERSION="v2.28.0-7-gabc1234"
out=$(migrate_agent_unit)
check '[ -z "$out" ] && cmp -s "$UNIT" "$NEU"' "nichts geaendert"

echo "Rollback der Flotte auf v2.27.0 (Tor in beide Richtungen):"
: > "$CALLS"
AGENT_VERSION="v2.27.0"
out=$(migrate_agent_unit)
check '[ "$(cat "$UNIT")" = "$AGENT_UNIT_CANONICAL" ]' "alte Unit zurueck"
check '[ ! -e "$RECOVER" ]' "Recover-Unit entfernt"
check 'grep -q "@@tf-event unit_drift_repaired unit=thinforge-agent.service" <<<"$out"' "Markerzeile unit_drift_repaired"
check '[ "$(calls daemon-reload)" = 1 ]' "ein daemon-reload"

echo "Drift der Recover-Unit wird repariert und gemeldet:"
AGENT_VERSION="v2.28.0"
migrate_agent_unit >/dev/null
echo "kaputt" > "$RECOVER"
out=$(migrate_agent_unit)
check 'cmp -s "$RECOVER" "$REC"' "Recover-Unit repariert"
check 'grep -q "@@tf-event unit_drift_repaired unit=thinforge-agent-recover.service" <<<"$out"' "Markerzeile fuer die Recover-Unit"

echo "Ohne Unit-Datei (kein verwaltetes Geraet) passiert nichts:"
rm -f "$UNIT" "$RECOVER"
out=$(migrate_agent_unit)
check '[ -z "$out" ] && [ ! -e "$UNIT" ] && [ ! -e "$RECOVER" ]' "nichts angelegt"

echo "Journal auf /data (V15):"
: > "$CALLS"
LINK="$ETC/var/log/journal"
DROPIN="$ETC/etc/systemd/journald.conf.d/thinforge.conf"
mkdir -p "$LINK/abc"
echo "alt" > "$LINK/abc/system.journal"
migrate_journal >/dev/null
check '[ -L "$LINK" ] && [ "$(readlink "$LINK")" = "/data/log/journal" ]' "/var/log/journal ist ein Symlink auf /data/log/journal"
check '[ "$(cat "$JOURNAL_DIR/abc/system.journal")" = "alt" ]' "vorhandenes Journal wurde verschoben, nicht geloescht"
check '[ ! -e "$LINK.migrated" ]' "Zwischenverzeichnis aufgeraeumt"
check 'case "$(stat -c %a "$JOURNAL_DIR")" in 755|2755) true;; *) false;; esac' "Verzeichnis 0755 (oder journalds 2755)"
check '[ "$(cat "$DROPIN")" = "$JOURNALD_DROPIN_CANONICAL" ] && grep -q "^Storage=persistent$" "$DROPIN" && grep -q "^SystemMaxUse=200M$" "$DROPIN"' "Drop-in Storage=persistent, SystemMaxUse=200M"
check '[ "$(calls --rotate)" = 1 ] && [ "$(calls --flush)" = 1 ]' "journalctl --rotate und --flush genau einmal"

echo "Journal zweiter Lauf (idempotent, auch mit journalds 2755):"
: > "$CALLS"
chmod 2755 "$JOURNAL_DIR"
out=$(migrate_journal)
check '[ -z "$out" ] && [ "$(calls journal)" = 0 ] && [ "$(calls rotate)" = 0 ]' "keine Ausgabe, kein journalctl"

echo "Journal: fehlender Symlink und falscher Symlink werden gesetzt:"
rm -f "$LINK"; : > "$CALLS"
migrate_journal >/dev/null
check '[ "$(readlink "$LINK")" = "/data/log/journal" ]' "Symlink angelegt"
rm -f "$LINK"; ln -s /tmp/woanders "$LINK"
migrate_journal >/dev/null
check '[ "$(readlink "$LINK")" = "/data/log/journal" ]' "falscher Symlink korrigiert"

# ── Recover-Unit: Wiederherstellung aus .prev, sonst Wiederholung nach 5 min ──
# Das Skript der Unit (ExecStart=/bin/bash -c '…', Fortsetzungszeilen,
# $$ → $) wird aus dem kanonischen Text gelesen und mit nachgebildetem
# systemctl, sleep und minisign (PATH) auf einem Temp-/data ausgefuehrt.
echo "Recover-Unit (Skript aus RECOVERUNIT):"
RSCRIPT=$(printf '%s\n' "$RECOVER_UNIT_CANONICAL" | sed -n "/^ExecStart=/,/'\$/p" | sed -e 's/\\$//' | tr '\n' ' ')
RSCRIPT=${RSCRIPT#ExecStart=/bin/bash -c \'}
RSCRIPT=${RSCRIPT%\' }
RSCRIPT=${RSCRIPT//\$\$/\$}
check '[ -n "$RSCRIPT" ] && [[ "$RSCRIPT" == *"sleep 300"* ]] && [[ "$RSCRIPT" != *'"'"'$$'"'"'* ]]' "Skript der Unit gelesen (sleep 300, keine \$\$ mehr)"
FAKEBIN="$TMP/fakebin"; mkdir -p "$FAKEBIN"
export TF_CALLS="$TMP/recover-calls" TF_STATE="$TMP/agent-state" TF_MINISIGN_RC="$TMP/minisign-rc"
cat > "$FAKEBIN/systemctl" <<'FAKE'
#!/bin/bash
echo "systemctl $*" >> "$TF_CALLS"
case "$1" in is-failed) [ "$(cat "$TF_STATE")" = failed ] ;; *) exit 0 ;; esac
FAKE
cat > "$FAKEBIN/sleep" <<'FAKE'
#!/bin/bash
echo "sleep $*" >> "$TF_CALLS"
FAKE
cat > "$FAKEBIN/minisign" <<'FAKE'
#!/bin/bash
echo "minisign $*" >> "$TF_CALLS"
exit "$(cat "$TF_MINISIGN_RC")"
FAKE
chmod +x "$FAKEBIN"/*
RDATA="$TMP/data/thinforge"
recover_run() { # $1 = Zustand der Agent-Unit (failed|inactive), $2 = minisign-Exit
    rm -rf "$RDATA"; mkdir -p "$RDATA"
    printf 'untrusted comment: k\nRWQkey\n' > "$RDATA/signing.pub"
    printf 'laufende binary\n' > "$RDATA/thinforge-agent"
    printf 'sig neu\n' > "$RDATA/thinforge-agent.minisig"
    echo "$1" > "$TF_STATE"; echo "$2" > "$TF_MINISIGN_RC"; : > "$TF_CALLS"
    PATH="$FAKEBIN:$PATH" bash -c "${RSCRIPT/D=\/data\/thinforge;/D=$RDATA;}" 2>&1
}
rcalls() { grep -cF -- "$1" "$TF_CALLS" || true; }

echo "  ohne .prev, Unit failed → Wiederholung nach 5 min:"
out=$(recover_run failed 0)
check 'grep -q "nothing to restore" <<<"$out"' "meldet: nichts zurueckzustellen"
check '[ "$(rcalls "sleep 300")" = 1 ]' "wartet 300 s"
check '[ "$(rcalls "systemctl is-failed --quiet thinforge-agent.service")" = 1 ]' "prueft vorher, ob die Unit noch failed ist"
check '[ "$(rcalls "systemctl reset-failed thinforge-agent.service")" = 1 ] && [ "$(rcalls "systemctl start --no-block thinforge-agent.service")" = 1 ]' "reset-failed und start"
check '[ -f "$RDATA/thinforge-agent" ] && [ ! -e "$RDATA/thinforge-agent.failed" ] && [ ! -e "$RDATA/agent-recovered" ]' "Binary unangetastet, kein Marker"

echo "  ohne .prev, Unit vom Bediener gestoppt (inactive) → keine Wiederholung:"
out=$(recover_run inactive 0)
check '[ "$(rcalls "sleep 300")" = 1 ] && [ "$(rcalls "reset-failed")" = 0 ] && [ "$(rcalls "systemctl start")" = 0 ]' "wartet, startet aber nicht"
check 'grep -q "no longer failed" <<<"$out"' "meldet: nicht mehr failed"

echo "  .prev mit gueltiger Signatur → sofortige Wiederherstellung:"
recover_prev() {
    printf '#!/bin/bash\necho v2.28.0\n' > "$RDATA/thinforge-agent.prev"; chmod +x "$RDATA/thinforge-agent.prev"
    printf 'sig alt\n' > "$RDATA/thinforge-agent.prev.minisig"
}
rm -rf "$RDATA"; mkdir -p "$RDATA"; recover_prev
printf 'untrusted comment: k\nRWQkey\n' > "$RDATA/signing.pub"
printf 'laufende binary\n' > "$RDATA/thinforge-agent"; printf 'sig neu\n' > "$RDATA/thinforge-agent.minisig"
echo failed > "$TF_STATE"; echo 0 > "$TF_MINISIGN_RC"; : > "$TF_CALLS"
out=$(PATH="$FAKEBIN:$PATH" bash -c "${RSCRIPT/D=\/data\/thinforge;/D=$RDATA;}" 2>&1)
check '[ "$(rcalls "minisign -V -q -P RWQkey -m $RDATA/thinforge-agent.prev -x $RDATA/thinforge-agent.prev.minisig")" = 1 ]' "prueft .prev mit .prev.minisig gegen den Schluessel"
check 'grep -q "^#!/bin/bash" "$RDATA/thinforge-agent" && [ ! -e "$RDATA/thinforge-agent.prev" ]' ".prev ueber die Binary geschoben (verbraucht)"
check '[ "$(cat "$RDATA/thinforge-agent.failed")" = "laufende binary" ]' "gescheiterte Binary liegt als .failed"
check '[ "$(cat "$RDATA/thinforge-agent.minisig")" = "sig alt" ] && [ ! -e "$RDATA/thinforge-agent.prev.minisig" ]' ".prev.minisig wurde zur .minisig"
check 'grep -q "^restored=v2.28.0$" "$RDATA/agent-recovered" && grep -qE "^failed=[0-9a-f]{8}$" "$RDATA/agent-recovered"' "Marker restored=/failed="
check '[ "$(rcalls "sleep")" = 0 ] && [ "$(rcalls "reset-failed")" = 1 ] && [ "$(rcalls "systemctl start --no-block thinforge-agent.service")" = 1 ]' "sofort reset-failed und start, kein Warten"

echo "  .prev mit ungueltiger Signatur → nicht zurueckgestellt, Wiederholung:"
rm -rf "$RDATA"; mkdir -p "$RDATA"; recover_prev
printf 'untrusted comment: k\nRWQkey\n' > "$RDATA/signing.pub"
printf 'laufende binary\n' > "$RDATA/thinforge-agent"
echo failed > "$TF_STATE"; echo 1 > "$TF_MINISIGN_RC"; : > "$TF_CALLS"
out=$(PATH="$FAKEBIN:$PATH" bash -c "${RSCRIPT/D=\/data\/thinforge;/D=$RDATA;}" 2>&1)
check 'grep -q "not restored" <<<"$out" && [ -e "$RDATA/thinforge-agent.prev" ] && [ "$(cat "$RDATA/thinforge-agent")" = "laufende binary" ]' "laesst .prev und Binary liegen"
check '[ "$(rcalls "sleep 300")" = 1 ] && [ "$(rcalls "reset-failed")" = 1 ]' "wartet und wiederholt"

echo
if [ "$fehler" -eq 0 ]; then echo "agent-migrate-unit-gate: alle Pruefungen bestanden"; exit 0; fi
echo "agent-migrate-unit-gate: $fehler Pruefung(en) fehlgeschlagen"; exit 1
