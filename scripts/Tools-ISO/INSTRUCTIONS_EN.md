# ThinForge Install Scripts — Quick Reference

## Prerequisites

- Cloning VM with Debian or Manjaro ISO as boot medium
- Tools ISO attached as second CD-ROM (appears automatically in file manager as THINFORGE_TOOLS)

## Workflow: Debian (recommended)

```
0. In the ThinForge UI Cloning-VM card -> click "Create base HD",
   enter desired sizes, apply. The qcow2 is now prepared with
   ESP + System (btrfs, no subvolumes yet) + Data (btrfs/@data).
1. Boot from Debian Live ISO (XFCE)
2. Navigate to THINFORGE_TOOLS in file manager, open terminal
3. Prepare:    sudo bash install-debian.sh prepare /dev/vda
4. Start Debian installer (Calamares), select Manual partitioning,
   assign partition 2 to / with mount option subvol=@root
5. Reboot into the new system
6. Navigate to THINFORGE_TOOLS in file manager, open terminal
7. Finalize:   sudo bash install-debian.sh finish
```

### prepare

Configures Calamares for the layout created via UI in step 0:
- Creates/modifies mount.conf: root subvolume set to `@root` (required for delta updates)
- Creates partition.conf: btrfs as default filesystem

The disk layout itself is no longer verified — the UI is the single source of
truth and Calamares will complain itself if the partitions don't match.

### finish

Configures the installed system:

| Step | Description |
|------|-------------|
| GRUB | 2s timeout, snapshot menu visible |
| grub-btrfs | Snapshots as boot entries |
| Data partition | Adds partition 3 from step 0 (label "Daten") to fstab and mounts it as `/data` (subvolume `@data`); if it is missing, `finish` aborts before installing the agent |
| Packages | nfs-common, zstd, curl, jq, python3, x11-utils, minisign, chrony, zenity, yad |
| NetBird agent | VPN client via the official installer (`pkgs.netbird.io/install.sh`); service reconfigured to force relay and disable IPv6, then disabled and stopped (it is only enabled once ThinForge activates the device for the VPN); `/etc/netbird` and `/var/lib/netbird` point to `/data/netbird` so the enrollment survives delta updates |
| SSH | Key-only auth, root via key |
| Agent | ThinForge agent + delta update service. The agent binary is first checked with `minisign` against its signature and the server's signing key; if it does not match, `finish` aborts (see below) |
| Branding | tf-wall.png → `/etc/thinforge/`, set as desktop background, GRUB/Plymouth boot splash and login background (non-fatal) |
| System update | apt-get dist-upgrade + cache cleanup |

---

## Workflow: Debian Minimal (netinst, no live system)

For `debian-13.4.0-amd64-netinst.iso` — no live system, no Calamares, just
the classic Debian installer (d-i). Suitable for slim installs without a
desktop environment and for setups where a netinst ISO is already on hand.

```
0. In the ThinForge UI Cloning-VM card -> click "Create base HD",
   enter desired sizes, apply. The qcow2 is now prepared with
   ESP + System (btrfs, no subvolumes yet) + Data (btrfs/@data).
1. Boot the VM with the netinst ISO, regular d-i (no rescue needed)
2. In d-i: "Manually edit partitions":
     Partition 1 -> /boot/efi   (keep FAT32, do NOT reformat)
     Partition 2 -> /            (keep btrfs, do NOT reformat,
                                  set mount option subvol=@root)
     Partition 3 -> do NOT use (reserved for /data)
3. Tasksel: only "standard system utilities" (minimal)
4. Run installation, boot into the new system
5. Mount the Tools-ISO and finish:
     sudo mkdir -p /mnt/tools && sudo mount /dev/sr1 /mnt/tools
     sudo bash /mnt/tools/install-debian-minimal.sh finish
```

**Tools-ISO path after booting the installed system:** the ThinForge
cloning VM always attaches the Tools-ISO as the second CD-ROM — it is
guaranteed to be reachable as `/dev/sr1` (volume label `THINFORGE_TOOLS`).
A regular Debian desktop will auto-mount it under
`/media/thinforge/THINFORGE_TOOLS` (or similar). From a TTY or without
auto-mount, mount manually: `mount /dev/sr1 /mnt/tools`.
`/dev/sr0` is the install medium and should not be touched.

### finish

Same as `install-debian.sh finish` — see table above. In addition, at the start
you select the local users who get sudo rights (the first of them gets LightDM
autologin without screen lock), and unneeded preinstalled programs are removed
(`DistroTweaks/cleanup-debian.sh`). At the end the script offers to install the
VDI clients (`DebianVDIClients/install-vdi-clients-debian.sh`). When started via
`su` instead of `sudo`, it sets up sudo for the calling account and restarts
itself through it.

`install-debian-minimal.sh` has no `prepare` step: the layout is created in
step 0 via the UI and the netinst-d-i uses it directly — no Calamares
intermediate step needed like in the Live-ISO variant.

---

## Workflow: Manjaro (alternative)

