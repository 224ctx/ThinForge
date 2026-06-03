# DRBL (Diskless Remote Boot in Linux)

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Steven Shiau and DRBL / NCHC Free Software Labs contributors
- **Upstream:** https://drbl.org/ · https://github.com/stevenshiau/drbl
- **Version distributed with ThinForge:** 5.3.17 (reference snapshot only)
- **Source included in this repository:** `quellinfos/drbl/` (version 5.3.17, unmodified upstream snapshot)

## How ThinForge uses DRBL

DRBL is **not installed into any ThinForge container image** and **not bundled in any ThinForge release artifact**. It is present in the source repository only as a developer-reference snapshot of the upstream project, used occasionally to look up how DRBL / Clonezilla handle PXE, multicast, and related mechanisms.

No DRBL binary is shipped as part of ThinForge.

## Distribution status

Since ThinForge does not distribute DRBL binaries, GPL v2 §3 source-with-binary obligations do not apply to ThinForge for DRBL. The upstream project distributes its own source.

## Reference

- Upstream: https://drbl.org/ and https://github.com/stevenshiau/drbl
- Full GPL v2 text shipped in [`GPL-2.0.txt`](GPL-2.0.txt) and in `quellinfos/drbl/LICENSE`.

The reference snapshot under `quellinfos/drbl/` may be pruned from future releases of the source repository without affecting compliance, as ThinForge is not a distributor of DRBL.
