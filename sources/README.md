# sources/ — Corresponding source for distributed GPL binaries

This directory contains the **complete, corresponding source code** for the GPL v2-licensed binaries that are physically shipped inside ThinForge container images and release artifacts. It satisfies GPL v2 §3(a) for every binary distribution.

## What is here and why

Only GPL-licensed components whose **binaries** are shipped by ThinForge's distribution (container images pushed to the registry, tools-ISO, etc.) have their source kept in this directory. Components that ThinForge merely references or orchestrates (without shipping binaries) have source pointers in `../LICENSES/` instead — see "Not shipped" below.

| File | Corresponds to binary | License | Image(s) | Source origin |
|------|-----------------------|---------|----------|---------------|
| `partclone-0.3.33.tar.gz` | Alpine `community/partclone` 0.3.33 | GPL v2 | `docker/cloner`, `docker/bt-seeder` | upstream release https://github.com/Thomas-Tsai/partclone/releases/tag/0.3.33 |
| `ezio-snapshot.tar.gz` | EZIO daemon built from this source | GPL v2 | `docker/bt-seeder` | tar of `quellinfos/ezio/` at ThinForge commit `7faaa45` (2026-04-17). Verify via `git log -1 -- quellinfos/ezio/` in the source repo. |

### Integrity (SHA-256)

Recompute at any time with `sha256sum *.tar.gz`. Values below are those at the time of release.

```
b5ebae1dd3763d8dc719835e46c4517419692f66e7748050faab38f8761d4719  partclone-0.3.33.tar.gz
1c51c2f16fc6cb462ee7c62f58f67cbb4742ae416462d651a6b478fa0d8a24dd  ezio-snapshot.tar.gz
```

## Not shipped — pointer-only (no source tarball here)

ThinForge does **not** ship binaries for the following components. They are downloaded / built on the ThinForge server at install time, or referenced only. GPL §3 source-with-binary obligations do not apply to ThinForge for these.

| Component | Why no source here |
|-----------|--------------------|
| **Clonezilla Live** | The ThinForge server downloads the ISO from SourceForge at install time via the ThinForge UI. ThinForge is a downloader / orchestrator, not a distributor of Clonezilla binaries. The ISO itself contains its own source. Upstream: https://clonezilla.org/ |
| **DRBL** | Not installed into any ThinForge container image. Only referenced in documentation / architecture. Upstream: https://drbl.org/ |
| **Alpine base packages** (`btrfs-progs`, `dnsmasq`, `qemu-img`, `util-linux`, `udpcast`, …) | Installed via `apk add` from Alpine community / main. Unmodified upstream packages. Source: https://pkgs.alpinelinux.org/packages and https://gitlab.alpinelinux.org/alpine/aports |

## Regenerating / updating source tarballs

When a new ThinForge release is cut:

1. **Partclone version** matches Alpine version currently in use:
   ```bash
   docker run --rm alpine:3.22 apk info -v community/partclone
   # → partclone-0.3.33-r0
   # Then refetch: curl -fsSLO https://github.com/Thomas-Tsai/partclone/archive/refs/tags/<version>.tar.gz
   ```

2. **EZIO snapshot** is a tar of `../quellinfos/ezio/` at the commit used for the release build:
   ```bash
   tar --exclude='.git' --exclude='build' --exclude='CMakeCache.txt' \
       -czf sources/ezio-snapshot.tar.gz -C quellinfos ezio
   ```

3. Update SHA-256 values in this README accordingly.

## See also

- [`../THIRD_PARTY_LICENSES.md`](../THIRD_PARTY_LICENSES.md) — full list of distributed FOSS with upstream pointers
- [`../WRITTEN_OFFER.md`](../WRITTEN_OFFER.md) — written source offer per GPL v2 §3(b)
- [`../LICENSES/`](../LICENSES/) — canonical license texts and per-component metadata
