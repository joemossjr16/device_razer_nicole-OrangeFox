LOCAL_PATH := device/razer/nicole
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
PRODUCT_SHIPPING_API_LEVEL := 30
PRODUCT_USE_DYNAMIC_PARTITIONS := true
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH) hardware/qcom-caf/bootctrl device/qcom/common/gpt-utils
AB_OTA_UPDATER := true
PRODUCT_VIRTUAL_AB_OTA := true
PRODUCT_PROPERTY_OVERRIDES += \
    ro.virtual_ab.enabled=true \
    ro.virtual_ab.retrofit=false \
    ro.virtual_ab.userspace.snapshots.enabled=true \
    ro.virtual_ab.skip_snapshot_creation=true \
    ro.dynamic.full_size=17171480576
AB_OTA_PARTITIONS := boot dtbo odm product system system_ext vbmeta vbmeta_system vendor vendor_boot
PRODUCT_PACKAGES += fastbootd \
    android.hardware.fastboot@1.0-impl-mock \
    android.hardware.boot@1.0-impl \
    android.hardware.boot@1.0-impl.recovery \
    android.hardware.boot@1.0-service \
    bootctrl.lahaina \
    bootctrl.lahaina.recovery \
    bootctrl.default \
    bootctrl.default.recovery \
    qcom_decrypt \
    qcom_decrypt_fbe
TARGET_RECOVERY_DEVICE_MODULES += libion
RECOVERY_LIBRARY_SOURCE_FILES += $(TARGET_OUT_SHARED_LIBRARIES)/libion.so
PRODUCT_COPY_FILES += $(LOCAL_PATH)/init/init.qcom.recovery.rc:root/init.qcom.recovery.rc \
    $(LOCAL_PATH)/init/ueventd.qcom.rc:recovery/root/vendor/ueventd.rc \
    $(LOCAL_PATH)/recovery/root/vendor/etc/vintf/manifest.xml:recovery/root/vendor/etc/vintf/manifest.xml \
    $(LOCAL_PATH)/recovery/root/system/manifest.xml:recovery/root/system/etc/vintf/manifest.xml \
    $(LOCAL_PATH)/recovery/root/init.recovery.disable-services.rc:root/init.recovery.disable-services.rc \
    $(LOCAL_PATH)/recovery/root/vendor_manifest_clean.xml:root/vendor_manifest_clean.xml \
    $(LOCAL_PATH)/recovery/root/system/bin/nicole_crypto_prep.sh:recovery/root/system/bin/nicole_crypto_prep.sh \
    $(LOCAL_PATH)/recovery/root/system/etc/twrp.flags:recovery/root/system/etc/twrp.flags \
    $(LOCAL_PATH)/recovery/root/system/bin/prepdecrypt.sh:recovery/root/system/bin/prepdecrypt.sh \
    $(LOCAL_PATH)/recovery/root/init.recovery.services.qcom_decrypt.rc:root/init.recovery.services.qcom_decrypt.rc \
    $(LOCAL_PATH)/recovery/root/init.recovery.services.qcom_decrypt.fbe.rc:root/init.recovery.services.qcom_decrypt.fbe.rc \
    $(LOCAL_PATH)/prebuilt/vendor/qseecomd:recovery/root/system/bin/qseecomd \
    $(LOCAL_PATH)/prebuilt/vendor/keymaster-qti:recovery/root/system/bin/keymaster-qti \
    $(LOCAL_PATH)/prebuilt/vendor/gatekeeper-qti:recovery/root/system/bin/gatekeeper-qti \
    $(LOCAL_PATH)/prebuilt/vendor/libdiag.so:recovery/root/vendor/lib64/libdiag.so \
    $(LOCAL_PATH)/prebuilt/vendor/libQSEEComAPI.so:recovery/root/vendor/lib64/libQSEEComAPI.so \
    $(LOCAL_PATH)/prebuilt/vendor/libdrmfs.so:recovery/root/vendor/lib64/libdrmfs.so \
    $(LOCAL_PATH)/prebuilt/vendor/libdrmtime.so:recovery/root/vendor/lib64/libdrmtime.so \
    $(LOCAL_PATH)/prebuilt/vendor/libkeymasterdeviceutils.so:recovery/root/vendor/lib64/libkeymasterdeviceutils.so \
    $(LOCAL_PATH)/prebuilt/vendor/libkeymasterutils.so:recovery/root/vendor/lib64/libkeymasterutils.so \
    $(LOCAL_PATH)/prebuilt/vendor/libminkdescriptor.so:recovery/root/vendor/lib64/libminkdescriptor.so \
    $(LOCAL_PATH)/prebuilt/vendor/libops.so:recovery/root/vendor/lib64/libops.so \
    $(LOCAL_PATH)/prebuilt/vendor/libqcbor.so:recovery/root/vendor/lib64/libqcbor.so \
    $(LOCAL_PATH)/prebuilt/vendor/libqisl.so:recovery/root/vendor/lib64/libqisl.so \
    $(LOCAL_PATH)/prebuilt/vendor/libqtikeymaster4.so:recovery/root/vendor/lib64/libqtikeymaster4.so \
    $(LOCAL_PATH)/prebuilt/vendor/librpmb.so:recovery/root/vendor/lib64/librpmb.so \
    $(LOCAL_PATH)/prebuilt/vendor/libspcom.so:recovery/root/vendor/lib64/libspcom.so \
    $(LOCAL_PATH)/prebuilt/vendor/libspl.so:recovery/root/vendor/lib64/libspl.so \
    $(LOCAL_PATH)/prebuilt/vendor/libssd.so:recovery/root/vendor/lib64/libssd.so