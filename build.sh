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

# Device related
A225G(){
    DEVICE_KERNEL_BOARD='SRPTL28A009'
    DEVICE_KERNEL_BASE=0x40078000
    DEVICE_KERNEL_PAGESIZE=2048
    DEVICE_RAMDISK_OFFSET=0x11088000
    DEVICE_SECOND_OFFSET=0xbff88000
    PLATFORM_VERSION="12.0.0"
    PLATFORM_PATCH_LEVEL="2024-03"
    DEVICE_KERNEL_CMDLINE="" 
    DEVICE_KERNEL_HEADER=2
    DEVICE_DTB_HASHTYPE='sha1'  
    DEVICE_KERNEL_OFFSET=0x00008000 
    DEVICE_TAGS_OFFSET=0x07c08000
    DEVICE_HEADER_SIZE=1660
}


function compile() 
{
clangbin=clang/bin/clang
if ! [ -a $clangbin ]; then git clone --depth=1 https://github.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-6443078 clang
fi
gcc64bin=gcc64/bin/aarch64-linux-android-as
if ! [ -a $gcc64bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9 gcc64
fi
gcc32bin=gcc32/bin/arm-linux-androideabi-as
if ! [ -a $gcc32bin ]; then git clone --depth=1 https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9 gcc32
fi
rm -rf AnyKernel
make O=out ARCH=arm64 a22x_defconfig
PATH="${PWD}/clang/bin:${PATH}:${PWD}/gcc32/bin:${PATH}:${PWD}/gcc64/bin:${PATH}" \
make -j$(nproc --all) O=out \
                      ARCH=arm64 \
                      CC="clang" \
                      CLANG_TRIPLE=aarch64-linux-gnu- \
                      CROSS_COMPILE="${PWD}/gcc64/bin/aarch64-linux-android-" \
                      CROSS_COMPILE_ARM32="${PWD}/gcc32/bin/arm-linux-androideabi-" \
                      LD=ld.lld \
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
