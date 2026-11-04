# 测试与验收（autohook 主线）

对应发布版本：**v66**（内核 `4.19.325-dandelion-ksu`，KSU 35002 / UAPI 5）。

## 刷后必查（Gate）

- [ ] 能正常开机，无 bootloop / 卡 logo
- [ ] `adb shell uname -r` → `4.19.325-dandelion-ksu`
- [ ] `adb shell getenforce` → `Enforcing`
- [ ] 管理器显示 **工作中**（内核 35002-5 / 管理器 32680-5）
- [ ] 电量 / 充电状态正常：`adb shell dumpsys battery` 有 `level`、`present: true`
- [ ] 授权任意 App 后 `su -c id` → `uid=0 context=u:r:ksu:s0`
- [ ] 重启一次后管理器仍“工作中”，授权仍有效

## 稳定性检查

```bash
# 内核异常扫描（需要有 root；正式版可在管理器授权终端 App 后执行）
adb shell "su -c dmesg" | grep -iE "Internal error|Oops|panic|BUG:"
```

- 无输出 = 干净
- 若出现 `maps: invalid vm_file ...`：属已知 `/proc/pid/maps` 加固日志，附完整行反馈即可，不会崩内核

轻量压力（不要用 exec 风暴）：

```sh
# 单进程内循环读取 own maps，无 fork
i=0; while [ $i -lt 3000 ]; do
  while IFS= read -r l <&3; do :; done 3</proc/self/maps
  i=$((i+1))
done
```

## 功能矩阵

| 项目 | 检查 | v66 |
|---|---|---|
| 管理器识别 | 首次启动即连接，重启后仍连接 | PASS |
| Root | 授权 App → `uid=0`，撤销后拒绝 | PASS |
| 授权持久化 | 重启 ×3 后仍有效 | PASS |
| 模块 | 安装、启用、`post-fs-data.sh`/`service.sh` 执行 | PASS |
| 模块 `system/` | 需 metamodule（Hybrid Mount / meta-overlayfs），未装不生效属预期 | 说明 |
| 充电/电量 | 插拔、待机、开关屏状态正确 | PASS |
| SELinux | 强制，无新增 `avc: denied` 刷屏 | PASS |

## 已知非问题

- `com.android.nfc` ANR 循环：dandelion 无 NFC 硬件，ROM 自带行为
- 本底包 exec 延迟偏高（~19ms/次），纯净内核同样如此，与 KernelSU 无关
- 息屏后 `Emergency Sync` 日志：系统 drop_caches 触发，正常
