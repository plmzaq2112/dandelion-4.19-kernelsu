#!/bin/sh
# Validate the dandelion purity kernel configuration before building.
set -eu
cfg="${1:-.config}"
fail=0

need() {
	if ! grep -qx "$1" "$cfg"; then
		echo "MISSING: $1" >&2
		fail=1
	fi
}

deny() {
	if grep -q "^$1=" "$cfg"; then
		echo "UNEXPECTED: $1" >&2
		fail=1
	fi
}

need CONFIG_PSI=y
need CONFIG_LTO_NONE=y
need CONFIG_HZ_1000=y
need CONFIG_TEE=y
need CONFIG_MTK_M4U=y
need CONFIG_MTK_DEVAPC=y
need CONFIG_MTK_SEC_VIDEO_PATH_SUPPORT=y
need CONFIG_MTK_TRUSTED_MEMORY_SUBSYSTEM=y
need CONFIG_MTK_GPU_SUPPORT=y
need CONFIG_MTK_CCU=y
need CONFIG_IOSCHED_BFQ=y
need CONFIG_MTK_PBM=y
need CONFIG_MTK_LM_MODE=y
need 'CONFIG_DEFAULT_IOSCHED="bfq"'

deny CONFIG_ANDROID_DUMMY_LMK
deny CONFIG_WIREGUARD
deny CONFIG_SRANDOM

if [ "$fail" -ne 0 ]; then
	echo "purity config check FAILED" >&2
	exit 1
fi
echo "purity config check OK: $cfg"
