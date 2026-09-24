-- ThinForge complete database schema — single-file baseline.
--
-- Konsolidiert alle bisherigen Migrationen (Stand 2026-05-21) in einen
-- einzigen Apply. Vorteil: fresh-Deploys laufen in einer Transaktion durch;
-- das Drift-Risiko aus „Schema partial migriert, _sqlx_migrations nur
-- teil-getrackt" entfällt komplett. Eine DB mit Zeilen älterer Migrationen
-- oder alter Prüfsumme für Version 1 muss dafür NICHT gewipt werden:
-- thinforge-migrate gleicht `_sqlx_migrations` vor dem Lauf ab (veraltete
-- Zeilen > 1 löschen, Prüfsumme von Version 1 auffrischen), sonst verweigerte
-- sqlx::Migrator den Start (Checksum-Mismatch). Neu initialisiert werden muss
-- nur eine Datenbank von vor der VPN-Umstellung (Abweisung im Bootstrap).
--
-- Konsolidierungs-Historie:
--   2026-05-07 — Initial-Konsolidierung der ehemaligen 0001..0007.
--   2026-05-12 — 0002_defective_version_marker + 0003_defective_versions_table
--                eingebacken (imagestatus 'defective',
--                client_pending_snapshot_deletions, defective_versions).
--   2026-05-21 — 0002_thinvpn_netbird_migration + 0003_netbird_provisioning_ledger
--                eingebacken: vpn_firewall_rules entfernt, vpn_clients auf das
--                ThinVPN/NetBird-Schema umgestellt (WG-Felder raus, ThinVPN- +
--                ZTA-Spalten rein), system_settings_vpn + vpn_settings-Default.
--   2026-08-15 — Cutover der NetBird-Neuanbindung: die Tabellen der abgeloesten
--                Engine (vpn_audit_events, netbird_provisioning,
--                vpn_host_access_modules/_rules) sind hier entfernt. Auf
--                Bestands-DBs uebernimmt `apply_consolidated_backfills` die
--                Host-Module als Freigaben und loescht die vier Tabellen
--                anschliessend.
--
-- Regel für Schema-Änderungen: Diese Datei bleibt die EINZIGE Migration. Eine
-- Änderung gehört HIER hinein und zusätzlich als idempotente Anweisung ans Ende
-- von `apply_consolidated_backfills` (crates/thinforge-migrate/src/main.rs;
-- deren Doku-Kommentar nennt die Regeln für Backfill-Anweisungen), damit
-- bestehende Datenbanken sie beim nächsten Start nachziehen — NIE in eine
-- eigene 0002_*.sql. Grund: docker-entrypoint-initdb.d führt auf einer frischen
-- Datenbank JEDE .sql-Datei dieses Ordners aus, der Migrate-Bootstrap stempelt
-- aber nur Version 1 als angewendet; sqlx::run() wendet eine 0002 danach ein
-- zweites Mal an → „relation … already exists" → Crash-Loop von Backend und
-- Worker (2026-05-30 mit 0002_managed_certificates, siehe Abschnitt 33).
-- Diese Datei zu ändern ist dagegen sicher: der Bootstrap frischt die
-- Prüfsumme von Version 1 in `_sqlx_migrations` bei jedem Start auf. Der Test
-- `es_gibt_nur_die_eine_baseline_migration` (main.rs) hält die Regel fest.
--
-- Run-Pfad: docker-entrypoint-initdb.d (Postgres-Erst-Init) ODER
-- thinforge-migrate beim Backend-Start (sqlx::migrate!("./migrations")).

-- ── Enum types ──────────────────────────────────────────────────────────────

CREATE TYPE userrole AS ENUM ('admin', 'operator', 'viewer');
-- 'defective' markiert Baseline-Image-Versionen, die durch einen
-- Rollback-Task als defekt geflaggt wurden (siehe defective_versions
-- für Delta-only Versionen).
CREATE TYPE imagestatus AS ENUM ('ready', 'deprecated', 'defective');
CREATE TYPE clientstatus AS ENUM ('online', 'offline', 'cloning', 'error');
CREATE TYPE alertcondition AS ENUM (
    'client_offline', 'cpu_high', 'ram_high', 'disk_high',
    'client_error', 'warranty_expiring', 'version_mismatch',
    'mac_changed'
);
CREATE TYPE incidentstatus AS ENUM ('active', 'acknowledged', 'resolved');
CREATE TYPE clonedeploymentstatus AS ENUM (
    'scheduled', 'active', 'paused', 'completed', 'completed_with_errors', 'cancelled'
);
CREATE TYPE updatedeltastatus AS ENUM ('creating', 'ready', 'failed');
CREATE TYPE updaterolloutstatus AS ENUM ('draft', 'active', 'completed', 'aborted');
CREATE TYPE updaterolloutclientstatus AS ENUM (
    'pending', 'downloading', 'applying', 'prepared', 'confirmed',
    'rolled_back', 'failed', 'signature_failed'
);
CREATE TYPE rollbacktaskstatus AS ENUM ('active', 'completed', 'aborted');
CREATE TYPE rollbacktaskclientstatus AS ENUM ('pending', 'prepared', 'completed');
CREATE TYPE rolloutstatus AS ENUM ('draft', 'active', 'paused', 'completed', 'cancelled');
CREATE TYPE rolloutclientstatus AS ENUM ('pending', 'deploying', 'done', 'failed', 'cancelled');

-- ── 1. users ────────────────────────────────────────────────────────────────

