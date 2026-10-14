#!/usr/bin/env python3
"""Extract prebuilt/kernel from a stock LG D625 boot or recovery image."""

import hashlib
import pathlib
import struct
import sys

EXPECTED_SHA256 = "7273a61c75b31d6c5e620bb2ea6dd4cea53a8326e71438b43600acf8b8b67b38"
OUTPUT = pathlib.Path(__file__).resolve().parent / "prebuilt" / "kernel"


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} <boot.img|recovery.img|boot.emmc.win>", file=sys.stderr)
        return 2

    data = pathlib.Path(sys.argv[1]).read_bytes()
    if data[:8] != b"ANDROID!":
        print("input is not an Android boot image", file=sys.stderr)
        return 1

    kernel_size, _, _, _, _, _, _, page_size = struct.unpack("<8I", data[8:40])
    kernel = data[page_size:page_size + kernel_size]
    digest = hashlib.sha256(kernel).hexdigest()
    if digest != EXPECTED_SHA256:
        print(f"unexpected kernel SHA-256 {digest}", file=sys.stderr)
        print(f"expected                  {EXPECTED_SHA256}", file=sys.stderr)
        return 1

    OUTPUT.parent.mkdir(exist_ok=True)
    OUTPUT.write_bytes(kernel)
    print(f"wrote {OUTPUT} ({kernel_size} bytes, SHA-256 verified)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
