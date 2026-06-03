# Third-Party Licenses — ThinForge

This document summarises the Free / Open Source Software (FOSS) components distributed with ThinForge, their licenses, and how to obtain the corresponding source code.

> **Summary:** ThinForge is a commercial product. Its proprietary components (Rust backend, Go agent, TypeScript frontend) are distributed under the license in [`LICENSE`](LICENSE). ThinForge also ships unmodified third-party components licensed under the GNU General Public License, Version 2 (GPL v2). These GPL-licensed components remain under GPL v2 and are interacted with exclusively through process boundaries, not linking.

## GPL v2 Components ThinForge Actually Distributes

The following components are **built into container images that ThinForge pushes to its registry** and are therefore distributed by the ThinForge vendor. Their corresponding source is shipped in [`sources/`](sources/).

| # | Component | Version | Where distributed | Source | Details |
|---|-----------|---------|-------------------|--------|---------|
| 1 | **Partclone** | 0.3.33 (Alpine community pkg) | images: `docker/cloner`, `docker/bt-seeder` | [`sources/partclone-0.3.33.tar.gz`](sources/partclone-0.3.33.tar.gz) | [`LICENSES/Partclone.md`](LICENSES/Partclone.md) |
| 2 | **EZIO** | snapshot in `quellinfos/ezio/` | image: `docker/bt-seeder` | [`sources/ezio-snapshot.tar.gz`](sources/ezio-snapshot.tar.gz) | [`LICENSES/EZIO.md`](LICENSES/EZIO.md) |

Canonical license texts: [`LICENSES/GPL-2.0.txt`](LICENSES/GPL-2.0.txt), [`LICENSES/GPL-3.0.txt`](LICENSES/GPL-3.0.txt).

## GPL v2 Components ThinForge References But Does Not Distribute

The following components are **orchestrated** by ThinForge but their binaries are never built into ThinForge's own release artifacts. They are downloaded from upstream or referenced for documentation only; GPL v2 §3 source-with-binary obligations do not apply to ThinForge for these.

| Component | Why not distributed | Upstream | Details |
|-----------|--------------------|-----------| --------|
| **Clonezilla Live** | Downloaded on-demand by the customer from SourceForge via the ThinForge UI; ThinForge is a downloader, not a distributor. The ISO bundles its own source. ThinForge does not repackage or modify the downloaded ISO before serving its contents — it only extracts the already-GPL-compliant boot files into TFTP. | https://clonezilla.org/ | [`LICENSES/Clonezilla.md`](LICENSES/Clonezilla.md) |
| **DRBL** | Not installed in any ThinForge image. Developer reference only. | https://drbl.org/ | [`LICENSES/DRBL.md`](LICENSES/DRBL.md) |

## How ThinForge Interacts with GPL Components

| Component | Interaction | Linking? | Address-space shared? |
|-----------|-------------|----------|-----------------------|
| Partclone | invoked as external binary (`partclone.<fstype>`) from shell scripts and from Rust via `std::process::Command` | no | no |
| Clonezilla | runs as independent operating system, PXE-booted on client hardware | no | no |
| EZIO | runs as separate daemon, addressed via gRPC over network socket | no | no |

This separation means the GPL "derivative work" conditions of §2 do not extend to ThinForge's proprietary code, under the FSF interpretation and commonly-applied case law.

## Modifications

ThinForge ships every GPL component unmodified. If that changes in any future release, the modifications will be made available under GPL v2 in this repository.

## Corresponding Source Code

For every GPL v2 component **distributed by ThinForge** (Partclone, EZIO):

1. **Shipped in every release:** [`sources/`](sources/) contains the exact corresponding source tarball with a pinned SHA-256 — see [`sources/README.md`](sources/README.md).
2. **In the source repository:** EZIO additionally lives under `quellinfos/ezio/` (since it is built from there).
3. **From upstream:**
   - Partclone: https://github.com/Thomas-Tsai/partclone and https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/partclone
   - EZIO: https://github.com/tjjh89017/ezio
4. **On written request:** See [`WRITTEN_OFFER.md`](WRITTEN_OFFER.md) for the three-year written offer under GPL v2 §3(b).

For GPL v2 components **merely referenced but not distributed** by ThinForge (Clonezilla, DRBL), no source tarball is shipped by ThinForge; source is available from upstream as noted above.

## Additional FOSS Components via Base Images

The ThinForge container images are built on Alpine Linux 3.22 base images. Those base images include additional FOSS packages — kernel utilities, shell, libc (musl), OpenSSL, curl, and others — distributed under GPL v2, GPL v3, LGPL, MIT, BSD, Apache, or similar licenses.

