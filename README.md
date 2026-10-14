# TWRP device tree - LG D625 (g2mv)

**Device**: LG G2 Mini LTE / LG-D625  
**Codename**: g2mv  
**SoC**: NVIDIA Tegra 4i  
**CPU**: ARM Cortex-A9  
**Display**: 540x960, 32 bpp  
**Recovery base**: TWRP 3.1.1 / Android 4.4

This device tree builds a bootable TWRP recovery for the LG D625. It has been
tested on a D625 with firmware D62510c, both through `fastboot boot` and
installed to the recovery partition (SOS).

The stock bootloader rejects unsigned recovery images. The D625 needs the
patched EBT from
[lg-d625-tegra-bootloader-patch](https://github.com/chijure-android-system-development/lg-d625-tegra-bootloader-patch).
Prebuilt images are published in that repository's releases.

| Feature | Status |
|---|---|
| Display, touch, brightness, battery | Works (EMC floor fixes lines without USB) |
| ADB | Works |
| Internal storage (`/data/media`) | Works |
| Backup of System, Data and Boot (1945 MB, split archive) | Works, MD5 verified |
| Backup of LG/Icera partitions (MDM, CST, MPT, ...) | Works, matches raw `dd` dumps |
| Restore of Boot, System (split archive) and Data | Works, Android boots |
| Recovery via hardware keys (Vol- + Power taps) | Works |
| MicroSD (vfat): mount, read/write, backup to card | Works |
| MTP, exFAT, `/data` decryption | Not included |

## Entering recovery

### From Android or TWRP

```bash
adb reboot recovery
```

`adb reboot bootloader` (or TWRP's Reboot → Bootloader) opens fastboot. The
bootloader contains an NVIDIA menu for that mode ("Press <Volume Down> to
select, <Volume Up> for selection move", with a "Recovery mode" entry); this
path has not been tested yet. There is no key combination that enters
fastboot from power-off.

### With the keys (phone off)

The well-known LG combo ("release Power at the logo and press it again") does
not work on the D625. Tested sequence:

1. Power off and **unplug the USB cable**. The combo is ignored with USB.
2. Hold **Vol-** and keep it held until TWRP appears.
3. Hold **Power** until the LG logo appears.
4. **Release Power** as soon as the logo appears.
5. Immediately **tap Power 2-3 times**: press about 0.3 s, release about
   0.3 s. Very quick taps are not counted.
6. The "Factory Reset" screen appears and is confirmed by the held Vol-.
   TWRP starts.

This build sets `TW_IGNORE_MISC_WIPE_DATA`, so **no data is wiped** even though
the screen says "Factory Reset". Do not use this combo with stock recovery or
with a TWRP build without that flag: the bootloader writes
`recovery\n--wipe_data` to MSC and stock recovery will wipe `/data`.

Vol+ with USB connected enters LG download (LAF) mode instead.

### Why this sequence

Reverse-engineered from the D62510c bootloader (`LgeBootMain`, EBT offset
`0xc9d8`) and the D625 kernel (`arch/arm/mach-tegra/lge/board-pda-kbc.c`).
The power key is the MAX77660 `EN0` input; its interrupt register `GLBINT1`
(`0x07`) clears on read: press = `EN0_F` (`0x40`), release = `EN0_R` (`0x80`),
held 1 s = `EN0_1SEC` (`0x20`).

| Bootloader step | Requires | Window |
|---|---|---|
| Power-on check | Power held for at least 1 s | — |
| Boot-mode check | Vol- held, no USB cable (cable type `0xc`) | instant |
| Phase 1 | any new Power event (the release) | 0.75 s |
| Phase 2 | a read equal to `0x80` (a clean release) | 2.25 s |
| Phase 3 | another clean release while Vol- is held | 2.25 s |
| Factory Reset screen | Vol- confirms; Vol+ cancels and reboots | 10 s |

The register is polled every 150 ms, so a press and release inside the same
poll read as `0xc0` and are ignored. That is why taps must be slow.

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

### Display glitches without USB

Without USB nothing in recovery requests memory bandwidth, and EMC drops to
25.5 MHz. The display controller then cannot fetch the 540x960x32bpp
framebuffer (about 124 MB/s at 60 Hz) and short white horizontal lines appear.
With USB connected the UDC keeps EMC at 102 MHz or more, which hides it.

`recovery/root/init.recovery.g2mv.rc` mounts debugfs and sets the shared
`floor.emc` clock to 102 MHz on boot. Measured unplugged: before, EMC spent
seconds at 25.5 MHz with visible lines; after, it never went below 102 MHz and
no lines appeared.

`portrait_hdpi` has a 9:16 reference resolution and therefore scales evenly to
the D625 panel. The recovery header displays `3.1.1-1 by chijure` through
`TW_DEVICE_VERSION` and `TW_BUILD_AUTHOR`.

The file `recovery/graphics.c` is retained as a historical Tegra 4i reference
from the NVIDIA S8515/Wiko Wax device tree. It is not compiled by this tree;
the validated build uses TWRP's standard fbdev backend with the two settings
above.

## Boot image layout

The values were read from the original LG recovery image. The partition size
comes from the kernel GPT; nvflash reports 16 MiB for SOS, but the last 4 MiB
belong to the following DTB partition.

| Field | Value |
|---|---:|
| Kernel address | `0x10008000` |
| Ramdisk address | `0x11000000` |
| Second address | `0x10f00000` |
| Tags address | `0x10000100` |
| Page size | `2048` |
| Command line | `androidboot.hardware=g2mv vmalloc=440M` |
| Recovery/boot partition size | `12582912` bytes |

## Kernel

`prebuilt/kernel` is the unmodified stock LG kernel from firmware D62510c
(source: [android_kernel_lge_d625](https://github.com/chijure-android-system-development/android_kernel_lge_d625)).
The boot (LNX) and recovery (SOS) images carry the same kernel. Its SHA-256 is:

```text
7273a61c75b31d6c5e620bb2ea6dd4cea53a8326e71438b43600acf8b8b67b38
```

To regenerate it from your own stock boot image, stock recovery image or a
TWRP `boot.emmc.win` backup:

```bash
device/lge/g2mv/extract-kernel.py boot.emmc.win
```

The script refuses any kernel with a different SHA-256.

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

The data crypto footer lives in `MDA`, as in the stock fstab. This build does
not include decryption support, so an encrypted `/data` cannot be backed up.

These LG/Icera partitions are offered as optional raw-image backups. Back them
up once before installing any ROM:

| Mount point | Partition | Size |
|---|---|---:|
| `/modem` | `MDM` (Icera modem, ext4) | 16 MiB |
| `/cust` | `CST` (carrier customization, ext4) | 50 MiB |
| `/mpt` | `MPT` | 16 MiB |
| `/pst` | `PST` | 8 MiB |
| `/sns` | `SNS` | 8 MiB |
| `/rct` | `RCT` | 2 MiB |
| `/drm` | `DRM` | 8 MiB |
| `/sep` | `SEP` | 2 MiB |

## Build

Place this repository at `device/lge/g2mv` in an Android 4.4 TWRP source tree:

```bash
device/lge/g2mv/apply-recovery-patches.sh
source build/envsetup.sh
lunch omni_g2mv-eng
make -j$(nproc) recoveryimage
device/lge/g2mv/revert-recovery-patches.sh
```

The local patch fixes a TWRP 3.1.1 deadlock in the tar child processes. Those
children called GUI functions after `fork()`, which hung every `/system`
backup when it was split into multiple archives. The patch removes every GUI
call from the backup and restore children, including the error paths. The helper scripts apply it only for the build
and restore `bootable/recovery` afterward, which keeps the upstream source tree
clean. Always run the revert script after the build, including after a failed
build.

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

