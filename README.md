# dandelion-4.19-kernelsu

Xiaomi Redmi 9A（`dandelion`，MT6765）的 KernelSU 内核线，基于 Linux 4.19.325，
面向 crDroid Android 16（系统指纹 `blossom/...`）。

- 主线分支：**`autohook`**
- 当前发布：**v66** — https://github.com/plmzaq2112/dandelion-4.19-kernelsu/releases/tag/v66
- 内核版本串：`4.19.325-dandelion-ksu`
- KernelSU 模块：**BakaSU `auto-hook`**（UAPI v5，`KSU_VERSION 35002`）
- 管理器：**tiann 官方 KernelSU v3.3.1（32680）**，直连免重签

## 特点：零内核源码钩子

主线使用 BakaSU 的 auto-hook 机制，**`fs/*`、`kernel/*` 里没有任何 KernelSU 钩子调用点**：

| 钩子 | 方式 |
|---|---|
| execve / execveat | inline hook（`do_execveat_common`） |
| faccessat | inline hook（`__arm64_sys_faccessat`） |
| newfstatat / fstat / fstat64 | inline hook（对应 syscall wrapper） |
| sys_reboot（驱动 fd + supercall） | inline hook（`__arm64_sys_reboot`） |
| setuid（管理器识别 / 解除 seccomp / 装 fd） | LSM `task_fix_setuid` |
| init.rc 读取 | LSM |
| input（安全模式） | input handler |
| packages.list 追踪 | LSM `inode_rename` |

对比历史 `bakasu` 线（v65，manual-hook）需要 4 处源码调用点，本线不再需要任何源码钩子补丁。

## 关键改动（相对纯净基线）

- 内核功能代码只加了一处加固：`fs/proc/task_mmu.c` 的 `show_map_vma` 对非法/失效
  `vm_file` 记录限速日志并跳过，避免读 `/proc/pid/maps` 时内核 panic
- 配置增量：`CONFIG_KSU`、`CONFIG_KSU_MANUAL_HOOK`（auto-hook 家族）、
  `CONFIG_KSU_MULTI_MANAGER_SUPPORT`、`CONFIG_MODULES`、`CONFIG_KALLSYMS(_ALL)`、
  `CONFIG_BATTERY_MT6357=y`、`CONFIG_SND_SOC_MT6357_ACCDET=y`
- `CONFIG_KPROBES` 保持关闭（本机 kprobe 不可用，v0.9.5/kprobe 路线会 bootloop）

## 目录结构

```
arch/arm64/configs/blossom_kernelsu_defconfig   主配置（纯净基线 + KSU 增量）
build-tools/fetch_kernelsu.sh                   拉取 BakaSU 模块并打本地补丁
build-tools/patches/                            本地模块补丁（3 个）
build-tools/pack_boot.py                        仅替换 kernel 段重打包 boot
build-tools/recompute_avb.py                    AVB 重算（底包带 footer 时使用）
drivers/kernelsu -> ../KernelSU/kernel          模块软链（clone 后生成）
docs/BUILD.md                                   构建 / 打包 / 验证细节
docs/TESTING.md                                 刷后验收清单与功能矩阵
docs/TROUBLESHOOTING.md                         刷机 / 管理器 / 电量 / adb 排障
docs/CHANGELOG.md                               版本变更记录
docs/PURITY-4.19.325.md                         纯净基线范围（历史参考）
docs/RELEASE-4.19.325.md                        纯净基线发布说明（历史参考）
```

模块源码不进本仓库：`KernelSU/` 被 gitignore，首次构建执行
`build-tools/fetch_kernelsu.sh`，脚本会 clone `Baka-SU/BakaSU`（`auto-hook` 分支）并
`git am` 应用 `build-tools/patches/` 下的三个补丁（版本号冻结、UAPI v5、file_wrapper 引用修复）。

## 快速开始

```bash
# 1) 取模块 + 建立软链
bash build-tools/fetch_kernelsu.sh

# 2) 配置 + 编译
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:$PATH
make ARCH=arm64 O=out-kernelsu \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar blossom_kernelsu_defconfig
make -j"$(nproc)" ARCH=arm64 O=out-kernelsu \
  CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar Image.gz

# 3) 打包（底包必须是可启动的同版 boot.img；只替换 kernel 段）
KERNEL_IMG=out-kernelsu/arch/arm64/boot/Image.gz \
  python3 build-tools/pack_boot.py <base-boot.img> out/boot-dandelion-ksu.img
```

详细说明见 [docs/BUILD.md](docs/BUILD.md)；刷后验收见
[docs/TESTING.md](docs/TESTING.md)；异常排查见
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)；版本记录见
[docs/CHANGELOG.md](docs/CHANGELOG.md)。

## 刷入

```bash
fastboot flash boot out/boot-dandelion-ksu.img
fastboot reboot
```

底包保留一份，变砖回滚：`fastboot flash boot <base-boot.img>`。

## 分支

| 分支 | 说明 |
|---|---|
| `autohook` | **主线**：BakaSU auto-hook，零源码钩子（本分支） |
| `bakasu` | v65 历史线：BakaSU manual-hook（4 处源码钩子） |
| `main` | 旧文档/工具仓库线（保留） |
| `v11ksu` | 更早的 v11 KernelSU 线（保留） |

## 已知事项

- NFC：dandelion 无 NFC 硬件，`com.android.nfc` 的 ANR 循环是 ROM 自带行为，与内核无关
- 模块 `system/` 目录需要 metamodule（Hybrid Mount / meta-overlayfs）才会挂载；纯脚本模块不受影响
- 不含 susfs / root 隐藏类特性
- `/proc/pid/maps` 的异常 `vm_file` 已被加固拦截；若出现
  `maps: invalid vm_file ...` 日志，请附 dmesg 反馈

## 许可

内核源码遵循 `COPYING` 及各文件自带许可证；KernelSU 模块来自
[BakaSU](https://github.com/Baka-SU/BakaSU)（GPL-2.0）。
