#!/bin/bash
#
# ThinForge — Branding (Wallpaper + Boot-Splash) fuer CachyOS (XFCE-Edition)
#
# Kopiert tf-wall.png von der Tools-ISO nach /etc/thinforge/ und setzt es als:
#   - GRUB-Bootmenue-Hintergrund
#   - Plymouth-Boot-Splash
#   - Display-Manager-Login-Hintergrund (LightDM/SDDM)
#   - Desktop-Hintergrund (XFCE u.a., aktuelle + kuenftige Benutzer)
#
# Aufruf:
#   sudo bash install-branding-cachyos.sh           # eigenstaendig
#
# Wird ausserdem automatisch aus install-cachyos.sh (finish) aufgerufen.
#
# Bildquelle: tf-wall.png im ISO-Root (neben den install-*.sh) oder via
# Env TF_WALL_FILE=/pfad/zur/tf-wall.png.

set -euo pipefail

TF_SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TF_DISTRO="CachyOS"

# shellcheck source=branding-common.sh
. "$TF_SCRIPT_DIR/branding-common.sh"

tf_pkg_install_plymouth() {
    # Bewusst KEIN -Sy: ein erneutes DB-Refresh nach dem -Syu im Installer waere
    # ein Partial-Upgrade (Arch-Antipattern). Die Sync-DB ist hier bereits frisch.
    pacman -S --noconfirm --needed plymouth 2>/dev/null || return 1
}

tf_grub_regen()      { grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null; }
tf_initramfs_regen() { mkinitcpio -P 2>/dev/null; }

# CachyOS nutzt wie Arch mkinitcpio — 'plymouth' als HOOK eintragen
# (gemeinsame Logik in branding-common.sh).
tf_initramfs_prepare_plymouth() { tf_mkinitcpio_add_plymouth_hook; }

tf_branding_main "$@"
