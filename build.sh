#!/usr/bin/env bash
BASE_DIR="$(pwd)"
SOURCEDIR="${BASE_DIR}/work"
rm -rf "${SOURCEDIR}"
mkdir -p "${SOURCEDIR}"
cd "${SOURCEDIR}"
export CI=true
export ALLOW_MISSING_DEPENDENCIES=true
repo init --depth=1 -u https://github.com/LineageOS/android -b lineage-19.1
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
git clone --depth=1 https://github.com/PixelExperience-Devices/device_xiaomi_miatoll.git device/xiaomi/miatoll
git clone --depth=1 https://github.com/PixelExperience-Devices/device_xiaomi_sm6250-common.git device/xiaomi/sm6250-common
git clone --depth=1 https://gitlab.pixelexperience.org/android/vendor-blobs/vendor_xiaomi_miatoll.git vendor/xiaomi/miatoll
git clone --depth=1 https://gitlab.pixelexperience.org/android/vendor-blobs/vendor_xiaomi_sm6250-common.git vendor/xiaomi/sm6250-common
git clone --depth=1 https://github.com/LineageOS/android_kernel_xiaomi_sm6250.git kernel/xiaomi/sm6250
git clone --depth=1 https://github.com/PixelExperience/hardware_xiaomi.git hardware/xiaomi
git clone --depth=1 https://gitlab.pixelexperience.org/android/vendor-blobs/vendor_xiaomi_miatoll-gcam.git vendor/xiaomi/miatoll-gcam
cd device/xiaomi/miatoll
sed -i 's/aosp/lineage/g' aosp_miatoll.mk AndroidProducts.mk device.mk
mv aosp_miatoll.mk lineage_miatoll.mk
mv aosp.dependencies lineage.dependencies
cd -
source build/envsetup.sh
lunch aosp_miatoll-userdebug
mka -j$(nproc) bacon
cd out/target/product/miatoll
curl --upload-file *PixelExperence*miatoll*.zip https://transfer.sh
cd -
exit 0
