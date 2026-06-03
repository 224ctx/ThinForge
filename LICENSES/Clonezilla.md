# Clonezilla

- **License:** GNU General Public License, Version 2 — see [`GPL-2.0.txt`](GPL-2.0.txt)
- **Copyright:** Steven Shiau and Clonezilla / NCHC Free Software Labs contributors
- **Upstream:** https://clonezilla.org/ · https://github.com/stevenshiau/clonezilla
- **Version distributed with ThinForge:** Clonezilla Live 3.3.1-35 (default; configurable via `CLONEZILLA_VERSION`)
- **Source included in this repository:** `quellinfos/clonezilla/` (version 5.8.1, reference / unmodified upstream snapshot)
- **Clonezilla Live ISO origin:** https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/

## How ThinForge uses Clonezilla

Clonezilla is used as an **independent live operating system**, fetched on demand at the customer site:

- `crates/thinforge-services/src/clonezilla_service.rs` triggers a download of the official Clonezilla Live ISO from SourceForge to the customer's ThinForge server, on customer request via the ThinForge UI.
- The ThinForge server extracts the PXE boot files (`vmlinuz`, `initrd.img`, `filesystem.squashfs`) from the ISO into the TFTP root.
- Client machines PXE-boot into the unmodified Clonezilla Live environment from the customer's local TFTP server.
- The ThinForge Rust process never links Clonezilla code and never shares address space with Clonezilla.

## Distribution status

**ThinForge (the vendor) does not distribute Clonezilla binaries.** The Clonezilla Live ISO is:

1. Downloaded directly from the upstream SourceForge mirror by the customer's ThinForge server at install time.
2. Re-served by the customer's own server to the customer's own client machines within their LAN.

In this chain, the upstream distributor is SourceForge; the re-distributor (if any) is the customer operating their own LAN. ThinForge as a commercial software product is an orchestrator / downloader, analogous to a package-manager install script.

Accordingly, GPL v2 §3 source-with-binary obligations do not apply to ThinForge for Clonezilla. The Clonezilla Live ISO contains complete corresponding source as bundled by upstream; no further distribution action by ThinForge is required.

## Reference source

- Upstream release page: https://clonezilla.org/downloads.php
- `clonezilla-live-<version>-src.iso` / `.tar.xz` archives accompany every binary release upstream.
- Full GPL v2 text shipped in [`GPL-2.0.txt`](GPL-2.0.txt) and in `quellinfos/clonezilla/LICENSE`.

The ThinForge source repository historically included a reference snapshot of the Clonezilla 5.8.x source tree under `quellinfos/clonezilla/` for developer reference. That snapshot is not a formal source offer (we are not the distributor) and may be pruned from future releases of the source repository without affecting compliance.
