# scripts/

Generic device / image helpers only.

| Script | Purpose |
|---|---|
| `extract_stock_config.sh` | dump the kernel config out of a stock kernel image |
| `extract_stock_kernel.sh` | pull the kernel image out of a stock `boot.img` |

Version-specific build/pack/recover helpers from superseded kernel lines were
moved to [`../legacy/`](../legacy/README.md).

Current build tooling: **`bakasu` branch, `build-tools/`** — see
[`docs/BUILD.md`](../docs/BUILD.md) for the reproducible build pipeline
(`build_ksu.sh` / `make_boot.sh` / `check_config.sh` / `ksu.config`).
