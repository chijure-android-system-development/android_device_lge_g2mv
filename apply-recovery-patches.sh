#!/bin/bash

set -euo pipefail

if [[ ! -f build/envsetup.sh || ! -f bootable/recovery/twrpTar.cpp ]]; then
    echo "Run this script from the root of the TWRP source tree." >&2
    exit 1
fi

device_dir="device/lge/g2mv"
patch_file="$device_dir/patches/0001-twrpTar-avoid-gui-calls-in-forked-children.patch"

if patch --dry-run --silent -d bootable/recovery -p1 < "$patch_file"; then
    patch --silent -d bootable/recovery -p1 < "$patch_file"
    echo "Applied twrpTar fork patch."
elif patch --dry-run --silent --reverse -d bootable/recovery -p1 < "$patch_file"; then
    echo "twrpTar fork patch is already applied."
else
    echo "Patch does not apply cleanly to bootable/recovery." >&2
    exit 1
fi
