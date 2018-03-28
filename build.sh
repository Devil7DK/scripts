ROM_NAME="${PWD##*/}" #Usually i use the rom name for its dir. So get name from there
DEVICE_NAME=land
export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 100G
export KBUILD_BUILD_USER=devil7
export KBUILD_BUILD_HOST=Alone
source build/envsetup.sh
lunch "${ROM_NAME}_${DEVICE_NAME}-userdebug"
case $ROM_NAME in
	aicp|lineage|candy)time brunch  ${DEVICE_NAME} 2>&1 | tee build.log ;;
	viper|aosvp)time mka poison 2>&1 | tee build.log ;;
	citrus)time mka lemonade -j$(($(nproc)*2)) 2>&1 | tee build.log ;;
        *)time mka bacon 2>&1 | tee build.log ;;
esac;
