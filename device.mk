LOCAL_PATH := device/lge/g2mv

$(call inherit-product-if-exists, vendor/lge/g2mv/g2mv-vendor.mk)

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio_policy.conf:system/etc/audio_policy.conf \
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
    frameworks/native/data/etc/android.hardware.telephony.gsm.xml:system/etc/permissions/android.hardware.telephony.gsm.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml

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
    wpa_supplicant

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
    persist.sys.usb.config=mtp,adb

PRODUCT_CHARACTERISTICS := default
PRODUCT_AAPT_CONFIG := normal hdpi xhdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi
