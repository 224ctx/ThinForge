#!/bin/bash
#
# ThinForge — Branding-Bibliothek (gemeinsam fuer alle Distributionen)
#
# Wird von den install-branding-<distro>.sh Wrappern gesourct, NICHT direkt
# ausgefuehrt. Der Wrapper definiert vorher:
#
#   TF_SCRIPT_DIR     Verzeichnis des Wrappers (= DistroTweaks/ auf der ISO)
#   TF_DISTRO         Anzeigename der Distribution (z.B. "Debian")
#
#   tf_pkg_install_plymouth   Plymouth (+Themes) installieren        [Pflicht]
#   tf_grub_regen             GRUB-Config neu generieren             [Pflicht]
#   tf_initramfs_regen        initramfs neu bauen                    [Pflicht]
#   tf_initramfs_prepare_plymouth   distro-spez. initramfs-Vorbereitung [optional]
#
# ...und ruft am Ende `tf_branding_main "$@"` auf.
#
# Aufgabe: tf-wall.png nach /etc/thinforge/ kopieren und als Hintergrund
# setzen fuer (1) GRUB-Bootmenue, (2) Plymouth-Boot-Splash,
# (3) Display-Manager-Login, (4) Desktop aller Benutzer.

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "branding-common.sh is a library — please call install-branding-<distro>.sh instead." >&2
    exit 1
fi

# -- Konstanten / Helfer -----------------------------------------------------

TF_WALL_DEST="/etc/thinforge/tf-wall.png"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()   { echo -e "${GREEN}[thinforge]${NC} $*"; }
warn()  { echo -e "${YELLOW}[thinforge]${NC} $*"; }
error() { echo -e "${RED}[thinforge]${NC} $*" >&2; }
fatal() { error "$*"; exit 1; }

require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        fatal "This script must run as root (sudo bash $0)."
    fi
}

tf_usage() {
    cat <<USAGE
ThinForge Branding (${TF_DISTRO:-?})

Copies tf-wall.png to ${TF_WALL_DEST} and sets it as the background for
GRUB boot menu, Plymouth boot splash, login screen and desktop (all users).

Usage:
  sudo bash $(basename "$0")

Image source (one is sufficient, searched in this order):
  1. Env TF_WALL_FILE=/path/to/tf-wall.png
  2. tf-wall.png next to this script (DistroTweaks/)
  3. tf-wall.png in the ISO root (one level up)
  4. already installed ${TF_WALL_DEST}
USAGE
}

# -- tf-wall.png finden ------------------------------------------------------

tf_locate_wall() {
    if [ -n "${TF_WALL_FILE:-}" ]; then
        if [ ! -f "$TF_WALL_FILE" ]; then
            error "TF_WALL_FILE=$TF_WALL_FILE does not exist."
            return 1
        fi
        printf '%s\n' "$TF_WALL_FILE"
        return 0
    fi
    local c
    for c in "$TF_SCRIPT_DIR/tf-wall.png" "$TF_SCRIPT_DIR/../tf-wall.png" "$TF_WALL_DEST"; do
        if [ -f "$c" ]; then
            printf '%s\n' "$c"
            return 0
        fi
    done
    return 1
}

# -- GRUB-Bootmenue-Hintergrund ----------------------------------------------

tf_set_grub_background() {
    local img="$1"
    local grub_def="${TF_GRUB_DEFAULT:-/etc/default/grub}"
    if [ ! -f "$grub_def" ]; then
        warn "/etc/default/grub not found — GRUB background skipped."
        return 0
    fi
    # Subvolume-agnostisch: GRUB_BACKGROUND zeigt auf den kanonischen /etc-Pfad.
    # Die @root-/Snapshot-Aufloesung passiert erst beim "Update speichern"
    # (delta_runner::resolve_root_subvol -> grub-mkconfig regeneriert grub.cfg
    # mit korrektem Subvolume-Prefix). Wir hardcoden hier also KEIN Subvolume.
    if grep -qE '^[#[:space:]]*GRUB_BACKGROUND=' "$grub_def"; then
        sed -i -E "s|^[#[:space:]]*GRUB_BACKGROUND=.*|GRUB_BACKGROUND=\"$img\"|" "$grub_def"
    else
        printf 'GRUB_BACKGROUND="%s"\n' "$img" >> "$grub_def"
    fi
    log "GRUB background set: $img"
    TF_GRUB_DIRTY=1
    tf_grub_theme_override "$img"
}

