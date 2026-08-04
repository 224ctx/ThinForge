# ThinForge Install Scripts — Quick Reference

## Prerequisites

- Cloning VM with Debian or Manjaro ISO as boot medium
- Tools ISO attached as second CD-ROM (appears automatically in file manager as THINFORGE_TOOLS)

## Workflow: Debian (recommended)

```
0. In the ThinForge UI Cloning-VM card -> click "Create base HD",
   enter desired sizes, apply. The qcow2 is now prepared with
   ESP + System (btrfs/@root) + Data (btrfs/@data).
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
| GRUB | 5s timeout, snapshot menu visible |
| grub-btrfs | Snapshots as boot entries |
| Home mount generator | Automatic @home swap on rollback |
| Data partition | ~5 GB at end of disk |
| Packages | nfs-common, zstd, curl, jq, wireguard-tools, python3, ffmpeg, xdotool, minisign |
| SSH | Key-only auth, root via key |
| Agent | ThinForge agent + delta update service |
| System update | apt-get dist-upgrade + cache cleanup |

---

## Workflow: Debian Minimal (netinst, no live system)

For `debian-13.4.0-amd64-netinst.iso` — no live system, no Calamares, just
the classic Debian installer (d-i). Suitable for slim installs without a
desktop environment and for setups where a netinst ISO is already on hand.

```
0. In the ThinForge UI Cloning-VM card -> click "Create base HD",
   enter desired sizes, apply. The qcow2 is now prepared with
   ESP + System (btrfs/@root) + Data (btrfs/@data).
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

Identical to `install-debian.sh finish` — see table above.

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
| GRUB | 5s timeout, snapshot menu visible |
| grub-btrfs | Snapshots as boot entries |
| Home mount generator | Automatic @home swap on rollback |
| Data partition | ~5 GB at end of disk |
| Packages | nfs-utils, zstd, curl, jq, wireguard-tools, python, ffmpeg, xdotool |
| SSH | Key-only auth, root via key |
| Agent | ThinForge agent + delta update service |
| System update | pacman -Syu + cache cleanup |

---

## Option --server

```bash
sudo bash install-debian.sh finish --server=https://thinforge.example.com
sudo bash install-manjaro.sh finish --server=https://thinforge.example.com
```

Sets the server URL if no `server_url` file is present on the ISO.

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
└── advanced/
    ├── 1-create-client-management.sh
    ├── create-data-partition.sh
    ├── agent-home-mount-generator
    ├── thinforge-agent.py
    ├── server_url
    ├── server.crt
    ├── provisioning_key.pub
    └── heartbeat_token
```
