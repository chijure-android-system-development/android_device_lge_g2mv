$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, vendor/omni/config/common.mk)

PRODUCT_DEVICE := g2mv
PRODUCT_NAME := omni_g2mv
PRODUCT_BRAND := lge
PRODUCT_MODEL := LG-D625
PRODUCT_MANUFACTURER := LGE

PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery.fstab:recovery/root/etc/recovery.fstab \
    $(LOCAL_PATH)/recovery/root/init.recovery.g2mv.rc:root/init.recovery.g2mv.rc
