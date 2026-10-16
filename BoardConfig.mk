DEVICE_PATH := device/lge/g2mv

TARGET_ARCH := arm
TARGET_ARCH_VARIANT := armv7-a-neon
TARGET_CPU_ABI := armeabi-v7a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_VARIANT := cortex-a9
TARGET_CPU_SMP := true
ARCH_ARM_HAVE_TLS_REGISTER := true

TARGET_BOARD_PLATFORM := tegra
TARGET_TEGRA_VERSION := t114
TARGET_TEGRA_FAMILY := t11x
TARGET_BOOTLOADER_BOARD_NAME := g2mv
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true

# Values read from the live D625 recovery header.
# Source kernel (pda_android_defconfig) with CM11 backlight fix: PRISM/PWM
# backlight disabled so only RT8542 leds/lcd-backlight is used. Stock prebuilt
# remains at $(DEVICE_PATH)/prebuilt/kernel as a fallback if SOURCE is missing.
TARGET_KERNEL_SOURCE := kernel/lge/d625
TARGET_KERNEL_CONFIG := pda_android_defconfig
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
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1937768448
BOARD_CACHEIMAGE_PARTITION_SIZE := 805306368
BOARD_FLASH_BLOCK_SIZE := 4096

TARGET_USERIMAGES_USE_EXT4 := true
BOARD_HAS_LARGE_FILESYSTEM := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# LG offline charge: the bootloader passes androidboot.mode=chargerlogo.
# CM's init enters its charger mode on this cmdline match (see init.grey.rc).
BOARD_CHARGING_CMDLINE_NAME := androidboot.mode
BOARD_CHARGING_CMDLINE_VALUE := chargerlogo

BOARD_USES_GENERIC_AUDIO := false
BOARD_USES_ALSA_AUDIO := true

# CM 11's CVE-2017-13154 backport unlocks OMXNodeInstance::mLock after
# freeNode's "delete this" (use-after-free on the freed node), which
# corrupted the mediaserver heap. Build freeNode without that lock, as LG's
# stock libstagefright_omx does.
BOARD_SKIP_CVE_2017_13154 := true
USE_CAMERA_STUB := false
USE_OPENGL_RENDERER := true
BOARD_DISABLE_TRIPLE_BUFFERED_DISPLAY_SURFACES := true
BOARD_EGL_CFG := $(DEVICE_PATH)/egl.cfg
TARGET_RUNNING_WITHOUT_SYNC_FRAMEWORK := false

BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_BCM := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth
BOARD_BLUEDROID_VENDOR_CONF := $(DEVICE_PATH)/bluetooth/vnd_g2mv.txt

# max77660 haptic (not timed_output); path relative to hardware/libhardware_legacy.
BOARD_HAS_VIBRATOR_IMPLEMENTATION := ../../device/lge/g2mv/vibrator/vibrator.c

# CMHW: KnockON / double tap to wake (Atmel S336 LPWG).
BOARD_HARDWARE_CLASS := $(DEVICE_PATH)/cmhw/

# NXP PN547 on /dev/pn547 (init also symlinks /dev/pn544 for the NCI HAL).
BOARD_NFC_CHIPSET := pn547
BOARD_NFC_HAL_SUFFIX := $(TARGET_DEVICE)

BOARD_WLAN_DEVICE := bcmdhd
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_bcmdhd
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_bcmdhd
# Source kernel and bcmdhd.ko share the same vermagic (built together).
WIFI_DRIVER_MODULE_PATH := /system/lib/modules/bcmdhd.ko
WIFI_DRIVER_MODULE_NAME := bcmdhd
WIFI_DRIVER_MODULE_ARG := "firmware_path=/system/etc/firmware/fw_bcmdhd.bin nvram_path=/system/etc/wifi/bcmdhd.cal"
WIFI_DRIVER_FW_PATH_PARAM := /sys/module/bcmdhd/parameters/firmware_path
WIFI_DRIVER_FW_PATH_STA := /system/etc/firmware/fw_bcmdhd.bin
WIFI_DRIVER_FW_PATH_AP := /system/etc/firmware/fw_bcmdhd_apsta.bin
WIFI_DRIVER_FW_PATH_P2P := /system/etc/firmware/fw_bcmdhd.bin
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_HOSTAPD_DRIVER := NL80211

BOARD_CONNECTIVITY_VENDOR := NVIDIA
TARGET_SYSTEM_PROP := $(DEVICE_PATH)/system.prop

TARGET_BOOTANIMATION_PRELOAD := true
TARGET_BOOTANIMATION_TEXTURE_CACHE := true
TARGET_OTA_ASSERT_DEVICE := g2mv,D625,LG-D625

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
