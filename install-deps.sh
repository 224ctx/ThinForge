#!/usr/bin/env bash
# install-deps.sh — Install host dependencies required to run ThinForge
# Tested on: Ubuntu 24.04+ (Noble Numbat)
#
# Host requirements are minimal — almost everything runs in Docker containers.
# This script only installs Docker and loads kernel modules that containers need.

set -euo pipefail

cd "$(dirname "$0")"

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------
source "$(dirname "$0")/scripts/lib-log.sh"
source "$(dirname "$0")/scripts/lib-env.sh"

if [ "$(id -u)" -eq 0 ]; then
  err "Do not run this script as root. It will use sudo where needed."
  exit 1
fi

NEEDS_RELOGIN=false

# ---------------------------------------------------------------------------
# 1. Docker Engine + Docker Compose Plugin
# ---------------------------------------------------------------------------
info "Installing base packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg git openssl
ok "Base packages installed."

if command -v docker &>/dev/null; then
  ok "Docker already installed: $(docker --version)"
else
  info "Installing Docker Engine..."

  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
  ok "Docker installed: $(docker --version)"
fi

if docker compose version &>/dev/null; then
  ok "Docker Compose plugin: $(docker compose version --short)"
else
  info "Installing Docker Compose plugin..."
  sudo apt-get install -y -qq docker-compose-plugin
  ok "Docker Compose plugin installed: $(docker compose version --short)"
fi

# ---------------------------------------------------------------------------
# 2. User groups (docker, kvm)
# ---------------------------------------------------------------------------
if groups "$USER" | grep -qw docker; then
  ok "User '$USER' is in the docker group."
else
  info "Adding '$USER' to the docker group..."
  sudo usermod -aG docker "$USER"
  NEEDS_RELOGIN=true
fi

if getent group kvm &>/dev/null; then
  if id -nG "$USER" | grep -qw kvm; then
    ok "User '$USER' is in the kvm group."
  else
    info "Adding '$USER' to the kvm group..."
    sudo usermod -aG kvm "$USER"
    NEEDS_RELOGIN=true
  fi
fi

# ---------------------------------------------------------------------------
# 3. Kernel modules
#    Containers share the host kernel — these modules must be loaded on the
#    host even though the tools that use them run inside containers.
#    load_module() is provided by lib-env.sh
# ---------------------------------------------------------------------------

# nbd — required for exposing qcow2 images as block devices (cloning)
load_module nbd max_part=16 || { err "nbd module not available — cloning will not work."; exit 1; }

# NFS — modules are in linux-modules-extra on Ubuntu 24.04 (no extra package needed)
load_module nfs  || warn "NFS module not found. Run: sudo apt-get install linux-modules-extra-\$(uname -r)"
load_module nfsd || warn "NFSD module not found. Run: sudo apt-get install linux-modules-extra-\$(uname -r)"

# WireGuard — built into kernel on Ubuntu 22.04+
load_module wireguard || warn "WireGuard module not found. Run: sudo apt-get install linux-headers-\$(uname -r)"

# KVM — detect CPU vendor, load appropriate module (pulls in base kvm module)
if [ -d "/sys/module/kvm" ] || lsmod | grep -q "^kvm "; then
  ok "KVM module available."
else
  KVM_MOD=""
  if grep -q "vendor_id.*GenuineIntel" /proc/cpuinfo; then
    KVM_MOD=kvm_intel
  elif grep -q "vendor_id.*AuthenticAMD" /proc/cpuinfo; then
    KVM_MOD=kvm_amd
  fi
  if [ -n "$KVM_MOD" ]; then
    load_module "$KVM_MOD" || warn "KVM not available — VMs will use TCG emulation (slower)."
  else
    warn "Unknown CPU vendor — skipping KVM module."
  fi
fi

if [ -c /dev/kvm ]; then
  ok "/dev/kvm is available."
else
  warn "/dev/kvm not found — Cloning-VM will run without hardware acceleration."
fi

# Persist modules across reboots
MODULES_CONF=/etc/modules-load.d/thinforge.conf
for mod in nbd nfs nfsd wireguard; do
  if ! grep -qs "^${mod}$" "$MODULES_CONF" 2>/dev/null; then
    echo "$mod" | sudo tee -a "$MODULES_CONF" > /dev/null
  fi
done
# Persist vendor-specific KVM module
KVM_MOD=""
if grep -q "GenuineIntel" /proc/cpuinfo; then KVM_MOD=kvm_intel;
elif grep -q "AuthenticAMD" /proc/cpuinfo; then KVM_MOD=kvm_amd; fi
if [ -n "$KVM_MOD" ] && ! grep -qs "^${KVM_MOD}$" "$MODULES_CONF" 2>/dev/null; then
  echo "$KVM_MOD" | sudo tee -a "$MODULES_CONF" > /dev/null
fi
if ! grep -qs "nbd" /etc/modprobe.d/thinforge-nbd.conf 2>/dev/null; then
  echo "options nbd max_part=16" | sudo tee /etc/modprobe.d/thinforge-nbd.conf > /dev/null
