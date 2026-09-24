# sources/ — Corresponding source for distributed GPL binaries

This directory contains the **complete, corresponding source code** for the GPL v2-licensed binaries that are physically shipped inside ThinForge container images and release artifacts. It satisfies GPL v2 §3(a) for every binary distribution.

## What is here and why

Only GPL-licensed components whose **binaries** are shipped by ThinForge's distribution (container images pushed to the registry, tools-ISO, etc.) have their source kept in this directory. Components that ThinForge merely references or orchestrates (without shipping binaries) have source pointers in `../LICENSES/` instead — see "Not shipped" below.

### Current — corresponds to what today's images ship

| File | Corresponds to binary | License | Image(s) | Source origin |
|------|-----------------------|---------|----------|---------------|
| `partclone-0.3.47.tar.gz` | Alpine `community/partclone` **0.3.47-r0** (Alpine 3.24) | GPL v2 | `docker/cloner`, `docker/bt-seeder` | upstream release tag 0.3.47 — `git archive --prefix=partclone-0.3.47/ 0.3.47`. Alpine 3.24 applies **no patches** to this version (aports verified), so the upstream tree is the complete corresponding source. |
| `ezio-2.0.30.tar.gz` | EZIO daemon, built from source into the image | GPL v2 | `docker/bt-seeder` | upstream release tag **v2.0.30** (2026-08-27) of https://github.com/tjjh89017/ezio — `git archive --prefix=ezio/ v2.0.30`. Tag hash verified against upstream: `0d7df7887e14999abb1ff3e88ea714f2c4d478fb`. |

> Becomes true only once the rebuilt images are **pushed**. Commit, image
> rebuild and registry push belong in one movement — otherwise this table
> claims a correspondence that the registry does not have.

### Superseded — corresponding source for previously distributed releases

The GPL §3(a) obligation runs with **each** act of distribution, so the source
for images already shipped stays here. Do not delete these.

| File | Corresponds to | Distributed in |
|------|----------------|----------------|
| `partclone-0.3.40-r0-alpine3.23.tar.gz` | Alpine `community/partclone` **0.3.40-r0** — upstream tree 0.3.40 **plus the five aports patches** (`byteswap`, `gcc14`, `musl`, `remove-usage-of-off64_t`, `very-funny-glibc-types`) and the `APKBUILD` that applies them | releases `v2026.07.19` … `v2026.07.21` (Alpine 3.23 base) |
| `ezio-2.0.29.tar.gz` | EZIO upstream release tag **v2.0.29** (2026-08-05) | every EZIO-bearing image between the 2026-08-25 rebuild and the v2.0.30 bump on 2026-08-29 — including the `:beta` images pushed on 2026-08-29 |
| `ezio-v2.0.23-11-g4414248.tar.gz` | EZIO at upstream commit `4414248` — the state every image up to 2026-08-25 was actually built from | all EZIO-bearing images before the v2.0.29 rebuild |
| `partclone-0.3.33.tar.gz` | Alpine `community/partclone` 0.3.33 | **no registry release found.** The registry starts at `v2026.07.19`, which already carried 0.3.40. Retained in case a pre-registry artefact was ever handed out. |
| `ezio-snapshot.tar.gz` | tree at ThinForge commit `7faaa45` (2026-04-17) | **nothing.** See the correction below. |

> **Correction, 2026-08-25.** Until this date the two files at the bottom of
> that table were declared to be the corresponding source for everything shipped
> before. Checking the registry images themselves disproved both:
>
> - **`ezio-snapshot.tar.gz` was never built.** It contains a ThinForge-local
>   patch in `main.cpp` (an `LISTEN_INTERFACES` env override, log string
>   `listen_interfaces override`) that exists in **no** upstream commit. That
>   string appears in **none** of the distributed `ezio` binaries — they were all
>   built from the unpatched upstream commit `4414248`. So the shipped "source"
>   described code that never ran, while the code that did run had no source
>   here at all. Both directions were wrong.
> - **partclone 0.3.33 was never distributed through the registry**, and
>   **0.3.40 — which was — had no tarball at all**. The Alpine base moved
>   3.22 → 3.23 → 3.24 and carried the package along; the tarball here never
>   followed.
>
> Both gaps are now filled from reproducible sources. The lesson is in the rule
> below: read the version out of the **image**, never off a decision recorded in
> a document.

### Integrity (SHA-256)

Recompute at any time with `sha256sum *.tar.gz`.

```
b3060d301fd100ba1f5a8fad5b91deeb6309db09f4374d991ed84e27d8cb4cbc  partclone-0.3.47.tar.gz
6710fa77504020ee248075eb7826678f98c9b8a6134d5a641101ec60e37fd560  ezio-2.0.30.tar.gz
325f3d7068f2f1499ba9a033d7f1bdfafa6227e451ddd10edbdcc36ae25e60be  partclone-0.3.40-r0-alpine3.23.tar.gz
b8f76d08a2093e9f53df242f8172ff5040e5e87252b59e9f1b8e67dbdc7f6054  ezio-2.0.29.tar.gz
d26c4c5fe3c465b2c9e00854a7fe86db5d43819c3ba0e662a4860c266e1db91f  ezio-v2.0.23-11-g4414248.tar.gz
b5ebae1dd3763d8dc719835e46c4517419692f66e7748050faab38f8761d4719  partclone-0.3.33.tar.gz
1c51c2f16fc6cb462ee7c62f58f67cbb4742ae416462d651a6b478fa0d8a24dd  ezio-snapshot.tar.gz
```

