#!/bin/bash
#
# Apply the g2mv changes to LineageOS/CyanogenMod 11 projects.
# Run from the top of the CM 11 source tree:
#
#   device/lge/g2mv/patches/apply-patches.sh
#
# Already applied patches are detected and skipped, so the script can be run
# again after a repo sync.

set -e

TOP=$(pwd)
PATCHES=$(cd "$(dirname "$0")" && pwd)

if [ ! -f "$TOP/build/envsetup.sh" ]; then
    echo "Run this from the top of the CM 11 source tree" >&2
    exit 1
fi

# project directory : patch file
LIST="
bionic:bionic-raise-tgkill.patch
system/core:init-chargerlogo.patch
frameworks/av:frameworks-av-omx-node-instance.patch
external/libnfc-nci:libnfc-nci-reset-recovery.patch
packages/apps/Camera2:camera2-video-quality-defaults.patch
packages/apps/LockClock:lockclock-bound-gps-weather-location.patch
"

failed=0
for entry in $LIST; do
    project=${entry%%:*}
    patch=$PATCHES/${entry##*:}

    if git -C "$TOP/$project" apply --check -R "$patch" 2>/dev/null; then
        echo "already applied: ${entry##*:} ($project)"
    elif git -C "$TOP/$project" apply --check "$patch" 2>/dev/null; then
        git -C "$TOP/$project" apply "$patch"
        echo "applied:         ${entry##*:} ($project)"
    else
        echo "FAILED:          ${entry##*:} ($project)" >&2
        failed=1
    fi
done

exit $failed
