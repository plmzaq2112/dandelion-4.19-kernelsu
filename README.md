# dandelion-4.19-kernelsu — `bakasu`（v65 历史分支）

> **状态：冻结，不再更新。** 主线已迁移到 `autohook`（默认分支）：
> https://github.com/plmzaq2112/dandelion-4.19-kernelsu/tree/autohook
>
> 下载与更新日志统一在 Releases 发布：
> https://github.com/plmzaq2112/dandelion-4.19-kernelsu/releases

## 内容

Xiaomi Redmi 9A（`dandelion`，MT6765）的 Linux 4.19.325 KernelSU 内核源码，
v65 线，采用 BakaSU **manual-hook** 集成（内核源码中 4 处钩子调用点）。

- 内核版本串：`4.19.325-dandelion-ksu`
- KernelSU：UAPI v5，`KSU_VERSION 35002`
- 管理器：tiann 官方 KernelSU（直连免重签）
- SELinux：Enforcing

## 构建

本分支的构建脚本与断言在 `build-tools/`：

- `build-tools/BUILD.md`：构建、打包、刷入说明
- `build_ksu.sh` / `make_boot.sh`：一键编译与打包
- `check_config.sh` + `ksu.config`：配置断言

## 相关

- v65 Release：https://github.com/plmzaq2112/dandelion-4.19-kernelsu/releases/tag/v65
- 主线（零源码钩子）：`autohook` 分支
