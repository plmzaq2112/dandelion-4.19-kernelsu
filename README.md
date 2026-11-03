# Dandelion KernelSU (BakaSU auto-hook)

KernelSU build of the Dandelion Pure kernel for the Xiaomi Redmi 9A
(`dandelion`, MT6765), Linux 4.19.325.

- Base: `01-pure-baseline` (`dandelion-4.19-purity`, branch `4.19.325-purity`)
- Branch: `4.19.325-kernelsu`
- KernelSU module: **BakaSU** `auto-hook` branch (`Baka-SU/BakaSU`)
- Manager: **official tiann KernelSU v3.3.1 (32680)** — reports `工作中`

## Design: zero kernel-source hooks

The kernel C code is untouched (`fs/*`, `kernel/*` unchanged). All hooks are
installed at runtime from inside the KernelSU module:

| Hook | Mechanism |
|---|---|
| execve / execveat | inline hook on `do_execveat_common` |
| faccessat | inline hook on `__arm64_sys_faccessat` |
| newfstatat / fstat | inline hook on `__arm64_sys_newfstatat` / `__arm64_sys_fstat` |
| sys_reboot (driver-fd install + supercall) | inline hook on `__arm64_sys_reboot` |
| setuid (manager detection, seccomp relax, fd install) | LSM `task_fix_setuid` |
| init.rc read | LSM |
| input (safe mode) | input handler |
| packages.list tracking | LSM `inode_rename` |

BakaSU's `kernel/tools/auto_hook_detect.mk` selects these automatically when the
kernel source has no manual hook call sites; with `CONFIG_KALLSYMS_ALL=y` the
"manual hook required" compile check is skipped by design.

## Pinned module changes (`KernelSU/`, local git commits)

1. `kernel/Kbuild` — freeze `KSU_LOCAL_VERSION` to 4302 so the version code is
   `30000 + 4302 + 700 = 35002` (official manager minimum is 32513) even from a
   shallow clone/archive.
2. `uapi/supercall.h` — report `KERNEL_SU_UAPI_VERSION = 5` (+ `EVENT_SERVICES`
   and `KSU_GET_INFO_FLAG_BUNDLED` constants) so the official v3.3.1 manager
   stops showing "需要更新内核". Feature discovery stays per-ID, so missing
   newer features degrade gracefully (e.g. `shell_su_adb_only` unsupported).

## defconfig delta (`blossom_kernelsu_defconfig`)

```
CONFIG_KSU=y
CONFIG_KSU_DEBUG=y                 # temporary: allow_shell -> adb shell can su
CONFIG_KSU_MANUAL_HOOK=y           # non-GKI hook family (runtime inline hooks)
CONFIG_KSU_MULTI_MANAGER_SUPPORT=y # official + unofficial manager signatures
CONFIG_MODULES=y
CONFIG_KALLSYMS=y
CONFIG_DEBUG_KERNEL=y              # required by KALLSYMS_ALL on 4.19
CONFIG_KALLSYMS_ALL=y              # data symbols + skip manual-hook compile check
CONFIG_KALLSYMS_BASE_RELATIVE=y
CONFIG_LOCALVERSION="-dandelion-ksu-a12bbb"
```

No `CONFIG_KPROBES` (kprobes are broken/bootloop-prone on this MTK tree).

## Update KernelSU

```sh
cd KernelSU
git fetch --tags origin
git checkout <newer auto-hook commit>
```

Keep the two local commits (version freeze + uapi 5) on top.

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

Pack with `build-tools/pack_boot.py` (kernel segment only) and
`build-tools/recompute_avb.py`, as in the pure-baseline tree.

## Verified

- `uname -r` → `4.19.325-dandelion-ksu-a12bbb`
- Manager v3.3.1 shows **工作中** (kernel 35002, UAPI 5)
- `su -c id` → `uid=0(root) context=u:r:ksu:s0` (survives reboot)
- dmesg: `ksu_handle_stat: su->sh!`, `faccessat su->sh!`,
  `do_execveat_common su found`, `handle_setresuid ...` — inline/LSM hooks live
- SELinux stays `Enforcing`

## Notes

- `CONFIG_KSU_DEBUG=y` currently keeps `allow_shell=true` so `adb shell su`
  works for testing. For a release build turn it off; app grants still work,
  but shell `su` then depends on the manager's Shell toggle (the newer
  `shell_su_adb_only` feature ID is not implemented in this module line).
- Verified working combination: module version 35002 / UAPI 5 / manager 32680.
