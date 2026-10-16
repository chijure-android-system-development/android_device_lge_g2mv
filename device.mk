LOCAL_PATH := device/lge/g2mv

DEVICE_PACKAGE_OVERLAYS += $(LOCAL_PATH)/overlay

# Prefer device NFC config over the stock blob (FW path + standby). Must be
# registered before g2mv-vendor.mk — PRODUCT_COPY_FILES keeps the first entry.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/libnfc-nxp.conf:system/etc/libnfc-nxp.conf

# Media: NV AVC + YUV path; OMXCodec skips freeNode/leaks dealers on teardown.
# Camera2 (EIS off, skip thumbs) + StagefrightRecorder encoder clear.
# Override vendor media_codecs/profiles (PRODUCT_COPY_FILES first wins).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/media_codecs.xml:system/etc/media_codecs.xml \
    $(LOCAL_PATH)/configs/media_profiles.xml:system/etc/media_profiles.xml

# Patched sensors HAL (TYPE_LIGHT + sysfs path). Overrides stock extract.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/sensors.g2mv.so:system/lib/hw/sensors.g2mv.so

# Stock LG offline-charge UI (ramdisk). Binary patched to drive RT8542
# leds/lcd-backlight instead of pwm-backlight. Requires init chargerlogo
# trigger (system/core patch in patches/init-chargerlogo.patch).
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/chargerlogo:root/sbin/chargerlogo

# Icera modem product/device config (must precede vendor mk). Without these
# the BB stays at CFUN=0 and gsm.sim.state stays UNKNOWN.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/prebuilt/icera/config/productConfig.bin:system/vendor/firmware/data/config/productConfig.bin \
    $(LOCAL_PATH)/prebuilt/icera/config/default_calibration.bin:system/vendor/firmware/data/config/default_calibration.bin \
    $(LOCAL_PATH)/prebuilt/icera/factory/deviceConfig.bin:system/vendor/firmware/data/factory/deviceConfig.bin \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_2.xml:system/vendor/firmware/data/factory/platformConfig_2.xml \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_3.xml:system/vendor/firmware/data/factory/platformConfig_3.xml \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_4.xml:system/vendor/firmware/data/factory/platformConfig_4.xml \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_5.xml:system/vendor/firmware/data/factory/platformConfig_5.xml \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_6.xml:system/vendor/firmware/data/factory/platformConfig_6.xml \
    $(LOCAL_PATH)/prebuilt/icera/factory/platformConfig_9.xml:system/vendor/firmware/data/factory/platformConfig_9.xml

# UEI MXQ616 IR blaster (Quick Remote). Blobs (jar/so/serialport/permissions)
# come from vendor/lge/g2mv. librctransport opens /dev/ttyAS1; init.grey.rc
# symlinks that to ttyHS3. qremote_conf keeps lite_db=true for D625.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/qremote_conf.xml:system/etc/qremote_conf.xml

$(call inherit-product-if-exists, vendor/lge/g2mv/g2mv-vendor.mk)

