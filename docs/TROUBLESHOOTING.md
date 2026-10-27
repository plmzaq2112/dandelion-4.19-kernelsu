# Troubleshooting

## Device does not boot after flashing

1. reboot to bootloader (usually recoverable with `fastboot`):
   ```bash
   fastboot flash boot <stock-boot.img>      # brick-proof fallback
   # or
   fastboot flash boot <previous-release.img>
   ```
2. always keep a copy of the **stock** dandelion boot.img — it is the packing
   base AND the last-resort rollback target
3. capture evidence before flashing again: `adb shell dmesg`, `logcat`

## Manager says "not installed" / `su` fails

- `adb shell uname -r` — must end with `-dandelion-ksu` (check you flashed the
  right image).
- `adb shell getenforce` — must be `Enforcing`; this line ships no permissive
  cmdline patch.
- manager/kernel pairing: this line uses UAPI v5, KSU version code 35002;
  the official tiann KernelSU Manager 3.3.1 (32680) connects directly.
  Old v2-era managers (e.g. 32601 "gkipatched") belong to the retired
  v11ksu line and will not pair.
- watch `adb shell dmesg | grep -i kernelsu` for the init line.
- **fresh manager install needs the Shell superuser toggle** — without it,
  `su` reports *not found* for uid 2000 even though the kernel is working.
  A fresh manager install starts with `allow_shell=false` (non-DEBUG build,
  `core/init.c`).
- **quirk: while `adb root` is active, `su` "disappears"** — adbd runs as uid 0
  and KernelSU's sucompat hook only redirects `/system/bin/su` lookups for
  uid-2000 processes (already-root callers are left alone). Run `adb unroot`
  and the granted `su -c id` → `uid=0 context=u:r:ksu:s0` works again.

## Modules don't apply

- **file-replacing modules need a metamodule** (KernelSU 3.x design — without
  one, `system/` is never mounted and *nothing is reported*); install e.g.
  Hybrid Mount or meta-overlayfs. Script-only modules work without it.
- verify scripts ran: `post-fs-data.sh` / `service.sh` markers +
  `ksud debug` logs at boot.

## adb / fastboot quirks (this device)

- clock stuck on a stale date — cosmetic, ignore
- `adb devices` empty: toggle USB debugging, try `svc power stayon usb`,
  wake the screen first:
  `adb shell "input keyevent 224; wm dismiss-keyguard"`
- device drops into recovery state after long idle: `adb reboot` normally

## Unexpected SELinux denials

- v65 baseline ran with **zero** new `avc:` denials; anything above that is a
  regression — capture `dmesg` before/or recover and bisect the change
  (`check_config.sh` asserts the SELinux options, so config drift is unlikely)
