#
# Copyright (C) 2026 The OrangeFox Recovery Project
#
# SPDX-License-Identifier: Apache-2.0
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Inherit from device configuration
$(call inherit-product, device/razer/nicole/device.mk)

PRODUCT_DEVICE := nicole
PRODUCT_NAME := twrp_nicole
PRODUCT_BRAND := Razer
PRODUCT_MODEL := Razer Edge 5G
PRODUCT_MANUFACTURER := Razer
PRODUCT_CHARACTERISTICS := tablet

PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe \
    fastbootd

# ART / Dalvik
PRODUCT_ENABLE_UFFD_GC := false
