#!/usr/bin/env bash

 #
 # Script For Building Android Kernel
 #

##----------------------------------------------------------##
# Specify Kernel Directory
KERNEL_DIR="$(pwd)"

##----------------------------------------------------------##
# Kernel Version Code
VERSION=CyberPunk-v1.4

##----------------------------------------------------------##
# Device Name and Model
MODEL=Xiaomi
DEVICE=MiAtoll

# Kernel Defconfig
DEFCONFIG=cust_defconfig

# Files
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz
DTBO=$(pwd)/out/arch/arm64/boot/dtbo.img
DTB=$(pwd)/out/arch/arm64/boot/dts/qcom/cust-atoll-ab.dtb

# Verbose Build
VERBOSE=0

# Kernel Version
KERVER=$(make kernelversion)

COMMIT_HEAD=$(git log --oneline -1)

# Date and Time
DATE=$(TZ=Asia/Kolkata date +"%Y%m%d-%T")
TANGGAL=$(date +"%F%S")

# Specify Final Zip Name
ZIPNAME=Velvet
FINAL_ZIP=${ZIPNAME}-${VERSION}-${DEVICE}-${TANGGAL}.zip

##----------------------------------------------------------##
# Specify compiler.

COMPILER=neutron

##----------------------------------------------------------##
# Specify Linker

LINKER=ld.lld

##----------------------------------------------------------##
# Clone ToolChain
function cloneTC() {

	if [ $COMPILER = "atomx" ];
	then
        post_msg " Cloning Atomx Clang ToolChain "
	git clone --depth=1 https://gitlab.com/ElectroPerf/atom-x-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

        elif [ $COMPILER = "neutron" ];
        then
        post_msg " Cloning Neutron Clang ToolChain "
        git clone --depth=1 https://gitlab.com/dakkshesh07/neutron-clang.git clang
        PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "azure" ];
	then
        post_msg " Cloning Azure Clang ToolChain "
	git clone --depth=1 https://gitlab.com/Panchajanya1999/azure-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "proton-13" ];
	then
        post_msg " Cloning Proton Clang 13 ToolChain "
	git clone --depth=1 https://github.com/kdrag0n/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

        elif [ $COMPILER = "proton-15" ];
	then
	post_msg " Cloning Proton Clang 15 ToolChain "
	git clone --depth=1 https://gitlab.com/LeCmnGend/proton-clang.git clang
	PATH="${KERNEL_DIR}/clang/bin:$PATH"

	elif [ $COMPILER = "eva" ];
	then
        post_msg " Cloning Eva GCC ToolChain "
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git gcc64
	git clone --depth=1 https://github.com/mvaisakh/gcc-arm.git gcc32
	PATH=$KERNEL_DIR/gcc64/bin/:$KERNEL_DIR/gcc32/bin/:/usr/bin:$PATH

	elif [ $COMPILER = "aosp" ];
	then
        post_msg " Cloning Aosp Clang 14.0.4 ToolChain "
        mkdir aosp-clang
        cd aosp-clang || exit
	wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r450784b.tar.gz
        tar -xf clang*
        cd .. || exit
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_aarch64_aarch64-linux-android-4.9.git --depth=1 gcc
	git clone https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9.git  --depth=1 gcc32
	PATH="${KERNEL_DIR}/aosp-clang/bin:${KERNEL_DIR}/gcc/bin:${KERNEL_DIR}/gcc32/bin:${PATH}"
	fi
        # Clone AnyKernel
        git clone --depth=1 https://github.com/Excalibur-99/AnyKernel3

        }