For every such package installed via `apk add` in the Dockerfiles under `docker/`, corresponding source code and license is available via the Alpine package archive:

- https://pkgs.alpinelinux.org/packages — find any `apk info`-listed package
- https://gitlab.alpinelinux.org/alpine/aports — the build recipe + `source` tarball URL per package

This written notice, together with the authoritative upstream channels above, serves as the source offer for those additional FOSS packages. The written offer in [`WRITTEN_OFFER.md`](WRITTEN_OFFER.md) likewise extends to any GPL-covered package installed into a ThinForge-distributed image, should upstream sources become unavailable.

The table below lists every non-trivially-licensed package currently installed in any ThinForge-distributed image. **This list is non-exhaustive — the authoritative inventory for any released image is the output of `apk info -v` inside that image.**

| Package | License | Role | In image(s) |
|---------|---------|------|-------------|
| `partclone` | GPL v2 | filesystem image save/restore | cloner, bt-seeder |
| `udpcast` | GPL v2 | UDP multicast | multicast-sender |
| `dnsmasq` | GPL v2 | DHCP/TFTP | dnsmasq |
| `syslinux` | GPL v2 | PXE boot loader | dnsmasq |
| `grub` / `grub-efi` | GPL v3 | BIOS + UEFI boot loader | dnsmasq |
| `btrfs-progs` | GPL v2 | btrfs tooling | cloner |
| `ntfs-3g` | GPL v2 | NTFS filesystem | cloner |
| `gptfdisk` / `sgdisk` | GPL v2 | GPT partitioning | cloner |
| `util-linux` | GPL v2 + LGPL | disk / partition utilities | cloner |
| `parted` | GPL v3 | partition editor | cloner |
| `dosfstools` | GPL v3 | FAT filesystem tools | cloner |
| `kmod` | LGPL | module loading | cloner |
| `coreutils` | GPL v3 | GNU core utilities | cloner, cloning-vm |
| `qemu-system-x86_64` / `qemu-img` | GPL v2 | full system + disk-image emulation | cloning-vm, cloner |
| `qemu-hw-display-virtio-*` | GPL v2 | QEMU display devices | cloning-vm |
| `procps-ng` | GPL v2 + LGPL | process utilities | bt-seeder |
| `bash` | GPL v3 | shell | cloner, bt-seeder, multicast-sender, cloning-vm |
| `jq` | MIT | JSON tool | multicast-sender, cloning-vm |
| `curl` | curl license (MIT-like) | HTTP client | multicast-sender, bt-seeder |
| `zstd` | BSD + GPL v2 (dual) | compression | cloner, bt-seeder |
| `ovmf` | BSD-2-Clause-Patent | UEFI firmware | cloner, cloning-vm |
| `opentracker` | Beerware | BitTorrent tracker | bt-seeder |
| `libtorrent-rasterbar` | BSD-3-Clause | BitTorrent library | bt-seeder |
| `ca-certificates` | MPL-2.0 | root CA bundle | various |
| `cdrkit` (`genisoimage`) | GPL v2 | ISO creation | cloning-vm |
| `websockify` | LGPL v3 | WebSocket↔TCP bridge | cloning-vm |
| `wget` | GPL v3 | HTTP(S) client | dnsmasq |
| `py3-libtorrent-rasterbar` | BSD-3-Clause | Python BitTorrent binding | bt-seeder |

None of these are linked into the proprietary ThinForge binaries; all are invoked as separate processes or used via their own daemons.

## License Files Bundled With the Release

Each distribution of ThinForge (source repository, Release repository, container images, installation media) includes:

- `LICENSE` — ThinForge's own license (proprietary, with explicit carve-outs listing the GPL components above).
- `NOTICE` — short notice of bundled FOSS.
- `THIRD_PARTY_LICENSES.md` — this file.
- `LICENSES/` — directory containing `GPL-2.0.txt` and per-component metadata.
- `WRITTEN_OFFER.md` — written offer for source code per GPL v2 §3(b).
- `sources/` — corresponding source tarballs for every GPL binary ThinForge distributes (with pinned SHA-256).

## Contact

- **Copyright holder (proprietary parts):** Andreas Christ (info@thinforge.org)
- **License inquiries and source requests:** info@thinforge.org
- **Project repository:** https://git.example.com/thinforge/ThinForge

---

*This document is a compliance statement, not a license. The licenses themselves are the authoritative legal instruments — see [`LICENSE`](LICENSE) and [`LICENSES/GPL-2.0.txt`](LICENSES/GPL-2.0.txt).*
