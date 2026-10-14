DEVICE_PATH := device/lge/g2mv

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_CPU_SMP := true

TARGET_BOARD_PLATFORM := tegra
TARGET_BOOTLOADER_BOARD_NAME := g2mv
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true

# Values read from the live D625 recovery header.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
BOARD_KERNEL_CMDLINE := androidboot.hardware=g2mv vmalloc=440M
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 \
    --ramdisk_offset 0x01000000 \
    --tags_offset 0x00000100

# LNX and SOS are 12 MiB in the kernel GPT (24576 sectors). nvflash reports
# 16 MiB for SOS, but the extra 4 MiB belong to the following DTB partition.
BOARD_BOOTIMAGE_PARTITION_SIZE := 12582912
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 12582912
BOARD_FLASH_BLOCK_SIZE := 4096
# eMMC has no NAND spare area. Without this the 4.4 size check scales the
# partition by 2112/2048 and accepts images up to 12845184 bytes.
BOARD_NAND_SPARE_SIZE := 0

TARGET_USERIMAGES_USE_EXT4 := true
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"
DEVICE_RESOLUTION := 540x960
BOARD_USE_SKIA_LCDTEXT := true
RECOVERY_GRAPHICS_FORCE_USE_LINELENGTH := true
RECOVERY_GRAPHICS_FORCE_SINGLE_BUFFER := true
TW_NO_SCREEN_BLANK := true

# The only key combo (Vol- + Power, USB unplugged) goes through LG's factory
# reset screen, which writes "recovery\n--wipe_data" to MSC. Open TWRP instead
# of wiping /data.
TW_IGNORE_MISC_WIPE_DATA := true

# 1080x1920 has the same 9:16 aspect ratio as the D625 framebuffer (540x960),
# avoiding the non-uniform 480x800 -> 540x960 scaling of portrait_mdpi.
TW_THEME := portrait_hdpi
TW_BUILD_AUTHOR := chijure
TW_DEVICE_VERSION := 1
TW_BRIGHTNESS_PATH := /sys/devices/platform/pwm-backlight/backlight/pwm-backlight/brightness
TW_MAX_BRIGHTNESS := 255
TW_INTERNAL_STORAGE_PATH := /data/media
TW_INTERNAL_STORAGE_MOUNT_POINT := sdcard
TW_EXTERNAL_STORAGE_PATH := /external_sd
TW_EXTERNAL_STORAGE_MOUNT_POINT := external_sd
RECOVERY_SDCARD_ON_DATA := true
TARGET_USE_CUSTOM_LUN_FILE_PATH := /sys/devices/platform/tegra-udc.0/gadget/lun0/file

# Keep the first diagnostic build small and avoid unverified crypto/MTP blobs.
TW_NO_EXFAT := true
TW_NO_EXFAT_FUSE := true
TW_EXCLUDE_MTP := true
