#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
ANYKERNEL="/workspace/jale/AnyKernel3"
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
TC_DIR="/workspace/"
KERNEL_LOG="$KERNEL_DIR/out/log-$(TZ=Asia/Jakarta date +'%H%M').txt"
MKDTBOIMG="/workspace/jale/libufdt/utils/src/mkdtboimg.py"
CLANG_DIR="/workspace/jale/clang/clang-r530560"
GCC64_DIR="/workspace/jale/gcc64/aarch64--glibc--stable-2024.02-1"
GCC32_DIR="/workspace/jale/gcc32"
export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="AnymoreProject"
export KBUILD_BUILD_USER="t.me"

export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$GCC32_DIR/bin:$PATH"

if ! [ -d "$CLANG_DIR" ]; then
    echo "Toolchain not found! Cloning to $CLANG_DIR..."
    if ! git clone -q --depth=1 --single-branch https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r530567.git -b 14.0 $TC_DIR; then
        echo "Cloning failed! Aborting..."
        exit 1
    fi
fi

# Colors
NC='\033[0m'
RED='\033[0;31m'
LRD='\033[1;31m'
LGR='\033[1;32m'

make_defconfig()
{
    START=$(date +"%s")
    echo -e ${LGR} "########### Generating Defconfig ############${NC}"
    make -s ARCH=${ARCH} O=${objdir} ${CONFIG_FILE} -j$(nproc --all)
}
compile()
{
    cd ${kernel_dir}
    echo -e ${LGR} "######### Compiling kernel #########${NC}"
    make -j$(nproc --all) \
    O=out \
    ARCH=arm64                              \
    SUBARCH=arm64                           \
    DTC_EXT=dtc				    \
    CLANG_TRIPLE=aarch64-linux-gnu-         \
    CROSS_COMPILE=aarch64-linux-gnu-        \
    CROSS_COMPILE_ARM32=arm-linux-gnueabi-  \
    CROSS_COMPILE_COMPAT=arm-linux-gnueabi- \
    LD=ld.lld                               \
    AR=llvm-ar                              \
    NM=llvm-nm                              \
    STRIP=llvm-strip                        \
    OBJCOPY=llvm-objcopy                    \
    OBJDUMP=llvm-objdump                    \
    READELF=llvm-readelf                    \
    HOSTCC=clang                            \
    HOSTCXX=clang++                         \
    HOSTAR=llvm-ar                          \
    HOSTLD=ld.lld                           \
    LLVM=1                                  \
    LLVM_IAS=1                              \
    CC="ccache clang"                       \
    $1
}
sdk()
{
    python3 $MKDTBOIMG create $ANYKERNEL/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
    find out/arch/arm64/boot/dts/qcom -name 'sm8150-v2*.dtb' -exec cat {} + > $ANYKERNEL/dtb
}
completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} ]]; then
        echo -e ${LGR} "############################################"
        echo -e ${LGR} "############# OkThisIsEpic!  ##############"
        echo -e ${LGR} "############################################${NC}"
        exit 0
    else
        echo -e ${RED} "############################################"
        echo -e ${RED} "##         This Is Not Epic :'(           ##"
        echo -e ${RED} "############################################${NC}"
        exit 1
    fi
}
make_defconfig
compile
sdk
completion
cd ${kernel_dir}