# Ist ein GRUB-Theme aktiv, kommt der Hintergrund aus dessen theme.txt und
# GRUB_BACKGROUND wird ignoriert. Daher das desktop-image des Themes umbiegen.
tf_grub_theme_override() {
    local img="$1"
    local grub_def="${TF_GRUB_DEFAULT:-/etc/default/grub}"
    local theme_line theme_txt
    # `|| true`: ohne Theme liefert grep Exit 1, was unter `set -e` + pipefail
    # sonst das ganze Script abbraeche.
    theme_line="$(grep -E '^[[:space:]]*GRUB_THEME=' "$grub_def" 2>/dev/null | tail -1 || true)"
    [ -n "$theme_line" ] || return 0
    theme_txt="$(printf '%s' "$theme_line" | sed -E 's/^[^=]*=//; s/^"//; s/"$//')"
    [ -f "$theme_txt" ] || return 0
    local theme_dir
    theme_dir="$(dirname "$theme_txt")"
    # Bild NEBEN die theme.txt legen und RELATIV referenzieren. Ein absoluter
    # Pfad (/etc/...) wird von GRUB gegen das btrfs-Top-Level aufgeloest und
    # scheitert auf @root-Layouts ("fs/btrfs.c:find_path: not found"); ein
    # relativer Name wird gegen das Theme-Verzeichnis aufgeloest, das GRUB
    # korrekt (inkl. Subvolume) kennt — genau wie der Stock-Theme-Hintergrund.
    if ! { install -m0644 "$img" "$theme_dir/tf-wall.png" 2>/dev/null \
           || cp -f "$img" "$theme_dir/tf-wall.png" 2>/dev/null; }; then
        warn "Could not copy image to $theme_dir — GRUB theme background skipped."
        return 0
    fi
    if grep -qE '^[[:space:]]*desktop-image:' "$theme_txt"; then
        sed -i -E "s|^[[:space:]]*desktop-image:.*|desktop-image: \"tf-wall.png\"|" "$theme_txt"
    else
        printf '\ndesktop-image: "tf-wall.png"\n' >> "$theme_txt"
    fi
    log "GRUB theme background redirected: $theme_txt (relative: tf-wall.png)"
    TF_GRUB_DIRTY=1
}

# -- Plymouth-Boot-Splash ----------------------------------------------------

