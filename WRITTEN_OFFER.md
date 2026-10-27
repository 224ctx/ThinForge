# Written Offer for Source Code (GPL v2 §3(b), GPL v3 §6(b) and AGPL v3 §13)

**Valid for three (3) years from the date of distribution of the binary.**

This written offer satisfies Section 3(b) of the GNU General Public License, Version 2, and Section 6(b) of the GNU General Public License, Version 3. It extends equally to the LGPL-licensed packages in ThinForge's container images. A voluntary source statement regarding Section 13 of the GNU Affero General Public License, Version 3 — covering the NetBird stack behind the hosted ThinVPN service — is at the end of this document.

## Offer

For any binary distribution of ThinForge that includes GPL v2- or GPL v3-licensed software, the copyright holder offers — for a period of at least **three years from the date you received the binary** — to provide, to any third party, a complete machine-readable copy of the corresponding source code of each GPL-licensed component, on a medium customarily used for software interchange, for a charge no more than the cost of physically performing source distribution.

## How to request source

Send a written request containing:

1. The name and version of the ThinForge release from which you wish to receive source (e.g. visible in `/about`, `VERSION` file, or the Git tag of the Release repository).
2. The specific GPL component(s) you are requesting (Partclone, EZIO, any GPL package installed in our distributed container images, or "all").
3. Your shipping address (for physical medium) or an email address (if you accept electronic delivery at no cost).
4. Your preferred medium (USB stick, DVD, or electronic download — whichever is mutually convenient).

Requests may be sent to:

> **Andreas Christ**
> Email: info@thinforge.org
> Subject line: `GPL Source Request — ThinForge <version>`

## Cost

- **Electronic delivery** (via download link or attached archive): **no charge**.
- **Physical medium** (USB / DVD): at cost of medium + shipping; an invoice will be provided before dispatch.

## Scope of source delivered

For each requested component, the delivered archive contains the exact source code used to build the binary shipped in that ThinForge release, corresponding to the list in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md). This includes:

- All source files
- Build scripts and configuration
- Any modifications (none at time of writing; any future modifications will be disclosed)
- The full GPL v2 license text

## Scope

This offer covers every GPL- or LGPL-licensed binary that ThinForge itself distributes as part of a release artifact (container images, installation media, or other binary packages signed / published by the ThinForge vendor). That comprises two groups.

**1. Components ThinForge builds or bundles itself** — their corresponding source is also shipped in `sources/` (see "Alternative: immediate access" below):

- **Partclone** — shipped in the `docker/cloner` and `docker/bt-seeder` images
- **EZIO** — shipped in the `docker/bt-seeder` image

**2. Alpine Linux packages inside the distributed container images.** All ten images ThinForge publishes are built on Alpine Linux: nine — `backend`, `worker`, `cloner`, `cloning-vm`, `bt-seeder`, `multicast-sender`, `dnsmasq`, `nfs-server` and `chrony` — on Alpine 3.24, and `frontend` (since 2026-10-26) on the official `caddy:2-alpine` image, at present Alpine 3.23. The packages installed there via `apk add`, and those the Alpine base layer already brings, are distributed by ThinForge as binaries inside the image. They are unmodified Alpine packages; this offer covers every one of them whose license is a GPL or an LGPL, **without condition** — the public Alpine channels named below are a convenience, not a prerequisite. (`frontend` names no package in its Dockerfile; its Alpine packages, `busybox` and `apk-tools` among them, come with the `caddy:2-alpine` base image. Until 2026-10-26 it was built on a distroless image without Alpine packages.)

GPL- and LGPL-licensed packages installed by name in ThinForge's Dockerfiles (`docker/<image>/Dockerfile`; `backend` and `worker` share `docker/backend/Dockerfile.rust`):

| Image | Packages named in the Dockerfile |
|-------|----------------------------------|
| `cloner` | `partclone`, `util-linux`, `btrfs-progs`, `gptfdisk` / `sgdisk`, `parted`, `dosfstools`, `ntfs-3g`, `qemu-img`, `kmod`, `bash`, `coreutils` |
| `bt-seeder` | `partclone`, `procps-ng`, `bash` |
| `multicast-sender` | `udpcast`, `bash` |
| `dnsmasq` | `dnsmasq`, `syslinux`, `grub`, `grub-efi`, `wget` |
| `cloning-vm` | `qemu-system-x86_64`, `qemu-img`, `qemu-hw-display-virtio-vga`, `qemu-hw-display-virtio-gpu-pci`, `cdrkit`, `websockify` (LGPL), `bash`, `coreutils` |
| `nfs-server` | `nfs-utils` |
| `chrony` | `chrony` |
| `backend`, `worker` | `iproute2`, `iputils`, `cdrkit`, `p7zip` (LGPL; installed as `7zip`) |

