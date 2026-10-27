#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# KSU 线一键生成：defconfig → 追加 ksu.config → olddefconfig → 断言 → 编译 Image.gz
#
# 用法:
#   O=out        bash build-tools/build_ksu.sh   # 常规输出到 out/
#   O=out-fresh  bash build-tools/build_ksu.sh   # 全新目录从零构建
#   JOBS=8       ...                             # 覆盖并发（默认 nproc）
#
# 注意：不要用 build_full.sh（那是纯基线流程，不合入 KSU 片段，会卡在断言）。
# 打包成可刷入的 boot 镜像用：O=<out> bash build-tools/make_boot.sh
set -euo pipefail
cd "$(dirname "$0")/.."

O=${O:-out}
LOG=${LOG:-$O/build.log}
JOBS=${JOBS:-$(nproc)}
mkdir -p "$O"
export PATH=/usr/lib/llvm-21/bin:/usr/bin:/bin:/usr/local/bin:$PATH

MAKE_ARGS=(
    ARCH=arm64
    O="$O"
    CC=clang
    CROSS_COMPILE=aarch64-linux-gnu-
    LD=ld.lld
    NM=llvm-nm
    OBJCOPY=llvm-objcopy
    OBJDUMP=llvm-objdump
    STRIP=llvm-strip
    AR=llvm-ar
)

echo "=== [1/5] 生成 $O/.config（blossom_defconfig）==="
make "${MAKE_ARGS[@]}" blossom_defconfig

echo "=== [2/5] 追加 KSU 差量并重解析（olddefconfig）==="
cat build-tools/ksu.config >> "$O/.config"
make "${MAKE_ARGS[@]}" olddefconfig

echo "=== [3/5] 断言 ==="
bash build-tools/check_config.sh "$O/.config"

echo "=== [4/5] 编译 Image.gz（日志: $LOG）==="
# set -e + pipefail 会让失败管道立刻退出本脚本（tee 吞掉 make 的 rc），
# rc=${PIPESTATUS[0]} 永远执行不到 —— 必须临时放开。
set +e
make -j"$JOBS" "${MAKE_ARGS[@]}" Image.gz 2>&1 | tee "$LOG"
rc=${PIPESTATUS[0]}
set -e

if [ "$rc" -ne 0 ]; then
    echo "=== 编译 FAILED (rc=$rc) ==="
    grep -E 'error:' "$LOG" | head -20 || true
    exit "$rc"
fi

echo "=== [5/5] build OK ==="
echo "  image : $O/arch/arm64/boot/Image.gz ($(stat -c%s "$O/arch/arm64/boot/Image.gz") bytes)"
echo "  uts   : $(grep UTS_RELEASE "$O/include/generated/utsrelease.h" | tail -1)"
echo "  next  : O=\"$O\" bash build-tools/make_boot.sh"
