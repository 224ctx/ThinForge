# EZIO

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Ceng-Wei Jang (tjjh89017) and EZIO contributors
- **Upstream:** https://github.com/tjjh89017/ezio
- **Version distributed with ThinForge:** **v2.0.30** (upstream release tag, 2026-08-27), compiled into `docker/bt-seeder`. Read it off a running image with
  `docker run --rm --entrypoint sh <image> -c 'cat /usr/local/share/ezio-version'`.
- **Not carried in this repository.** ThinForge changes nothing about the EZIO source, so the repository references the original project rather than copying it: `docker/bt-seeder/Dockerfile` (Stage 1) clones the pinned tag — `ARG EZIO_VERSION` — from upstream at build time.
- **Corresponding source per GPL v2 §3(a):** [`sources/ezio-2.0.30.tar.gz`](../sources/ezio-2.0.30.tar.gz), a regular file in this repository, produced with `git archive` from the same tag the binary is built from. SHA-256 pinned in [`sources/README.md`](../sources/README.md).

## How ThinForge uses EZIO

EZIO runs as a **standalone daemon**. Communication with ThinForge happens exclusively via gRPC over a network socket:

- Stage 1 of `docker/bt-seeder/Dockerfile` builds EZIO with CMake from the cloned upstream tag. Stage 2 copies only the resulting `/usr/local/sbin/ezio` binary and the `utils/*.py` helpers out of the builder — both therefore come from one and the same tree.
- Those Python utilities speak to the EZIO daemon via generated gRPC stubs (`ezio_pb2.py`, `ezio_pb2_grpc.py`).
- ThinForge does **not** link against EZIO code and does **not** statically combine EZIO with the Rust binary or the Go agent.

## Compliance status

- Built from **unmodified** upstream source. Verified 2026-08-25 for `v2.0.29` and re-verified 2026-08-29 for `v2.0.30`: no local commits outside upstream, the earlier checkout `4414248` was itself an upstream commit, and both tags match the upstream tag hashes exactly. The v2.0.29 → v2.0.30 diff touches only `app.cpp`, `config.cpp`, `config.hpp` and CI/metadata files; `ezio.proto` and `utils/` are unchanged, so the generated gRPC stubs are unaffected.
- Full GPL v2 text ships in this directory and inside the image under `/usr/share/licenses/`.

## Source offer

Corresponding source for the EZIO build in the bt-seeder image ships with every ThinForge release:

| Distributed images | Corresponding source |
|---|---|
| v2.0.30 build (2026-08-29 onwards) | [`sources/ezio-2.0.30.tar.gz`](../sources/ezio-2.0.30.tar.gz) |
| v2.0.29 build (2026-08-25 … 2026-08-29) | [`sources/ezio-2.0.29.tar.gz`](../sources/ezio-2.0.29.tar.gz) |
| everything before that | [`sources/ezio-v2.0.23-11-g4414248.tar.gz`](../sources/ezio-v2.0.23-11-g4414248.tar.gz) |

It is additionally available from upstream (https://github.com/tjjh89017/ezio) and on written request per [`WRITTEN_OFFER.md`](../WRITTEN_OFFER.md).

> **Corrections made on 2026-08-25 — two claims in this file were wrong.**
>
> 1. **The wrong tarball was declared as the historical source.** This file named `sources/ezio-snapshot.tar.gz` (tree at ThinForge commit `7faaa45`, 2026-04-17) as the corresponding source for everything shipped earlier. Checking the distributed binaries disproved it: that snapshot carries a **ThinForge-local patch** in `main.cpp` — a `LISTEN_INTERFACES` env override, log string `listen_interfaces override` — which exists in no upstream commit and in **none** of the distributed `ezio` binaries. Every shipped image was built from the unpatched upstream commit `4414248`, for which no tarball existed at all. The reconstruction above closes that gap; `ezio-snapshot.tar.gz` is retained but corresponds to no released image.
>    The patch was never committed — it lived only in the working tree that got tarred, which is why checking the git history could not see it. When verifying "unmodified", compare the **artefact**, not just the history.
> 2. **`quellinfos/ezio/` was a gitlink without a `.gitmodules` entry.** Git recorded a commit hash but had no URL, so a fresh clone produced an **empty** directory, and the file-copy repo sync hit `cp -p` on a directory and copied nothing — silently, because that script had no `set -e` at the time. The source therefore never reached the public repositories. The build now fetches from upstream, and the sync aborts loudly on any non-file path.
