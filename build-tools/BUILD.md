# 构建与维护指南 · Redmi 9A（dandelion）· KernelSU 线

> 本树在 4.19.325 基线上内置 KernelSU（BakaSU manual hook 模式，KPROBES=n 也可用）。
> 内核版本串 `4.19.325-dandelion-ksu`，KSU 版本号随源码冻结（v65 = 35002，
> 由 `drivers/kernelsu/Kbuild` 的 `KSU_LOCAL_VERSION` 计算：30000 + 本地偏移 + 700）。
> 纯基线线（pure-kernel）的 `build_full.sh` 在本树故意无法通过断言——
> 这里统一用 `build_ksu.sh` / `make_boot.sh`。

## 1. 环境要求

- WSL Ubuntu + clang 21 工具链（`/usr/lib/llvm-21/bin`，Ubuntu clang 21.1.8 / LLD 21.1.8）
- `aarch64-linux-gnu-` 交叉前缀（链接走 lld，仍保留前缀兼容 Kbuild）
- `python3`（打包脚本唯一依赖，纯标准库）
- **原厂 stock boot.img**（打包基底 + 一键回滚兜底）
  默认位置 `$HOME/android-kernel/pure-kernel/stock/boot.img`，可用 `BASE_BOOT=…` 覆盖
- 设备解锁后 `fastboot`（platform-tools）

```bash
# 工具链自检
ls /usr/lib/llvm-21/bin/clang && aarch64-linux-gnu-ld --version | head -1
```

## 2. 配置策略：`blossom_defconfig` + `ksu.config` 差量

配置分两层（不要直接编辑生成的 `out/.config`，那是一次性产物）：

1. `arch/arm64/configs/blossom_defconfig` —— 基线主体（性能线选项同源纯基线）
2. `build-tools/ksu.config` —— **KSU 线差量（权威，~15 项）**：
   - 开：`KSU`、`KSU_MANUAL_HOOK`(+3 AUTO_*)、`KSU_MULTI_MANAGER_SUPPORT`、
     `KSU_FULL_NAME_FORMAT`、`MODULES=y`、`KALLSYMS_ALL=y`
   - 关：`KPROBES`、`KSU_SUSFS`（评估搁档）、`KSU_DEBUG`、`KSU_TOOLKIT_SUPPORT`、
     `KSU_TRACEPOINT_HOOK`

改配置的正确做法：

```bash
# 1. 改 defconfig 或 build-tools/ksu.config
# 2. 重生成（一条龙：defconfig → 追加差量 → olddefconfig → 断言）
O=out bash build-tools/build_ksu.sh
# 3. 断言失败会点名不符项；修复后重跑，杜绝静默漂移
```

断言清单在 `build-tools/check_config.sh`（53 must-y / 18 must-n / 6 精确值，
基准 = v65 实测快照）。历史经验：Kconfig 依赖关系会"整条吃掉"看似无关的选项
（trusted_mem 三件套案例见清单内注释），所以新增同链路选项时**成组加入断言**。

## 3. 编译

```bash
# 一条龙（推荐）
O=out bash build-tools/build_ksu.sh

# 或手动复现核心步骤
export PATH=/usr/lib/llvm-21/bin:$PATH
make O=out ARCH=arm64 CC=clang CROSS_COMPILE=aarch64-linux-gnu- \
     LD=ld.lld NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump \
     STRIP=llvm-strip AR=llvm-ar blossom_defconfig
cat build-tools/ksu.config >> out/.config
make O=out olddefconfig ARCH=arm64 CC=clang
make O=out -j$(nproc) Image.gz ARCH=arm64 CC=clang …
```

- 产物：`out/arch/arm64/boot/Image.gz`
- 版本串：`UTS_RELEASE = 4.19.325-dandelion-ksu`
  （`CONFIG_LOCALVERSION="-dandelion-ksu"`，见 `out/include/generated/utsrelease.h`）
- **产物不是逐字节可复现的**（编译时间戳内嵌），验收以功能等价为准：
  ① UTS 串正确 ② KSU 功能自检（见 §6）③ Image.gz 落在正常尺寸区间

## 4. 打包：`make_boot.sh`（一条龙）

原理：原厂 boot.img（header v1/v2）**只替换 kernel 段**，ramdisk / dtb /
pagesize / cmdline 逐字节原封不动——因此任何"变砖回滚"都可以退回原厂镜像。

```bash
# 编译 + 打包 + 区域校验 + sha256，输出 out/boot-4.19.325-dandelion-ksu.img(.sha256)
O=out bash build-tools/make_boot.sh

# 手动打包（等价）
KERNEL_IMG=$PWD/out/arch/arm64/boot/Image.gz \
python3 build-tools/pack_boot.py <原厂boot.img> out/boot-xxx.img
```

`make_boot.sh` 内置区域校验：打包后再读回镜像，比对 ramdisk/dtb 段 md5 与基底**必须一致**，
不一致立即报 FATAL（基底不对或 pack 脚本被改动时兜底）。发布版文件名惯例：
`boot-4.19.325-dandelion-ksu-35002-vN.img`（加 `-vN` 用 `NAME=boot-…-vN.img` 覆盖）。

## 5. 刷入与回滚

```bash
adb reboot bootloader
fastboot flash boot out/boot-4.19.325-dandelion-ksu-35002-v65.img
fastboot reboot
```

- 变砖兜底（顺序）：last_boot 机制失效 → fastboot 刷**原厂 boot.img**（基底）
  → 还不行就刷上一个 release 版镜像。基底镜像务必长期保管。
- 附带 vbmeta 不用刷（MTK 解锁态自跳过 verify）。

## 6. 验证清单（刷后）

```bash
adb shell uname -r                 # = 4.19.325-dandelion-ksu
adb shell su -c id                 # uid=0（装官方 KernelSU 管理器授 root 后）
adb shell getenforce               # = Enforcing
adb shell cat /proc/version        # 里含 dandelion-ksu 与 clang 21.1.8
adb shell dmesg | grep -i kernelsu # KSU init 日志（Built-in 模式）；无 audit 刷屏
```

- 管理器：tiann 官方 v3.3.1(32680) 直连即可；签名白名单含 tiann/bbe8fc8d/15c4f235(BakaSU)
- 版本号核对：管理器显示的版本码应与 `drivers/kernelsu/Kbuild` 计算值一致（v65=35002）
- 标准验收矩阵（18 项：WiFi/基带/NFC-无/SUSFS-无 等）见仓库 TESTING 文档与 commits.md 台账

## 7. 发布流程摘要

1. `O=out bash build-tools/make_boot.sh` → 记录 sha256
2. 成品 + 管理器 APK 上传 GitHub Releases（版本 vN）
3. 台账 `commits.md` 追加行（commit 哈希、验证状态、发布链接）
4. XDA 帖不更新版本号（版本更新只走 Releases，见 xda/STATUS.md）
