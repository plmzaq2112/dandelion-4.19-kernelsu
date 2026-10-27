#!/bin/bash
# SPDX-License-Identifier: GPL-2.0
#
# 配置断言（KSU 线 / bakasu 分支）：防止 olddefconfig 或 Kconfig 依赖
# 关系静默改动关键选项。断言基准 = v65 实测内核快照。
#
# 与纯基线线（pure-kernel）的差异：
#   - KSU 由 must_n 改为 must_y（manual hook 模式，不依赖 KPROBES）
#   - MODULES=y（ksud 模块功能需要）
#   - KALLSYMS_ALL=y（v65 实测，KPROBES 关闭时 KSU 运行期与调试都要全符号）
#   - KPROBES 系列进 must_n（本设备 KCONFIG 无 KProbes）
#   - KSU_SUSFS 保持关闭（评估搁档，见 research/susfs-evaluation.md）
#
# 用法:  bash build-tools/check_config.sh [path/to/.config]
#        默认检查 out/.config
#
# 退出码: 0 = 全部通过, 1 = 有不符项
#
CFG=${1:-out/.config}
fail=0

if [ ! -f "$CFG" ]; then
    echo "check_config: $CFG 不存在（先跑 make blossom_defconfig 或 build_ksu.sh）"
    exit 1
fi

# 必须开启
must_y=(
    # KSU 核心（manual hook；KPROBES=n 兼容）
    KSU KSU_MANUAL_HOOK
    KSU_MANUAL_HOOK_AUTO_SETUID_HOOK KSU_MANUAL_HOOK_AUTO_INITRC_HOOK
    KSU_MANUAL_HOOK_AUTO_INPUT_HOOK KSU_MULTI_MANAGER_SUPPORT
    # 模块系统（ksud 模块功能需要 y）
    MODULES
    # 性能取向（与纯基线同源，v65 实测全部保留：BFQ / io_uring / BBR…）
    DEFAULT_BFQ IOSCHED_BFQ BFQ_GROUP_IOSCHED
    IO_URING KSM PSI UCLAMP_TASK UCLAMP_TASK_GROUP SECRETMEM WIREGUARD
    PREEMPT
    # SELinux 强制
    SECURITY_SELINUX DEFAULT_SECURITY_SELINUX
    # 文件系统
    EROFS_FS FS_VERITY
    # 调度/内存基础
    CGROUPS MEMCG BLK_CGROUP CGROUP_SCHED
    TCP_CONG_BBR NET_SCH_FQ KALLSYMS_BASE_RELATIVE
    BATTERY_MT6357 SND_SOC_MT6357_ACCDET
    # 基础加固（已验证开启）
    STACKPROTECTOR_STRONG HARDENED_USERCOPY SLAB_FREELIST_HARDENED
    SLAB_FREELIST_RANDOM REFCOUNT_FULL SECCOMP
    # TEE / Keymaster / 安全媒体链（Widevine L1，勿拆）
    TEE MICROTRUST_TEE_SUPPORT MICROTRUST_TZ_DRIVER
    MICROTRUST_DYNAMIC_CORE MICROTRUST_VFS_DRIVER
    MICROTRUST_KEYMASTER_DRIVER MICROTRUST_TZ_LOG
    MTK_SEC_VIDEO_PATH_SUPPORT MTK_DRM_KEY_MNG_SUPPORT MTK_ION_SEC_HEAP
    MTK_SECURE_MEM_SUPPORT
    # trusted_mem 三件套一起断（缺 HAVE_ 会被 Kconfig 整条吃掉，见纯基线注释）
    HAVE_MTK_TRUSTED_MEMORY_SUBSYSTEM MTK_TRUSTED_MEMORY_SUBSYSTEM MTK_SSMR
    # 防御纵深
    ARM64_SW_TTBR0_PAN
    # kallsyms：v65 起全符号（KPROBES=n 时 KSU 运行期自检与排障都需要）
    KALLSYMS KALLSYMS_ALL
)

# 必须关闭
must_n=(
    # KPROBES 系列保持关闭（设备 KCONFIG 约束；manual hook 不依赖它）
    KPROBES
    # KSU 调试与 SUSFS（评估搁档）
    KSU_SUSFS KSU_DEBUG KSU_TOOLKIT_SUPPORT KSU_TRACEPOINT_HOOK
    # dandelion 无指纹/NFC 硬件
    MICROTRUST_FP_DRIVER FPC_FINGERPRINT FOCALTECH_FINGERPRINT NFC
    # 遗留拥塞控制（ModuleS=y 下仍锁定关闭，v65 实测口径）
    TCP_CONG_BIC TCP_CONG_WESTWOOD
    # 调试/性能损耗项
    KASAN UBSAN DEBUG_PREEMPT DEBUG_INFO
    # 无用噪音
    IKHEADERS
)

# 精确值
must_eq=(
    "HZ=1000"
    "HZ_1000=y"
    'MICROTRUST_TEE_VERSION="300"'
    'DEFAULT_IOSCHED="bfq"'
    'DEFAULT_TCP_CONG="bbr"'
    'KSU_FULL_NAME_FORMAT="%REPO_NAME%-%COMMIT_SHA%"'
)

for c in "${must_y[@]}"; do
    if ! grep -q "^CONFIG_${c}=y" "$CFG"; then
        echo "  MISSING(y): CONFIG_${c}"
        fail=1
    fi
done

for c in "${must_n[@]}"; do
    if grep -qE "^CONFIG_${c}=" "$CFG"; then
        echo "  VIOLATION(n): CONFIG_${c} = $(grep -E "^CONFIG_${c}=" "$CFG" | head -1 | cut -d= -f2-)"
        fail=1
    fi
done

for kv in "${must_eq[@]}"; do
    if ! grep -q "^CONFIG_${kv}$" "$CFG"; then
        echo "  WRONG VALUE: expected CONFIG_${kv}, got: $(grep -E "^# CONFIG_${kv%%=*} is not set|^CONFIG_${kv%%=*}=" "$CFG" | head -1)"
        fail=1
    fi
done

n_y=${#must_y[@]}
n_n=${#must_n[@]}
n_e=${#must_eq[@]}

if [ "$fail" -eq 0 ]; then
    echo "check_config: OK ($n_y must-y, $n_n must-n, $n_e exact)"
else
    echo "check_config: FAILED — 请检查 arch/arm64/configs/blossom_defconfig 与 build-tools/ksu.config"
    echo "  （KSU 线请过 build-tools/build_ksu.sh；build_full.sh 不合入 KSU 片段，属纯基线流程）"
    exit 1
fi
