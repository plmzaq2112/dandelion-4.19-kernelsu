# 故障排除（autohook 主线）

## 刷完开不了机 / 循环重启

1. 长按电源 10~15 秒强制关机
2. 按住「音量下」插 USB 进 fastboot
3. 刷回底包：

```bash
fastboot flash boot <base-boot.img>
fastboot reboot
```

底包（可启动的同版本 boot.img）是唯一可靠的回滚手段，请长期保留。

**历史提醒**：不要启用 `CONFIG_KPROBES`（本机 kprobe 不可用，v0.9.5/kprobe 路线会
bootloop）。KASAN 构建在这棵 MTK 4.19 上也无法启动（早期崩溃，无日志）。

## 管理器显示「需要更新内核」

- 本线内核应报告 `KSU_VERSION=35002`、`KERNEL_SU_UAPI_VERSION=5`
- 管理器低于 v3.3.1 或内核被别人替换成旧线（如 `bakasu` v65）时会出现该提示
- 确认 `uname -r` 为 `4.19.325-dandelion-ksu`

## 管理器显示「未安装」/ 识别不了

1. 确认刷的是本线镜像（`uname -r` 带 `-dandelion-ksu`）
2. 在管理器运行状态下重装一次管理器 APK（触发 `packages.list` 重建，内核学习管理器
   UID）：

```bash
adb install -r KernelSU_v3.3.1_32680-release.apk
```

3. 重新打开管理器；仍不行时抓日志：

```bash
adb logcat -d | grep -iE "kernelsu|ksud"
```

## 电量读不出来 / 充电状态不更新

开启 `CONFIG_MODULES` 后，MT6357 电源驱动默认会变成 `=m`，而 boot 镜像不带 `.ko`，
于是 `/sys/class/power_supply/battery` 整个消失。本线已显式内置：

```
CONFIG_BATTERY_MT6357=y
CONFIG_SND_SOC_MT6357_ACCDET=y
```

改配置后请对比纯净基线 `.config`，确认没有功能驱动被悄悄翻成 `=m`。

## `adb shell su` 提示 not found

正式版（`KSU_DEBUG` 关闭）不会给 shell（uid 2000）自动放行 root。这属预期：

- 应用授权 root 正常
- 需要 shell root 调试时，用 `CONFIG_KSU_DEBUG=y` 构建（v66 之前调试镜像即如此）

## 模块的 `system/` 不生效

KernelSU 3.x 设计如此：需要 metamodule（Hybrid Mount / meta-overlayfs）才会挂载模块的
`system/` 目录。纯脚本模块（`post-fs-data.sh` / `service.sh`）不受影响。

## `maps: invalid vm_file ...` 日志

内核在 `/proc/pid/maps` 输出时检测到异常/失效的 `vm_file`，已做加固：记录一条限速
日志并跳过该条目，不再 panic。若频繁出现，请把完整 dmesg 行反馈（含 `comm/pid/`
`file/inode/f_count`），用于定位是否有人提前释放了文件对象。

## 强制重启后 adb 显示 offline

1. 拔插 USB
2. 开发者选项里关闭再打开「USB 调试」
3. 仍不行再重启一次设备

## NFC 相关 ANR

dandelion 无 NFC 硬件，`com.android.nfc` 的 ANR 循环是 ROM 自带行为，与内核无关。
