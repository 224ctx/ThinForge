# Written Offer for Source Code (GPL v2 §3(b) and GPL v3 §6(b))

**Valid for three (3) years from the date of distribution of the binary.**

This written offer satisfies Section 3(b) of the GNU General Public License, Version 2, and Section 6(b) of the GNU General Public License, Version 3.

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

This offer covers every GPL v2-licensed binary that ThinForge itself distributes as part of a release artifact (container images, installation media, or other binary packages signed / published by the ThinForge vendor). Concretely, that currently means:

- **Partclone** — shipped in the `docker/cloner` and `docker/bt-seeder` images
- **EZIO** — shipped in the `docker/bt-seeder` image

It also covers any GPL-covered package installed via Alpine `apk add` into a ThinForge-distributed image, should its upstream source become unavailable through https://pkgs.alpinelinux.org/packages or https://gitlab.alpinelinux.org/alpine/aports.

It does **not** cover Clonezilla Live (customer downloads from SourceForge directly, ThinForge is not the distributor) or DRBL (not shipped in any release artifact).

## Alternative: immediate access

Source code is already distributed with every release of ThinForge:

- Partclone: `sources/partclone-0.3.33.tar.gz` (pinned SHA-256 in [`sources/README.md`](sources/README.md))
- EZIO: `sources/ezio-snapshot.tar.gz` (pinned SHA-256 in [`sources/README.md`](sources/README.md))

It is also available from the authoritative upstream projects listed in [`THIRD_PARTY_LICENSES.md`](THIRD_PARTY_LICENSES.md). You do not need to invoke this written offer if those channels meet your needs.

---

*This offer is made pursuant to Section 3(b) of the GNU General Public License, Version 2, and Section 6(b) of the GNU General Public License, Version 3. Copies of both license texts are provided in [`LICENSES/GPL-2.0.txt`](LICENSES/GPL-2.0.txt) and [`LICENSES/GPL-3.0.txt`](LICENSES/GPL-3.0.txt).*
