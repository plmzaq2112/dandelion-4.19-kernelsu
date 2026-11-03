# Dandelion KernelSU Next

KernelSU build of the Dandelion Pure kernel for the Xiaomi Redmi 9A
(`dandelion`, MediaTek MT6765), Linux 4.19.325.

- Base: `01-pure-baseline` (`dandelion-4.19-purity`, branch `4.19.325-purity`)
- Branch: `4.19.325-kernelsu`
- Root: KernelSU **Next v3.4.0-legacy** (manager: KernelSU Next app, `com.rifsxd.ksunext`)

## KernelSU integration (zero source-code hooks)

KernelSU Next is provided as a separate repository pinned with git, symlinked
in from the drivers tree — the same layout as the official KernelSU setup
script:

- `KernelSU/` — `git clone https://github.com/KernelSU-Next/KernelSU-Next`,
  pinned to tag `v3.4.0-legacy`
- `drivers/kernelsu` — symlink to `../KernelSU/kernel`
- `drivers/Makefile` — one added line: `obj-$(CONFIG_KSU) += kernelsu/`
- `drivers/Kconfig` — one added line: `source "drivers/kernelsu/Kconfig"`

No hooks are patched into `fs/*` or elsewhere. The defconfig enables
`CONFIG_KSU_SYSCALL_TABLE_HOOK=y`: at boot KSU intercepts the desired syscalls
by patching entries of arm64 `sys_call_table` (pt_regs ABI, kernel >= 4.17)
and restores them at exit — nothing is added to the kernel's own C code,
and no kprobes are required.

`blossom_kernelsu_defconfig` is identical to `blossom_purity_defconfig`
plus:

```
CONFIG_KSU=y
# CONFIG_KSU_DEBUG is not set
# CONFIG_KSU_DISABLE_MANAGER is not set
# CONFIG_KSU_DISABLE_POLICY is not set
# CONFIG_KSU_ALLOWLIST_WORKAROUND is not set
# CONFIG_KSU_MANUAL_HOOK is not set
CONFIG_KSU_SYSCALL_TABLE_HOOK=y
```

Note on tag choice: `v3.4.0-legacy` (the `-legacy` line of every KernelSU
Next release) is the newest tree that keeps the compat layer for pre-5.10
non-GKI kernels. The plain `v3.4.x` tags dropped old-kernel support, and
official (tiann) KernelSU dropped non-GKI entirely at v1.0.

## Updating KernelSU

```sh
cd KernelSU
git fetch --tags
git checkout <newest -legacy tag>
```

Rebuild afterwards. Upgrading from the tinned `-legacy` line is expected to
stay compile-compatible; migrating to a plain non-legacy tag would need the
old-kernel compat layer reinstated first.

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
