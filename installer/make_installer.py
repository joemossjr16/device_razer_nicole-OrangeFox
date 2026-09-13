import os
import zipfile
import shutil

pkg_dir = '/opt/twrp/source/installer_pkg'
shutil.rmtree(pkg_dir, ignore_errors=True)
os.makedirs(os.path.join(pkg_dir, 'META-INF/com/google/android'), exist_ok=True)

updater_script = '#dummy\n'
with open(os.path.join(pkg_dir, 'META-INF/com/google/android/updater-script'), 'w') as f:
    f.write(updater_script)

update_binary = """#!/sbin/sh
OUTFD=$2
[ -z "$OUTFD" ] && OUTFD=1

ui_print() {
  if [ -e "/proc/self/fd/$OUTFD" ]; then
    echo "ui_print $1" > "/proc/self/fd/$OUTFD"
    echo "ui_print" > "/proc/self/fd/$OUTFD"
  else
    echo "$1"
  fi
}

ui_print "****************************************"
ui_print "*    TWRP Permanent Installer (A/B)    *"
ui_print "*        Razer Edge 5G (nicole)        *"
ui_print "****************************************"

ZIP_PATH="$3"
WORK_DIR="/tmp/twrp_installer_work"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

ui_print "- Extracting installer files..."
unzip -o "$ZIP_PATH" -d "$WORK_DIR" >/dev/null 2>&1

if [ ! -f "$WORK_DIR/magiskboot" ] || [ ! -f "$WORK_DIR/twrp-ramdisk.cpio" ]; then
  ui_print "! Error: Missing required installer components!"
  cd /
  rm -rf "$WORK_DIR"
  exit 1
fi

chmod 755 "$WORK_DIR/magiskboot"

find_boot() {
  local slot="$1"
  for p in "/dev/block/bootdevice/by-name/boot${slot}" "/dev/block/by-name/boot${slot}"; do
    if [ -b "$p" ]; then
      echo "$p"
      return
    fi
  done
}

BOOT_A=$(find_boot "_a")
BOOT_B=$(find_boot "_b")

patch_boot() {
  local slot_name="$1"
  local boot_dev="$2"

  if [ -z "$boot_dev" ] || [ ! -b "$boot_dev" ]; then
    ui_print "! Boot partition for slot $slot_name not found, skipping."
    return
  fi

  ui_print "- Patching boot partition for slot $slot_name ($boot_dev)..."
  mkdir -p "$WORK_DIR/$slot_name"
  cd "$WORK_DIR/$slot_name"

  "$WORK_DIR/magiskboot" unpack "$boot_dev" >/dev/null 2>&1
  if [ ! -f "kernel" ]; then
    ui_print "! Failed to unpack boot_$slot_name!"
    cd "$WORK_DIR"
    return 1
  fi

  cp -f "$WORK_DIR/twrp-ramdisk.cpio" ramdisk.cpio
  "$WORK_DIR/magiskboot" repack "$boot_dev" new-boot.img >/dev/null 2>&1
  if [ ! -f "new-boot.img" ]; then
    ui_print "! Failed to repack new-boot.img for slot $slot_name!"
    cd "$WORK_DIR"
    return 1
  fi

  cat new-boot.img > "$boot_dev"
  ui_print "- Successfully flashed TWRP to boot_$slot_name"
  cd "$WORK_DIR"
}

patch_boot "A" "$BOOT_A"
patch_boot "B" "$BOOT_B"

ui_print "- Setting up addon.d survival script..."
SYS_MNT=""
for p in "/system_root" "/system"; do
  if mountpoint -q "$p"; then
    SYS_MNT="$p"
    break
  fi
done

if [ -z "$SYS_MNT" ]; then
  mount /system >/dev/null 2>&1 || mount /system_root >/dev/null 2>&1
  for p in "/system_root" "/system"; do
    if mountpoint -q "$p"; then
      SYS_MNT="$p"
      break
    fi
  done
fi

if [ -n "$SYS_MNT" ]; then
  mount -o remount,rw "$SYS_MNT" 2>/dev/null || mount -o remount,rw /system 2>/dev/null || mount -o remount,rw /system_root 2>/dev/null
fi

TARGET_ADDOND=""
if [ -d "$SYS_MNT/system/addon.d" ]; then
  TARGET_ADDOND="$SYS_MNT/system/addon.d"
elif [ -d "$SYS_MNT/addon.d" ]; then
  TARGET_ADDOND="$SYS_MNT/addon.d"
elif [ -n "$SYS_MNT" ]; then
  mkdir -p "$SYS_MNT/system/addon.d" 2>/dev/null
  TARGET_ADDOND="$SYS_MNT/system/addon.d"
fi

if [ -n "$TARGET_ADDOND" ]; then
  cp -f "$WORK_DIR/99-twrp.sh" "$TARGET_ADDOND/99-twrp.sh"
  cp -f "$WORK_DIR/magiskboot" "$TARGET_ADDOND/magiskboot"
  cp -f "$WORK_DIR/twrp-ramdisk.cpio" "$TARGET_ADDOND/twrp-ramdisk.cpio"
  chmod 755 "$TARGET_ADDOND/99-twrp.sh" "$TARGET_ADDOND/magiskboot"
  chmod 644 "$TARGET_ADDOND/twrp-ramdisk.cpio"
  ui_print "- Survival script installed to $TARGET_ADDOND"
else
  ui_print "! Warning: Could not locate /system/addon.d; survival script skipped."
fi

cd /
rm -rf "$WORK_DIR"
ui_print "****************************************"
ui_print "*       TWRP Installation Done!        *"
ui_print "*    TWRP will now survive updates!    *"
ui_print "****************************************"
exit 0
"""
ub_path = os.path.join(pkg_dir, 'META-INF/com/google/android/update-binary')
with open(ub_path, 'w', newline='\n') as f:
    f.write(update_binary)
