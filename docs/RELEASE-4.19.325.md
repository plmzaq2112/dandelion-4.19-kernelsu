# Dandelion Pure 4.19.325 — release notes

## Release

- Tag: `v4.19.325-purity`
- Branch: `4.19.325-purity`
- Base: IsHacker 4.19.325
- Device: Xiaomi Redmi 9A / `dandelion` / MT6765
- Target: crDroid Android 16

This is the first maintained purity baseline. It is a source release; the
64 MiB boot image is not committed to Git.

## Kernel image

- Image: `boot-dandelion-pure-4.19.325.img`
- SHA256:
  `3E7364FC2E306D43E42400087B7984BA92DA7EC631978AB4A49629C9D3EFCF51`
- Kernel UTS: `4.19.325-dandelion-pure #18 SMP PREEMPT`
- `Image.gz`: 9,358,127 bytes

## Configuration

- Defconfig: `arch/arm64/configs/blossom_purity_defconfig`
- Assertions: `scripts/check_purity_config.sh`
- `CONFIG_LTO_NONE=y`
- `CONFIG_PSI=y`
- `CONFIG_DEFAULT_BFQ=y`
- `CONFIG_DEFAULT_IOSCHED="bfq"`
- `CONFIG_MTK_PBM=y`
- `CONFIG_MTK_LM_MODE=y`
- `CONFIG_TEE=y`
- `CONFIG_MTK_M4U=y`
- `CONFIG_MTK_DEVAPC=y`
- `CONFIG_MTK_SEC_VIDEO_PATH_SUPPORT=y`
- `CONFIG_MTK_TRUSTED_MEMORY_SUBSYSTEM=y`
- `CONFIG_ANDROID_DUMMY_LMK` disabled
- `CONFIG_WIREGUARD` / `CONFIG_SRANDOM` / `CONFIG_KSU*` absent

## Validation

Validated on dandelion:

- boot to Android 16; `sys.boot_completed=1`
- suspend and wake
- display and brightness
- USB configured and charging
- Wi-Fi scan
- Bluetooth ON
- 2 cameras
- 14 hardware sensors
- audio service
- TEEI / keymaster / soter / RPMB
- PBM `/proc/pbm` interface and kernel thread

Non-fatal known log line:

```text
lmkd MemBpfRingbuf init failed
```

This is the expected PSI/vmstats fallback when BPF memevents are unavailable.

`loadavg` may remain around 9–10 because several MediaTek threads use
uninterruptible sleeps (`msleep`/`ssleep`); this is not a PBM deadlock and CPU
utilization is low.

## Build

```sh
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:$PATH

make ARCH=arm64 O=out-dandelion \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar blossom_purity_defconfig

scripts/check_purity_config.sh out-dandelion/.config

make -j"$(nproc)" ARCH=arm64 O=out-dandelion \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar Image.gz
```

## Purity summary

Removed from the working baseline:

- KernelSU / SUSFS / BannedApps
- srandom
- WireGuard
- Mali/BM stubs
- AEE / DCM / LPM / systracker / log_store
- fpsgo_cus / camera_security
- non-dandelion platform trees
- directory-level `-flto`

Retained intentionally:

- PBM v4 / LM_MODE
- BFQ default
- BLAKE2s wrappers
- `log_store_reclaim.c`
- TEEI / IOMMU / DEVAPC / secure video / trusted memory
- `ext_disp` / `hdmi` and a small set of header-only MediaTek dependencies

See [PURITY-4.19.325.md](PURITY-4.19.325.md) for the complete policy and
remaining source debt.

## Flashing

Use the validated boot image with the maintainer’s AVB/boot packing flow:

```cmd
fastboot flash boot boot-dandelion-pure-4.19.325.img
fastboot reboot
```

Keep a previously validated boot image available for rollback.

## License

Kernel source is covered by `COPYING` and the per-file licenses. No root or
hiding framework is included.
