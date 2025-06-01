#!/bin/bash

# Credits:
# Boot for rpi 5 (this way reqs wired internet connection) - https://kiljan.org/2023/11/24/arch-linux-arm-on-a-raspberry-pi-5-model-b/

set -e

if [ -f "./PREINSTALLLOCK" ]; then
    exit 0
fi

echo "Please wait, doing preinstall things. This programm should run only once. System will reboot soon..."
pacman-key --init
pacman-key --populate archlinuxarm
pacman -R --noconfirm linux-aarch64 uboot-raspberrypi
pacman -U --overwrite "/boot/*" --noconfirm /etc/preinstall/linux-rpi.tar.xz

touch PREINSTALLLOCK
systemctl reboot