os.chmod(ub_path, 0o755)

addon_sh = """#!/system/bin/sh
#
# ADDOND_VERSION=3
#
# /system/addon.d/99-twrp.sh
# Survives LineageOS / A/B ROM updates and automatically patches TWRP into the target boot partition.
#

. /tmp/backuptool.functions 2>/dev/null || . /postinstall/tmp/backuptool.functions 2>/dev/null

list_files() {
cat <<EOF_LIST
addon.d/99-twrp.sh
addon.d/twrp-ramdisk.cpio
addon.d/magiskboot
EOF_LIST
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
    chmod 755 $S/addon.d/99-twrp.sh
    chmod 755 $S/addon.d/magiskboot
    chmod 644 $S/addon.d/twrp-ramdisk.cpio
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    CURRENTSLOT=$(getprop ro.boot.slot_suffix)
    [ -z "$CURRENTSLOT" ] && CURRENTSLOT="_$(getprop ro.boot.slot)"
    if [ "$CURRENTSLOT" = "_a" ]; then
      TARGET_SLOT="_b"
    elif [ "$CURRENTSLOT" = "_b" ]; then
      TARGET_SLOT="_a"
    else
      TARGET_SLOT=""
    fi

    MAGISKBOOT="/postinstall/system/addon.d/magiskboot"
    [ ! -x "$MAGISKBOOT" ] && MAGISKBOOT="/system/addon.d/magiskboot"
    RAMDISK="/postinstall/system/addon.d/twrp-ramdisk.cpio"
    [ ! -f "$RAMDISK" ] && RAMDISK="/system/addon.d/twrp-ramdisk.cpio"

    if [ ! -x "$MAGISKBOOT" ] || [ ! -f "$RAMDISK" ]; then
      echo "TWRP survival: missing magiskboot or twrp-ramdisk.cpio!"
      exit 0
    fi

    BOOT_DEVS=""
    if [ -n "$TARGET_SLOT" ]; then
      for p in "/dev/block/bootdevice/by-name/boot${TARGET_SLOT}" "/dev/block/by-name/boot${TARGET_SLOT}"; do
        if [ -b "$p" ]; then
          BOOT_DEVS="$p"
          break
        fi
      done
    fi

    if [ -z "$BOOT_DEVS" ]; then
      for s in "_a" "_b"; do
        for p in "/dev/block/bootdevice/by-name/boot${s}" "/dev/block/by-name/boot${s}"; do
          if [ -b "$p" ]; then
            BOOT_DEVS="$BOOT_DEVS $p"
            break
          fi
        done
      done
    fi

    for BOOT_DEV in $BOOT_DEVS; do
      echo "TWRP survival: patching TWRP into $BOOT_DEV..."
      WORK_DIR="/postinstall/tmp/twrp_repack"
      [ ! -d "/postinstall/tmp" ] && WORK_DIR="/tmp/twrp_repack"
      rm -rf "$WORK_DIR"
      mkdir -p "$WORK_DIR"
      cd "$WORK_DIR" || continue

      "$MAGISKBOOT" unpack "$BOOT_DEV" >/dev/null 2>&1
      if [ -f "kernel" ]; then
        cp -f "$RAMDISK" ramdisk.cpio
        "$MAGISKBOOT" repack "$BOOT_DEV" new-boot.img >/dev/null 2>&1
        if [ -f "new-boot.img" ]; then
          cat new-boot.img > "$BOOT_DEV"
          echo "TWRP survival: successfully injected TWRP into $BOOT_DEV!"
        else
          echo "TWRP survival: failed to repack $BOOT_DEV"
        fi
      else
        echo "TWRP survival: failed to unpack $BOOT_DEV"
      fi
      cd /
      rm -rf "$WORK_DIR"
    done
  ;;
esac
exit 0
"""
addon_path = os.path.join(pkg_dir, '99-twrp.sh')
with open(addon_path, 'w', newline='\n') as f:
    f.write(addon_sh)
os.chmod(addon_path, 0o755)

shutil.copy2('/opt/twrp/source/out/target/product/nicole/recovery/root/system/bin/magiskboot', os.path.join(pkg_dir, 'magiskboot'))
os.chmod(os.path.join(pkg_dir, 'magiskboot'), 0o755)
shutil.copy2('/opt/twrp/source/out/target/product/nicole/ramdisk-recovery.cpio', os.path.join(pkg_dir, 'twrp-ramdisk.cpio'))

out_zip = '/opt/twrp/source/out/target/product/nicole/twrp-installer-nicole.zip'
if os.path.exists(out_zip):
    os.remove(out_zip)

print('Compressing ZIP...')
with zipfile.ZipFile(out_zip, 'w', zipfile.ZIP_DEFLATED) as zf:
    for root, dirs, files in os.walk(pkg_dir):
        for file in files:
            full = os.path.join(root, file)
            rel = os.path.relpath(full, pkg_dir)
            zf.write(full, rel)

print(f'SUCCESS! Created {out_zip} ({os.path.getsize(out_zip):,} bytes)')