```
0. In the ThinForge UI Cloning-VM card -> click "Create base HD",
   enter desired sizes, apply.
1. Boot from Manjaro Live ISO
2. Navigate to THINFORGE_TOOLS in file manager, open terminal
3. Prepare:    sudo bash install-manjaro.sh prepare
4. Start Calamares, select Manual partitioning, assign partition 2
   to / with mount option subvol=@root
5. Reboot into the new system
6. Navigate to THINFORGE_TOOLS in file manager, open terminal
7. Finalize:   sudo bash install-manjaro.sh finish
```

> The same workflow applies to `install-arch.sh` and `install-cachyos.sh`.

### prepare

Adjusts Calamares for the layout created via UI in step 0:
- Changes root subvolume from `@` to `@root` (required for delta updates)

The disk layout itself is no longer verified — the UI is the single source of
truth and Calamares will complain itself if the partitions don't match.

### finish

| Step | Description |
|------|-------------|
| GRUB | 2s timeout, snapshot menu visible |
| grub-btrfs | Snapshots as boot entries |
| Data partition | `advanced/create-data-partition.sh`: mounts partition 3 from step 0 as `/data` (subvolume `@data`) and adds it to fstab, or creates it from the free space at the end of the disk if it is missing; without `/data`, `finish` aborts |
| Packages | nfs-utils, zstd, curl, jq, python, xorg-xdpyinfo, minisign, zenity, yad |
| NetBird agent | as on Debian: official installer, force relay and IPv6 off, service disabled and stopped, state under `/data/netbird` |
| SSH | Key-only auth, root via key |
| Agent | ThinForge agent + delta update service. The agent binary is first checked with `minisign` against its signature and the server's signing key; if it does not match, `finish` aborts (see below) |
| Branding | tf-wall.png → `/etc/thinforge/`, set as desktop background, GRUB/Plymouth boot splash and login background (non-fatal) |
| System update | pacman -Syu + cache cleanup |

---

## Branding (wallpaper + boot splash)

At the end, `finish` automatically calls the matching `DistroTweaks/install-branding-<distro>.sh`.
It copies `tf-wall.png` (located in the ISO root) to `/etc/thinforge/tf-wall.png`
and sets it as:

- **Desktop background** — for current and future users, via a system-wide
  login autostart (`/etc/xdg/autostart/thinforge-wallpaper.desktop`) that
  detects the running desktop environment itself (XFCE/KDE/GNOME/Cinnamon/MATE/LXQt).
- **GRUB boot menu background**, **Plymouth boot splash** and **login screen**
  (LightDM/SDDM).

The step is non-fatal — if it fails, `finish` continues normally.
It can also be run on its own later: `sudo bash DistroTweaks/install-branding-<distro>.sh`
(image can be overridden via `TF_WALL_FILE=`).

---

## Option --server

```bash
sudo bash install-debian.sh finish --server=https://thinforge.example.com
sudo bash install-manjaro.sh finish --server=https://thinforge.example.com
```

Only sets the VM's NTP server (Debian: chrony, Manjaro/Arch/CachyOS:
systemd-timesyncd) and takes precedence over the host from `advanced/server_url`.
The agent's server URL always comes from `advanced/server_url` on the ISO; if
the file is missing, the agent installation aborts.

## Agent signature

`advanced/1-create-client-management.sh` (called by `finish`) only installs the
agent if `thinforge-agent` matches `thinforge-agent.minisig` and the server's
signing key that was installed just before (`minisign -V`). If `minisign` is
missing, the script installs it via apt/dnf/pacman — the VM then needs access
to the package repositories; the `install-*.sh` scripts include it in their
package list anyway. If the script reports `signature check of the agent binary
FAILED` or `thinforge-agent.minisig is missing`: on the server, build or sign
the binary under Clients → Agent ("Sign" or "Re-sign"), restart the VM (the
server rebuilds the Tools ISO on start), mount the ISO again and run `finish`
again.

## ISO Structure

```
THINFORGE_TOOLS/
├── install-debian.sh
├── install-debian-minimal.sh
├── install-manjaro.sh
├── install-arch.sh
├── install-cachyos.sh
├── ANLEITUNG_DE.md
├── INSTRUCTIONS_EN.md
├── tf-wall.png
├── DistroTweaks/
│   ├── branding-common.sh
│   ├── cleanup-debian.sh
│   ├── install-branding-debian.sh
│   ├── install-branding-debian-minimal.sh
│   ├── install-branding-arch.sh
│   ├── install-branding-cachyos.sh
│   └── install-branding-manjaro.sh
├── DebianVDIClients/
│   ├── install-vdi-clients-debian.sh
│   ├── README.md
│   ├── urls.conf.example
│   └── (uploaded VDI client packages)
└── advanced/
    ├── 1-create-client-management.sh
    ├── agent-apply-update.service
    ├── Agent-Check.sh
    ├── agent-migrate.sh
    ├── create-data-partition.sh
    ├── enable-ssh.sh
    ├── manual-manage-snapshots.sh
    ├── provision-remote-desktop.sh
    │   (the server generates the following files when building the ISO)
    ├── thinforge-agent            agent binary from agent-go/bin/
    ├── thinforge-agent.minisig    its signature (required)
    ├── thinforge.pub              the server's signing key
    ├── agent-version              version string, if known
    ├── server_url
    ├── server.crt
    ├── provisioning_key.pub
    └── heartbeat_token
```

Without a built, signed agent binary the server builds no Tools ISO; the
cloning VM then does not start, and the message names the missing step.