tf_set_plymouth() {
    local img="$1"
    if ! tf_pkg_install_plymouth; then
        warn "Plymouth could not be installed — boot splash skipped."
        return 0
    fi
    if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
        warn "plymouth-set-default-theme missing — boot splash skipped."
        return 0
    fi

    local themedir=/usr/share/plymouth/themes/thinforge
    install -d -m0755 "$themedir"
    # Plymouth laeuft in der initramfs — das Bild muss IM Theme-Verzeichnis
    # liegen, damit es mit eingebacken wird (kein Zugriff auf /etc beim Boot).
    install -m0644 "$img" "$themedir/tf-wall.png"

    # Kleiner weisser Punkt (32x32 RGBA) fuer den animierten Drei-Punkt-Throbber.
    # Plymouth-script kann keine Kreise zeichnen, daher als Bild hinterlegt;
    # base64-embedded, damit kein separates Asset auf der ISO gepflegt werden muss.
    # Schlaegt das Erzeugen fehl, zeigt der Splash nur den Hintergrund (kein Abbruch).
    local dots_ok=0
    if base64 -d > "$themedir/tf-dot.png" 2>/dev/null <<'TFDOT'
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAAzklEQVR42u2XsQ3EIAxF6bMGC7AN
C7CH92ABBsk6mYDCR/GL6JQjwEHsIpZ+E2HnYQwYw8xGUuYF6HSwRb6IimJRgiK+eYyZDuDwg70o
82/LGEPwmQIQELTXdvgOA2yYycHjdiDGNgJAN+lutYxYXQDhz5lfZSK0ArjBNW+pCdcCQLzO6A7A
Lpr9OQu2BuAnFV6tIH0NYGX6L5fhGyA+ABBrAOkBgKQaQHwJxItQfBuKH0TiR7GKy0j8OlbRkKho
ycSbUjVtuYqHyfs2XKYPrbTxRIdhljcAAAAASUVORK5CYII=
TFDOT
    then
        [ -s "$themedir/tf-dot.png" ] && dots_ok=1
    fi
    [ "$dots_ok" = 1 ] || rm -f "$themedir/tf-dot.png"

    cat > "$themedir/thinforge.plymouth" <<'PLY'
[Plymouth Theme]
Name=ThinForge
Description=ThinForge boot splash
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/thinforge
ScriptFile=/usr/share/plymouth/themes/thinforge/thinforge.script
PLY

    # Basis: vollflaechiges Hintergrundbild.
    cat > "$themedir/thinforge.script" <<'SCR'
# Vollflaechiges Hintergrundbild, auf die Bildschirmgroesse skaliert.
wallpaper = Image("tf-wall.png");
screen_w = Window.GetWidth();
screen_h = Window.GetHeight();
bg = Sprite(wallpaper.Scale(screen_w, screen_h));
bg.SetX(0);
bg.SetY(0);
bg.SetZ(-100);
SCR

    # Drei animierte Punkte (gilt fuer Boot- UND Shutdown-Splash, da Plymouth
    # dasselbe Default-Theme nutzt) — nur wenn der Throbber-Punkt erzeugt wurde.
    if [ "$dots_ok" = 1 ]; then
        cat >> "$themedir/thinforge.script" <<'SCR'

# --- Animierter Drei-Punkt-Throbber (gestaffeltes Pulsieren) ---
dot_image = Image("tf-dot.png");
dot_w = dot_image.GetWidth();
dot_h = dot_image.GetHeight();
gap = dot_w * 1.6;
center_x = screen_w / 2;
base_y = screen_h * 0.72;

dots[0] = Sprite(dot_image);
dots[1] = Sprite(dot_image);
dots[2] = Sprite(dot_image);

i = 0;
while (i < 3) {
    dots[i].SetX(center_x + (i - 1) * gap - dot_w / 2);
    dots[i].SetY(base_y - dot_h / 2);
    dots[i].SetZ(50);
    dots[i].SetOpacity(0.3);
    i = i + 1;
}

tick = 0;
fun refresh () {
    tick = tick + 1;
    j = 0;
    while (j < 3) {
        phase = (tick / 8) - (j * 0.9);
        opacity = 0.25 + 0.75 * (0.5 + 0.5 * Math.Sin(phase));
        dots[j].SetOpacity(opacity);
        j = j + 1;
    }
}
Plymouth.SetRefreshFunction(refresh);
SCR
        log "Plymouth splash: background + animated three-dot throbber."
    else
        log "Plymouth splash: background only (no throbber dot generated)."
    fi

    # Distro-spezifische initramfs-Vorbereitung (z.B. mkinitcpio-HOOK bei Arch).
    if declare -F tf_initramfs_prepare_plymouth >/dev/null 2>&1; then
        tf_initramfs_prepare_plymouth
    fi

    if plymouth-set-default-theme thinforge 2>/dev/null; then
        log "Plymouth theme 'thinforge' set."
    else
        warn "plymouth-set-default-theme failed."
    fi

    tf_ensure_kernel_splash
    TF_INITRAMFS_DIRTY=1
}

