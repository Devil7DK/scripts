script_path=$BASH_SOURCE
script_dir=$(dirname "$script_path")

# Import Scripts
source $script_dir/colors.sh
source $script_dir/toolchains.sh

function show_banner() {
    echo -e "\n${BLUE}==================================================================================================================${NC}"
    echo -e "${BLUE}________              .__.__${DARKGRAY}_________  ${BLUE}        ${WHITE}  _________       _____  __                                        ${NC}"
    echo -e "${BLUE}\______ \   _______  _|__|  ${DARKGRAY}\______  \ ${BLUE}        ${WHITE} /   _____/ _____/ ____\/  |___  _  _______  ______   ____   ______${NC}"
    echo -e "${BLUE} |    |  \_/ __ \  \/ /  |  |   ${DARKGRAY}/    / ${BLUE} ______ ${WHITE} \_____  \ /  _ \   __\\|   __\ \/ \/ /\__  \\|_  __ \_/ __ \ /  ___/${NC}"
    echo -e "${BLUE} |    \`   \  ___/\   /|  |  |__${DARKGRAY}/    /  ${BLUE}/_____/ ${WHITE} /        (  <_> )  |   |  |  \     /  / __ \|  | \/\  ___/ \___ \ ${NC}"
    echo -e "${BLUE}/_______  /\___  >\_/ |__|____/${DARKGRAY}____/   ${BLUE}        ${WHITE}/_______  /\____/|__|   |__|   \/\_/  (____  /__|    \___  >____  >${NC}"
    echo -e "${BLUE}        \/     \/              ${DARKGRAY}        ${BLUE}        ${WHITE}        \/                                 \/            \/     \/ ${NC}"
    echo -e "${BLUE}==================================================================================================================${NC}"
}

function setup() {
    case $1 in
        kernel-building)
            setup-kernel-building
        ;;
        *)
            echo -e $RED"Invalid Parameter."$NC
        ;;
    esac
}

function setup-kernel-building() {
    echo -e $GREEN"Preparing Environment for Kernel Building..."$NC
    echo -e $BLUE"Pick ARCH for building:"$YELLOW
    select arch in arm arm64 ;
    do
        case "$arch" in
            arm)
                export ARCH=arm
                export SUBARCH=arm
                break
                ;;
            arm64)
                export ARCH=arm64
                export SUBARCH=arm64
                break
                ;;
        esac
    done
    echo -e $GREEN"Selected Arch: $arch"$NC
    echo ""

    echo -e $BLUE"Pick toolchain for building:"$YELLOW
    select tc in aosp-gcc aosp-clang ;
    do
        case "$tc" in
            aosp-gcc)
                setup-aosp-gcc
                break
                ;;
            aosp-clang)
                setup-aosp-gcc
                setup-aosp-clang
                break
                ;;
        esac
    done
    echo -e $NC
    # Export Other Variables
    export O=out/
    export USE_CCACHE=1

    mkdir -p out
    echo -e $GREEN"Setup completed..."$NC
}

function setup-aosp-gcc() {
    echo -e $GREEN"Setting up GCC for $arch architecture..."$NC
    case $arch in
        arm)
            setup_toolchain $tc_aosp_gcc_arm_path $tc_aosp_gcc_arm $tc_aosp_branch
            export CROSS_COMPILE=arm-linux-androideabi-
            break
            ;;
        arm64)
            setup_toolchain $tc_aosp_gcc_arm64_path $tc_aosp_gcc_arm64 $tc_aosp_branch
            export CROSS_COMPILE=aarch64-linux-android-
            break
            ;;
        *)
            echo -e $RED"Unknown/Unsupported Arch! Aborting..."$NC && exit 1
    esac
}

function setup-aosp-clang() {
    echo -e $GREEN"Setting up clang..."$NC
    setup_toolchain $tc_aosp_clang_path $tc_aosp_clang $tc_aosp_branch
    export CC="$tc_aosp_clang_path/bin/clang"
    export CLANG_TRIPLE=aarch64-linux-gnu-
}

# Check Path & Clone Toolchain if it doesn't exist
function setup_toolchain() {
    path=$1
    url=$2
    branch=$3

    if [ ! -d "$path" ]; then
        parent=$(dirname $path)
        mkdir -p "$parent"
        echo -e $GREEN"Cloning toolchain..."$NC
        git clone --depth=2 $url -b $branch $path > /dev/null 2>&1 || (echo -e $RED"Unable to clone toolchain! Aborting..."$NC && exit 1)
    fi

    export PATH=$PATH:$path/bin
}

# make_kernel <device_name> <additional_parms>
function make_kernel() {
    device=$1
    add_parms=$2

    echo -e $GREEN"Building for $device"$NC
    make mrproper &&
    make clean &&
    make ${device}_defconfig &&
    time make -j$(($(nproc)*2)) $add_parms 2>&1 | tee build.log
}

# Syntax:
#        selected_value=$(selectWithDefault <default_value> <values>)
#        selected_value=$(selectWithDefault option2 option1 option2 option3)
#
# Based on https://stackoverflow.com/questions/42789273/bash-choose-default-from-case-when-enter-is-pressed-in-a-select-prompt
selectWithDefault() {
    local item i=0 numItems=$#

    # Print numbered menu items, based on the arguments passed.
    for item in "${@:2}"; do # Skip first arg as its default value
        printf '%s\n' "$((++i))) $item"
    done >&2 # Print to stderr, as `select` does.

    # Prompt the user for the index of the desired item.
    while :; do
        printf %s "${PS3-#? [$1] }" >&2 # Print the prompt string to stderr, as `select` does.
        read -r index
        # Make sure that the input is either empty or that a valid index was entered.
        [[ -z $index ]] && break  # empty input
        (( index >= 1 && (index+1) <= numItems )) 2>/dev/null || { echo "Invalid selection. Please try again." >&2; continue; }
        break
    done

    # Output the selected item, if any.
    if [[ -n $index ]]; then
        printf %s "${@: (index+1):1}" # Return selected item
    else
        printf %s "$1" # Return default
    fi
}
