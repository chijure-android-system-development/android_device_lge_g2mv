LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $(call all-java-files-under, src)
LOCAL_PACKAGE_NAME := UnifiedEULA
LOCAL_CERTIFICATE := platform
LOCAL_PROGUARD_ENABLED := disabled
# No LOCAL_SDK_VERSION: need @hide SystemProperties for the agree flag.
include $(BUILD_PACKAGE)
