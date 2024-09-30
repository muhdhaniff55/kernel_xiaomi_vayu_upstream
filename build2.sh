#!/bin/bash

kernel_dir="${PWD}"
CCACHE=$(command -v ccache)
objdir="${kernel_dir}/out"
anykernel=$HOME/anykernel
builddir="${kernel_dir}/build"
ZIMAGE=$kernel_dir/out/arch/arm64/boot/Image
kernel_name="AnymoreProject_vayu_"
zip_name="$kernel_name$(date +"%Y%m%d").zip"
CLANG_DIR=${kernel_dir}/toolchain
export CONFIG_FILE="vayu_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_HOST="AnymoreProject"
export KBUILD_BUILD_USER=home

export PATH="$CLANG_DIR/bin:$PATH"

if [ ! -d "$CLANG_DIR" ]; then
    echo "Toolchain not found! Cloning to $CLANG_DIR..."
    curl -L -o toolchain.tar.gz "https://github.com/ZyCromerZ/Clang/releases/download/20.0.0git-20240926-release/Clang-20.0.0git-20240926.tar.gz"
    tar -xf toolchain.tar.gz -C "$CLANG_DIR"
    rm toolchain.tar.gz
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
    python3 mkdtoimg create $anykernel/dtbo.img --page_size=4096 out/arch/arm64/boot/dts/qcom/vayu-sm8150-overlay.dtbo
    find out/arch/arm64/boot/dts/qcom -name 'sm8150-v2*.dtb' -exec cat {} + > $anykernel/dtb
}
completion()
{
    cd ${objdir}
    COMPILED_IMAGE=arch/arm64/boot/Image
    COMPILED_DTBO=arch/arm64/boot/dtbo.img
    if [[ -f ${COMPILED_IMAGE} && ${COMPILED_DTBO} ]]; then

        git clone -q https://github.com/muhdhaniff55/AnyKernel3.git -b anothermaster $anykernel

        mv -f $ZIMAGE ${COMPILED_DTBO} $anykernel

        cd $anykernel
        find . -name "*.zip" -type f
        find . -name "*.zip" -type f
        zip -r AnyKernel.zip *
        mv AnyKernel.zip $zip_name
        mv $anykernel/$zip_name $HOME/$zip_name
        rm -rf $anykernel
        echo -e ${LGR} "#### build completed successfully (hh:mm:ss) ####"
        exit 0
    else
        echo -e ${LGR} "#### failed to build some targets (hh:mm:ss) ####"

    fi
}
make_defconfig
compile
sdk
completion
cd ${kernel_dir}
