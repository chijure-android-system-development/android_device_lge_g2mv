#!/bin/bash

set -e

DEVICE=g2mv
VENDOR=lge
SRC="${1:-adb}"
BASE=../../../vendor/$VENDOR/$DEVICE/proprietary

cd "$(dirname "$0")"
rm -rf "$BASE"
mkdir -p "$BASE"

while IFS= read -r FILE; do
    case "$FILE" in
        ''|'#'*) continue ;;
    esac

    mkdir -p "$BASE/$(dirname "$FILE")"
    if [ "$SRC" = adb ]; then
        adb pull "/$FILE" "$BASE/$FILE"
    else
        cp -p "$SRC/$FILE" "$BASE/$FILE"
    fi
done < proprietary-files.txt

./setup-makefiles.sh
