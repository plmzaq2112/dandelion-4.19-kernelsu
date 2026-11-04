# 构建与验证（autohook 主线）

本文是 `autohook` 主线（v66 起）的构建、打包、刷入与验收说明。

## 1. 环境

- WSL2 / Ubuntu，clang + LLD **21**（`/usr/lib/llvm-21/bin`）
- `aarch64-linux-gnu-` 交叉工具（链接走 `ld.lld`）
- `python3`（打包脚本，标准库）
- 一份可启动的**同版本底包** `boot.img`（只替换 kernel 段，也是回滚兜底）
- 设备已解锁，`fastboot` 可用

## 2. 取模块

模块不在本仓库内（`KernelSU/` 已 gitignore），用脚本拉取并应用本地补丁：

```bash
bash build-tools/fetch_kernelsu.sh
```

脚本行为：

1. `git clone --depth 1 -b auto-hook https://github.com/Baka-SU/BakaSU.git KernelSU`
2. `git am build-tools/patches/*.patch`
   - 冻结 `KSU_LOCAL_VERSION`（`30000+4302+700=35002`，满足官方管理器最低 32513）
   - `KERNEL_SU_UAPI_VERSION=5`（消除管理器“需要更新内核”）
   - `file_wrapper`：`mntget(anon_inode_mnt)`
3. `ln -sfn ../KernelSU/kernel drivers/kernelsu`

## 3. 配置与编译

```bash
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:$PATH
MAKE="make ARCH=arm64 O=out-kernelsu CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
  LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
  STRIP=llvm-strip AR=llvm-ar"

$MAKE blossom_kernelsu_defconfig
$MAKE -j"$(nproc)" Image.gz
```

产物：`out-kernelsu/arch/arm64/boot/Image.gz`，UTS
`4.19.325-dandelion-ksu`。

### 配置要点

| 项 | 值 | 说明 |
|---|---|---|
| `CONFIG_KSU` | y | 模块本体 |
| `CONFIG_KSU_MANUAL_HOOK` | y | 非 GKI 钩子家族（auto-hook 自动检测并安装） |
| `CONFIG_KSU_MULTI_MANAGER_SUPPORT` | y | 官方 + 社区管理器签名 |
| `CONFIG_MODULES` | y | ksud/模块功能需要 |
| `CONFIG_KALLSYMS` / `_ALL` | y | 符号解析；`KALLSYMS_ALL` 同时跳过“必须手动钩子”的编译检查 |
| `CONFIG_DEBUG_KERNEL` | y | 4.19 上 `KALLSYMS_ALL` 的依赖 |
| `CONFIG_BATTERY_MT6357` | y | 必须内置：开 `MODULES` 后默认变 `=m`，会丢电量计 |
| `CONFIG_SND_SOC_MT6357_ACCDET` | y | 同上，耳机检测 |
| `CONFIG_KPROBES` | n | 本机 kprobe 不可用（会 bootloop） |
| `CONFIG_LOCALVERSION` | `-dandelion-ksu` | UTS 后缀 |

改动配置后务必对比纯净基线 `.config`，确认没有功能驱动被悄悄翻成 `=m`。

## 4. 打包

```bash
KERNEL_IMG=out-kernelsu/arch/arm64/boot/Image.gz \
  python3 build-tools/pack_boot.py <base-boot.img> out/boot-kernel.img
```

- 只替换 kernel 段，ramdisk / dtb / cmdline 原样保留
- 若底包带 AVB footer，再执行：
  ```bash
  python3 build-tools/recompute_avb.py <base-boot.img> out/boot-kernel.img out/boot-final.img
  ```
  无 footer 的底包（本机当前使用）直接刷 `out/boot-kernel.img`

## 5. 刷入与回滚

```bash
adb reboot bootloader
fastboot flash boot out/boot-final.img
fastboot reboot
```

回滚：`fastboot flash boot <base-boot.img>`。底包请长期保留。

## 6. 验收清单

- [ ] `adb shell uname -r` → `4.19.325-dandelion-ksu`
- [ ] 管理器显示 **工作中**（内核 35002-5 / 管理器 32680-5）
- [ ] `adb shell getenforce` → `Enforcing`
- [ ] 电量 / 充电状态正常（`dumpsys battery` 有 level/present）
- [ ] 授权 App 执行 `su -c id` → `uid=0 context=u:r:ksu:s0`
- [ ] `adb shell su -c dmesg | grep -i kernelsu`：无 panic / oops
- [ ] 开关屏、待机、重启后管理器仍正常

## 7. 调试构建（可选）

- `blossom_kernelsu_slub_defconfig`：SLUB 毒化（定位 UAF，会变慢）
- `blossom_kernelsu_kasan_defconfig`：KASAN（本机 MTK 4.19 无法启动，仅存档）

两者均为临时调试用，不要用于发布。
