#!/usr/bin/env bash
# Flash a KernelSU boot image on Redmi 9A (dandelion, MT6765).
#
# Requirements: adb + fastboot (platform-tools), unlocked bootloader.
# Usage: flash.sh <boot.img>        — fastboot (recommended, works in recovery state)
#        flash.sh --dd <boot.img>   — adb + dd while booted (needs working adbd root)
#
# Verify after boot (see docs/TESTING.md):
#   adb shell uname -r  -> 4.19.325-dandelion-ksu
#   adb shell getenforce -> Enforcing
#
# Rollback: fastboot flash boot <stock boot.img>  — always keep a copy of the
# stock image; it is both the packing base and the brick-proof fallback.
set -euo pipefail

MODE="fastboot"
if [ "${1:-}" = "--dd" ]; then MODE="dd"; shift; fi
IMG="${1:?usage: flash.sh [--dd] <boot.img>}"
BOOT_DEV="/dev/block/mmcblk0p33"

# checksum sidecar, when present
DIR=$(dirname "$IMG")
NAME=$(basename "$IMG")
if [ -f "$DIR/$NAME.sha256" ]; then
    echo "== verify checksum =="
    (cd "$DIR" && sha256sum -c "$NAME.sha256")
fi

if [ "$MODE" = "fastboot" ]; then
    echo "== reboot to bootloader =="
    adb reboot bootloader
    echo "waiting for fastboot device..."
    for _ in $(seq 1 30); do
        fastboot devices 2>/dev/null | grep -q . && break
        sleep 1
    done
    echo "== flash boot =="
    fastboot flash boot "$IMG"
    fastboot reboot
else
    echo "== push =="
    adb push "$IMG" /data/local/tmp/boot.img
    echo "== target must be ${BOOT_DEV} =="
    adb shell "readlink /dev/block/by-name/boot"
    read -rp "review the line above, press Enter to dd, or Ctrl+C to abort ... " _
    adb shell "dd if=/data/local/tmp/boot.img of=${BOOT_DEV} bs=4096 conv=fsync"
    adb shell "rm -f /data/local/tmp/boot.img"
    adb reboot
fi

echo
echo "== after boot (~2 min), verify =="
echo "  adb shell uname -r                 # 4.19.325-dandelion-ksu"
echo "  adb shell getenforce               # Enforcing"
echo "  KernelSU Manager connected; su -c id -> uid=0"
echo
echo "== rollback if needed =="
echo "  fastboot flash boot <stock-boot.img>   # or the previous release image"
