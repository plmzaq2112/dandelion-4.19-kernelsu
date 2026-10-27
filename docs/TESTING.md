# Flash-time acceptance checklist

Run after **every** flash. This is the distilled version of the full
[v65 test report](v65-test-report.md) (20-item matrix with evidence).

## Gate checks — any failure means do not ship

- [ ] boots to home screen, no bootloop, no stuck logo
- [ ] `adb shell uname -r` → `4.19.325-dandelion-ksu`
- [ ] `adb shell getenforce` → `Enforcing` (no permissive cmdline, anywhere)
- [ ] KernelSU Manager shows *working*, connects on first launch **and** after reboot
- [ ] granted app: `su -c id` → `uid=0`, context `u:r:ksu:s0`
- [ ] revoke the grant → `su` denied; re-grant → works again
- [ ] grant survives reboot (test ×3–4)
- [ ] `dmesg`: KSU init line present; no panic / oops / BUG; no new `avc:` storm

## Feature matrix (v65 reference)

| Area | Check | v65 |
|---|---|---|
| Communication | manager recognizes kernel | PASS |
| Communication | reconnect after reboot | PASS |
| Communication | kernel ↔ manager protocol match | PASS |
| SU | granted app gets root | PASS |
| SU | un-granted caller refused (behavioural) | PASS |
| SU | revoke takes effect immediately | PASS |
| SU | grant persists across restart | PASS |
| App Profile | configuration surface | PASS |
| App Profile | changes apply live to new sessions | PASS |
| Modules | install | PASS |
| Modules | activate after reboot | PASS |
| Modules | `system/` file mount *(needs metamodule)* | PASS¹ |
| Modules | `post-fs-data.sh` / `service.sh` run | PASS |
| Modules | disable / uninstall clean | PASS |
| System | SELinux enforcing, no avc noise | PASS |
| System | app/system compatibility | PASS² |
| System | root available after reboot | PASS |
| System | kernel log healthy | PASS |

¹ KernelSU 3.x mounts module `system/` **only** with a metamodule installed —
by design (see the Modules section of the README). Script-only modules work
without one.
² `com.android.nfc` ANR loop is *stock* behaviour on dandelion (no NFC
hardware, `CONFIG_NFC` off) — not a kernel regression; source-verified
(NFC HAL cannot register without `/dev/nfc*`).

## Device quirks worth knowing

- device clock may show a stale date — harmless, untouched operations
- after `adb` interactions the screen often needs waking:
  `adb shell "input keyevent 224; wm dismiss-keyguard"`
- `svc power stayon usb` keeps the device awake during long test sessions
