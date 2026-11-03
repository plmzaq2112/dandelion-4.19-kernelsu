# dandelion 4.19.325 purity scope

This document defines what “purity” means for this repository. The
repository is not a vanilla upstream tree; it is a **4.19.325 kernel with the
minimum MediaTek/dandelion integration required by the device**.

## Baseline

- Linux base: `4.19.325`
- Device: Xiaomi Redmi 9A (`dandelion`, MT6765)
- Android target: crDroid Android 16
- Branch: `4.19.325-purity`
- Release tag: `v4.19.325-purity`
- Reference build: Dandelion Pure 4.19.325, kernel UTS
  `4.19.325-dandelion-pure-a12bbb #19 SMP PREEMPT`

## Purity rules

The following are intentionally absent:

- KernelSU, SUSFS and BannedApps / NightShadow logic
- srandom driver and its `mem.c` / `random.c` hooks
- WireGuard
- Mali and Bandwidth Manager GPU stubs
- Non-dandelion platform audio/GPU/camera/peripheral trees
- fingerprint, NFC, i3c, interconnect, UFS and unneeded TEE backends
- AEE, DCM, LPM, systracker, log_store, fpsgo_cus and camera_security
- Directory-level `-flto` overrides

The following are intentionally retained because the release needs them:

- PBM v4 and `CONFIG_MTK_LM_MODE=y` (ported from V7)
- BFQ default I/O scheduler
- BLAKE2s inline wrappers
- `log_store_reclaim.c` (reclaims the bootloader log reservation)
- TEEI, IOMMU/M4U, DEVAPC, secure video/trusted memory/SSMR
- 14 dandelion camera sensors
- `ext_disp` / `hdmi`: required by `video/mt6765/videox`
- `dws`: consumed by `scripts/drvgen`
- `power_throttling`: PBM header dependency

## Remaining MediaTek source debt

A few unbuilt directories still exist because other compiled MediaTek
subsystems include their headers:

- `geniezone`
- `mdla`
- `mmp`
- `mmqos`
- `typec`
- `vpu`

They are not compiled in the release config. Removing them requires a
subsystem-by-subsystem include-path refactor (thermal, video, USB, cmdq), so
they are deliberately retained for build stability.

## Configuration contract

The release configuration is `arch/arm64/configs/blossom_purity_defconfig`.
`scripts/check_purity_config.sh <config>` asserts the important properties,
including:

- `PSI`, `LTO_NONE`, TEE, M4U, DEVAPC, secure video, trusted memory
- BFQ default
- PBM and LM_MODE enabled
- no KSU/SUSFS/BannedApps, WireGuard, srandom, dummy LMK

## Validation

The release image was rebuilt from the D1 source state with only
`CONFIG_LOCALVERSION` changed after the clean8 validation (boot, suspend,
display, USB/charging, Wi-Fi/BT, camera, sensors, audio, TEE). The kernel image
is not committed to Git; its release digest is recorded in
[RELEASE-4.19.325.md](RELEASE-4.19.325.md).

## Important non-goals

- This is not a vanilla `linux-4.19.325` source release.
- This is not a generic MT6765 kernel; it is tuned for dandelion.
- Remaining vendor code is not claimed to follow upstream Linux coding style.
- The repository does not provide root, hiding, or module-loading frameworks.