`scripts/release-sync-licenses.sh` verifies these; keep every line in the plain
`<sha256>  <filename>` form so its grep keeps matching all of them.

## Not shipped — pointer-only (no source tarball here)

ThinForge does **not** ship binaries for the following components. They are downloaded / built on the ThinForge server at install time, or referenced only. GPL §3 source-with-binary obligations do not apply to ThinForge for these.

| Component | Why no source here |
|-----------|--------------------|
| **Clonezilla Live** | The ThinForge server downloads the ISO from SourceForge at install time via the ThinForge UI. ThinForge is a downloader / orchestrator, not a distributor of Clonezilla binaries. The ISO itself contains its own source. Upstream: https://clonezilla.org/ |
| **DRBL** | Not installed into any ThinForge container image. Only referenced in documentation / architecture. Upstream: https://drbl.org/ |
| **Alpine base packages** (`btrfs-progs`, `dnsmasq`, `qemu-img`, `util-linux`, `udpcast`, …) | Installed via `apk add` from Alpine community / main. Unmodified upstream packages. Source: https://pkgs.alpinelinux.org/packages and https://gitlab.alpinelinux.org/alpine/aports |

## Regenerating / updating source tarballs

When a new ThinForge release is cut:

1. **Read the version out of the image you actually ship** — never off a
   Dockerfile pin, because the pin names the *base*, not the package:
   ```bash
   docker run --rm --entrypoint sh thinforge-bt-seeder:latest \
     -c 'apk list --installed | grep -oE "^partclone-[0-9][^ ]*"'
   # → partclone-0.3.47-r0
   docker run --rm --entrypoint sh thinforge-bt-seeder:latest \
     -c 'cat /usr/local/share/ezio-version'
   # → v2.0.30
   ```

2. **Produce both tarballs with `git archive`**, so the result is reproducible
   and carries no build droppings:
   ```bash
   git -C buildsources/partclone archive --format=tar --prefix=partclone-<ver>/ <ver> \
     | gzip -n > sources/partclone-<ver>.tar.gz
   git -C buildsources/ezio archive --format=tar --prefix=ezio/ <tag> \
     | gzip -n > sources/ezio-<ver>.tar.gz
   ```
   `gzip -n` keeps the timestamp out of the archive, so an unchanged input
   yields an unchanged checksum.
   `rebuild.sh` only keeps `buildsources/partclone` at its pinned tag. EZIO is
   cloned by `docker/bt-seeder/Dockerfile` at build time (`ARG EZIO_VERSION`),
   so `buildsources/ezio` has to be cloned once by hand
   (`git clone https://github.com/tjjh89017/ezio buildsources/ezio`) and
   fetched before each bump.

3. **Name the file by version.** `ezio-snapshot.tar.gz` was the old,
   version-less name; a file whose name does not say what is inside cannot be
   matched to a release afterwards.

4. **Move the superseded file to the "Superseded" table — do not delete it.**
   The §3(a) obligation runs with each act of distribution.

5. Recompute the SHA-256 values and update both tables in this README, plus
   **all six** documents that name the files explicitly:
   `../NOTICE`, `../THIRD_PARTY_LICENSES.md`, `../WRITTEN_OFFER.md`,
   `../LICENSES/README.md`, `../LICENSES/Partclone.md`, `../LICENSES/EZIO.md`.
   A rename that misses one leaves a legal document pointing at a file that no
   longer corresponds to anything shipped. Find them with:
   `grep -rln 'sources/.*\.tar\.gz' --include='*.md' . ; grep -l 'sources/.*\.tar\.gz' NOTICE`
   — **the `--include='*.md'` filter alone misses `NOTICE`, because that file
   has no extension.** That is precisely how `NOTICE` came to be the document
   left behind; the note below records the symptom, this command fixes the
   cause.
   `../LICENSES/README.md` names the shipped *version* ("Version shipped"),
   not the file, so the grep does not list it; update it by hand.
   (This list said "five" until 2026-08-25 and omitted `NOTICE` — which is
   exactly how `NOTICE` came to be the one document left behind.)

## See also

- [`../THIRD_PARTY_LICENSES.md`](../THIRD_PARTY_LICENSES.md) — full list of distributed FOSS with upstream pointers
- [`../WRITTEN_OFFER.md`](../WRITTEN_OFFER.md) — written source offer per GPL v2 §3(b)
- [`../LICENSES/`](../LICENSES/) — canonical license texts and per-component metadata
