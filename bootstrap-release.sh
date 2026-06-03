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

GITEA_HOST="${GITEA_HOST:-git.example.com}"
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
# ---------------------------------------------------------------------------
echo ""
echo "[3/3] Pulling images and starting the stack..."
./deploy.sh

echo ""
echo "============================================"
echo " Bootstrap done. ThinForge should be up at:"
echo "   https://$(hostname -f 2>/dev/null || hostname)/"
echo "============================================"
