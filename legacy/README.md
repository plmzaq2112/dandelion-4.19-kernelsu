# legacy/

Assets from **before the current BakaSU manual-hook line** — kept for
reference only, not maintained.

| Path | What it was |
|---|---|
| `apk/KernelSU_v3.3.0_32601_gkipatched_v2only.apk.sha256` | manager checksum for the v11ksu line (4.19.275, v2-UAPI era, specially built manager) |
| `flash/boot_ksu43_load.img.sha256` | checksum of a 4.19.275 (ksu43) load-runner flash image |
| `modules/perftune/` | KernelSU perftune module from the performance-tuned line |
| `patches/` | `ksu43_kernelsu.patch`, syscall-hook sources ("final-kernel-patches", old universal-hook approach) and perf patch drafts for the old 4.19.275 tree |
| `scripts-build/`, `scripts-pack/` | 4.19.275-era build/pack helpers (build52/53, pack52/53, inspect/verify tools) |
| `scripts/recover_boot.ps1` | machine-specific auto-rollback helper referencing `#27`-era local paths |

The current line's kernel is integrated on the **`bakasu` branch** and its
build tooling lives in `build-tools/` there — see [`docs/BUILD.md`](../docs/BUILD.md).
