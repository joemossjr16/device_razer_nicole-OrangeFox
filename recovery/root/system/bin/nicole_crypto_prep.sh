#!/system/bin/sh
# Nicole Crypto Preparation Script for TWRP
# Automatically configures environment, mounts, and properties for Android 16 metadata decryption

# Find active slot suffix (_a or _b)
suffix=$(getprop ro.boot.slot_suffix)
if [ -z "$suffix" ]; then
    suf=$(getprop ro.boot.slot)
    if [ -n "$suf" ]; then
        suffix="_$suf"
    else
        suffix="_a"
    fi
fi

# Detect actual OS version and security patch from installed ROM's system partition
ROM_PATCH=""
ROM_VER=""
for i in $(seq 1 20); do
    if [ -e /dev/block/mapper/system$suffix ]; then
        break
    fi
    sleep 0.2
done

mkdir -p /tmp/rom_sys
if mount -t ext4 -o ro /dev/block/mapper/system$suffix /tmp/rom_sys 2>/dev/null || \
   mount -t erofs -o ro /dev/block/mapper/system$suffix /tmp/rom_sys 2>/dev/null; then
    for bp in /tmp/rom_sys/system/build.prop /tmp/rom_sys/build.prop; do
        if [ -f "$bp" ]; then
            ROM_PATCH=$(grep -m1 '^ro.build.version.security_patch=' "$bp" | cut -d= -f2 | tr -d '\r\n')
            ROM_VER=$(grep -m1 '^ro.build.version.release=' "$bp" | cut -d= -f2 | tr -d '\r\n')
            [ -n "$ROM_PATCH" ] && break
        fi
    done
    umount /tmp/rom_sys 2>/dev/null || true
    rmdir /tmp/rom_sys 2>/dev/null || true
fi

[ -z "$ROM_PATCH" ] && ROM_PATCH="2026-09-01"
[ -z "$ROM_VER" ] && ROM_VER="16"

# Set ROM properties so Qualcomm Keymaster TA matches the key
if [ -f /system/bin/resetprop ]; then
    /system/bin/resetprop -n ro.build.version.release "$ROM_VER"
    /system/bin/resetprop -n ro.build.version.release_or_codename "$ROM_VER"
    /system/bin/resetprop -n ro.build.version.security_patch "$ROM_PATCH"
    /system/bin/resetprop -n persist.twrp.touch_flip_y 1
    /system/bin/resetprop -n persist.twrp.touch_flip_x 0
    /system/bin/resetprop -n ro.virtual_ab.enabled true
    /system/bin/resetprop -n ro.virtual_ab.retrofit false
    /system/bin/resetprop -n ro.virtual_ab.userspace.snapshots.enabled true
    /system/bin/resetprop -n ro.virtual_ab.skip_snapshot_creation true
    /system/bin/resetprop -n ro.dynamic.full_size 17171480576
fi

# Wait for mapper dynamic partitions
for i in $(seq 1 20); do
    if [ -e /dev/block/mapper/vendor$suffix ]; then
        break
    fi
    sleep 0.5
done
mount -t ext4 /dev/block/mapper/vendor$suffix /vendor 2>/dev/null || true

for i in $(seq 1 20); do
    if [ -e /dev/block/mapper/odm$suffix ]; then
        break
    fi
    sleep 0.5
done
mount -t ext4 /dev/block/mapper/odm$suffix /odm 2>/dev/null || true

# Symlink Keymaster service binary so init/binder finds it under either name
ln -sf /system/bin/keymaster-qti /system/bin/android.hardware.keymaster@4.1-service-qti

# Remove incompatible Android 16 vintf manifest if present
rm -f /system/etc/vintf/manifest/boot-service.qti.xml

# Mask problematic Android 16 VINTF manifest with clean recovery manifest
if [ -f /vendor_manifest_clean.xml ] && ! mountpoint -q /vendor/etc/vintf/manifest.xml; then
    mount --bind /vendor_manifest_clean.xml /vendor/etc/vintf/manifest.xml 2>/dev/null || true
fi
mkdir -p /tmp/empty_vintf
if ! mountpoint -q /vendor/etc/vintf/manifest; then
    mount --bind /tmp/empty_vintf /vendor/etc/vintf/manifest 2>/dev/null || true
fi
if ! mountpoint -q /odm/etc/vintf; then
    mount --bind /tmp/empty_vintf /odm/etc/vintf 2>/dev/null || true
fi

# Mount modem firmware and initialize ADSP for battery and power management
if [ ! -f /tmp/nicole_adsp_booted ]; then
    mkdir -p /vendor/firmware_mnt
    if ! mountpoint -q /vendor/firmware_mnt; then
        mount -t vfat -o ro /dev/block/bootdevice/by-name/modem$suffix /vendor/firmware_mnt 2>/dev/null || \
        mount -t vfat -o ro /dev/block/by-name/modem$suffix /vendor/firmware_mnt 2>/dev/null || true
    fi
    ln -sf /vendor/firmware_mnt /firmware

    if [ -d /vendor/lib/modules ]; then
        modprobe -a -d /vendor/lib/modules q6_pdr_dlkm q6_notifier_dlkm snd_event_dlkm apr_dlkm adsp_loader_dlkm 2>/dev/null || true
    fi

    if [ -e /sys/kernel/boot_adsp/boot ]; then
        echo 1 > /sys/kernel/boot_adsp/boot
        touch /tmp/nicole_adsp_booted
    fi
fi

# Setup boot control HAL symlinks
mkdir -p /vendor/lib64/hw /system/lib64/hw
ln -sf /system/lib64/hw/bootctrl.lahaina.so /vendor/lib64/hw/bootctrl.lahaina.so 2>/dev/null || true
ln -sf /system/lib64/hw/bootctrl.lahaina.so /vendor/lib64/hw/bootctrl.default.so 2>/dev/null || true
ln -sf /system/lib64/hw/bootctrl.lahaina.so /system/lib64/hw/bootctrl.default.so 2>/dev/null || true
ln -sf /system/lib64/hw/android.hardware.boot@1.0-impl.so /vendor/lib64/hw/android.hardware.boot@1.0-impl.so 2>/dev/null || true

# Start crypto stack services
start qseecomd
start keymaster-4-1-qti
start gatekeeper-1-0-qti
start keystore2
start boot-hal-1-0

exit 0
