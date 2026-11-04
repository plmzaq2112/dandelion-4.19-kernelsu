#!/bin/bash
# Fetch the BakaSU auto-hook module and apply this tree's local patches.
# Result: KernelSU/ repo + drivers/kernelsu symlink (as expected by Kbuild).
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT"

if [ ! -d KernelSU/.git ]; then
  git clone --depth 1 --branch auto-hook https://github.com/Baka-SU/BakaSU.git KernelSU
fi
cd KernelSU
# apply local patches if not already present
if ! git log --oneline -8 | grep -q 'pin anon_inode_mnt'; then
  for p in "$ROOT"/build-tools/patches/*.patch; do
    git am "$p"
  done
fi
cd "$ROOT"
ln -sfn ../KernelSU/kernel drivers/kernelsu
ls -l drivers/kernelsu
echo "KernelSU ready."
