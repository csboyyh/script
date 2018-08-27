# Copyright (C) 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := hal_play
LOCAL_MULTILIB := both
LOCAL_MODULE_STEM_32 := $(LOCAL_MODULE)_32
LOCAL_MODULE_STEM_64 := $(LOCAL_MODULE)_64
LOCAL_CFLAGS := -D_POSIX_SOURCE -Wno-multichar -g
LOCAL_C_INCLUDES += \
    external/tinyalsa/include \
    external/tinycompress/include \
    external/expat/lib \
    system/media/audio_utils/include \
    system/media/audio_effects/include \

LOCAL_SRC_FILES := \
    hal_play.c \

LOCAL_SHARED_LIBRARIES := \
    libcutils \
    libexpat \
    libdl \
    libhardware_legacy \
    libutils \

include $(BUILD_EXECUTABLE)
