# ThinForge — Release Repository

Dieses Repo enthält alles, was ein Host zum Betrieb von ThinForge braucht — **außer dem Quellcode**. Container-Images werden aus der Gitea-Registry gezogen; die Dateien hier werden zur Laufzeit in die Container gebindmountet oder von `deploy.sh` ausgewertet.

| Pfad | Zweck |
|---|---|
| `bootstrap-release.sh` | Ein-Kommando-Installer, der alles Weitere fährt |
| `install-deps.sh` | Installiert Docker, Kernel-Module, Gruppen, Zeitzone und erzeugt `.env` mit Zufalls-Secrets |
| `deploy.sh` | Pullt Images, legt Storage an, startet den Stack |
| `docker-compose.yml` | Registry-Compose (pull-only, keine `build:`-Blöcke) |
| `.env.example` | Vorlage mit `CHANGE_ME_*`-Platzhaltern; `install-deps.sh` füllt sie beim Erstaufruf automatisch |
| `migrations/0001_initial.sql` | Postgres-Schema (von `initdb` beim ersten Container-Start ausgeführt) |
| `docker/caddy/Caddyfile` | Reverse-Proxy-Config (wird von `deploy.sh` in `${STORAGE_DIR}/caddy/` kopiert) |
| `docker/prometheus/`, `docker/grafana/` | Monitoring-Configs (Services sind **seit 2026-04-20 auskommentiert**, siehe unten) |
| `scripts/` | Tools-ISO-Provisioning + Shell-Libraries, gemountet ins Backend |
| `ansible/` | Playbooks, gemountet ins Backend |
| `agent-go/bin/` | Signierte amd64-Agent-Binary, die das Backend an PXE-Clients ausliefert |
| `license/` | Leerer Mount-Placeholder (Backend schreibt License-Dateien rein) |
| `docs/security/`, `docs/CHANGELOG.md` | Werden vom Backend/Frontend RO gemountet |
| `anleitungen/` | Operator-Doku (DE + EN): Dashboard, Clients, Cloning, Rollouts, Netzwerk, Einstellungen |

Der Quellcode liegt separat in `thinforge/ThinForge` (private Source-Repo). Dieses Release-Repo ist **öffentlich** — zum Klonen ist kein Gitea-Zugang nötig.

---

## Voraussetzungen

- Ubuntu 24.04 (oder neuer) mit sudo-Zugriff
- Netzwerk: ausgehender HTTPS-Zugang zu `git.thinforge.org`

Dieses Repo und die zugehörigen Container-Images sind **öffentlich lesbar** — kein Gitea-Account, kein PAT, kein `docker login` nötig.

---

## Schnellstart

```bash
curl -fsSL https://git.thinforge.org/thinforge/ThinForge-Release/raw/branch/master/bootstrap-release.sh -o bootstrap-release.sh
chmod +x bootstrap-release.sh
./bootstrap-release.sh
```

Der Bootstrapper läuft komplett non-interaktiv durch (ausser wenn `install-deps.sh` Docker nachinstalliert und einen Re-Login der Shell erzwingt):

1. Klont dieses Repo nach `~/ThinForge-Release`.
2. `./install-deps.sh` — installiert Docker + Kernel-Module, legt `.env` an und ersetzt die `CHANGE_ME_*`-Passwörter durch Zufallswerte.
3. `./deploy.sh` — pullt die 11 ThinForge-Images, legt Storage-Verzeichnisse an, generiert Self-Signed-TLS-Cert, startet den Stack.

Nach dem Abschluss ist das Web-UI unter `https://<hostname>/` erreichbar. Der **erste Aufruf öffnet den Setup-Wizard**, in dem du einen Admin-Account anlegst (es gibt keinen Default-Login).

---

## Manueller Ablauf (wenn du den Bootstrap-Skript-Call vermeiden willst)

```bash
git clone https://git.thinforge.org/thinforge/ThinForge-Release.git ~/ThinForge-Release
cd ~/ThinForge-Release
./install-deps.sh            # materialisiert .env, installiert Docker etc.
./deploy.sh
```

Falls nach `install-deps.sh` die Gruppenmitgliedschaft für `docker` neu ist, bittet das Skript explizit um ein Relog (oder `newgrp docker`). Dann weiter mit `./deploy.sh`.

---

## .env-Konfiguration

`install-deps.sh` füllt die Pflicht-Secrets (Postgres-/Grafana-/Semaphore-Passwort) mit `openssl rand`-Werten. Alles andere läuft mit Defaults.

Optional überschreiben, typischerweise **vor dem ersten `deploy.sh`**:

| Variable | Default | Wann anfassen |
|---|---|---|
| `STORAGE_DIR` | `./ThinForgeDaten` (relativ zum Repo) | Für Produktion auf eigenes Volume/Disk legen (`/opt/thinforge-data` o. ä.). Wird beim Erst-Start auf absoluten Pfad aufgelöst und in `.env` zurückgeschrieben. |
| `CLONING_VM_RAM`, `_CPUS`, `_DISK_SIZE` | 4096 MB / 2 CPU / 50 GB | Wenn Golden-Image-VMs knapp laufen |
| `CLONING_VM_KVM_ENABLED` | `true` | Auf `false` setzen wenn der Host kein `/dev/kvm` hat (getestet Warnung in `install-deps.sh`) |
| `MANAGEMENT_DNS` | leer (Fallback: Default-Gateway) | Wenn Clients per DHCP einen spezifischen Upstream-Resolver bekommen sollen |
| `THINFORGE_ACCEPTANCE_LIST_MODE` | `local` | Auf `remote` nur wenn `THINFORGE_ACCEPTANCE_LIST_URL` gesetzt ist; sonst in Default lassen |
| `THINFORGE_ENABLED_PROFILES` | auto-verwaltet | `deploy.sh` schreibt die Liste aus `START_PROFILES` rein — nicht manuell editieren, sonst verschwindet die Zeile beim nächsten Deploy |