fi
ok "Kernel modules will persist across reboots."

# ---------------------------------------------------------------------------
# 4. Check for conflicting host services
# ---------------------------------------------------------------------------
for svc in nfs-server rpcbind; do
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    warn "Host service '$svc' is running — it will conflict with the NFS Docker container."
    warn "  Fix: sudo systemctl disable --now $svc && sudo systemctl mask rpcbind.service rpcbind.socket"
  fi
done

# ---------------------------------------------------------------------------
# 5. Host timezone
#    Korrekte Uhrzeit ist Voraussetzung fuer TLS-Validierung (Agent-
#    Heartbeat ueber HTTPS) und fuer aussagekraeftige Logs/Snapshots.
#    Ablauf:
#      - DESIRED_TZ aus Env vorbelegen (headless installs)
#      - sonst interaktiv abfragen mit aktueller TZ als Default
#      - bei nicht-interaktivem stdin (curl|bash, CI) DESIRED_TZ
#        auf aktuelle TZ lassen, Fallback Europe/Berlin
#      - Eingabe gegen `timedatectl list-timezones` validieren
# ---------------------------------------------------------------------------
CURRENT_TZ=$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo "Etc/UTC")

# Vorgabe: Env > aktuelle TZ > Europe/Berlin
DEFAULT_TZ="${DESIRED_TZ:-${CURRENT_TZ:-Europe/Berlin}}"
[ "$DEFAULT_TZ" = "unknown" ] && DEFAULT_TZ="Europe/Berlin"

if [ -n "${DESIRED_TZ:-}" ]; then
  # Explizit per Env vorgegeben — nicht fragen
  TARGET_TZ="$DESIRED_TZ"
elif [ -t 0 ]; then
  # Interaktiv abfragen
  echo ""
  echo "  Aktuelle Zeitzone: $CURRENT_TZ"
  echo "  Beispiele:         Europe/Berlin, Europe/Vienna, Europe/Zurich,"
  echo "                     UTC, America/New_York, Asia/Tokyo"
  echo "  Liste:             timedatectl list-timezones"
  echo ""
  while true; do
    read -rp "  Zeitzone setzen [$DEFAULT_TZ]: " TARGET_TZ
    TARGET_TZ="${TARGET_TZ:-$DEFAULT_TZ}"
    if timedatectl list-timezones 2>/dev/null | grep -qx "$TARGET_TZ"; then
      break
    fi
    err "  Unbekannte Zeitzone: '$TARGET_TZ' — bitte exakten IANA-Namen angeben."
  done
else
  # Nicht-interaktiv: aktuelle TZ behalten, sonst Berlin
  TARGET_TZ="$DEFAULT_TZ"
  info "Non-interactive run — using DEFAULT_TZ=$TARGET_TZ (override via DESIRED_TZ=...)."
fi

if [ "$CURRENT_TZ" = "$TARGET_TZ" ]; then
  ok "Host timezone: $CURRENT_TZ"
else
  info "Setting host timezone to $TARGET_TZ (was: $CURRENT_TZ)..."
  sudo timedatectl set-timezone "$TARGET_TZ"
  ok "Host timezone set to $TARGET_TZ"
fi

# NTP-Sync sicherstellen — ohne korrekte Uhrzeit schlaegt TLS fehl
if timedatectl show -p NTPSynchronized --value 2>/dev/null | grep -q "yes"; then
  ok "System clock is NTP-synchronized."
else
  info "Enabling NTP synchronization..."
  sudo timedatectl set-ntp true 2>/dev/null || warn "Could not enable NTP — check 'timedatectl status'."
fi

# ---------------------------------------------------------------------------
# 6. .env file + storage directory
#    load_storage_dir resolves PROJECT_ROOT, materialises .env from the
#    template (generating secrets), and exports STORAGE_DIR.
# ---------------------------------------------------------------------------
load_storage_dir

if [ -d "$STORAGE_DIR" ]; then
  ok "Storage directory exists: $STORAGE_DIR"
else
  info "Creating storage directory: $STORAGE_DIR"
  mkdir -p "$STORAGE_DIR"
  ok "Storage directory created."
fi

# ---------------------------------------------------------------------------
# 8. Enable & start Docker service
# ---------------------------------------------------------------------------
if systemctl is-active --quiet docker; then
  ok "Docker service is running."
else
  info "Starting Docker service..."
  sudo systemctl enable --now docker
  ok "Docker service started and enabled."
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " ThinForge — All dependencies installed"
echo "============================================"
echo ""
echo "  Docker:          $(docker --version 2>/dev/null)"
echo "  Docker Compose:  $(docker compose version --short 2>/dev/null)"
echo "  KVM:             $([ -c /dev/kvm ] && echo 'available' || echo 'not available')"
echo "  Storage:         $STORAGE_DIR"
echo ""

if [ "$NEEDS_RELOGIN" = true ]; then
  warn "Group membership changed — log out and back in (or run 'newgrp docker'), then:"
else
  echo "  Next step:"
fi
echo "   ./rebuild.sh"
echo "============================================"
