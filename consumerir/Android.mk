LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := libcir_driver
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_SRC_FILES := ../prebuilt/uei/lib/libcir_driver.so
LOCAL_MODULE_TAGS := optional
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := consumerir.$(TARGET_BOOTLOADER_BOARD_NAME)
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_SRC_FILES := consumerir.c
LOCAL_SHARED_LIBRARIES := liblog libcutils libcir_driver
LOCAL_MODULE_TAGS := optional
include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := cir_test
LOCAL_SRC_FILES := cir_test.c
LOCAL_SHARED_LIBRARIES := libcir_driver
LOCAL_MODULE_TAGS := optional
include $(BUILD_EXECUTABLE)
