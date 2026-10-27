#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# KSU 线一条龙「编译 + 打包 + 只换内核段验证 + sha256」
#
# 用法:
#   O=out        bash build-tools/make_boot.sh
#   BASE_BOOT=…  指定原厂基底镜像（默认 $HOME/android-kernel/pure-kernel/stock/boot.img）
#   IMG_NAME=…   覆盖输出文件名（默认 boot-<uts_release>.img；发布版惯例另加 -vN）
#                 （注意：不要叫 NAME —— 该名字在部分 WSL 互操作环境里有预置值，会静默抢走）
#
# 流程: build_ksu.sh 编译 → pack_boot.py 把 Image.gz 替换进原厂 boot
#       （ramdisk/dtb 逐字节原封不动）→ 区域校验 → sha256。
# 需要: 原厂 stock boot.img（打包基底与回滚兜底）。
set -euo pipefail
cd "$(dirname "$0")/.."

O=${O:-out}
BASE_BOOT=${BASE_BOOT:-$HOME/android-kernel/pure-kernel/stock/boot.img}
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:/usr/local/bin:$PATH

if [ ! -f "$BASE_BOOT" ]; then
    echo "ERROR: 原厂基底镜像不存在: $BASE_BOOT" >&2
    echo "  提供: BASE_BOOT=/路径/原始boot.img bash build-tools/make_boot.sh" >&2
    exit 1
fi

echo "=== [1/4] 编译 ==="
O="$O" bash build-tools/build_ksu.sh

REL=$(sed -n 's/^#define UTS_RELEASE "\(.*\)"$/\1/p' "$O/include/generated/utsrelease.h" | tail -1)
NAME=${IMG_NAME:-boot-$REL.img}
OUT="$O/$NAME"

echo "=== [2/4] 打包（基底 $BASE_BOOT）==="
KERNEL_IMG="$PWD/$O/arch/arm64/boot/Image.gz" \
    python3 build-tools/pack_boot.py "$BASE_BOOT" "$OUT"

echo "=== [3/4] 区域校验：只换内核段，ramdisk/dtb 必须与基底逐字节一致 ==="
python3 - "$BASE_BOOT" "$OUT" <<'PY'
import struct, sys, hashlib

def seg(p):
    with open(p, "rb") as f:
        d = f.read()
    page = struct.unpack_from("<I", d, 36)[0]
    ks   = struct.unpack_from("<I", d, 8)[0]
    rs   = struct.unpack_from("<I", d, 16)[0]
    ss   = struct.unpack_from("<I", d, 28)[0]
    ds   = struct.unpack_from("<I", d, 1648)[0] if len(d) >= 1648 + 4 else 0
    au = lambda x: ((x + page - 1) // page) * page
    ro = page + au(ks)
    do = page + au(ks) + au(rs) + au(ss)
    md5 = hashlib.md5
    return ks, md5(d[ro:ro+rs]).hexdigest(), md5(d[do:do+ds]).hexdigest()

bk, br, bd = seg(sys.argv[1])
ok, orr, od = seg(sys.argv[2])
assert br == orr and bd == od, "FATAL: ramdisk/dtb 与基底不一致 —— 基底镜像不对或 pack 脚本有 bug"
print("PASS: ramdisk/dtb 原封不动；内核段 %d → %d bytes" % (bk, ok))
PY

echo "=== [4/4] sha256 ==="
sha256sum "$OUT" | tee "$OUT.sha256"

echo
echo "=== 完成 ==="
echo "  可刷镜像 : $PWD/$OUT"
echo "  刷入     : adb reboot bootloader && fastboot flash boot $PWD/$OUT"
echo "  兜底回滚 : fastboot flash boot <原厂 boot 或上一版镜像>"