# 'splash' in der Kernel-Cmdline sicherstellen — sonst zeigt Plymouth nichts.
tf_ensure_kernel_splash() {
    local grub_def="${TF_GRUB_DEFAULT:-/etc/default/grub}"
    [ -f "$grub_def" ] || return 0
    if ! grep -qE '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_def"; then
        printf 'GRUB_CMDLINE_LINUX_DEFAULT="splash"\n' >> "$grub_def"
        log "Kernel cmdline created: splash"
        TF_GRUB_DIRTY=1
        return 0
    fi
    if grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$grub_def" | grep -qw splash; then
        return 0
    fi
    # 'splash' vor dem schliessenden Quote einfuegen — fuer doppelte UND einfache
    # Anführungszeichen (Distro-Profile nutzen mal das eine, mal das andere). Je
    # Zeile trifft nur einer der beiden Seds. [[:space:]] statt \s (POSIX-portabel).
    sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"[[:space:]]*$|\1 splash"|' "$grub_def"
    sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT='[^']*)'[[:space:]]*\$|\1 splash'|" "$grub_def"
    # evtl. entstandenes fuehrendes Leerzeichen nach dem oeffnenden Quote entfernen
    sed -i -E 's|^(GRUB_CMDLINE_LINUX_DEFAULT=")[[:space:]]+|\1|' "$grub_def"
    sed -i -E "s|^(GRUB_CMDLINE_LINUX_DEFAULT=')[[:space:]]+|\1|" "$grub_def"
    log "Kernel cmdline: 'splash' added."
    TF_GRUB_DIRTY=1
}

# 'plymouth' als HOOK in mkinitcpio.conf eintragen (nach 'systemd' bzw.
# 'udev'). Von den Arch-Familie-Wrappern via tf_initramfs_prepare_plymouth
# genutzt; Debian braucht das nicht (update-initramfs zieht das Theme selbst).
tf_mkinitcpio_add_plymouth_hook() {
    local f="${TF_MKINITCPIO:-/etc/mkinitcpio.conf}"
    [ -f "$f" ] || return 0
    if grep -qE '^HOOKS=.*\bplymouth\b' "$f"; then
        return 0
    fi
    # 'plymouth' nach dem systemd- bzw. udev-Hook einsetzen; sonst direkt nach
    # dem Opener. Bewusst NICHT auf '(' festgenagelt, damit sowohl die Array-Form
    # HOOKS=(...) als auch die String-Form HOOKS="..." korrekt getroffen werden.
    if grep -qE '^HOOKS=.*\bsystemd\b' "$f"; then
        sed -i -E "s/^(HOOKS=.*\\bsystemd\\b)/\\1 plymouth/" "$f"
    elif grep -qE '^HOOKS=.*\budev\b' "$f"; then
        sed -i -E "s/^(HOOKS=.*\\budev\\b)/\\1 plymouth/" "$f"
    else
        sed -i -E "s/^(HOOKS=[(\"']?)/\\1plymouth /" "$f"
    fi
    # Ehrliche Erfolgsmeldung: nur loggen wenn der Hook wirklich drinsteht.
    if grep -qE '^HOOKS=.*\bplymouth\b' "$f"; then
        log "mkinitcpio HOOK 'plymouth' added."
    else
        warn "mkinitcpio HOOKS format unexpected — 'plymouth' not added (boot splash may be inactive)."
    fi
}

# -- Display-Manager-Login-Hintergrund ---------------------------------------

tf_set_dm_background() {
    local img="$1"
    local did=0

    # LightDM (GTK-Greeter) — sauber unterstuetzt (XFCE/diverse).
    local lightdm_dir="${TF_LIGHTDM_DIR:-/etc/lightdm}"
    if [ -d "$lightdm_dir" ]; then
        local f="$lightdm_dir/lightdm-gtk-greeter.conf"
        if [ -f "$f" ] && grep -qE '^\[greeter\]' "$f"; then
            if grep -qE '^[#[:space:]]*background=' "$f"; then
                sed -i -E "s|^[#[:space:]]*background=.*|background=$img|" "$f"
            else
                sed -i "/^\[greeter\]/a background=$img" "$f"
            fi
        else
            printf '[greeter]\nbackground=%s\n' "$img" >> "$f"
        fi
        log "LightDM greeter background set."
        did=1
    fi

    # SDDM (KDE) — Breeze-Theme via theme.conf.user (best effort).
    if command -v sddm >/dev/null 2>&1 || [ -d /usr/share/sddm ]; then
        local btheme=/usr/share/sddm/themes/breeze
        if [ -d "$btheme" ]; then
            install -m0644 "$img" "$btheme/thinforge-bg.png" 2>/dev/null || true
            cat > "$btheme/theme.conf.user" <<SDDM
[General]
background=thinforge-bg.png
SDDM
            log "SDDM (Breeze) login background set."
            did=1
        else
            warn "SDDM without Breeze theme — login background skipped."
        fi
    fi

    # GDM (GNOME) — Login-Hintergrund ist versionsabhaengig gesperrt und nicht
    # zuverlaessig setzbar; der Desktop-Hintergrund wird trotzdem gesetzt.
    if command -v gdm >/dev/null 2>&1 || command -v gdm3 >/dev/null 2>&1; then
        warn "GDM detected — login background locked by GNOME, skipped."
    fi

    [ "$did" = 1 ] || warn "No matching display manager found for login background."
}

