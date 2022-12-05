#! /bin/bash

#
# Author: Badr BADRI © pythops
#

set -e

BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t210/jetson-210_linux_r32.5.1_aarch64.tbz2
JETSON_ROOTFS_DIR=/home/gary/Documents/workspace-router/jetson-nano-image-v2/rootfs
JETSON_BUILD_DIR=/home/gary/Documents/workspace-router/jetson-nano-image-v2/build
JETSON_NANO_BOARD=jetson-nano

# JETSON_NANO_BOARD=jetson-nano-2gb
# Revision only needed for non-2GB board!!

# For newest version (B01)
# JETSON_NANO_REVISION=300

# For older version (A01)
JETSON_NANO_REVISION=200

# Check if the user is not root
if [ "x$(whoami)" != "xroot" ]; then
        printf "\e[31mThis script requires root privilege\e[0m\n"
        exit 1
fi

# Check for env variables
if [ ! $JETSON_ROOTFS_DIR ] || [ ! $JETSON_BUILD_DIR ]; then
	printf "\e[31mYou need to set the env variables \$JETSON_ROOTFS_DIR and \$JETSON_BUILD_DIR\e[0m\n"
	exit 1
fi

# Check if $JETSON_ROOTFS_DIR if not empty
if [ ! "$(ls -A $JETSON_ROOTFS_DIR)" ]; then
	printf "\e[31mNo rootfs found in $JETSON_ROOTFS_DIR\e[0m\n"
	exit 1
fi

# Check if board type is specified
if [ ! $JETSON_NANO_BOARD ]; then
	printf "\e[31mJetson nano board type must be specified\e[0m\n"
	exit 1
fi

printf "\e[32mBuild the image ...\n"

# Create the build dir if it does not exists
mkdir -p $JETSON_BUILD_DIR

# Download L4T
if [ ! "$(ls -A $JETSON_BUILD_DIR)" ]; then
        printf "\e[32mDownload L4T...       "
        wget -qO- $BSP | tar -jxpf - -C $JETSON_BUILD_DIR
	rm $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/README.txt
        printf "[OK]\n"
fi

cp -rp $JETSON_ROOTFS_DIR/*  $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/ > /dev/null

patch $JETSON_BUILD_DIR/Linux_for_Tegra/nv_tegra/nv-apply-debs.sh < patches/nv-apply-debs.diff

pushd $JETSON_BUILD_DIR/Linux_for_Tegra/ > /dev/null

printf "Extract L4T...        "
./apply_binaries.sh > /dev/null
printf "[OK]\n"

pushd $JETSON_BUILD_DIR/Linux_for_Tegra/tools
case "$JETSON_NANO_BOARD" in
    jetson-nano-2gb)
        printf "Create image for Jetson nano 2GB board"
        ./jetson-disk-image-creator.sh -o jetson.img -b jetson-nano-2gb-devkit
        printf "OK\n"
        ;;

    jetson-nano)
        nano_board_revision=${JETSON_NANO_REVISION:=300}
        printf "Create image for Jetson nano board (%s revision)" $nano_board_revision
        ./jetson-disk-image-creator.sh -o jetson.img -b jetson-nano -r $nano_board_revision
        printf "OK\n"
        ;;

    *)
	printf "\e[31mUnknown Jetson nano board type\e[0m\n"
	exit 1
        ;;
esac


printf "\e[32mImage created successfully\n"
printf "Image location: $JETSON_BUILD_DIR/Linux_for_Tegra/tools/jetson.img\n"
