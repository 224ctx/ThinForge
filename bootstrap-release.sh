#!/usr/bin/env bash
# bootstrap-release.sh — One-shot deployment of ThinForge from the
# pre-built container images in the Gitea registry. Run once on a fresh
# Debian/Ubuntu host.
#
# Usage:
#   ./bootstrap-release.sh                   # default target: ~/ThinForge-Release
#   TARGET_DIR=/opt/thinforge ./bootstrap-release.sh
#
# The script can be fetched and run standalone — it does its own git clone.
# Release repo and container registry are both anonymously readable, so no
# credentials are needed.

set -euo pipefail

GITEA_HOST="${GITEA_HOST:-git.thinforge.org}"
TARGET_DIR="${TARGET_DIR:-$HOME/ThinForge-Release}"

echo "============================================"
echo " ThinForge — Release Bootstrap"
echo " Gitea:  https://${GITEA_HOST}"
echo " Target: ${TARGET_DIR}"
echo "============================================"

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git is required. Install it first: sudo apt-get install -y git"
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Clone (or update) the Release repo — public, no auth.
# ---------------------------------------------------------------------------
if [ -d "$TARGET_DIR/.git" ]; then
  echo ""
  echo "[1/3] Updating existing clone in ${TARGET_DIR}..."
  git -C "$TARGET_DIR" pull --ff-only
else
  echo ""
  echo "[1/3] Cloning ThinForge-Release to ${TARGET_DIR}..."
  git clone "https://${GITEA_HOST}/thinforge/ThinForge-Release.git" "$TARGET_DIR"
fi

cd "$TARGET_DIR"

# ---------------------------------------------------------------------------
# 2. Install host dependencies. install-deps.sh also materialises .env
#    from the template and seeds CHANGE_ME_* placeholders with random
#    secrets — no manual .env editing needed for a default deploy.
# ---------------------------------------------------------------------------
echo ""
echo "[2/3] Running install-deps.sh..."
./install-deps.sh

# ---------------------------------------------------------------------------
# 3. Pull images + start the stack. The Gitea container registry is
#    anonymous-readable for the thinforge/* packages — docker pull just works.
#
#    Fresh-host gotcha: install-deps.sh just added this user to the `docker`
#    group, but that membership is NOT active in the already-running shell
#    (usermod needs a fresh login). Running deploy.sh directly would then fail
#    with "permission denied ... /var/run/docker.sock". If the socket is not
#    reachable yet but the user IS a member of the docker group per the system
#    database, re-exec the deploy under `sg docker` so no logout/login is needed.
# ---------------------------------------------------------------------------
echo ""
echo "[3/3] Pulling images and starting the stack..."

_tf_user="$(id -un)"
if docker info >/dev/null 2>&1; then
  # Docker socket already reachable in this session.
  ./deploy.sh
elif command -v sg >/dev/null 2>&1 && id -nG "$_tf_user" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
  # User is in the docker group per the system DB but this shell predates that
  # change — activate the group for the deploy without a full re-login.
  echo "    Note: activating the freshly-assigned 'docker' group via sg (no re-login needed)..."
  sg docker -c "cd '$TARGET_DIR' && ./deploy.sh"
else
  # Not in the docker group, or the daemon is down — run anyway so deploy.sh
  # surfaces its own clear error.
  ./deploy.sh
fi

echo ""
echo "============================================"
echo " Bootstrap done. ThinForge should be up at:"
echo "   https://$(hostname -f 2>/dev/null || hostname)/"
echo "============================================"
