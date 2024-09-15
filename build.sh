#!/bin/bash
#
KERNEL_DIR=$(pwd)
AIK="/home/itachi/Desktop/AIK"
SP="/home/itachi/Desktop/AIK/split_img"
ZIMG=out/arch/arm64/boot/Image

# arch & build
export ARCH=arm64
export KBUILD_BUILD_HOST=android-build
export KBUILD_BUILD_USER="Itachi"

# Toolchain directory
TOOLCHAIN_DIR="${KERNEL_DIR}/toolchain"

# Check if toolchain exists, if not clone it
if [ ! -d "${TOOLCHAIN_DIR}" ]; then
    echo "Toolchain not found, cloning..."
    git clone --depth=1 https://gitlab.com/neel0210/toolchain.git "${TOOLCHAIN_DIR}"
fi

# Set GCC, Clang, and Clang Triple paths
GCC64_PATH="${TOOLCHAIN_DIR}/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
CLANG_PATH="${TOOLCHAIN_DIR}/clang/host/linux-x86/clang-r383902/bin/clang"
CLANG_TRIPLE_PATH="${TOOLCHAIN_DIR}/clang/host/linux-x86/clang-r383902/bin/aarch64-linux-gnu-"

# Device-related settings


function compile() 
{
    # Make sure the toolchain paths are correct in Makefile
    sed -i "s|^CROSS_COMPILE=.*|CROSS_COMPILE=${GCC64_PATH}|" Makefile
    sed -i "s|^CC=.*|CC=${CLANG_PATH}|" Makefile
    sed -i "s|^CLANG_TRIPLE=.*|CLANG_TRIPLE=${CLANG_TRIPLE_PATH}|" Makefile

    # Set environment variables for Android version and architecture
    export ANDROID_MAJOR_VERSION=r
    export ARCH=arm64

    # Clean any previous build artifacts
    rm -rf AnyKernel

    # Compile the kernel
        make O=out ARCH=arm64 a22x_defconfig
	make -j$(nproc --all) O=out \
        ARCH=arm64 \
        CC="clang" \
        CLANG_TRIPLE=aarch64-linux-gnu- \
        CROSS_COMPILE="${GCC64_PATH}" \
        CC="${CLANG_PATH}" \
        CLANG_TRIPLE="${CLANG_TRIPLE_PATH}" \
        CONFIG_NO_ERROR_ON_MISMATCH=y
}

check_build(){
    echo " " && echo " "
    echo -e "${YELLOW}                     x Building Boot.img x"
    A225G
    #
    $(pwd)/tools/make/bin/mkbootimg \
              --kernel $ZIMG \
              --cmdline " " --board "$DEVICE_KERNEL_BOARD" \
              --base $DEVICE_KERNEL_BASE --pagesize $DEVICE_KERNEL_PAGESIZE \
              --kernel_offset $DEVICE_KERNEL_OFFSET --ramdisk_offset $DEVICE_RAMDISK_OFFSET \
              --second_offset $DEVICE_SECOND_OFFSET --tags_offset $DEVICE_TAGS_OFFSET \
              --os_version "$PLATFORM_VERSION" --os_patch_level "$PLATFORM_PATCH_LEVEL" \
              --header_version $DEVICE_KERNEL_HEADER --hashtype $DEVICE_DTB_HASHTYPE \
              -o $KERNEL_DIR/boot.img
              sleep 2
    #
    if [ -f ${KERNEL_DIR}/boot.img ];then
        echo -e "${GRN}Image has been built at $(pwd)/boot.img${RST}"
    else
        echo -e "${RED}Check for error"
    fi
}

# UPLOAD
upload(){
    if [ -f $(pwd)/boot.img ];then
        for i in boot.img
        do
        curl -F "document=@$i" --form-string "caption=" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument?chat_id=${CHAT_ID}&parse_mode=HTML"
        done
    else
        echo -e "${RED}Boot image not found"
    fi
}

compile
check_build
upload
