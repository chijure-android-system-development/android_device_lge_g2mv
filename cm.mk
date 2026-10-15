$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, device/lge/g2mv/device.mk)
$(call inherit-product, vendor/cm/config/gsm.mk)
$(call inherit-product, vendor/cm/config/common_full_phone.mk)
$(call inherit-product, vendor/cm/config/nfc_enhanced.mk)

PRODUCT_NAME := cm_g2mv
PRODUCT_DEVICE := g2mv
PRODUCT_BRAND := lge
PRODUCT_MODEL := LG-D625
PRODUCT_MANUFACTURER := LGE
TARGET_SCREEN_HEIGHT := 960
TARGET_SCREEN_WIDTH := 540

PRODUCT_PACKAGES += Torch

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=g2mv_sca_com \
    BUILD_FINGERPRINT=lge/g2mv_sca_com/g2mv:4.4.2/KOT49I/D62510c.1423076878:user/release-keys \
    PRIVATE_BUILD_DESC="g2mv_sca_com-user 4.4.2 KOT49I D62510c.1423076878 release-keys"
