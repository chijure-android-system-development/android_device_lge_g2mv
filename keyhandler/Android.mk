LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := com.cyanogenmod.keyhandler
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $(call all-java-files-under, src)
# Loaded by PhoneWindowManager through DexClassLoader.
LOCAL_DEX_PREOPT := false
include $(BUILD_JAVA_LIBRARY)
