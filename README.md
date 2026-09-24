# ThinForge — Release Repository

This repository contains everything a host needs to run ThinForge — **except the source code**. The container images come from the registry at `git.thinforge.org`; the files here are bind-mounted into the containers at runtime or read by `deploy.sh`.

It is published at [git.thinforge.org/thinforge/ThinForge-Release](https://git.thinforge.org/thinforge/ThinForge-Release) (the installer clones from there) and mirrored to [github.com/224ctx/ThinForge](https://github.com/224ctx/ThinForge). The complete source code is public in [`thinforge/ThinForge-Dev`](https://git.thinforge.org/thinforge/ThinForge-Dev) (GPL-3.0-or-later). This repository carries the tested versions for production use — no account is needed to clone it.

| Path | Purpose |
|---|---|
| `bootstrap-release.sh` | One-command installer that runs everything else |
| `install-deps.sh` | Installs Docker, kernel modules, groups and time zone, and creates `.env` with random secrets |
| `deploy.sh` | Pulls the images, prepares storage, starts the stack |
| `stop-all.sh` | Stops all ThinForge containers, including the ones started outside Compose; data stays |
| `docker-compose.yml` | Registry Compose file (pull-only, no `build:` sections) |
| `.env.example` | Template with `CHANGE_ME_*` placeholders; `install-deps.sh` fills them in on the first run |
| `migrations/0001_initial.sql` | Postgres schema, run by `initdb` only when the database is created |
| `docker/caddy/Caddyfile` | Reverse-proxy configuration (copied to `${STORAGE_DIR}/caddy/` by `deploy.sh`) |
| `docker/prometheus/`, `docker/grafana/` | Monitoring configuration (the services are currently disabled, see below) |
| `scripts/` | Tools-ISO provisioning and shell libraries, mounted into the backend |
| `ansible/` | Playbooks, mounted into the backend |
| `agent-go/bin/` | amd64 agent binary and `agent-version`, served to the devices by the backend — unsigned: every server signs it with its own key (see [Updating the agent binary](#updating-the-agent-binary)) |
| `docs/CHANGELOG.en.md`, `docs/CHANGELOG.md`, `docs/security/` | Change log (EN/DE) and public security documents, mounted read-only into backend and frontend |
| `anleitungen/` | Operator documentation (EN + DE): dashboard, clients, cloning, rollouts, network, settings, VPN |
| `LICENSE`, `NOTICE`, `THIRD_PARTY_LICENSES.md`, `LICENSES/`, `sources/`, `WRITTEN_OFFER.md` | Licence texts and the corresponding source for the third-party components (GPL compliance) |

---

## Requirements

- Ubuntu 24.04 or newer with sudo access
- Outbound HTTPS to `git.thinforge.org` (this repository and the ThinForge images), to Docker Hub (`postgres`, `redis`, `caddy`, `guacamole/guacd`, `netbirdio/netbird`) and to the Ubuntu and Docker package repositories (`install-deps.sh` installs Docker from `download.docker.com`)

This repository and its container images are **publicly readable** — no account, no token, no `docker login` needed.

---

## Quick start

```bash
curl -fsSL https://git.thinforge.org/thinforge/ThinForge-Release/raw/branch/master/bootstrap-release.sh -o bootstrap-release.sh
chmod +x bootstrap-release.sh
./bootstrap-release.sh
```

The bootstrapper runs without questions:

1. Clones this repository to `~/ThinForge-Release` (set `TARGET_DIR=/opt/thinforge` for another location).
2. `./install-deps.sh` — installs Docker and the kernel modules, creates `.env` and replaces the `CHANGE_ME_*` passwords with random values.
3. `./deploy.sh` — pulls the images, creates the storage directories, generates a self-signed TLS certificate and starts the stack. If the `docker` group was only just assigned, the bootstrapper runs `deploy.sh` under `sg docker`, so no logout is needed.

Afterwards the web interface is available at `https://<hostname>/`. The **first visit opens the setup wizard**, where you create the admin account (there is no default login).

Then sign the agent binary once: **Clients → Agent → Sign**. Without a signature built with this server's key, the backend refuses to build the Tools-ISO and to start the cloning VM.

---

## Manual installation

If you prefer not to run the bootstrap script:

```bash
git clone https://git.thinforge.org/thinforge/ThinForge-Release.git ~/ThinForge-Release
cd ~/ThinForge-Release
./install-deps.sh            # creates .env, installs Docker etc.
./deploy.sh
```

If `install-deps.sh` has just added you to the `docker` group, log in again (or run `newgrp docker`) before `./deploy.sh`.

---

## .env configuration

`install-deps.sh` fills in the required secrets (Postgres, Grafana, Semaphore and Redis passwords) with `openssl rand` values. Everything else runs with defaults.

Optional overrides, usually **before the first `deploy.sh`**:

| Variable | Default | When to change it |
|---|---|---|
| `STORAGE_DIR` | `./ThinForgeDaten` (relative to this repository) | For production, put it on a dedicated volume or disk (`/opt/thinforge-data` or similar). It is resolved to an absolute path on the first run and written back to `.env`. |
| `CLONING_VM_RAM`, `CLONING_VM_CPUS` | 2048 MB / 2 CPUs | If golden-image VMs run short of resources |
| `CLONING_VM_MEM_LIMIT` | `2560m` | Memory limit of the cloning-VM container; keep it above `CLONING_VM_RAM` |
| `CLONING_VM_KVM_ENABLED` | `true` | Set to `false` if the host has no `/dev/kvm` (`install-deps.sh` warns about it) |
| `THINFORGE_ACCEPTANCE_LIST_MODE` | `local` | Set to `remote` only together with `THINFORGE_ACCEPTANCE_LIST_URL`; otherwise leave the default |
| `THINFORGE_ENABLED_PROFILES` | default from `deploy.sh` | `deploy.sh` writes its default only while the line is missing, empty or holds an earlier default. Your own value stays — e.g. leave out `testing` on hosts without KVM. Delete the line to return to the default. |
| `WORKER_DB_MAX_CONNECTIONS`, `WORKER_DB_MIN_CONNECTIONS` | 24 / 2 | Size of the worker's database pool; keep the sum of all pools below Postgres `max_connections` (100) |

Do not touch (generated or maintained automatically):

- `POSTGRES_PASSWORD`, `GRAFANA_PASSWORD`, `SEMAPHORE_ADMIN_PASSWORD` — random values from `install-deps.sh`/`deploy.sh`
- `REDIS_PASSWORD` — required: Redis runs with a password, and the stack does not start without it (`docker compose` aborts with “REDIS_PASSWORD fehlt in .env”). `install-deps.sh` creates it; on existing installations `deploy.sh` appends a random value. Change it only together with `docker compose up -d --force-recreate redis backend worker`.
- `SECRET_KEY` and `ANSIBLE_INVENTORY_TOKEN` — created on the first backend start as files under `${STORAGE_DIR}`, not in `.env`

---

## Updating

When a new release is out, on the host:

```bash
cd ~/ThinForge-Release
git pull
./deploy.sh
```

`deploy.sh` is idempotent: storage directories are only created when missing, the TLS certificate only on the first run, and the `.env` migrations (e.g. a missing `SEMAPHORE_ADMIN_PASSWORD` or `REDIS_PASSWORD`) run once.

`docker-compose.yml` pulls the `:release` tag, which always points to the current release. Every release additionally keeps an immutable version tag (`vYYYY.MM.DD`) in the registry.

- `./deploy.sh --pull-only` — pulls new images without touching the running stack (useful in maintenance windows when you want to control the restart yourself)

Schema changes for an **existing** database are applied by `thinforge-migrate` when the backend container starts. `migrations/0001_initial.sql` is run by `initdb` only on the first start of an empty database.

If the update brings a new agent binary, sign it again afterwards — see the next section.

---

## Updating the agent binary

This repository ships `agent-go/bin/thinforge-agent-amd64` and `agent-version` **without** a signature: every server signs the binary with its own Minisign key, and no `.minisig` is ever shipped. After a `git pull` that replaces the binary:

1. Run `./deploy.sh` (or just `git pull` — the backend reads the file on every agent download).
2. In the web interface, go to **Clients → Agent → Re-sign**. Without a new signature the Tools-ISO build and the VM start are rejected with 409, and the devices discard the update.

The devices then fetch the new version on their own (checked when the agent starts and every five minutes).

---

## Registry access

The Forgejo registry at `git.thinforge.org` serves over HTTPS on port 443 — **no `insecure-registries` entry and no `docker login` needed**. The `thinforge/*` container packages are public; Docker obtains an anonymous bearer token by itself. `deploy.sh` therefore does not check for a login.

---

## Currently disabled services

**Prometheus, Grafana and Semaphore are commented out in `docker-compose.yml`.** Their configuration (`docker/prometheus/`, `docker/grafana/`, `SEMAPHORE_ADMIN_PASSWORD` in `.env`) stays in place, so re-enabling them only takes a Compose change.

In practice:

- `./deploy.sh` starts no metrics stack and no job engine — the `--profile monitoring` flags are currently no-ops.
- The Semaphore password rotation in `deploy.sh` finds no running Semaphore container and skips itself quietly.
- The storage directories for the three services are created anyway.

---

## Stopping and resetting

| What | Command |
|---|---|
| Stop the stack, keep all data | `./stop-all.sh` |
| Stop without removing the containers (faster restart) | `./stop-all.sh --keep` |
| Start again | `./deploy.sh` |
| Discard only `.env` and keep the data | **Don't.** `install-deps.sh` refuses on purpose: new random credentials would not match the existing Postgres data. Restore `.env` from a backup instead. |

The database, clones, deltas and backups live under `STORAGE_DIR` (bind mounts), so `docker compose down -v` does **not** delete them. A complete reset deletes all of it — clients, users, settings, images:

```bash
cd ~/ThinForge-Release
./stop-all.sh
STORAGE_DIR="$(grep '^STORAGE_DIR=' .env | cut -d= -f2-)"   # absolute path, written on the first run
sudo rm -rf "$STORAGE_DIR" .env
./install-deps.sh && ./deploy.sh
```

---

## Support and further reading

- Operator documentation: [`anleitungen/EN/`](anleitungen/EN/README.md) · [`anleitungen/DE/`](anleitungen/DE/README.md)
- Change log: [`docs/CHANGELOG.en.md`](docs/CHANGELOG.en.md) · [`docs/CHANGELOG.md`](docs/CHANGELOG.md) (German)
- Source code: [`thinforge/ThinForge-Dev`](https://git.thinforge.org/thinforge/ThinForge-Dev)
- Bug reports: [GitHub issues](https://github.com/224ctx/ThinForge/issues)
- Security issues: please report privately to <security@thinforge.org> (PGP key: [`docs/security/security-thinforge-org.asc`](docs/security/security-thinforge-org.asc)) or via GitHub's private vulnerability reporting — not as a public issue. Contact details: [`docs/security/security.txt`](docs/security/security.txt)
- Website: <https://thinforge.org>

---

## Licence

ThinForge is free software under the GPL-3.0-or-later — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE). Third-party components and their licences are listed in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md); their corresponding source is in [`sources/`](sources/), see also [`WRITTEN_OFFER.md`](WRITTEN_OFFER.md).