# -- Desktop-Hintergrund (alle Benutzer, via Login-Autostart) ----------------
#
# Statt fragiler Offline-Configs pro Desktop-Umgebung wird ein systemweiter
# Autostart-Eintrag installiert. Der laeuft beim Login JEDES Benutzers (auch
# kuenftiger), erkennt die laufende DE und setzt den Hintergrund in der
# Session — so sind echte Monitor-Namen und DBus-Session verfuegbar.

tf_install_wallpaper_autostart() {
    local helper=/usr/local/bin/thinforge-set-wallpaper.sh
    install -d -m0755 /usr/local/bin

    cat > "$helper" <<'HELP'
#!/bin/sh
# ThinForge — setzt das Desktop-Hintergrundbild fuer die aktuelle Session.
# Via /etc/xdg/autostart beim Login gestartet; erkennt die DE selbst.
WALL=/etc/thinforge/tf-wall.png
[ -f "$WALL" ] || exit 0

# Nur einmal pro Bild-Version setzen, damit eigene Aenderungen des Benutzers
# nicht bei jedem Login ueberschrieben werden.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/thinforge"
MARKER="$STATE_DIR/wallpaper-applied"
VER="$(stat -c %Y "$WALL" 2>/dev/null || echo 0)"
[ -f "$MARKER" ] && [ "$(cat "$MARKER" 2>/dev/null)" = "$VER" ] && exit 0

DESK="$(echo "${XDG_CURRENT_DESKTOP:-}" | tr '[:upper:]' '[:lower:]')"
ok=0
case "$DESK" in
  *xfce*)
    if command -v xfconf-query >/dev/null 2>&1; then
        # Monitor-Backdrop-Basispfade einsammeln: bestehende Properties (legacy
        # monitorN oder monitor<NAME>/workspaceN) UND die aktuell verbundenen
        # Monitore per xrandr. XFCE 4.18 keyt nach Connector-Name (z.B.
        # monitorVirtual-1/workspace0), das Property existiert evtl. noch nicht.
        bases=""
        for lp in $(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep -E '/(last-image|image-path)$'); do
            bases="$bases ${lp%/*}"
        done
        if command -v xrandr >/dev/null 2>&1; then
            for mon in $(xrandr 2>/dev/null | awk '/ connected/{print $1}'); do
                bases="$bases /backdrop/screen0/monitor${mon}/workspace0"
            done
        fi
        for base in $(printf '%s\n' $bases | sort -u); do
            # Der sichtbare Hintergrund haengt je nach xfdesktop-Version an
            # last-image ODER image-path ODER last-single-image — alle setzen
            # (nur last-image zu setzen reicht auf XFCE 4.18 NICHT).
            for prop in last-image image-path last-single-image; do
                xfconf-query -c xfce4-desktop -p "$base/$prop" -s "$WALL" 2>/dev/null \
                    || xfconf-query -c xfce4-desktop -p "$base/$prop" -n -t string -s "$WALL" 2>/dev/null
            done
            xfconf-query -c xfce4-desktop -p "$base/image-style" -s 5 2>/dev/null \
                || xfconf-query -c xfce4-desktop -p "$base/image-style" -n -t int -s 5 2>/dev/null
            xfconf-query -c xfce4-desktop -p "$base/image-show" -s true 2>/dev/null \
                || xfconf-query -c xfce4-desktop -p "$base/image-show" -n -t bool -s true 2>/dev/null
            ok=1
        done
        # Laufendes xfdesktop neu laden, damit die Aenderung sofort greift —
        # ohne Reload wird sie erst beim naechsten Login sichtbar.
        if [ "$ok" = 1 ] && command -v xfdesktop >/dev/null 2>&1; then
            xfdesktop --reload 2>/dev/null || true
        fi
    fi
    ;;
  *kde*|*plasma*)
    if command -v plasma-apply-wallpaperimage >/dev/null 2>&1; then
        plasma-apply-wallpaperimage "$WALL" 2>/dev/null && ok=1
    fi
    ;;
  *gnome*|*unity*|*ubuntu*)
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.background picture-uri "file://$WALL" 2>/dev/null && ok=1
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true
    fi
    ;;
  *cinnamon*)
    command -v gsettings >/dev/null 2>&1 \
        && gsettings set org.cinnamon.desktop.background picture-uri "file://$WALL" 2>/dev/null && ok=1
    ;;
  *mate*)
    command -v gsettings >/dev/null 2>&1 \
        && gsettings set org.mate.background picture-filename "$WALL" 2>/dev/null && ok=1
    ;;
  *lxqt*)
    command -v pcmanfm-qt >/dev/null 2>&1 \
        && pcmanfm-qt --set-wallpaper "$WALL" 2>/dev/null && ok=1
    ;;
  *)
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.background picture-uri "file://$WALL" 2>/dev/null && ok=1
    fi
    ;;
