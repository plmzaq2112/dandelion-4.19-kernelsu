# Building the kernel (v65 line)

Kernel source lives on the **`bakasu` branch**; all tooling is in its
`build-tools/`. This page is the summary — the in-tree `build-tools/BUILD.md`
has full details and troubleshooting notes.

## Requirements

- Linux host (developed on Ubuntu 24.04 / WSL2), **clang 21** toolchain
  (`/usr/lib/llvm-21/bin`, Ubuntu clang 21.1.8 + lld)
- `aarch64-linux-gnu-` cross tools on PATH (linker is lld)
- `python3` (standard library only, used by the packer)
- **the stock boot.img** of dandelion — packing replaces *only* the kernel
  segment, so the stock image is both the base and the brick-proof rollback
- device with unlocked bootloader for flashing

## Configuration strategy — two layers

1. `arch/arm64/configs/blossom_defconfig` — baseline (BFQ / BBR / io_uring
   perf set included, SELinux enforcing, KPROBES off)
2. `build-tools/ksu.config` — the KernelSU delta, authoritative ~15 entries:
   - on: `KSU`, `KSU_MANUAL_HOOK` (+3 `_AUTO_*` hooks), `KSU_MULTI_MANAGER_SUPPORT`,
     `MODULES=y`, `KALLSYMS_ALL=y`
   - off: `KPROBES`, `KSU_SUSFS` (evaluation parked), `KSU_DEBUG`,
     `KSU_TOOLKIT_SUPPORT`, `KSU_TRACEPOINT_HOOK`

`build-tools/check_config.sh` asserts **53 must-y / 18 must-n / 6 exact
values** (reference: the v65 runtime snapshot) and fails loudly on any silent
Kconfig drift. Never edit `out/.config` directly.

## One-shot build + pack

```bash
O=out        bash build-tools/build_ksu.sh   # compile → out/arch/arm64/boot/Image.gz
O=out        bash build-tools/make_boot.sh   # + pack → out/boot-<release>.img(+.sha256)
```

`make_boot.sh` pipeline:

1. `build_ksu.sh` — defconfig → append delta → olddefconfig → assert → Image.gz
2. `pack_boot.py` — replace only the kernel segment in the stock image
   (ramdisk / dtb / page-size / cmdline pass through byte-for-byte)
3. post-pack re-read: ramdisk + dtb segments are hash-compared against the
   base image — any mismatch aborts
4. `sha256sum` sidecar written next to the image

## Useful facts

- kernel release string: `4.19.325-dandelion-ksu`
  (`CONFIG_LOCALVERSION="-dandelion-ksu"`)
- KernelSU version code is frozen in source: `drivers/kernelsu/Kbuild`
  computes `30000 + KSU_LOCAL_VERSION + 700` (v65 → **35002**) — no build-time
  stamping needed
- builds are **not bit-reproducible** (embedded compilation timestamps);
  verify functionally instead: UTS string, Image.gz size range, KSU init line
  in dmesg
- `build_full.sh` (the pure-baseline flow) intentionally fails assertions on
  this tree — it cannot merge the KSU delta; use `build_ksu.sh`
