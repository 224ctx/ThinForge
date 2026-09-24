# LICENSES — Third-Party License Texts

This directory contains full license texts and per-component metadata for every third-party Free / Open Source Software (FOSS) component shipped as part of ThinForge, along with notes on how each component is integrated and where its source code can be obtained.

## Canonical texts

- [`GPL-2.0.txt`](GPL-2.0.txt) — GNU General Public License, Version 2 (full text).
- [`GPL-3.0.txt`](GPL-3.0.txt) — GNU General Public License, Version 3 (full text).

## Per-component metadata

### Distributed by ThinForge (source shipped in `../sources/`)

| Component | License | Version shipped | Integration | Details |
|-----------|---------|-----------------|-------------|---------|
| Partclone | GPL v2 | 0.3.47-r0 (Alpine pkg) | subprocess | [Partclone.md](Partclone.md) |
| EZIO | GPL v2 | from upstream at build time | separate daemon (gRPC) | [EZIO.md](EZIO.md) |

### Referenced / orchestrated, not distributed by ThinForge

| Component | License | Role | Details |
|-----------|---------|------|---------|
| Clonezilla Live | GPL v2 | downloaded at install time on the ThinForge server | [Clonezilla.md](Clonezilla.md) |
| DRBL | GPL v2 | developer reference only | [DRBL.md](DRBL.md) |

## Key points

1. **No linking.** ThinForge's Rust core, Go agent, and TypeScript frontend do not link against any GPL-v2-licensed library. All interaction with the GPL v2 components crosses a process boundary (subprocess invocation, gRPC, network protocols, PXE boot of a separate operating system). This keeps the GPL-v2-only components (Partclone, EZIO) and the GPL-v3-licensed ThinForge code separate programs — the two licenses are incompatible within a single combined work.
2. **No modifications.** The GPL components shipped with ThinForge are unmodified upstream releases. Any future modification must be disclosed under GPL v2.
3. **Source availability.** Complete corresponding source for each GPL component is either included in this repository (`quellinfos/`, `buildsources/`) or available from the authoritative upstream source. A written offer valid for three years is provided in [`../WRITTEN_OFFER.md`](../WRITTEN_OFFER.md).
4. **Commercial use.** GPL v2 permits commercial distribution and commercial use. The ThinForge components are licensed GPL-3.0-or-later; the GPL v2 components remain under GPL v2.

See [`../THIRD_PARTY_LICENSES.md`](../THIRD_PARTY_LICENSES.md) for the summary intended for end users.
