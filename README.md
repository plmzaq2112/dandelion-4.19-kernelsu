# Dandelion KernelSU

KernelSU build of the Dandelion Pure kernel for the Xiaomi Redmi 9A
(`dandelion`, MediaTek MT6765), Linux 4.19.325.

- Base: `01-pure-baseline` (`dandelion-4.19-purity`, branch `4.19.325-purity`)
- Branch: `4.19.325-kernelsu`
- Root: KernelSU **v0.9.5** (official manager, `me.weishu.kernelsu`)

## KernelSU integration (minimal source change)

KernelSU is provided as a separate repository pinned with git, symlinked in
from the drivers tree — the same layout as the official KernelSU setup
script:

- `KernelSU/` — `git clone https://github.com/tiann/KernelSU`, pinned to tag `v0.9.5`
- `drivers/kernelsu` — symlink to `../KernelSU/kernel`
- `drivers/Makefile` — one added line: `obj-$(CONFIG_KSU) += kernelsu/`
- `drivers/Kconfig` — one added line: `source "drivers/kernelsu/Kconfig"`

No hooks are patched into `fs/*` or elsewhere: KSU v0.9.5 attaches all of its
hooks (prctl/rename, execve/faccessat/newfstatat symlink, pts devpts) via
kprobes at runtime. The defconfig is `blossom_kernelsu_defconfig`, identical
to `blossom_purity_defconfig` plus:

```
CONFIG_MODULES=y      # 4.19 KPROBES depends on MODULES
CONFIG_KPROBES=y
# CONFIG_KPROBE_EVENTS is not set
CONFIG_KSU=y
# CONFIG_KSU_DEBUG is not set
```

`CONFIG_KSU` depends on `CONFIG_OVERLAY_FS`/`CONFIG_EXT4_FS`, both already
enabled in the base defconfig.

## Updating KernelSU

```sh
cd KernelSU
git fetch --tags
git checkout <tag>
```

Rebuild afterwards. Tags newer than `v0.9.5` target newer kernel ABI bits
(e.g. unmaintained `selinux_state` layout, `MODULE_IMPORT_NS` without guards)
and will need compat work on 4.19.

## Build

```sh
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:$PATH

make ARCH=arm64 O=out-kernelsu \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar blossom_kernelsu_defconfig

make -j"$(nproc)" ARCH=arm64 O=out-kernelsu \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar Image.gz
```

If gki/selinux headers are missing on a partial build, build
`security/selinux/` once so `flask.h`/`av_permissions.h` are generated
(same flags as above, target `security/selinux/`).

Boot image packing and AVB recomputation use the helpers in `build-tools/`.
