#!/usr/bin/env bash
# lib-env.sh — Shared environment helpers for ThinForge scripts
# Source this file: source "$(dirname "$0")/scripts/lib-env.sh"

# Load STORAGE_DIR from .env if not already set
load_storage_dir() {
  STORAGE_DIR="${STORAGE_DIR:-}"
  if [ -z "$STORAGE_DIR" ] && [ -f .env ]; then
    STORAGE_DIR=$(grep -E '^STORAGE_DIR=' .env | cut -d= -f2- || true)
  fi
  STORAGE_DIR="${STORAGE_DIR:-$(pwd)/ThinForgeDaten}"
  export STORAGE_DIR
}

# Load a kernel module with optional parameters
load_module() {
  local mod="$1"; shift
  if lsmod | grep -q "^${mod} " || [ -d "/sys/module/${mod}" ]; then
    echo "  Kernel module '${mod}' already loaded."
    return 0
  fi
  echo "  Loading kernel module '${mod}'..."
  if sudo modprobe "$mod" "$@" 2>/dev/null; then
    echo "  Kernel module '${mod}' loaded."
    return 0
  fi
  return 1
}