##------------------------------------------------------##
# Export Variables
function exports() {

        # Export KBUILD_COMPILER_STRING
        if [ -d ${KERNEL_DIR}/clang ];
           then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        elif [ -d ${KERNEL_DIR}/gcc64 ];
           then
               export KBUILD_COMPILER_STRING=$("$KERNEL_DIR/gcc64"/bin/aarch64-elf-gcc --version | head -n 1)
        elif [ -d ${KERNEL_DIR}/aosp-clang ];
            then
               export KBUILD_COMPILER_STRING=$(${KERNEL_DIR}/aosp-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')
        fi

        # Export ARCH and SUBARCH
        export ARCH=arm64
        export SUBARCH=arm64

        # Export Local Version
        export LOCALVERSION="-${VERSION}"

        # KBUILD HOST and USER
        export KBUILD_BUILD_HOST=DroneCI
        export KBUILD_BUILD_USER="TxExcalibur"

        # CI
        if [ "$CI" ]
           then

           if [ "$CIRCLECI" ]
              then                  
                  export CI_BRANCH=${CIRCLE_BRANCH}
           elif [ "$DRONE" ]
	      then		  
		  export CI_BRANCH=${DRONE_BRANCH}
              fi

        fi
	export PROCS=$(nproc --all)
	export DISTRO=$(source /etc/os-release && echo "${NAME}")
	}

##----------------------------------------------------------------##
# Telegram Bot Integration

function post_msg() {
	curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
	-d chat_id="$chat_id" \
	-d "disable_web_page_preview=true" \
	-d "parse_mode=html" \
	-d text="$1"
	}

function push() {
	curl -F document=@$1 "https://api.telegram.org/bot$token/sendDocument" \
	-F chat_id="$chat_id" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=html" \
	-F caption="$2"
	}
##----------------------------------------------------------------##
# Compilation
function compile() {
START=$(date +"%s")
	# Push Notification
        post_msg "<b>$KBUILD_BUILD_VERSION CI Build Triggered</b>%0A<b>Docker OS: </b><code>$DISTRO</code>%0A<b>Kernel Version : </b><code>$KERVER</code>%0A<b>Date : </b><code>$(TZ=Asia/Kolkata date)</code>%0A<b>Device : </b><code>$MODEL [$DEVICE]</code>%0A<b>Version : </b><code>$VERSION</code>%0A<b>Pipeline Host : </b><code>$KBUILD_BUILD_HOST</code>%0A<b>Host Core Count : </b><code>$PROCS</code>%0A<b>Compiler Used : </b><code>$KBUILD_COMPILER_STRING</code>%0A<b>Linker : </b><code>$LINKER</code>%0a<b>Branch : </b><code>$CI_BRANCH</code>%0A<b>Top Commit : </b><a href='$DRONE_COMMIT_LINK'>$COMMIT_HEAD</a>"
	# Compile
	make O=out ARCH=arm64 ${DEFCONFIG}
	if [ -d ${KERNEL_DIR}/clang ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=clang \
	       HOSTCC=clang \
	       HOSTCXX=clang++ \
	       CROSS_COMPILE=aarch64-linux-gnu- \
	       CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
	       LD=${LINKER} \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
	       STRIP=llvm-strip \
	       READELF=llvm-readelf \
	       OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
	elif [ -d ${KERNEL_DIR}/gcc64 ];
	   then
	       make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CROSS_COMPILE_ARM32=arm-eabi- \
	       CROSS_COMPILE=aarch64-elf- \
	       LD=aarch64-elf-${LINKER} \
	       AR=llvm-ar \
	       NM=llvm-nm \
	       OBJCOPY=llvm-objcopy \
	       OBJDUMP=llvm-objdump \
	       STRIP=llvm-strip \
	       OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
        elif [ -d ${KERNEL_DIR}/aosp-clang ];
           then
               make -kj$(nproc --all) O=out \
	       ARCH=arm64 \
	       CC=clang \
               HOSTCC=clang \
	       HOSTCXX=clang++ \
	       CLANG_TRIPLE=aarch64-linux-gnu- \
	       CROSS_COMPILE=aarch64-linux-android- \
	       CROSS_COMPILE_ARM32=arm-linux-androideabi- \
               LD=${LINKER} \
               AR=llvm-ar \
               NM=llvm-nm \
               OBJCOPY=llvm-objcopy \
               OBJDUMP=llvm-objdump \
               STRIP=llvm-strip \
               READELF=llvm-readelf \
               OBJSIZE=llvm-size \
	       V=$VERBOSE 2>&1 | tee error.log
        fi

	# Verify Files
	if ! [ -a "$IMAGE" ];
	   then
	       push "error.log" "Build Throws Errors"
	       exit 1
	   else
      	       post_msg " Kernel Compilation Finished. Started Zipping "
	fi
	}

##----------------------------------------------------------------##
function zipping() {
	# Copy Files To AnyKernel3 Zip
	cp $IMAGE AnyKernel3
	cp $DTBO AnyKernel3
        cp $DTB AnyKernel3/dtb
	# Zipping and Push Kernel
	cd AnyKernel3 || exit 1
        zip -r9 ${FINAL_ZIP} *
        MD5CHECK=$(md5sum "$FINAL_ZIP" | cut -d' ' -f1)
        push "$FINAL_ZIP" "Build took : $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) | For <b>$MODEL ($DEVICE)</b> | <b>${KBUILD_COMPILER_STRING}</b> | <b>MD5 Checksum : </b><code>$MD5CHECK</code>"
        cd ..
        }

##----------------------------------------------------------##

cloneTC
exports
configs
compile
END=$(date +"%s")
DIFF=$(($END - $START))
zipping

##----------------*****-----------------------------##