esac

if [ "$ok" = 1 ]; then
    mkdir -p "$STATE_DIR"
    echo "$VER" > "$MARKER"
fi
exit 0
HELP
    chmod 0755 "$helper"

    local desktop=/etc/xdg/autostart/thinforge-wallpaper.desktop
    install -d -m0755 /etc/xdg/autostart
    cat > "$desktop" <<'DESK'
[Desktop Entry]
Type=Application
Name=ThinForge Wallpaper
Comment=Sets the ThinForge wallpaper at login
Exec=/usr/local/bin/thinforge-set-wallpaper.sh
NoDisplay=true
X-GNOME-Autostart-enabled=true
DESK

    log "Desktop wallpaper autostart installed (applies to current + future users)."
}

# -- Orchestrierung ----------------------------------------------------------

tf_branding_main() {
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help) tf_usage; exit 0 ;;
            *) fatal "Unknown argument: $1 (see --help)" ;;
        esac
    done

    require_root

    : "${TF_SCRIPT_DIR:?TF_SCRIPT_DIR not set (wrapper error)}"
    : "${TF_DISTRO:?TF_DISTRO not set (wrapper error)}"
    for fn in tf_pkg_install_plymouth tf_grub_regen tf_initramfs_regen; do
        declare -F "$fn" >/dev/null 2>&1 || fatal "Wrapper function missing: $fn"
    done

    TF_GRUB_DIRTY=0
    TF_INITRAMFS_DIRTY=0

    echo ""
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  ThinForge Branding — ${TF_DISTRO}${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════${NC}"
    echo ""

    # 1) Bild finden + nach /etc/thinforge/ kopieren (einziger Ablageort).
    local src
    src="$(tf_locate_wall)" || fatal "tf-wall.png not found — place it on the Tools-ISO or set TF_WALL_FILE."
    install -d -m0755 /etc/thinforge
    if [ "$src" != "$TF_WALL_DEST" ]; then
        install -m0644 "$src" "$TF_WALL_DEST"
        log "Background image installed: $TF_WALL_DEST (source: $src)"
    else
        log "Background image already at destination: $TF_WALL_DEST"
    fi

    # 2) GRUB-Bootmenue
    tf_set_grub_background "$TF_WALL_DEST"
    # 3) Plymouth-Boot-Splash
    tf_set_plymouth "$TF_WALL_DEST"
    # 4) Login-Screen
    tf_set_dm_background "$TF_WALL_DEST"
    # 5) Desktop-Hintergrund (alle Benutzer)
    tf_install_wallpaper_autostart

    # 6) Nur regenerieren, wenn sich etwas geaendert hat.
    if [ "$TF_GRUB_DIRTY" = 1 ]; then
        log "Regenerating GRUB config..."
        tf_grub_regen || warn "GRUB regeneration failed."
    fi
    if [ "$TF_INITRAMFS_DIRTY" = 1 ]; then
        log "Rebuilding initramfs (Plymouth)..."
        tf_initramfs_regen || warn "initramfs rebuild failed."
    fi

    echo ""
    log "ThinForge branding complete."
}
