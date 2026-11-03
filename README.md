# Dandelion Pure

**Dandelion Pure 4.19.325** — a maintained Linux 4.19.325 purity kernel for the
Xiaomi Redmi 9A (`dandelion`, MediaTek MT6765), targeting crDroid Android 16.

- Baseline branch: `4.19.325-purity`
- Release tag: `v4.19.325-purity`
- Base: IsHacker 4.19.325
- Kernel UTS: `4.19.325-dandelion-pure`
- Release image: `boot-dandelion-pure-4.19.325.img`
- Release image SHA256: `3E7364FC2E306D43E42400087B7984BA92DA7EC631978AB4A49629C9D3EFCF51`

## What this repository is

This is a **maintained purity baseline**, not a copy of the IsHacker default
branch. The policy is:

- No KernelSU / SUSFS / BannedApps leftovers
- No srandom driver
- No WireGuard, Mali/BM GPU stubs, fingerprint/NFC/i3c/UFS/net-phy leftovers
- No non-dandelion platform audio/GPU/camera/peripheral trees
- No directory-level `-flto` overrides
- Keep only the MediaTek/dandelion support needed to boot and operate the device

The source is still an Android/MediaTek kernel, not vanilla Linux. Vendor
drivers and their include dependencies remain where the hardware or build
requires them. See [docs/PURITY-4.19.325.md](docs/PURITY-4.19.325.md) for the
exact scope and known retained dependencies.

## Supported hardware

- Display, touch and brightness
- GPU / RGX
- Camera and camera sensors
- Audio / speaker / microphone
- Wi-Fi, Bluetooth, GPS, FM
- Modem / CCCI / connectivity
- Battery, charging and USB
- TEE (TEEI / keymaster / soter / RPMB)
- Sensors
- Suspend / resume

## Required kernel features

- `CONFIG_PSI=y` with userspace `lmkd`
- `CONFIG_LTO_NONE=y`
- BFQ as default I/O scheduler
- PBM v4 and `CONFIG_MTK_LM_MODE=y`
- TEEI, IOMMU/M4U, DEVAPC, secure video and trusted memory
- 14 dandelion camera sensors only
- `CONFIG_ANDROID_DUMMY_LMK` disabled

## Build

From a Linux/WSL host with the AArch64 toolchain:

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

Boot image packing/AVB recomputation is done with the release tooling used by
the maintainer; the kernel source itself is the canonical artifact in this
repository. `blossom_purity_defconfig` and
`scripts/check_purity_config.sh` are the reproducible configuration/check
pair.

## Verification

The release image is a localversion-only rebuild of the validated clean8
source. The validation baseline is:

- boot and `sys.boot_completed=1`
- suspend / resume (`Dozing` / `Awake`)
- display and brightness
- USB configured / charging
- Wi-Fi scan and Bluetooth ON
- 2 cameras, 14 sensors
- audio service
- TEEI, keymaster, soter, RPMB
- PBM `/proc/pbm` interface and `pbm` kernel thread

Known non-fatal log line:

```text
lmkd MemBpfRingbuf init failed
```

This is the expected fallback when BPF memevents are not enabled; lmkd falls
back to PSI/vmstats.

## Repository layout

| Path | Contents |
|---|---|
| `arch/arm64/configs/blossom_purity_defconfig` | Release defconfig |
| `scripts/check_purity_config.sh` | Required/forbidden config assertions |
| `docs/PURITY-4.19.325.md` | Source purity scope and retained dependencies |
| `docs/RELEASE-4.19.325.md` | Release notes and validation record |

## License

The kernel source is distributed under the licenses in `COPYING` and the
individual source files. This repository does not add a proprietary kernel
module or a root/hiding framework.

## Disclaimer

This is a device-specific kernel. Do not treat it as a generic upstream Linux
4.19.325 tree; MediaTek and Android integration is intentionally retained.
