#!/bin/bash

# Credits:
# Base arch linux arm for rpi 4 - https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-4
# Boot for rpi 5 (this way reqs wired internet connection) - https://kiljan.org/2023/11/24/arch-linux-arm-on-a-raspberry-pi-5-model-b/

set -e
DEVICE="/dev/sdb"
LINUX_RPI_VER="6.12.30-1"
BOOT_PART="${DEVICE}1"
ROOT_PART="${DEVICE}2"
MOUNT_BOOT="./work/boot"
MOUNT_ROOT="./work/root"
DWNL_DIR="./dwnl"
SRC_DIR="./src"
ARM_TAR_PATH="$DWNL_DIR/archarm.tar.gz"
LINUX_RPI_TAR_PATH="$DWNL_DIR/linux-rpi.tar.xz"
ARM_DIR="$SRC_DIR/archarm"
LINUX_RPI_DIR="$SRC_DIR/linux-rpi"
SECONDS=0

echo "--- Preparing..."
read -p "Enter target device path [/dev/sdb] "
if [ ! -z $REPLY ]; then
    DEVICE=$REPLY
fi
echo "Downloading ArchLinuxARM-rpi-aarch64-latest.tar.gz ... [1/2]"
if [ ! -f $ARM_TAR_PATH ]; then
    wget -O $ARM_TAR_PATH http://os.archlinuxarm.org/os/ArchLinuxARM-rpi-aarch64-latest.tar.gz || { rm $ARM_TAR_PATH && exit; }
    mkdir $ARM_DIR
    sudo tar -xzf $ARM_TAR_PATH -C $ARM_DIR
else
    echo "Already downloaded"
fi
echo "Downloading linux-rpi-$LINUX_RPI_VER-aarch64.pkg.tar.xz ... [2/2]"
if [ ! -f $LINUX_RPI_TAR_PATH ]; then
    wget -O $LINUX_RPI_TAR_PATH http://mirror.archlinuxarm.org/aarch64/core/linux-rpi-$LINUX_RPI_VER-aarch64.pkg.tar.xz || { echo "!! If this download fails, check rpi-aarch64-latest version at https://archlinuxarm.org/packages/aarch64/linux-rpi and set correct version to LINUX_RPI_VER" && rm $LINUX_RPI_TAR_PATH && exit; }
    mkdir $LINUX_RPI_DIR
    sudo tar -xJf $LINUX_RPI_TAR_PATH -C $LINUX_RPI_DIR
else
    echo "Already downloaded"
fi
echo "--- Copying preinstall files"
sudo mkdir $ARM_DIR/etc/preinstall/ || true
sudo cp $SRC_DIR/preinstall/preinstall.sh $ARM_DIR/etc/preinstall/ || true
sudo cp $LINUX_RPI_TAR_PATH $ARM_DIR/etc/preinstall/ || true
sudo cp $SRC_DIR/preinstall/preinstall.service $ARM_DIR/etc/systemd/system/ || true
sudo ln -s /etc/systemd/system/preinstall.service $ARM_DIR/etc/systemd/system/multi-user.target.wants/preinstall.service || true

echo "Gonna delete everything from $DEVICE/"
read -p "Continue? [y/N] " -n 1 -r
echo
if [ ! $REPLY =~ ^[Yy]$ ]; then
    exit 1
fi

echo "--- Partitioning..." # hate this shit bukt it works !! :3
{
echo o
echo n
echo p
echo 1
echo
echo +200M
echo t
echo c
echo n
echo p
echo 2
echo
echo
echo w
} | sudo fdisk "$DEVICE"

sudo partprobe "$DEVICE"
sleep 3

echo "Creating filesystems..."
sudo mkfs.vfat -F32 "$BOOT_PART"
sudo mkfs.ext4 -F "$ROOT_PART"

echo "Mounting boot and root..."
mkdir -p "$MOUNT_BOOT" "$MOUNT_ROOT"
sudo mount "$BOOT_PART" "$MOUNT_BOOT"
sudo mount "$ROOT_PART" "$MOUNT_ROOT"

echo "--- Copying root and boot..."
echo "Copying root... [1/2]"
sudo cp -r "$ARM_DIR/"* "$MOUNT_ROOT/"
echo "Copying boot... [2/2]"
sudo cp -r "$LINUX_RPI_DIR/boot/"* "$MOUNT_BOOT/"

echo "--- Syncing..."
sync

echo "--- Unmounting..."
sudo umount "$MOUNT_BOOT" "$MOUNT_ROOT"
rmdir "$MOUNT_BOOT" "$MOUNT_ROOT"

echo "Finished in $SECONDS seconds"
echo "--- Completed! :3"