# Stock audio_policy.tegra.so is ABI-incompatible with CM 11 and SIGSEGVs
# mediaserver in getStreamVolumeIndex() (kills Camera). It is not listed in
# proprietary-files.txt, but a leftover under out/.../system/lib/hw survives
# incremental bacon and gets repackaged — delete it whenever the out tree exists.
$(shell rm -f $(TARGET_OUT)/lib/hw/audio_policy.tegra.so \
    vendor/lge/g2mv/proprietary/system/lib/hw/audio_policy.tegra.so)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_policy.conf:system/etc/audio_policy.conf \
    $(LOCAL_PATH)/configs/nvcamera.conf:system/etc/nvcamera.conf \
    $(LOCAL_PATH)/configs/gps.conf:system/etc/gps.conf \
    $(LOCAL_PATH)/rootdir/fstab.g2mv:root/fstab.g2mv \
    $(LOCAL_PATH)/rootdir/init.g2mv.rc:root/init.g2mv.rc \
    $(LOCAL_PATH)/rootdir/init.g2mv_product.rc:root/init.g2mv_product.rc \
    $(LOCAL_PATH)/rootdir/init.grey.rc:root/init.grey.rc \
    $(LOCAL_PATH)/rootdir/init.grey.usb.rc:root/init.grey.usb.rc \
    $(LOCAL_PATH)/rootdir/init.hdcp.rc:root/init.hdcp.rc \
    $(LOCAL_PATH)/rootdir/init.icera_g2mv.rc:root/init.icera_g2mv.rc \
    $(LOCAL_PATH)/rootdir/init.modem_icera.rc:root/init.modem_icera.rc \
    $(LOCAL_PATH)/rootdir/init.qvs.rc:root/init.qvs.rc \
    $(LOCAL_PATH)/rootdir/init.tlk.rc:root/init.tlk.rc \
    $(LOCAL_PATH)/rootdir/ueventd.g2mv.rc:root/ueventd.g2mv.rc \
    $(LOCAL_PATH)/recovery.fstab:recovery/root/etc/recovery.fstab

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.camera.xml:system/etc/permissions/android.hardware.camera.xml \
    frameworks/native/data/etc/android.hardware.camera.front.xml:system/etc/permissions/android.hardware.camera.front.xml \
    frameworks/native/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:system/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:system/etc/permissions/android.hardware.bluetooth_le.xml \
    $(LOCAL_PATH)/configs/bt_vendor.conf:system/etc/bluetooth/bt_vendor.conf \
    frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml \
    frameworks/native/data/etc/android.hardware.nfc.hce.xml:system/etc/permissions/android.hardware.nfc.hce.xml \
    frameworks/native/data/etc/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml

PRODUCT_PACKAGES += \
    audio_policy.default \
    audio.a2dp.default \
    audio.r_submix.default \
    audio.usb.default \
    com.android.future.usb.accessory \
    libnetcmdiface \
    libtinyalsa \
    libtinycompress \
    make_ext4fs \
    setup_fs \
    static_busybox \
    hostapd \
    tinycap \
    tinymix \
    tinyplay \
    wpa_supplicant \
    NfcNci \
    nfc_nci.g2mv \
    Tag \
    com.android.nfc_extras \
    QuicksetSDK \
    LGQRemote \
    UnifiedEULA

# Dalvik heap from stock D62510c (~1 GB RAM). Without these, Zygote uses tiny
# defaults and SystemUI/Camera2 hit OutOfMemoryError on full-screen bitmaps.
PRODUCT_PROPERTY_OVERRIDES += \
    dalvik.vm.heapstartsize=8m \
    dalvik.vm.heapgrowthlimit=96m \
    dalvik.vm.heapsize=256m \
    dalvik.vm.heaptargetutilization=0.25 \
    dalvik.vm.heapminfree=2m \
    dalvik.vm.heapmaxfree=8m

PRODUCT_PROPERTY_OVERRIDES += \
    ro.telephony.default_network=9 \
    ro.sf.lcd_density=240 \
    rild.libpath=/system/lib/libril-icera-lge.so \
    ap.interface=wlan0 \
    persist.tegra.compositor=glcomposer \
    ro.zygote.disable_gl_preload=true \
    ro.input.noresample=1 \
    af.resampler.quality=4 \
    wifi.interface=wlan0 \
    persist.sys.usb.config=mtp,adb \
    ro.nfc.port=I2C \
    ro.camera.sound.forced=0 \
    persist.camera.skip_video_thumb=1 \
    persist.camera.disable_meta=1 \
    ro.build.target_region=SCA \
    ro.build.target_country=PE \
    ro.build.target_operator=OPEN

PRODUCT_CHARACTERISTICS := default
PRODUCT_AAPT_CONFIG := normal hdpi xhdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi
