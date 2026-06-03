# Partclone

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Thomas Tsai and Partclone contributors
- **Upstream:** https://partclone.org/ · https://github.com/Thomas-Tsai/partclone
- **Version distributed in ThinForge containers:** 0.3.33 (Alpine 3.22 `community/partclone` package, unmodified)
- **Corresponding source shipped in releases:** `sources/partclone-0.3.33.tar.gz` — this is the version actually installed into our distributed images, fetched from upstream
- **Optional developer-reference snapshot:** `buildsources/partclone/` contains an older unmodified upstream tree (0.3.47). It is a developer reference only and is **not** the source that corresponds to any distributed binary. 0.3.33 is the only version ever installed into a distributed image.
- **Alpine aports source:** https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/partclone

## How ThinForge uses Partclone

Partclone is invoked **exclusively as an external binary** (subprocess) from shell scripts and from Rust via `std::process::Command`. ThinForge does **not** link against any Partclone library, does not share address space with Partclone, and does not include Partclone code in the Rust binary.

Invocation sites:
- `docker/cloner/clone.sh` — `partclone.<fstype> -c -F -B --prog-second …` during image capture
- `docker/bt-seeder/extract_clone.sh` — `partclone.dd` / `partclone.<fstype>` during BitTorrent image preparation
- `crates/thinforge-services/src/pxe_service.rs` — generates PXE restore scripts calling `partclone.restore`
- `crates/thinforge-services/src/delta_runner.rs` — generates delta-restore scripts calling `partclone.btrfs`

## Compliance status

- Unmodified upstream binary from Alpine community repository — source is publicly available via Alpine aports.
- Full GPL v2 text shipped in this directory and preserved in `buildsources/partclone/COPYING`.
- No Partclone modifications by ThinForge.

## Source offer

Corresponding source code for Partclone 0.3.33 is distributed with every ThinForge release as:

- `sources/partclone-0.3.33.tar.gz` (fetched from upstream at release time; SHA-256 pinned in [`sources/README.md`](../sources/README.md))

It is additionally available from:

1. Upstream release: https://github.com/Thomas-Tsai/partclone/releases/tag/0.3.33
2. Alpine aports (the exact build recipe used in our containers): https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/partclone
3. On written request per [`WRITTEN_OFFER.md`](../WRITTEN_OFFER.md).