CREATE TABLE users (
    id              UUID        NOT NULL DEFAULT gen_random_uuid(),
    username        VARCHAR(150) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    role            userrole    NOT NULL DEFAULT 'viewer',
    is_active       BOOLEAN     NOT NULL DEFAULT true,
    totp_secret     VARCHAR(255),
    -- Staged TOTP secret for a (re-)enrollment: /totp/setup writes here and the
    -- live totp_secret/totp_enabled stay untouched until /totp/enable verifies a
    -- code, so re-running setup never disables existing 2FA (Code-Review M1).
    totp_secret_pending VARCHAR(255),
    totp_enabled    BOOLEAN     NOT NULL DEFAULT false,
    -- Token-invalidation epoch: access/refresh tokens whose iat predates this
    -- timestamp are rejected. Bumped on password change/reset so existing
    -- sessions are logged out (Code-Review M2).
    tokens_valid_after TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX ix_users_username ON users (username);
CREATE UNIQUE INDEX ix_users_email    ON users (email);

-- ── 2. settings ─────────────────────────────────────────────────────────────

CREATE TABLE settings (
    key         VARCHAR(255) NOT NULL,
    value       JSONB        NOT NULL DEFAULT '{}',
    category    VARCHAR(100) NOT NULL DEFAULT 'general',
    description VARCHAR(500),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_by  UUID,
    PRIMARY KEY (key)
);

-- Default-Settings (vorher in einzelnen Migrationen angelegt):

-- Bandwidth-Throttle-Konfig für Delta-Update-Rollouts (vorher: 0003 + 0006).
INSERT INTO settings (key, value, category, description)
VALUES (
    'delta_throttle_config',
    '{"max_concurrent_downloads":10,"per_client_max_mbit":10,"reserve_mbit":5,"min_floor_mbit":1,"max_retries":3}'::jsonb,
    'delta_updates',
    'Bandwidth throttling config for delta-update rollouts (global).'
) ON CONFLICT (key) DO NOTHING;

-- ── 3. audit_log ────────────────────────────────────────────────────────────

CREATE TABLE audit_log (
    id            UUID        NOT NULL DEFAULT gen_random_uuid(),
    user_id       UUID,
    action        VARCHAR(50)  NOT NULL,
    resource_type VARCHAR(100) NOT NULL,
    resource_id   VARCHAR(255),
    details       JSONB,
    ip_address    INET,
    timestamp     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    -- Verdichtung wiederholter Anmeldeversuche (Review 2026-09-02, A4):
    -- Fehlversuche einer NICHT angemeldeten Anfrage schreiben je Minute EINE
    -- Zeile, die bei jedem weiteren Versuch hochgezaehlt wird
    -- (`details.count`, `first_at`, `last_at`, Beispielnamen). Vorher legte
    -- jeder Versuch eine eigene Zeile an, ohne Deckel je Quelle.
    -- `aggregation_key` fasst Aktion, Ressourcentyp, Grund, Konto und
    -- Absender zu einem Text zusammen (ein fehlender Absender steht als
    -- leerer Teil darin, nie als NULL — ein eindeutiger Index hielte zwei
    -- NULLs fuer verschieden, und der Upsert griffe genau bei Anfragen ohne
    -- Absender nicht). Bei gewoehnlichen Zeilen sind beide Spalten NULL.
    aggregation_key    TEXT,
    aggregation_minute TIMESTAMPTZ,
    PRIMARY KEY (id),
    CONSTRAINT audit_log_aggregation_pair
        CHECK ((aggregation_key IS NULL) = (aggregation_minute IS NULL))
);

CREATE INDEX idx_audit_created ON audit_log (timestamp DESC);
-- Ziel des Upserts in `audit_service::versuch_verbuchen`: je Schluessel und
-- Minute hoechstens eine Zeile, auch bei gleichzeitigen Anfragen.
CREATE UNIQUE INDEX ux_audit_log_aggregation
    ON audit_log (aggregation_key, aggregation_minute)
    WHERE aggregation_key IS NOT NULL;

-- ── 4. gruppen ──────────────────────────────────────────────────────────────

CREATE TABLE gruppen (
    id               UUID        NOT NULL DEFAULT gen_random_uuid(),
    name             VARCHAR(255) NOT NULL,
    beschreibung     TEXT,
    vpn_enabled      BOOLEAN     NOT NULL DEFAULT false,
    parent_gruppe_id UUID,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (name),
    FOREIGN KEY (parent_gruppe_id) REFERENCES gruppen (id)
);

-- ── 5. images ───────────────────────────────────────────────────────────────
--
-- Versionierung seit 2026-05-07: CalVer (vYYYY.MM.DD-NNN), serverseitig
-- generiert per `image_service::generate_next_calver`. `name_slug` wird vom
-- Backend aus `name` abgeleitet (slugify). Vollständige Spec in
-- docs/architecture/image-versioning.md.

CREATE TABLE images (
    id              UUID          NOT NULL DEFAULT gen_random_uuid(),
    name            VARCHAR(255)  NOT NULL,
    name_slug       VARCHAR(80)   NOT NULL,
    version         VARCHAR(50)   NOT NULL,
    beschreibung    TEXT,
    dateiname       VARCHAR(500),
    sha256_hash     VARCHAR(64),
    groesse_bytes   BIGINT,
    status          imagestatus   NOT NULL DEFAULT 'ready',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- UNIQUE(name) nur für aktive Images — deprecated-History bleibt frei
-- duplizierbar, falls je ein History-Set per Hard-Cut deprecated wird.
CREATE UNIQUE INDEX images_name_unique
    ON images(name)
 WHERE status <> 'deprecated';

-- (name, version) global eindeutig — schützt gegen Counter-Race im
-- generate_next_calver-Pfad auch über das deprecated-Set hinweg.
CREATE UNIQUE INDEX images_name_version_unique
    ON images(name, version);

-- ── 6. maintenance_windows ──────────────────────────────────────────────────

CREATE TABLE maintenance_windows (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    name             VARCHAR(255) NOT NULL,
    description      TEXT,
    start_time       TIMESTAMPTZ  NOT NULL,
    end_time         TIMESTAMPTZ  NOT NULL,
    scope            VARCHAR(20)  NOT NULL DEFAULT 'all',
    client_ids       JSONB        NOT NULL DEFAULT '[]',
    created_by       UUID,
    is_recurring     BOOLEAN      NOT NULL DEFAULT false,
    recurrence_type  VARCHAR(20),
    recurrence_days  JSONB,
    recurrence_end   TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE INDEX ix_maintenance_windows_start_time ON maintenance_windows (start_time);
CREATE INDEX ix_maintenance_windows_end_time   ON maintenance_windows (end_time);

-- ── 7. pending_clients ──────────────────────────────────────────────────────

CREATE TABLE pending_clients (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    mac_address   VARCHAR(17)  NOT NULL,
    hostname_hint VARCHAR(255),
    first_seen    TIMESTAMPTZ  NOT NULL,
    last_seen     TIMESTAMPTZ  NOT NULL,
    seen_count    INTEGER      NOT NULL DEFAULT 1,
    notes         TEXT,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

CREATE UNIQUE INDEX ix_pending_clients_mac_address ON pending_clients (mac_address);

-- ── 8. scheduled_tasks ──────────────────────────────────────────────────────

CREATE TABLE scheduled_tasks (
    id               UUID         NOT NULL DEFAULT gen_random_uuid(),
    key              VARCHAR(100) NOT NULL,
    name             VARCHAR(200) NOT NULL,
    description      TEXT,
    enabled          BOOLEAN      NOT NULL DEFAULT true,
    interval_minutes INTEGER      NOT NULL,
    config           JSONB,
    last_run_at      TIMESTAMPTZ,
    next_run_at      TIMESTAMPTZ,
    last_error       TEXT,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (key)
);

-- ── 10. clients ─────────────────────────────────────────────────────────────

CREATE TABLE clients (
    id                       UUID         NOT NULL DEFAULT gen_random_uuid(),
    mac_address              VARCHAR(17)  NOT NULL,
    hostname                 VARCHAR(255) NOT NULL,
    inventarnummer           VARCHAR(100),
    raum                     VARCHAR(100),
    benutzer                 VARCHAR(255),
    kaufdatum                DATE,
    garantiezeit_monate      INTEGER,
    rechnungsnummer          VARCHAR(200),
    lieferant                VARCHAR(200),
    gruppe_id                UUID,
    status                   clientstatus NOT NULL DEFAULT 'offline',
    last_seen                TIMESTAMPTZ,
    hw_cpu_percent           FLOAT,
    hw_ram_used_mb           INTEGER,
    hw_ram_total_mb          INTEGER,
    hw_disk_used_gb          FLOAT,
    hw_disk_total_gb         FLOAT,
    hw_cpu_model             VARCHAR(255),
    hw_serial_number         VARCHAR(255),
    hw_manufacturer          VARCHAR(255),
    hw_model                 VARCHAR(255),
    hw_ram_slots             VARCHAR(500),
    hw_disk_model            VARCHAR(255),
    hw_disk_serial           VARCHAR(255),
    hw_bios_version          VARCHAR(255),
    hw_inventory_at          TIMESTAMPTZ,
    assigned_ip              VARCHAR(45),
    ip_address               VARCHAR(45),
    -- TEXT, nicht VARCHAR(20): ein `git describe`-Suffix („v2.16.1-123-gabcdef1")
    -- trifft die Grenze auf den Zeichen genau, und der Heartbeat-UPDATE steht
    -- auf `?` — ein Ueberlauf laesst den GANZEN Schlag mit 500 scheitern, das
    -- Geraet gilt danach als offline.
    agent_version            TEXT,
    vpn_connected            BOOLEAN      NOT NULL DEFAULT false,
    vpn_ip                   INET,
    connection_type          VARCHAR(20),
    is_lager                 BOOLEAN      NOT NULL DEFAULT false,
    installed_image          VARCHAR(255),
    installed_image_version  VARCHAR(50),
    installed_clone_id       VARCHAR(500),
    installed_image_at       TIMESTAMPTZ,
    boot_counter             INTEGER,
    -- TEXT, nicht VARCHAR(100): hier landet die komplette kommaseparierte
    -- Snapshot-Liste des Agenten (`available_snapshots`), die mit der Zahl der
    -- Snapshots waechst. Gleiche Folge wie oben — der ganze Heartbeat faellt.
    rollback_snap            TEXT,
    update_confirmed         BOOLEAN,
    installed_version        VARCHAR(50),
    pending_rollback         BOOLEAN      NOT NULL DEFAULT false,
    rollback_requested_at    TIMESTAMPTZ,
    boot_mode                VARCHAR(20),
    -- Per-Client-Heartbeat-Token (Token↔MAC-Bindung, M4 / F-HI-05 / F-CR-07).
    -- NULL = noch nicht enrollt → Client nutzt weiter den shared Token.
    heartbeat_token_hash     TEXT,
    heartbeat_token_at       TIMESTAMPTZ,
    heartbeat_enrolled_ip    VARCHAR(45),
    -- Operator-getriggerte per-Client-Token-Rotation („Token neu ausstellen"):
    -- der nächste Heartbeat (mit dem aktuellen per-Client-Token) bekommt einen
    -- neuen Token via next_token + Hash-Ersatz. Nie fleet-wide.
    heartbeat_token_rotate_pending BOOLEAN NOT NULL DEFAULT false,
    -- Heartbeat-Auth-Reject-Sichtbarkeit (UI, Clients-Tab). Bei jedem
    -- erfolgreichen Heartbeat wieder genullt → non-NULL ⟺ letzter
    -- Heartbeat-Ausgang war eine Ablehnung (kein Erfolg seither).
    last_heartbeat_rejected_at TIMESTAMPTZ,
    heartbeat_rejected_reason  TEXT,
    created_at               TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (hostname),
    UNIQUE (inventarnummer),
    FOREIGN KEY (gruppe_id) REFERENCES gruppen (id)
);

CREATE UNIQUE INDEX ix_clients_mac_address ON clients (mac_address);
CREATE UNIQUE INDEX ix_clients_assigned_ip_unique ON clients (assigned_ip) WHERE assigned_ip IS NOT NULL;
CREATE UNIQUE INDEX ix_clients_heartbeat_token_hash ON clients (heartbeat_token_hash) WHERE heartbeat_token_hash IS NOT NULL;
CREATE INDEX idx_client_last_seen ON clients (last_seen);
CREATE INDEX idx_client_gruppe ON clients (gruppe_id);
-- ── 11. ssh_command_logs ────────────────────────────────────────────────────

CREATE TABLE ssh_command_logs (
    id          UUID    NOT NULL DEFAULT gen_random_uuid(),
    client_id   UUID    NOT NULL,
    user_id     UUID,
    command     TEXT    NOT NULL,
    exit_code   INTEGER,
    stdout      TEXT,
    stderr      TEXT,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    duration_ms INTEGER,
    PRIMARY KEY (id),
    FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE,
    FOREIGN KEY (user_id)   REFERENCES users   (id) ON DELETE SET NULL
);

CREATE INDEX ix_ssh_command_logs_client_id ON ssh_command_logs (client_id);

-- ── 12. client_task_templates ───────────────────────────────────────────────

CREATE TABLE client_task_templates (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    name          VARCHAR(255) NOT NULL,
    task_type     VARCHAR(50)  NOT NULL,
    scope         VARCHAR(10)  NOT NULL DEFAULT 'all',
    gruppe_id     UUID,
    client_ids    JSONB,
    task_metadata JSONB,
    schedule      JSONB,
    recurring     BOOLEAN      NOT NULL DEFAULT false,
    enabled       BOOLEAN      NOT NULL DEFAULT true,
    created_by    UUID,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (gruppe_id)  REFERENCES gruppen (id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES users   (id) ON DELETE SET NULL
);

CREATE INDEX ix_client_task_templates_task_type ON client_task_templates (task_type);

-- ── 13. client_tasks ────────────────────────────────────────────────────────

CREATE TABLE client_tasks (
    id            UUID         NOT NULL DEFAULT gen_random_uuid(),
    client_id     UUID,
    task_type     VARCHAR(50)  NOT NULL,
    status        VARCHAR(20)  NOT NULL DEFAULT 'pending',
    arq_job_id    VARCHAR(255),
    -- Wann der Task zuletzt in die Redis-Queue gepusht wurde. Der
    -- Stale-Re-Dispatch (task_dispatch.rs) keyt hierauf statt auf created_at,
    -- damit nicht jeder >5min alte pending-Task bei JEDEM Heartbeat neu
    -- enqueued wird (Audit task_dispatch.rs:170).
    dispatched_at TIMESTAMPTZ,
    started_at    TIMESTAMPTZ,
    finished_at   TIMESTAMPTZ,
    error_msg     TEXT,
    progress_pct  INTEGER               DEFAULT 0,
    task_metadata JSONB,
    template_id   UUID,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (client_id)   REFERENCES clients              (id) ON DELETE SET NULL,
    FOREIGN KEY (template_id) REFERENCES client_task_templates (id) ON DELETE SET NULL
);

CREATE INDEX ix_client_tasks_client_id   ON client_tasks (client_id);
CREATE INDEX ix_client_tasks_task_type   ON client_tasks (task_type);
CREATE INDEX ix_client_tasks_status      ON client_tasks (status);
CREATE INDEX ix_client_tasks_template_id ON client_tasks (template_id);

-- ── 14. vpn_clients ─────────────────────────────────────────────────────────
--
-- Rueckbau 2026-08-20 (Legacy-Pruefung): `vpn_relay_id` (seit NetBird 0.71.x
-- vom Agenten nie mehr befuellt, von niemandem gelesen) und `tpm_updated_at`
-- (nur geschrieben, nie gelesen) sind entfallen; Bestands-DBs raeumen sie in
-- `apply_consolidated_backfills` ab.
--
-- ThinVPN/NetBird-Schema (war 0002): die alten WireGuard-Felder sind entfernt;
-- stattdessen NetBird-Peer-/Setup-Key-Referenzen, Lifecycle-State und ZTA-Hooks.
-- vpn_state-Maschine: not_installed | installed_disabled | enroll_pending |
-- enrolled_inactive | active | error. Spaltenreihenfolge entspricht dem
-- physischen Post-ALTER-Stand (id, client_id, created_at, dann die ehemals per
-- ALTER ergänzten Spalten).
--
-- `enroll_pending` kam mit Agent v2.16.9 (ff5b127) dazu und fehlte hier: der
-- Agent sendet den Zustand seither in JEDEM Heartbeat, sobald eine VPN-Konfig
-- vorgemerkt, aber noch nicht eingelöst ist. Der CHECK lehnte ihn ab, und weil
-- der VPN-Bericht des Heartbeats EIN Statement ist, fiel damit der ganze
-- Bericht weg — samt vpn_apply_status/-error, also genau der Information, die
-- den Fehlschlag erklärt hätte. Das Feature war über den DB-Pfad nie wirksam.

CREATE TABLE vpn_clients (
    id                      UUID         NOT NULL DEFAULT gen_random_uuid(),
    client_id               UUID,
    created_at              TIMESTAMPTZ  NOT NULL DEFAULT now(),
    vpn_peer_id             TEXT,
    setup_key_id            TEXT,
    -- Encryption ist thinforge_core::encryption::encrypt → liefert String mit
    -- "aes-gcm:"-Prefix; deshalb TEXT statt BYTEA.
    setup_key_secret_enc    TEXT,
    vpn_state               TEXT         NOT NULL DEFAULT 'installed_disabled'
        CHECK (vpn_state IN ('not_installed','installed_disabled','enroll_pending','enrolled_inactive','active','error')),
    vpn_connection          TEXT,
    vpn_last_handshake      TIMESTAMPTZ,
    vpn_apply_status        TEXT,
    vpn_apply_error         TEXT,
    -- Drossel fuer den Enroll-Push im Heartbeat: der Auftrag ging bisher in
    -- JEDEM Tick raus (Default 10 s), und der Agent startet dabei den
    -- NetBird-Daemon neu — das riss den frisch aufgebauten Tunnel wieder ab,
    -- bis der Poller den Peer band. NULL = sofort faellig.
    vpn_enroll_dispatched_at TIMESTAMPTZ,
    vpn_lan_mode            TEXT
        CHECK (vpn_lan_mode IS NULL OR vpn_lan_mode IN ('lan','remote','unknown')),
    -- TPM-Status aus dem Agent-Heartbeat (tpm_present/tpm_sealed im
    -- Full-Heartbeat). Kein `tpm_updated_at` mehr: die Spalte wurde bei jeder
    -- Meldung auf now() gesetzt und von keiner Zeile je gelesen (2026-08-20).
    tpm_present             BOOLEAN,
    tpm_sealed              BOOLEAN,
    -- Cloud-Verbindungsstatus aus dem Reconcile-Tick (vpn::tick), alleinige
    -- Quelle für "verbunden" im VPN-Tab. NULL = nie bestätigt.
    vpn_cloud_connected     BOOLEAN,
    vpn_cloud_seen_at       TIMESTAMPTZ,
    -- Absichts-Marker: gesetzt NUR von den Pfaden, die den Zugang wirklich
    -- entziehen — `vpn::enrollment::deactivate_client` (ein Geraet) und
    -- `vpn::firstconnect::nach_loeschung_aufraeumen` (die Flotte, nach dem
    -- Loeschen der Instanz-Objekte). Kein buchhalterischer Pfad setzt ihn.
    -- Aus ihm speist sich das `vpn_desired`-Feld der Heartbeat-Antwort.
    -- Bewusst eine eigene Spalte statt „keine Bindung mehr" — die Begruendung
    -- steht bei `handlers::clients::vpn_soll`.
    --
    -- REGEL: jeder Pfad, der `vpn_peer_id` auf einen Wert setzt, MUSS diese
    -- Spalte im selben Statement auf NULL ziehen (heute: `enrollment`,
    -- `firstconnect`, `backup`, zwei Stellen in `vpn::tick`). Wer wieder einen
    -- Peer haelt, hat wieder Zugang; ein stehen gebliebener Marker liesse den
    -- Server dem Geraet dauerhaft „aus" sagen, waehrend die Liste es als
    -- aktiviert fuehrt.
    vpn_deactivated_at      TIMESTAMPTZ,
    -- ZTA-Hooks (v1 nullable / unused; populated in v2)
    user_id                 UUID         REFERENCES users(id),
    idp_subject             TEXT,
    idp_groups              JSONB,
    requires_login_after    TIMESTAMPTZ,
    PRIMARY KEY (id),
    UNIQUE (client_id),
    FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
);

-- Ein NetBird-Peer gehoert zu genau EINEM Geraet. Ohne diese Zusicherung
-- konnten zwei Zeilen dieselbe Peer-ID tragen (Hostname umbenannt und
-- wiederverwendet) — ein „VPN deaktivieren" beim einen loeschte dann den Peer
-- des anderen. Partiell, weil NULL der Normalfall ist: nicht aktivierte und
-- geloeste Geraete tragen keine Bindung.
CREATE UNIQUE INDEX vpn_clients_peer_id_idx ON vpn_clients (vpn_peer_id)
    WHERE vpn_peer_id IS NOT NULL;
CREATE INDEX vpn_clients_setup_key_idx ON vpn_clients (setup_key_id);

-- ── 15. dhcp_leases ─────────────────────────────────────────────────────────

CREATE TABLE dhcp_leases (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    mac_address VARCHAR(17) NOT NULL,
    ip_address  INET        NOT NULL,
    hostname    VARCHAR(255),
    client_id   UUID,
    lease_start TIMESTAMPTZ NOT NULL,
    lease_end   TIMESTAMPTZ NOT NULL,
    is_active   BOOLEAN     NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE SET NULL
);

CREATE INDEX ix_dhcp_leases_mac_address ON dhcp_leases (mac_address);

-- ── 16. alert_incidents ─────────────────────────────────────────────────────

CREATE TABLE alert_incidents (
    id                 UUID            NOT NULL DEFAULT gen_random_uuid(),
    client_id          UUID            NOT NULL,
    condition          alertcondition  NOT NULL,
    status             incidentstatus  NOT NULL DEFAULT 'active',
    detail             VARCHAR(500),
    trigger_value      FLOAT,
    notified_at        TIMESTAMPTZ,
    notification_count INTEGER         NOT NULL DEFAULT 0,
    acknowledged_at    TIMESTAMPTZ,
    acknowledged_by    UUID,
    resolved_at        TIMESTAMPTZ,
    resolved_by        UUID,
    resolution_note    TEXT,
    created_at         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ     NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
);

CREATE INDEX ix_alert_incidents_client_id ON alert_incidents (client_id);
CREATE INDEX ix_alert_incidents_condition ON alert_incidents (condition);
CREATE INDEX ix_alert_incidents_status    ON alert_incidents (status);

-- ── 17. rollouts ────────────────────────────────────────────────────────────

CREATE TABLE rollouts (
    id                      UUID           NOT NULL DEFAULT gen_random_uuid(),
    name                    VARCHAR(255)   NOT NULL,
    image_id                UUID           NOT NULL,
    status                  rolloutstatus  NOT NULL DEFAULT 'draft',
    stages                  JSONB          NOT NULL,
    current_stage           INTEGER        NOT NULL DEFAULT 0,
    deploy_method           VARCHAR(20)    NOT NULL DEFAULT 'pxe',
    scope                   VARCHAR(20)    NOT NULL DEFAULT 'all',
    gruppe_id               UUID,
    total_eligible          INTEGER        NOT NULL DEFAULT 0,
    halt_on_errors          BOOLEAN        NOT NULL DEFAULT true,
    error_threshold_percent FLOAT          NOT NULL DEFAULT 20.0,
    created_by              UUID,
    started_at              TIMESTAMPTZ,
    created_at              TIMESTAMPTZ    NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ    NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (image_id) REFERENCES images (id) ON DELETE RESTRICT,
    -- Bis zum 2026-09-05 stand `gruppe_id` ohne Fremdschluessel da: nach dem
    -- Loeschen einer Gruppe zeigte die Spalte auf eine tote UUID, und der
    -- Bediener bekam beim Start nur „No eligible clients" zu sehen.
    -- SET NULL statt RESTRICT ist nur deshalb zulaessig, weil `launch_rollout`
    -- einen Gruppen-Rollout ohne Gruppe seither fail-closed abweist
    -- (`errors.rollouts.groupScopeGroupGone` — es wird KEIN Geraet gewaehlt) und
    -- `delete_group` das Loeschen einer Gruppe mit nicht abgeschlossenem
    -- Rollout schon vorher mit 409 verhindert.
    FOREIGN KEY (gruppe_id) REFERENCES gruppen (id) ON DELETE SET NULL
);

-- ── 18. rollout_clients ─────────────────────────────────────────────────────

CREATE TABLE rollout_clients (
    id                 UUID               NOT NULL DEFAULT gen_random_uuid(),
    rollout_id         UUID               NOT NULL,
    client_id          UUID               NOT NULL,
    stage              INTEGER            NOT NULL,
    status             rolloutclientstatus NOT NULL DEFAULT 'pending',
    assigned_at        TIMESTAMPTZ        NOT NULL,
    completed_at       TIMESTAMPTZ,
    created_at         TIMESTAMPTZ        NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ        NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (rollout_id) REFERENCES rollouts (id) ON DELETE CASCADE,
    FOREIGN KEY (client_id)  REFERENCES clients  (id) ON DELETE CASCADE
);

-- Ein Client darf pro Rollout nur EINMAL einer Stage zugeordnet sein. Verhindert
-- Duplikate, wenn launch_rollout nach einem partiellen Fehler erneut läuft
-- (Audit rollouts.rs:541); launch nutzt dazu ON CONFLICT DO NOTHING.
CREATE UNIQUE INDEX ix_rollout_clients_rollout_client_uq
    ON rollout_clients (rollout_id, client_id);

-- ── 19. clone_deployments ───────────────────────────────────────────────────

CREATE TABLE clone_deployments (
    id                               UUID                  NOT NULL DEFAULT gen_random_uuid(),
    clone_id                         VARCHAR(500)          NOT NULL,
    clone_name                       VARCHAR(255)          NOT NULL,
    gruppe_id                        UUID,
    status                           clonedeploymentstatus NOT NULL DEFAULT 'active',
    mode                             VARCHAR(20)           NOT NULL DEFAULT 'unicast',
    multicast_status                 VARCHAR(50),
    multicast_clients_ready          INTEGER               NOT NULL DEFAULT 0,
    multicast_total_partitions       INTEGER               NOT NULL DEFAULT 0,
    multicast_current_partition      VARCHAR(100),
    multicast_current_partition_index INTEGER              NOT NULL DEFAULT 0,
    multicast_first_ready_at         TIMESTAMPTZ,
    multicast_ready_deadline         TIMESTAMPTZ,
    completion_deadline              TIMESTAMPTZ,
    bt_status                        VARCHAR(50),
    bt_status_detail                 VARCHAR(255),
    bt_total_partitions              INTEGER               NOT NULL DEFAULT 0,
    bt_secret                        VARCHAR(64),
    scheduled_at                     TIMESTAMPTZ,
    wol_before_minutes               INTEGER,
    wol_sent                         BOOLEAN               NOT NULL DEFAULT false,
    post_action                      VARCHAR(20)           NOT NULL DEFAULT 'reboot',
    -- Online gemeldete Zielgeraete nach der Aktivierung per SSH neu starten
    -- (Neustart-Auftrag je Geraet); seit 2026-09-11, Vorgabe an. Bei
    -- BitTorrent erst, wenn der Seeder die Torrents bereitgestellt hat.
    reboot_now                       BOOLEAN               NOT NULL DEFAULT true,
    maintenance_window_id            UUID,
    -- Stage-Deployments von Image-Rollouts: activate_stage legt pro Stage ein
    -- clone_deployment an, damit Callbacks/Safety-Net/NFS-Grant identisch zu
    -- manuellen Deployments laufen; /done spiegelt darüber in rollout_clients.
    rollout_id                       UUID,
    created_at                       TIMESTAMPTZ           NOT NULL DEFAULT now(),
    updated_at                       TIMESTAMPTZ           NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (gruppe_id)             REFERENCES gruppen             (id) ON DELETE SET NULL,
    FOREIGN KEY (maintenance_window_id) REFERENCES maintenance_windows (id) ON DELETE SET NULL,
    FOREIGN KEY (rollout_id)            REFERENCES rollouts            (id) ON DELETE SET NULL
);

CREATE INDEX idx_deployment_active ON clone_deployments (status) WHERE status = 'active';

-- ── 20. clone_deployment_clients ────────────────────────────────────────────

CREATE TABLE clone_deployment_clients (
    id                  UUID        NOT NULL DEFAULT gen_random_uuid(),
    deployment_id       UUID        NOT NULL,
    client_id           UUID        NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending',
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    error_message       TEXT,
    multicast_ready     BOOLEAN     NOT NULL DEFAULT false,
    bt_download_progress INTEGER,
    bt_current_partition VARCHAR(100),
    callback_token      VARCHAR(64),
    -- Wann fuer das Geraet der Neustart-Auftrag (ssh_command reboot) entstand;
    -- NULL = keiner (offline, reboot_now abgewaehlt, geplant). Wird beim
    -- erneuten Bewaffnen (restart) geleert.
    reboot_sent_at      TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (deployment_id) REFERENCES clone_deployments (id) ON DELETE CASCADE,
    FOREIGN KEY (client_id)     REFERENCES clients           (id) ON DELETE CASCADE
);

-- Beide Fremdschluessel sind alleinige Suchbedingung haeufiger Abfragen:
-- PXE-Boot, DHCP-Ereignis und Rueckrufe suchen je Geraet den offenen Eintrag
-- (`client_id = … AND status IN ('pending','deploying')`), Deployment-Ansicht
-- und Multicast-Tick lesen je Deployment (`deployment_id = …`), und das
-- ON DELETE CASCADE beim Loeschen eines Geraets sucht ueber `client_id`. Ohne
-- Index war jede davon ein Seq-Scan ueber eine Tabelle, die mit Geraeten mal
-- Deployments waechst (Review 2026-09-02, sql-migrate-correctness:D2).
CREATE INDEX ix_clone_deployment_clients_client_id
    ON clone_deployment_clients (client_id, status);
CREATE INDEX ix_clone_deployment_clients_deployment_id
    ON clone_deployment_clients (deployment_id);

-- ── 21. capture_jobs ────────────────────────────────────────────────────────

CREATE TABLE capture_jobs (
    id             UUID        NOT NULL DEFAULT gen_random_uuid(),
    client_id      UUID        NOT NULL,
    capture_name   VARCHAR(255) NOT NULL,
    status         VARCHAR(20) NOT NULL DEFAULT 'pending',
    started_at     TIMESTAMPTZ,
    completed_at   TIMESTAMPTZ,
    error_message  TEXT,
    post_action    VARCHAR(20) NOT NULL DEFAULT 'shutdown',
    callback_token VARCHAR(64),
    -- Wann der Neustart-Auftrag fuer das Geraet entstand (reboot_now beim
    -- Anlegen, Geraet online gemeldet); NULL = keiner. Beim Restart geleert.
    reboot_sent_at TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE,
    -- Die fuenf Zustaende eines Aufnahme-Auftrags (CaptureJobStatus). Bis
    -- 2026-09-23 war die Spalte freier Text, und daneben stand ein Datentyp
    -- capturejobstatus, den keine Spalte nutzte: ein Tippfehler in einem
    -- Schreibweg ging still durch (Review 2026-09-02 D3/A3). Bestands-DBs:
    -- thinforge-migrate/src/aufnahme_status.rs.
    CONSTRAINT capture_jobs_status_check
        CHECK (status IN ('pending', 'capturing', 'done', 'failed', 'cancelled'))
);

-- ── 22. update_deltas ───────────────────────────────────────────────────────

CREATE TABLE update_deltas (
    id               UUID              NOT NULL DEFAULT gen_random_uuid(),
    from_version     VARCHAR(50)       NOT NULL,
    to_version       VARCHAR(50)       NOT NULL,
    from_snapshot    VARCHAR(100)      NOT NULL,
    to_snapshot      VARCHAR(100)      NOT NULL,
    delta_file       VARCHAR(500)      NOT NULL,
    delta_size_bytes BIGINT,
    clone_id         VARCHAR(500),
    status           updatedeltastatus NOT NULL DEFAULT 'ready',
    released         BOOLEAN           NOT NULL DEFAULT false,
    signature_file   VARCHAR(255),
    created_at       TIMESTAMPTZ       NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ       NOT NULL DEFAULT now(),
    PRIMARY KEY (id)
);

-- ── 23. update_rollouts ─────────────────────────────────────────────────────

CREATE TABLE update_rollouts (
    id                UUID               NOT NULL DEFAULT gen_random_uuid(),
    delta_id          UUID,
    target_version    VARCHAR(50)        NOT NULL DEFAULT '',
    gruppe_id         UUID,
    status            updaterolloutstatus NOT NULL DEFAULT 'draft',
    merge_in_progress BOOLEAN            NOT NULL DEFAULT false,
    notify_user       BOOLEAN            NOT NULL DEFAULT false,
    created_at        TIMESTAMPTZ        NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ        NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (delta_id)   REFERENCES update_deltas (id) ON DELETE SET NULL,
    FOREIGN KEY (gruppe_id)  REFERENCES gruppen       (id) ON DELETE SET NULL
);

-- ── 24. update_rollout_clients ──────────────────────────────────────────────
--
-- Slot-Lease + Throttle-Tracking pro Client (vorher: 0003 + 0005 + 0006).

CREATE TABLE update_rollout_clients (
    id                       UUID                       NOT NULL DEFAULT gen_random_uuid(),
    rollout_id               UUID                       NOT NULL,
    client_id                UUID                       NOT NULL,
    status                   updaterolloutclientstatus  NOT NULL DEFAULT 'pending',
    download_state           TEXT                       NOT NULL DEFAULT 'idle',
    download_lease_until     TIMESTAMPTZ,
    download_token_hash      VARCHAR(64),
    download_delta_file      VARCHAR(500),
    download_bytes_received  BIGINT,
    download_bytes_total     BIGINT,
    download_rate_mbit       DOUBLE PRECISION,
    download_retry_count     INT                        NOT NULL DEFAULT 0,
    -- Abbrueche im LAUFENDEN Zwischenschritt einer Update-Kette; das Budget
    -- max_retries greift hierauf. Der Hop-Reset (update_service
    -- update_client_rollout_status) setzt ihn zurueck, download_retry_count
    -- bleibt die Summe ueber alle Schritte (Bericht, Oberflaeche „Retry N").
    download_hop_retry_count INT                        NOT NULL DEFAULT 0,
    -- Zeitpunkt des Slot-Anspruchs. Deckel gegen ein Geraet, das seinen
    -- globalen Download-Slot unbegrenzt haelt (delta_download_slot::renew_lease).
    download_slot_since      TIMESTAMPTZ,
    -- Stand von download_bytes_received bei der letzten Verlaengerung. Ohne
    -- Fortschritt seit dann wird nicht verlaengert; die Lease laeuft aus.
    download_bytes_at_renew  BIGINT                     NOT NULL DEFAULT 0,
    created_at               TIMESTAMPTZ                NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ                NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (rollout_id) REFERENCES update_rollouts (id) ON DELETE CASCADE,
    FOREIGN KEY (client_id)  REFERENCES clients         (id) ON DELETE CASCADE,
    CONSTRAINT update_rollout_clients_download_state_check
        CHECK (download_state IN ('idle', 'downloading', 'staged', 'failed'))
);

-- Slot-Count-Query: WHERE download_state = 'downloading' AND lease_until > now().
CREATE INDEX idx_url_clients_active_download
    ON update_rollout_clients (download_state, download_lease_until)
 WHERE download_state = 'downloading';

-- agent_deltas-Handler-Lookup: WHERE download_token_hash = $1.
CREATE INDEX idx_url_clients_token_hash
    ON update_rollout_clients (download_token_hash)
 WHERE download_token_hash IS NOT NULL;

-- Hoechstens EIN offener Eintrag je Geraet (Review 2026-09-02,
-- update_service.rs:2075). Beide Suchen des Heartbeat-Wegs
-- (`get_pending_update_for_client`, `update_client_rollout_status`) fanden
-- vorher einen beliebigen von mehreren; `release_slot` fasste mit
-- `WHERE client_id = ...` sogar alle auf einmal an, sodass ein zweiter Rollout
-- als erledigt galt, ohne je ein Delta ausgeliefert zu haben.
--
-- Das Praedikat spiegelt `is_terminal_client_status` (update_service.rs):
-- terminal sind confirmed/failed/rolled_back/signature_failed, alles andere
-- gilt als offen. Als Negativliste geschrieben, damit ein spaeter ergaenzter
-- Status automatisch als offen zaehlt — so wie im Rust-Code auch.
CREATE UNIQUE INDEX ux_url_clients_open_per_client
    ON update_rollout_clients (client_id)
 WHERE status NOT IN ('confirmed'::updaterolloutclientstatus,
                      'failed'::updaterolloutclientstatus,
                      'rolled_back'::updaterolloutclientstatus,
                      'signature_failed'::updaterolloutclientstatus);

-- ── 25. rollback_tasks ──────────────────────────────────────────────────────

CREATE TABLE rollback_tasks (
    id           UUID               NOT NULL DEFAULT gen_random_uuid(),
    from_version VARCHAR(50)        NOT NULL,
    gruppe_id    UUID,
    status       rollbacktaskstatus NOT NULL DEFAULT 'active',
    created_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ        NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (gruppe_id) REFERENCES gruppen (id) ON DELETE SET NULL
);

-- ── 26. rollback_task_clients ───────────────────────────────────────────────

CREATE TABLE rollback_task_clients (
    id        UUID                     NOT NULL DEFAULT gen_random_uuid(),
    task_id   UUID                     NOT NULL,
    client_id UUID                     NOT NULL,
    status    rollbacktaskclientstatus NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ             NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ             NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (task_id)   REFERENCES rollback_tasks (id) ON DELETE CASCADE,
    FOREIGN KEY (client_id) REFERENCES clients        (id) ON DELETE CASCADE,
    CONSTRAINT uq_rollback_task_client UNIQUE (task_id, client_id)
);

-- ── 27. playbook_packages ───────────────────────────────────────────────────

CREATE TABLE playbook_packages (
    id                   UUID         NOT NULL DEFAULT gen_random_uuid(),
    name                 VARCHAR(200) NOT NULL,
    description          TEXT,
    playbook             VARCHAR(200) NOT NULL,
    directory            VARCHAR(200) NOT NULL,
    semaphore_template_id INTEGER,
    uploaded_at          TIMESTAMPTZ  NOT NULL DEFAULT now(),
    uploaded_by          UUID,
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    CONSTRAINT uq_playbook_packages_directory UNIQUE (directory)
);

-- ── 28. client_pending_snapshot_deletions ───────────────────────────────────
--
-- Pro Client: Liste von Snapshot-Versionen, die der Agent loeschen soll.
-- Wird per Heartbeat-Response ausgeliefert, per Heartbeat-Request bestaetigt,
-- nach Bestaetigung aus dieser Tabelle entfernt. Junction-Tabelle statt
-- text[]-Spalte: einzelne Bestaetigungen sauber per DELETE WHERE.

CREATE TABLE client_pending_snapshot_deletions (
    client_id   UUID         NOT NULL,
    version     VARCHAR(50)  NOT NULL,
    enqueued_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (client_id, version),
    FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE
);

-- Kein eigener Index auf client_id: der Primaerschluessel beginnt mit der
-- Spalte und bedient jedes `WHERE client_id = …` schon. Der fruehere
-- idx_pending_deletions_client war reine Schreiblast (Review 2026-09-02, D5).

-- ── 29. defective_versions ──────────────────────────────────────────────────
--
-- Globaler Defekt-Marker pro Version. Ergaenzt images.status='defective',
-- weil save_update fuer reine Delta-Versionen keine images-Zeile anlegt
-- (images traegt nur Baseline-Uploads). Ohne diese Tabelle waere die
-- defekte v002 fuer Backend-Logik wie path_crosses_defective unsichtbar.

CREATE TABLE defective_versions (
    version    VARCHAR(50)   PRIMARY KEY
);

-- ── 30. system_settings_vpn ─────────────────────────────────────────────────
--
-- ThinVPN-Mgmt-Verbindung (single-row, war 0002). access_token_encrypted ist
-- thinforge_core::encryption-Output (String mit "aes-gcm:"-Prefix) → TEXT.

CREATE TABLE system_settings_vpn (
    id                          INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    mgmt_url                    TEXT,
    access_token_encrypted      TEXT,
    last_modified_at            TIMESTAMPTZ,
    last_modified_by            UUID REFERENCES users(id),
    last_validated_at           TIMESTAMPTZ,
    last_validation_outcome     TEXT,
    -- Neuanbindung (2026-08): capabilities = gecachtes Ergebnis der
    -- Verbindungsprobe (probe_capabilities); anchor_id = eigene Instanz-ID
    -- (uuid v4, einmalig via ensure_anchor_id), als Marker in NetBird-Objekten
    -- hinterlegt und beim Inspect als Eigentumsnachweis wiedererkannt;
    -- bootstrap_state = Fortschritt des Setup-Wizards.
    capabilities                JSONB,
    anchor_id                   TEXT,
    bootstrap_state             TEXT NOT NULL DEFAULT 'unconfigured'
        CHECK (bootstrap_state IN ('unconfigured','inspect_pending','ready'))
);

INSERT INTO system_settings_vpn (id) VALUES (1) ON CONFLICT (id) DO NOTHING;

-- ── 31. Neuanbindung (2026-08) ──────────────────────────────────────────────
--
-- Das Schema der Reconcile-Engine neben der VPN-Baseline (vpn_clients,
-- system_settings_vpn). Freigaben (vpn_exposures/-_rules) sind die
-- Operator-Quelle des Soll-Zustands; vpn_objects ist das ID-Ledger;
-- vpn_apply_log protokolliert jeden Apply-Lauf für Audit + GUI-Fehleranzeige.

-- Freigaben (Operator-Regeln, Quelle des Soll-Zustands neben der Code-Baseline)
CREATE TABLE vpn_exposures (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    address     TEXT NOT NULL,          -- IP oder CIDR im Client-Netz
    dns_name    TEXT,                   -- optionaler dnsmasq-Hosteintrag
    enabled     BOOLEAN NOT NULL DEFAULT true,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX ux_vpn_exposures_name ON vpn_exposures (lower(name));

CREATE TABLE vpn_exposure_rules (
    id           BIGSERIAL PRIMARY KEY,
    exposure_id  BIGINT NOT NULL REFERENCES vpn_exposures(id) ON DELETE CASCADE,
    protocol     TEXT NOT NULL CHECK (protocol IN ('tcp','udp','icmp','all')),
    ports        TEXT NOT NULL DEFAULT '',   -- Komma-Liste, leer = alle
    source_group TEXT NOT NULL DEFAULT 'Clients',
    description  TEXT NOT NULL DEFAULT ''
);

-- ID-Ledger: Identität der ThinForge-eigenen NetBird-Objekte
CREATE TABLE vpn_objects (
    id                 BIGSERIAL PRIMARY KEY,
    object_kind        TEXT NOT NULL CHECK (object_kind IN
        ('group','network','resource','router','policy','nameserver_group')),
    logical_name       TEXT NOT NULL,
    netbird_id         TEXT NOT NULL,
    config_fingerprint TEXT NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (object_kind, logical_name)
);

-- Apply-Historie (Audit + GUI-Fehleranzeige)
CREATE TABLE vpn_apply_log (
    id           BIGSERIAL PRIMARY KEY,
    run_id       UUID NOT NULL,
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    action       TEXT NOT NULL,          -- create|adopt|update|recreate|delete|delete_foreign
    object_kind  TEXT NOT NULL,
    logical_name TEXT NOT NULL,          -- bei delete_foreign: Remote-Name
    outcome      TEXT NOT NULL CHECK (outcome IN ('ok','failed','skipped')),
    error_class  TEXT,
    error_detail TEXT
);
CREATE INDEX ix_vpn_apply_log_run ON vpn_apply_log (run_id);
-- Leseordnung der GUI (vpn::apply::recent_apply_log: ORDER BY started_at DESC,
-- id DESC LIMIT n) und zugleich die Aufraeumregel des Reconcile-Ticks
-- (DELETE ... started_at < now() - 14 Tage).
CREATE INDEX ix_vpn_apply_log_started ON vpn_apply_log (started_at DESC, id DESC);

-- ── 33. managed_certificates ────────────────────────────────────────────────
--
-- Operator-uploaded trust certificates (CA oder Leaf, auf PEM normalisiert), die
-- der Agent in den OS-weiten CA-Trust-Store reconciled (z. B. damit Citrix
-- Workspace einem self-signed Server vertraut). Scope: gruppe_id IS NULL =
-- global (jeder Client); gruppe_id gesetzt = nur Clients dieser Gruppe.
-- Agent holt sein Set via GET /api/v1/klon/managed-certs?mac=<mac>.
-- Design: docs/superpowers/specs/2026-05-28-managed-client-certificates-design.md
--
-- War bis 2026-05-30 eine separate Migration 0002. Eingefaltet, weil
-- docker-entrypoint-initdb.d bei fresh-initdb ALLE migrations/*.sql ausführt,
-- der Migrate-Bootstrap aber nur die Baseline (Version 1) als applied stempelte
-- → sqlx::run() versuchte 0002 erneut → "relation managed_certificates already
-- exists" → Crash-Loop. Single-0001-Baseline schließt das.

CREATE TABLE managed_certificates (
    id          UUID         NOT NULL DEFAULT gen_random_uuid(),
    name        VARCHAR(255) NOT NULL,
    gruppe_id   UUID,
    pem         TEXT         NOT NULL,
    sha256      VARCHAR(64)  NOT NULL,
    subject_cn  VARCHAR(255) NOT NULL DEFAULT '',
    not_after   TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (gruppe_id) REFERENCES gruppen (id) ON DELETE CASCADE
);

CREATE INDEX ix_managed_certificates_gruppe_id ON managed_certificates (gruppe_id);

-- ── 34. fleet_daily ─────────────────────────────────────────────────────────
--
-- Tages-Snapshot der Flotten-Verfügbarkeit (Phase-3-Reporting). Eine Zeile pro
-- Tag, befüllt vom scheduled_task 'fleet_daily_snapshot' (UPSERT auf snapshot_date).
CREATE TABLE fleet_daily (
    id               UUID             NOT NULL DEFAULT gen_random_uuid(),
    snapshot_date    DATE             NOT NULL,
    total_clients    INTEGER          NOT NULL DEFAULT 0,
    online_clients   INTEGER          NOT NULL DEFAULT 0,
    offline_clients  INTEGER          NOT NULL DEFAULT 0,
    error_clients    INTEGER          NOT NULL DEFAULT 0,
    avg_cpu_percent  DOUBLE PRECISION,
    avg_ram_percent  DOUBLE PRECISION,
    avg_disk_percent DOUBLE PRECISION,
    created_at       TIMESTAMPTZ      NOT NULL DEFAULT now(),
    PRIMARY KEY (id),
    UNIQUE (snapshot_date)
);

-- ── 35. Eindeutiger DNS-Name je Freigabe (Befund V110, 2026-09-06) ──────────
-- Die dnsmasq-Hosteintraege werden allein ueber den Hostnamen gepflegt: zwei
-- Freigaben mit demselben `dns_name` ueberschrieben einander den Eintrag, und
-- das Loeschen oder Umbenennen der einen nahm der anderen den Namen — die
-- Oberflaeche zeigte ihn weiter als eingerichtet. Partiell: NULL heisst „kein
-- Name" und darf beliebig oft vorkommen; case-insensitiv wie dnsmasq.
CREATE UNIQUE INDEX ux_vpn_exposures_dns_name
    ON vpn_exposures (lower(dns_name)) WHERE dns_name IS NOT NULL;
