# DRBL (Diskless Remote Boot in Linux)

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Steven Shiau and DRBL / NCHC Free Software Labs contributors
- **Upstream:** https://drbl.org/ · https://github.com/stevenshiau/drbl
- **Version distributed with ThinForge:** none (5.3.17 was the reference snapshot formerly kept in the repository)
- **Source:** not part of this repository — available from upstream (see “Reference” below)

## How ThinForge uses DRBL

DRBL is **not installed into any ThinForge container image**, **not bundled in any ThinForge release artifact** and not part of the source repository. Developers occasionally consult the upstream project to look up how DRBL / Clonezilla handle PXE, multicast, and related mechanisms.

No DRBL binary is shipped as part of ThinForge.

## Distribution status

Since ThinForge does not distribute DRBL binaries, GPL v2 §3 source-with-binary obligations do not apply to ThinForge for DRBL. The upstream project distributes its own source.

## Reference

- Upstream: https://drbl.org/ and https://github.com/stevenshiau/drbl
- Full GPL v2 text shipped in [`GPL-2.0.txt`](GPL-2.0.txt).

A reference snapshot formerly kept under `quellinfos/drbl/` was removed from the repository on 2026-04-25; this does not affect compliance, as ThinForge is not a distributor of DRBL.
