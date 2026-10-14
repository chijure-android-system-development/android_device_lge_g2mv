# TWRP device tree - LG D625 (g2mv)

**Device**: LG G2 Mini LTE / LG-D625  
**Codename**: g2mv  
**SoC**: NVIDIA Tegra 4i  
**CPU**: ARM Cortex-A9  
**Display**: 540x960, 32 bpp  
**Recovery base**: TWRP 3.1.1 / Android 4.4

This device tree builds a bootable TWRP recovery for the LG D625. It has been
tested on real hardware by loading the image temporarily with `fastboot boot`.
Display, touch, ADB and the main storage mounts work.

## Important display settings

The Tegra framebuffer has padding at the end of each row. These settings are
required to avoid a stretched or slanted interface:

```make
TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
DEVICE_RESOLUTION := 540x960
RECOVERY_GRAPHICS_FORCE_USE_LINELENGTH := true
RECOVERY_GRAPHICS_FORCE_SINGLE_BUFFER := true
TW_THEME := portrait_hdpi
```

`portrait_hdpi` has a 9:16 reference resolution and therefore scales evenly to
the D625 panel. The recovery header displays `3.1.1-0 by chijure` through
`TW_BUILD_AUTHOR`.

The file `recovery/graphics.c` is retained as a historical Tegra 4i reference
from the NVIDIA S8515/Wiko Wax device tree. It is not compiled by this tree;
the validated build uses TWRP's standard fbdev backend with the two settings
above.

## Boot image layout

The values were read from the original LG recovery image:

| Field | Value |
|---|---:|
| Kernel address | `0x10008000` |
| Ramdisk address | `0x11000000` |
| Second address | `0x10f00000` |
| Tags address | `0x10000100` |
| Page size | `2048` |
| Command line | `androidboot.hardware=g2mv vmalloc=440M` |
| Recovery partition size | `16777216` bytes |

The checked-in `prebuilt/kernel` is the kernel extracted from the original LG
recovery image. Its SHA-256 is:

```text
7273a61c75b31d6c5e620bb2ea6dd4cea53a8326e71438b43600acf8b8b67b38
```

## Partitions

The recovery uses the Tegra by-name paths exposed by the stock kernel:

| Mount point | Type | Partition |
|---|---|---|
| `/recovery` | emmc | `SOS` |
| `/boot` | emmc | `LNX` |
| `/system` | ext4 | `APP` |
| `/cache` | ext4 | `CAC` |
| `/data` | ext4 | `UDA` |
| `/misc` | emmc | `MSC` |
| `/staging` | emmc | `USP` |
| `/encrypt` | emmc | `MDA` |
| `/external_sd` | auto | external microSD partition 1 |

## Build

Place this repository at `device/lge/g2mv` in an Android 4.4 TWRP source tree:

```bash
source build/envsetup.sh
lunch omni_g2mv-eng
make -j$(nproc) recoveryimage
```

Output:

```text
out/target/product/g2mv/recovery.img
```

## Test without flashing

Boot the image temporarily from the unlocked bootloader:

```bash
fastboot boot out/target/product/g2mv/recovery.img
```

This command does not install the recovery. Verify the display, touch, ADB and
mounts before considering any permanent write. APX/nvflash is not required for
this test.

