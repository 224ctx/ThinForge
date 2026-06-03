#!/usr/bin/env bash
# lib-log.sh — Canonical colored logging helpers for ThinForge scripts
# Source this file: source "$(dirname "$0")/scripts/lib-log.sh"

_RED='\033[1;31m'
_GREEN='\033[1;32m'
_YELLOW='\033[1;33m'
_CYAN='\033[1;34m'
_NC='\033[0m'

info() { echo -e "${_CYAN}[INFO]${_NC}  $*"; }
ok()   { echo -e "${_GREEN}[OK]${_NC}    $*"; }
warn() { echo -e "${_YELLOW}[WARN]${_NC}  $*"; }
err()  { echo -e "${_RED}[ERROR]${_NC} $*" >&2; }
die()  { err "$@"; exit 1; }
