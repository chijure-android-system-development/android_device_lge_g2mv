LOCAL_PATH := $(call my-dir)

# Stock UEI QuicksetSDK needs android.uid.system (sharedUserId) → resign
# with the platform cert. LGQRemote is dex-patched and platform-signed (PRESIGNED).

include $(CLEAR_VARS)
LOCAL_MODULE := QuicksetSDK
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := app/QuicksetSDK.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := platform
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := LGQRemote
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := app/LGQRemote.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
include $(BUILD_PREBUILT)
