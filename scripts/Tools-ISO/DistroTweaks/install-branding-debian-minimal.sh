#!/bin/bash
#
# ThinForge — Branding (Wallpaper + Boot-Splash) fuer Debian-Minimal
#
# Wie install-branding-debian.sh. Auf Minimal-Systemen ohne Desktop greifen
# nur GRUB-Hintergrund und Plymouth-Splash; die Desktop-/Login-Schritte laufen
# folgenlos durch (kein Display-Manager / keine DE vorhanden).
#
# Aufruf:
#   sudo bash install-branding-debian-minimal.sh    # eigenstaendig
#
# Wird ausserdem automatisch aus install-debian-minimal.sh (finish) aufgerufen.
#
# Bildquelle: tf-wall.png im ISO-Root (neben den install-*.sh) oder via
# Env TF_WALL_FILE=/pfad/zur/tf-wall.png.

set -euo pipefail

TF_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TF_DISTRO="Debian-Minimal"

# shellcheck source=branding-common.sh
. "$TF_SCRIPT_DIR/branding-common.sh"

tf_pkg_install_plymouth() {
    DEBIAN_FRONTEND=noninteractive apt-get update -qq || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        plymouth plymouth-themes || return 1
}

tf_grub_regen()      { update-grub 2>/dev/null; }
tf_initramfs_regen() { update-initramfs -u 2>/dev/null; }

tf_branding_main "$@"
