ROM_NAME="${PWD##*/}" #Usually i use the rom name for its dir. So get name from there
export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 100G
export KBUILD_BUILD_USER=devil7
export KBUILD_BUILD_HOST=Alone
source build/envsetup.sh
lunch "${ROM_NAME}_land-userdebug"
