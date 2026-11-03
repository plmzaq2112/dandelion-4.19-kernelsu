# Dandelion Pure

Maintained Linux 4.19.325 kernel for the Xiaomi Redmi 9A
(`dandelion`, MediaTek MT6765), targeting crDroid Android 16.

- Maintainer: **a12bbb**
- Base: IsHacker 4.19.325
- Branch: `4.19.325-purity`

## Overview

Dandelion Pure keeps the kernel close to a clean Linux 4.19.325 baseline while
retaining the MediaTek/dandelion support required by the device. The project
is maintained as a stable source baseline; release-specific changes, build
digests and verification notes are published on the GitHub Releases page.

## Supported hardware

Display and touch, GPU, camera, audio, Wi-Fi, Bluetooth, GPS, FM, modem,
battery/charging, USB, TEE, sensors, and suspend/resume.

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

Boot image packing and AVB recomputation use the helpers in `build-tools/`.

## Documentation

- [Purity scope](docs/PURITY-4.19.325.md)
- [Release notes](docs/RELEASE-4.19.325.md)

## License

Kernel source is distributed under the licenses in `COPYING` and the
individual source files.
