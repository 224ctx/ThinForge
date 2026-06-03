#!/bin/bash
#
# ThinForge — Branding (Wallpaper + Boot-Splash) fuer Debian
#
# Kopiert tf-wall.png von der Tools-ISO nach /etc/thinforge/ und setzt es als:
#   - GRUB-Bootmenue-Hintergrund
#   - Plymouth-Boot-Splash
#   - Display-Manager-Login-Hintergrund (LightDM/SDDM)
#   - Desktop-Hintergrund (alle Desktop-Umgebungen, aktuelle + kuenftige Benutzer)
#
# Aufruf:
#   sudo bash install-branding-debian.sh            # eigenstaendig
#
# Wird ausserdem automatisch aus install-debian.sh (finish) aufgerufen.
#
# Bildquelle: tf-wall.png im ISO-Root (neben den install-*.sh) oder via
# Env TF_WALL_FILE=/pfad/zur/tf-wall.png.

set -euo pipefail

TF_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TF_DISTRO="Debian"

# shellcheck source=branding-common.sh
. "$TF_SCRIPT_DIR/branding-common.sh"

tf_pkg_install_plymouth() {
    DEBIAN_FRONTEND=noninteractive apt-get update -qq || true
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        plymouth plymouth-themes || return 1
}

tf_grub_regen()      { update-grub 2>/dev/null; }
tf_initramfs_regen() { update-initramfs -u 2>/dev/null; }
# Debian: update-initramfs zieht das Plymouth-Theme automatisch — kein HOOK noetig.

tf_branding_main "$@"
