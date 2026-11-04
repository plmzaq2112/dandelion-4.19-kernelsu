# dandelion-4.19-kernelsu

Xiaomi Redmi 9A（`dandelion`，MT6765）的 KernelSU 内核仓库，基于 Linux 4.19.325。
适配该机型的常见 Android 版本，不绑定特定系统版本。

## 简介

- **主线分支**：`autohook`（默认分支）
- **内核**：`4.19.325-dandelion-ksu`（PREEMPT / HZ=1000 / SELinux Enforcing）
- **KernelSU**：BakaSU `auto-hook`（UAPI v5，版本码 35002）
- **管理器**：tiann 官方 KernelSU v3.3.1，直连免重签
- **特点**：零内核源码钩子 —— execve/faccessat/stat/reboot 等由运行时 inline hook
  安装，setuid/init.rc/input/packages.list 由 LSM 安装，`fs/*`、`kernel/*` 无钩子调用点

## 构建与使用

```bash
bash build-tools/fetch_kernelsu.sh   # 拉取 KernelSU 模块并打补丁
make ARCH=arm64 O=out-kernelsu ... blossom_kernelsu_defconfig
make ARCH=arm64 O=out-kernelsu ... Image.gz
```

完整的环境、打包、刷入与回滚见 [docs/BUILD.md](docs/BUILD.md)；
刷后验收见 [docs/TESTING.md](docs/TESTING.md)；
常见问题见 [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)。

## 下载与更新日志

固件镜像、管理器 APK 及每个版本的变更说明都在
[Releases](https://github.com/plmzaq2112/dandelion-4.19-kernelsu/releases) 页面。

## 分支

| 分支 | 说明 |
|---|---|
| `autohook` | 主线，零源码钩子（本分支） |
| `bakasu` | v65 历史线，manual-hook |
| `main` | 旧文档线 |
| `v11ksu` | 更早历史线 |

## 说明

- dandelion 无 NFC 硬件，`com.android.nfc` 的 ANR 属 ROM 自带行为
- 模块 `system/` 目录需 metamodule（如 Hybrid Mount）才会挂载
- 不包含 susfs / root 隐藏类特性

## 许可

内核遵循 `COPYING` 及各文件自带许可证；KernelSU 模块来自
[BakaSU](https://github.com/Baka-SU/BakaSU)（GPL-2.0）。