Nicht anfassen (werden auto-generiert / auto-verwaltet):

- `POSTGRES_PASSWORD`, `GRAFANA_PASSWORD`, `SEMAPHORE_ADMIN_PASSWORD` — Zufallswerte aus `install-deps.sh`/`deploy.sh`
- `SECRET_KEY` — wird beim ersten Backend-Start unter `${STORAGE_DIR}/.secret_key` materialisiert, nicht in `.env`

---

## Re-Deploy nach Image-Update

Dev drückt neue Images → auf dem Host:

```bash
cd ~/ThinForge-Release
git pull            # nur nötig wenn Compose/Scripts sich geändert haben
./deploy.sh
```

`deploy.sh` ist idempotent — Storage-Dirs werden nur angelegt wenn fehlend, TLS-Cert nur auf dem ersten Run, `.env`-Migrations (z. B. fehlende `SEMAPHORE_ADMIN_PASSWORD`) idempotent.

Varianten:

- `./deploy.sh --pull-only` — zieht neue Images, ohne den laufenden Stack anzufassen (sinnvoll in Wartungsfenstern, wenn du den tatsächlichen Restart selbst kontrollieren willst)

Schema-Migrations einer **bestehenden** Postgres-DB laufen **im Backend-Container** (sqlx-Migrations in `thinforge-migrate`). `migrations/0001_initial.sql` wird von `initdb` ausschließlich beim ersten Start einer leeren DB ausgeführt.

---

## Agent-Binary rotieren

Das Backend serviert `agent-go/bin/thinforge-agent-amd64` (+ `.minisig`) an PXE-Clients. Zum Austauschen:

1. Neue Binary + Minisig + Version aus einem Dev-Build (`scripts/build-and-sign.sh` im Source-Repo) in `agent-go/bin/` ablegen.
2. `agent-version` auf die neue Version aktualisieren.
3. `git commit -am "agent: bump vX.Y.Z"` + `git push`.
4. Auf dem Host: `git pull`. Das Backend liest die Datei on-demand bei jedem Agent-Download-Request (`/api/klon/agent-binary`) — die neue Binary ist beim nächsten Client-Boot aktiv, ohne Container-Restart.

---

## Registry-Zugriff

Die Gitea-Registry hinter `git.thinforge.org` serviert via HTTPS auf 443 — **kein `insecure-registries`-Eintrag, kein `docker login` nötig**. Die `thinforge/*`-Container-Packages sind als public markiert; Docker holt sich selbstständig einen anonymen Bearer-Token (`/v2/token?service=container_registry`) und pullt durch. `deploy.sh` macht dementsprechend keinen Login-Precheck.

Wenn ein Package später privat geschaltet werden soll, kommt ein `docker login git.thinforge.org` mit Gitea-PAT (Scope `read:package`) an — bis dahin nicht nötig.

---

## Aktuell deaktivierte Services

Stand Release 2026-04-23: **Prometheus, Grafana und Semaphore sind in `docker-compose.yml` auskommentiert**. Die Configs (`docker/prometheus/`, `docker/grafana/`, `SEMAPHORE_ADMIN_PASSWORD` in `.env`) sind vorhanden und bleiben, damit die Reaktivierung nur eine Compose-Änderung braucht. Siehe `docs/deaktivierte-features.md` im Source-Repo für den Re-Enable-Pfad.

Konkret heißt das:

- `./deploy.sh` startet keine Metriken/Job-Engine — die `--profile monitoring`-Flags sind aktuell No-Ops
- Die Semaphore-Passwort-Rotation in `deploy.sh` springt an, wenn `.env` die Variable ergänzt bekommt, und findet dann **keinen laufenden Semaphore-Container** — der Rotation-Block überspringt sich selbst sauber (keine Fehlermeldung)
- Storage-Dirs für die drei Services werden vorsorglich angelegt

---

## Aufräumen / Reset

| Was | Kommando |
|---|---|
| Stack anhalten, Daten behalten | `docker compose down` |
| Stack anhalten + Volumes löschen (⚠️ DB weg) | `docker compose down -v` |
| Komplett-Reset | `docker compose down -v && sudo rm -rf "${STORAGE_DIR}" .env && ./install-deps.sh && ./deploy.sh` |
| Nur `.env` verwerfen, bestehendes Volume behalten | **nicht tun**: `install-deps.sh` bricht mit einer ausdrücklichen Fehlermeldung ab, weil neue Zufalls-Credentials nicht zum bestehenden Postgres-Volume passen würden. Backup der alten `.env` oder Volume löschen. |

---

## Support & Weiterführend

- Source, Issues, Roadmap: https://git.thinforge.org/thinforge/ThinForge *(privat, Gitea-Zugang nötig)*
- Operator-Doku DE: [`anleitungen/DE/`](anleitungen/DE/README.md)
- Operator-Doku EN: [`anleitungen/EN/`](anleitungen/EN/README.md)
