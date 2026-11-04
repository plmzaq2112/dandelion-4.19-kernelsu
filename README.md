> **⚠️ 本分支（`main`）为旧文档线，不再更新。**
>
> 主线已迁移到 **`autohook`** 分支（默认分支）：
> https://github.com/plmzaq2112/kernel-ksu-dandelion/tree/autohook
>
> - 主线内核：4.19.325-dandelion-ksu（v66，BakaSU **auto-hook**，零内核源码钩子）
> - 构建/刷入/验收：见主线仓库的 `README.md` 与 `docs/BUILD.md`
> - 历史 v65（manual-hook）源码仍在 `bakasu` 分支

---

# KernelSU kernel for Redmi 9A (dandelion) — MT6765

A KernelSU-integrated kernel for the Redmi 9A / 9A Sport (dandelion), built on the
stock MediaTek MT6765 (Helio G25) kernel. KernelSU is compiled into the kernel, so
flashing the boot image is all it takes to get root — no kernel-flasher, no Magisk,
no per-boot setup.

- **Device:** Redmi 9A / 9A Sport — codename `dandelion` (MT6765 / Helio G25)
- **Kernel:** MediaTek stock 4.19 with KernelSU integrated (manual-hook, UAPI v5)
- **SELinux:** Enforcing
- **Manager:** official tiann KernelSU Manager — connects directly, no re-sign
- **Current release:** [v65](https://github.com/plmzaq2112/kernel-ksu-dandelion/releases/tag/v65) (4.19.325-dandelion-ksu, KSU 35002, UAPI v5)

## Build

Reproducible build guide: [`docs/BUILD.md`](docs/BUILD.md) — source on the
`bakasu` branch, one-shot `build_ksu.sh` / `make_boot.sh`, config asserted
against the v65 snapshot. After flashing, run
[`docs/TESTING.md`](docs/TESTING.md); if the device misbehaves,
[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Features

- Root via `su` (uid 0), per-app allowlist and per-app profiles
- Kernel-level sucompat — the stock `su` binary is redirected to ksud
- Module support: `post-fs-data.sh` / `service.sh` run at boot
- No kprobes / no ftrace — hooks patch the syscall table directly

## Modules

KernelSU 3.x mounts a module's `system/` directory only if a **metamodule** is
installed. Without one, file-replacing modules are not applied — this is expected
behaviour, not a bug. Script-only modules work out of the box.

## Repository layout

| Path | Contents |
|---|---|
| `bakasu` (branch) | kernel source + build tooling (`build-tools/`) — start at `docs/BUILD.md` |
| `main` (branch) | this page: docs, flash helpers, generic image utilities, APK checksums |
| `docs/` | `BUILD` / `TESTING` / `RELEASE` / `TROUBLESHOOTING` + full test reports |
| `flash/` | flash helpers (fastboot primary, adb-dd fallback) |
| `apk/` | manager APK checksum |
| `scripts/` | generic device / image helpers |
| `legacy/` | archived assets from superseded kernel lines (reference only) |

## Downloads

Boot images, the manager APK and their SHA256 checksums are published on the
[Releases](https://github.com/plmzaq2112/kernel-ksu-dandelion/releases) page.

```
fastboot flash boot <boot-image>.img
fastboot reboot
```

## Credits / license

- [KernelSU](https://github.com/tiann/KernelSU) by tiann — GPL-2.0
- MediaTek kernel source — GPL-2.0
- Not affiliated with Xiaomi, Google, or KernelSU.
