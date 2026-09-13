# OrangeFox Recovery Project Device Tree for Razer Edge (`nicole`)

```
   ____                                ______           
  / __ \_________ _____  ____ ____     / ____/___  _  __
 / / / / ___/ __ `/ __ \/ __ `/ _ \   / /_  / __ \| |/_/
/ /_/ / /  / /_/ / / / / /_/ /  __/  / __/ / /_/ />  <  
\____/_/   \__,_/_/ /_/\__, /\___/  /_/    \____/_/|_|  
                      /____/                            
```

## Device Specifications

| Feature | Specification |
| :--- | :--- |
| **Device** | Razer Edge 5G & Wi-Fi (`nicole` / `RZ45-0460`) |
| **Chipset** | Qualcomm Snapdragon G3x Gen 1 (`lahaina` / SM8350) |
| **CPU** | Kryo Octa-core (1x Cortex-X1 @ 3.0GHz, 3x Cortex-A78 @ 2.42GHz, 4x Cortex-A55 @ 1.8GHz) |
| **GPU** | Adreno 660 |
| **Display** | 6.8" 2400 x 1080 FHD+ AMOLED, 144Hz |
| **Storage** | 128GB UFS 3.1 + MicroSD slot |
| **Battery** | 5000 mAh |
| **Architecture** | AArch64 (64-bit only) |
| **Partition Scheme** | Virtual A/B (VAB) with Dynamic Partitions (`super`) |
| **Recovery Type** | Recovery-as-Boot (`boot.img`) |
| **Base Branch** | `fox_14.1` (Android 14.1 base) |

---

## Build Instructions

### 1. Sync the OrangeFox `14.1` Sources
```bash
mkdir -p ~/OrangeFox_sync
cd ~/OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd ~/OrangeFox_sync/sync
./orangefox_sync.sh --branch 14.1 --path ~/fox_14.1
```

### 2. Clone this Device Tree
```bash
cd ~/fox_14.1
git clone https://github.com/joemossjr16/device_razer_nicole-OrangeFox.git -b fox_14.1 device/razer/nicole
```

### 3. Build OrangeFox Recovery
```bash
cd ~/fox_14.1
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_TYPE="Beta"
lunch fox_nicole-eng # or twrp_nicole-eng
mka bootimage -j$(nproc)
```

The output recovery images and flashable zip installer will be generated in `out/target/product/nicole/`.

---

## Installation

### Fastboot Boot (Temporary / Testing)
```bash
fastboot boot OrangeFox-nicole.img # or twrp-boot.img
```

### Permanent Flash (Dual A/B Slots)
1. Boot into OrangeFox Recovery via fastboot.
2. Push or copy `OrangeFox-*-nicole.zip` to your storage.
3. Tap **Install** -> Select the OrangeFox zip -> **Swipe to Flash**.
4. OrangeFox will automatically patch both slot A and slot B boot partitions and preserve recovery across ROM updates.

---

## Maintainer & Credits
- **Maintainer:** [joemossjr16](https://github.com/joemossjr16)
- **OrangeFox Recovery Project:** [https://gitlab.com/OrangeFox](https://gitlab.com/OrangeFox)
- **TeamWin Recovery Project (TWRP)**
- **LineageOS Project**
