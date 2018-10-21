# Helps to save user settings
# Based on https://unix.stackexchange.com/questions/175648/use-config-file-for-my-shell-script
export kernel_config_file=$HOME/.bin/kernel-builder.conf

typeset -A kernel_config
kernel_config=(
[arch]=arm64
[toolchain]=aosp-gcc
)

function load_kernel-configs() {
    if [ -f "$kernel_config_file" ]; then
        while read line; do
            if echo $line | grep -F = &>/dev/null; then
                varname=$(echo "$line" | cut -d '=' -f 1)
                kernel_config[$varname]=$(echo "$line" | cut -d '=' -f 2-)
            fi
        done < $kernel_config_file
    fi
}

function save_kernel-configs() {
    parent_dir=$(dirname $kernel_config_file)
    if [ ! -d "$parent_dir" ]; then
        mkdir -p $parent_dir
    fi
    > $kernel_config_file
    for i in "${!kernel_config[@]}"; do
        echo "$i=${kernel_config[$i]}" >> $kernel_config_file
    done
}

function get_kernel-config() {
    printf %s "${kernel_config[$1]}"
}

function set_kernel-config() {
    kernel_config[$1]=$2
}