Every Alpine-based image additionally carries the GPL packages of the base layer (`busybox`, `apk-tools`, `alpine-baselayout`, …) and GPL or LGPL libraries pulled in as dependencies (for example `readline`, `libgcc` / `libstdc++`, `libblkid` / `libmount`, `xz-libs`). The authoritative, version-exact list for a given image is the output of `apk list --installed` inside it — each line names the package, its version and its license; this offer covers every entry whose license names a GPL or an LGPL.

For such a package, the corresponding source is the Alpine `aports` build recipe for exactly the installed package version — the `APKBUILD`, every patch it applies, and the upstream release archive it references — as published at https://pkgs.alpinelinux.org/packages and https://gitlab.alpinelinux.org/alpine/aports.

It does **not** cover Clonezilla Live (customer downloads from SourceForge directly, ThinForge is not the distributor) or DRBL (not shipped in any release artifact).

## Alternative: immediate access

Source code is already distributed with every release of ThinForge:

- Partclone: `sources/partclone-0.3.47.tar.gz` (pinned SHA-256 in [`sources/README.md`](sources/README.md))
- EZIO: `sources/ezio-2.0.30.tar.gz` (pinned SHA-256 in [`sources/README.md`](sources/README.md))

For earlier releases the corresponding source is also in `sources/`:
`partclone-0.3.40-r0-alpine3.23.tar.gz` (releases v2026.07.19 – v2026.07.21) and
`ezio-v2.0.23-11-g4414248.tar.gz` (every EZIO-bearing image before 2026-08-25).
[`sources/README.md`](sources/README.md) maps each file to the releases it
belongs to. This offer covers whichever of them matches the release you
received.

It is also available from the authoritative upstream projects listed in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md). You do not need to invoke this written offer if those channels meet your needs.

## AGPLv3 §13 — Hosted ThinVPN Service (NetBird)

The hosted ThinVPN service is built on **NetBird**. Its **server variant** — management, signal, relay and dashboard — is licensed **AGPL-3.0-or-later** and runs on an instance we operate; the NetBird **client**, which runs as a container inside each ThinForge stack, is BSD-3-Clause. ThinForge distributes neither (see [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md)).

**When §13 applies.** Section 13 of the AGPL v3 binds an operator only *if the operator modifies the Program*: "if you modify the Program, your modified version must prominently offer all users interacting with it remotely through a computer network … an opportunity to receive the Corresponding Source of your version". We operate NetBird from the **official upstream container images, unmodified**, and interact with it solely through its documented APIs — so no §13 obligation currently attaches. We name the source anyway — the statement below is voluntary, and it becomes binding the moment anything in the operated stack is patched.

**Source.** The Corresponding Source of the operated instance is, in full:

> https://github.com/netbirdio/netbird — server components, at the tag matching the running version, which we name on request
>
> https://github.com/netbirdio/dashboard — dashboard, likewise

Should the operated stack ever be modified (patched server components, altered dashboard, custom relay build), §13 attaches: the modified Corresponding Source will then be published under AGPL-3.0-or-later, linked here, and made available from a network server at no charge.

Requests may be sent to **info@thinforge.org**, subject line `AGPL Source Request — ThinVPN`.

Unlike the GPL offer above, this statement carries no three-year limit: it stands for as long as we operate the instance.

---

*This offer is made pursuant to Section 3(b) of the GNU General Public License, Version 2, and Section 6(b) of the GNU General Public License, Version 3; the AGPL v3 §13 statement above stands voluntarily for as long as the operated NetBird stack remains unmodified. Copies of the GPL texts are provided in [`LICENSES/GPL-2.0.txt`](LICENSES/GPL-2.0.txt) and [`LICENSES/GPL-3.0.txt`](LICENSES/GPL-3.0.txt); the AGPL v3 text is at https://www.gnu.org/licenses/agpl-3.0.html.*
