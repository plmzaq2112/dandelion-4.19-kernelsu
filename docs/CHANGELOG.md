# 变更记录

## v66 — 2026-11-04

主线迁移到 **BakaSU auto-hook**，内核源码不再包含任何 KernelSU 钩子调用点。

- 内核：`4.19.325-dandelion-ksu`（PREEMPT，HZ=1000，SELinux Enforcing）
- 模块：BakaSU `auto-hook`（UAPI v5，`KSU_VERSION 35002`），官方管理器 v3.3.1 直连
- 钩子：execve/execveat、faccessat、newfstatat/fstat/fstat64、sys_reboot 走 inline
  hook；setuid、init.rc read、input、packages.list 走 LSM
- 修复：`CONFIG_BATTERY_MT6357` / `CONFIG_SND_SOC_MT6357_ACCDET` 强制内置
  （`CONFIG_MODULES` 导致电量计驱动变 `=m` 而无法读取电量）
- 加固：`fs/proc/task_mmu.c` 的 `show_map_vma` 对异常 `vm_file` 只记录日志并跳过，
  避免 `/proc/pid/maps` 触发内核 panic
- 修复：KernelSU `file_wrapper` 对 `anon_inode_mnt` 增加 `mntget()` 引用
- 构建：模块补丁与拉取脚本入库（`build-tools/fetch_kernelsu.sh` + `build-tools/patches/`）
- Release：https://github.com/plmzaq2112/kernel-ksu-dandelion/releases/tag/v66

## v65 — 2026-10-14

`bakasu` 分支（历史）：BakaSU manual-hook（4 处源码钩子），管理器直连。详细说明见该分支
`build-tools/BUILD.md` 与 v65 Release。

## v11ksu — 更早历史线

早期 KernelSU 集成（`v11ksu` 分支），已停止维护。
