# EZIO

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Ceng-Wei Jang (tjjh89017) and EZIO contributors
- **Upstream:** https://github.com/tjjh89017/ezio
- **Version distributed with ThinForge:** built from source snapshot in `quellinfos/ezio/`
- **Source included in this repository:** `quellinfos/ezio/` (full upstream snapshot, unmodified)

## How ThinForge uses EZIO

EZIO runs as a **standalone daemon**. Communication with ThinForge happens exclusively via gRPC over a network socket:

- `docker/bt-seeder/Dockerfile` (Stage 1) builds EZIO from `quellinfos/ezio/` using CMake. Stage 2 copies only the resulting `/usr/local/sbin/ezio` binary into the runtime image.
- Python utilities (`quellinfos/ezio/utils/*.py`) speak to the EZIO daemon via generated gRPC stubs (`ezio_pb2.py`, `ezio_pb2_grpc.py`).
- ThinForge does **not** link against EZIO code and does **not** statically combine EZIO with the Rust binary or the Go agent.

## Compliance status

- EZIO is built from unmodified upstream source.
- Full source is included under `quellinfos/ezio/` and distributed with every copy of this repository.
- Full GPL v2 text shipped in this directory and preserved in `quellinfos/ezio/LICENSE`.

## Source offer

Corresponding source code for the EZIO build shipped in the bt-seeder image is distributed with every ThinForge release as:

- `sources/ezio-snapshot.tar.gz` (tar of `quellinfos/ezio/` at the build commit; SHA-256 pinned in [`sources/README.md`](../sources/README.md))

It is additionally available from:

1. This repository: `quellinfos/ezio/`
2. Upstream: https://github.com/tjjh89017/ezio
3. On written request per [`WRITTEN_OFFER.md`](../WRITTEN_OFFER.md).
