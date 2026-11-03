# Dandelion KernelSU Next

KernelSU build of the Dandelion Pure kernel for the Xiaomi Redmi 9A
(`dandelion`, MediaTek MT6765), Linux 4.19.325.

- Base: `01-pure-baseline` (`dandelion-4.19-purity`, branch `4.19.325-purity`)
- Branch: `4.19.325-kernelsu`
- Root: KernelSU **Next v3.4.0-legacy**, manager pinned to the **official
  (tiann) KernelSU manager APK** (`me.weishu.kernelsu`)

## KernelSU integration (zero source-code hooks)

KernelSU Next lives in a separate git-pinned repo, symlinked into the
drivers tree — the same layout as the official KernelSU setup script:

- `KernelSU/` — clone of `KernelSU-Next/KernelSU-Next`, tag `v3.4.0-legacy`
- `drivers/kernelsu` — symlink to `../KernelSU/kernel`
- `drivers/Makefile` — one added line: `obj-$(CONFIG_KSU) += kernelsu/`
- `drivers/Kconfig` — one added line: `source "drivers/kernelsu/Kconfig"`

No hooks are patched into `fs/*` or anywhere else in the kernel C code.
The defconfig enables `CONFIG_KSU_SYSCALL_TABLE_HOOK=y`: at boot, KSU
intercepts syscalls by patching arm64 `sys_call_table` entries (pt_regs ABI,
kernel >= 4.17) on the fly and restores them on exit.

### Manager pinning

The legacy tree normally requires the KernelSU *Next* manager. The private
Kbuild constants were committed as:

```make
KSU_NEXT_MANAGER_SIZE := 0x033b
KSU_NEXT_MANAGER_HASH := c371061b19d8c7d7d6133c6a9bafe198fa944e50c1b31c9d8daa8d7f1fc2d2d6
```

which are the official (tiann) manager APK signature values, so the stock
official manager app is recognized. The supercall ioctl ABI (KSU_IOCTL_*,
'K' base numbers 1-21) and `uapi/app_profile.h` are byte-for-byte identical
with official v3.3.1, verified by diffing `uapi/` of both trees — only the
uapi version constant differs (Next reports v4; official app degrades
gracefully).

### Tag choice

`v3.4.0-legacy` is the newest KernelSU Next tree that keeps the compat layer
for pre-5.10 non-GKI kernels AND compiles as-is against Linux 4.19 (verified:
full module builds, zero errors). The plain `v3.4.x` tags dropped the legacy
selinux/n-internal compat and target the Next manager; official (tiann)
KernelSU dropped non-GKI entirely at v1.0 and pins UAPI v5.

## Updating KernelSU

```sh
cd KernelSU
git fetch --tags
git checkout <newest -legacy tag>
```

Rebuild afterwards.

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

Defconfig additions (over `blossom_purity_defconfig`):

```
CONFIG_KSU=y
# CONFIG_KSU_DEBUG is not set
# CONFIG_KSU_DISABLE_MANAGER is not set
# CONFIG_KSU_DISABLE_POLICY is not set
# CONFIG_KSU_ALLOWLIST_WORKAROUND is not set
# CONFIG_KSU_MANUAL_HOOK is not set
CONFIG_KSU_SYSCALL_TABLE_HOOK=y
```

Boot image packing and AVB recomputation use the helpers in `build-tools/`.
