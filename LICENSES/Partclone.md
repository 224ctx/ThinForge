# Partclone

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Thomas Tsai and Partclone contributors
- **Upstream:** https://partclone.org/ · https://github.com/Thomas-Tsai/partclone
- **Version distributed in ThinForge containers:** 0.3.47-r0 (Alpine 3.24 `community/partclone` package, unmodified). Verify with `docker run --rm --entrypoint sh <image> -c 'apk list --installed | grep partclone'`.
- **Corresponding source shipped in releases:** `sources/partclone-0.3.47.tar.gz`
- **Superseded:** [`sources/partclone-0.3.40-r0-alpine3.23.tar.gz`](../sources/partclone-0.3.40-r0-alpine3.23.tar.gz) is the corresponding source for releases `v2026.07.19` … `v2026.07.21`, which ran on Alpine 3.23 with partclone **0.3.40-r0**. It contains the upstream 0.3.40 tree **plus the five aports patches** Alpine applies (`byteswap`, `gcc14`, `musl`, `remove-usage-of-off64_t`, `very-funny-glibc-types`) and the `APKBUILD` that drives them — the plain upstream tarball would not be complete corresponding source for that build.
- `sources/partclone-0.3.33.tar.gz` is retained, but **no registry release was found that shipped 0.3.33**: the registry starts at `v2026.07.19`, which already carried 0.3.40. Kept in case a pre-registry artefact was handed out.
- **Developer checkout:** `buildsources/partclone/` is an unmodified upstream tree, currently at tag 0.3.47 — the same release the distributed package is built from. It is gitignored and local-only.

> **Corrected 2026-08-25.** This file previously stated that 0.3.33 was *"the only version ever installed into a distributed image"* and described the 0.3.47 checkout as *"older"*. Checking the published images disproved both: they carry 0.3.47-r0 today and carried 0.3.40-r0 in July, while 0.3.33 appears in no registry release at all. The package version follows the Alpine base (3.22 → 3.23 → 3.24) and moved twice without the tarball here following. Read the version off the **image**, never off a decision recorded in a document:
> `docker run --rm --entrypoint sh <image> -c 'apk list --installed | grep partclone'`
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

Corresponding source code for Partclone 0.3.47 is distributed with every ThinForge release as:

| Distributed images | Corresponding source |
|---|---|
| `v2026.07.22` onwards (Alpine 3.24, partclone 0.3.47-r0) | [`sources/partclone-0.3.47.tar.gz`](../sources/partclone-0.3.47.tar.gz) — upstream tree; Alpine applies no patches to this version |
| `v2026.07.19` … `v2026.07.21` (Alpine 3.23, partclone 0.3.40-r0) | [`sources/partclone-0.3.40-r0-alpine3.23.tar.gz`](../sources/partclone-0.3.40-r0-alpine3.23.tar.gz) — upstream tree **plus** the five aports patches and the APKBUILD |

SHA-256 for both pinned in [`sources/README.md`](../sources/README.md).

It is additionally available from:

1. Upstream release: https://github.com/Thomas-Tsai/partclone/releases/tag/0.3.47
2. Alpine aports (the exact build recipe used in our containers): https://gitlab.alpinelinux.org/alpine/aports/-/tree/master/community/partclone
3. On written request per [`WRITTEN_OFFER.md`](../WRITTEN_OFFER.md).
