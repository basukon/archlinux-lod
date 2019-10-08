#!/bin/bash

# Script with the future idea of adapting it to generate any 
# linux distro image.
#
# Notes to remember:
# blkid image_name.img to view the image details.
#
# To edit the image arm image on x86_64:
# ================================================================
# This provides the qemu-aarch64-static binary
# yay -S qemu-arm-static
#
# Mount my target filesystem on /mnt
# mount -o loop fs.img loddir
#
# Copy the static ARM binary that provides emulation
# cp $(which qemu-aarch64-static) loddir/usr/bin
# Or, more simply: cp /usr/bin/qemu-aarch64-static loddir/usr/bin
#
# Finally chroot into loddir, then run 'qemu-aarch64-static bash'
# This chroots; runs the emulator; and the emulator runs bash
#
# cp /etc/resolv.conf loddir/etc/
# chroot loddir qemu-arm-static /bin/bash
# ================================================================

if [ ! -e "/usr/bin/arch-chroot" ]; then
    echo "Please install arch-chroot to continue."
    exit
fi

if [ ! -e "/usr/bin/qemu-aarch64-static" ]; then
    echo "Please install qemu-arm-static for qemu-aarch64-static support."
    exit
fi

if [ ! -e "FileSystems" ]; then
    mkdir FileSystems
fi

function make_archlinux {
    distro="ArchLinux"
    url="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
    directory=archlinux
    filesystem=ArchLinuxARM-aarch64-latest.tar.gz
    image_name=ArchLinux_LoD.img
    image_size=3076
    setup_file=archlinux_setup.sh

    if [ ! -d "${directory}" ]; then
        mkdir $directory
    fi

    if [ "$(ls $directory)" != "" ]; then
        echo "Umounting previous image."
        umount $directory/proc > /dev/null 2>&1
        umount $directory/sys/firmware/efi/efivars > /dev/null 2>&1
        umount $directory/sys > /dev/null 2>&1
        umount $directory/dev/pts > /dev/null 2>&1
        umount $directory/dev/shm > /dev/null 2>&1
        umount $directory/dev > /dev/null 2>&1
        umount $directory/run > /dev/null 2>&1
        umount $directory/tmp > /dev/null 2>&1
        umount $directory/etc/resolv.conf > /dev/null 2>&1
        umount $directory > /dev/null 2>&1
        sleep 3
    fi

    echo "Creating ${distro} disk image..."
    if [ -e "${image_name}" ]; then
        rm $image_name
    fi

    dd if=/dev/zero of=$image_name bs=1M count=$image_size

    mkfs.ext4 -L cloudimg-rootfs \
        -U 455a35d3-488b-4c5e-89b0-883ef8e77f68 \
        $image_name

    mount -o loop $image_name $directory

    echo "Downloading ${distro}..."
    if [ ! -e "FileSystems/${filesystem}" ]; then
        wget -O "FileSystems/${filesystem}" "${url}"
    fi

    echo "Decompressing ${distro}..."
    bsdtar -xpf FileSystems/$filesystem -C $directory

    echo "Preparing image for chroot with qemu..."
    cp /usr/bin/qemu-aarch64-static $directory/usr/bin/

    echo "Starting distro setup..."
    cp -av Setup/$setup_file $directory/
    arch-chroot $directory qemu-aarch64-static /bin/bash $setup_file

    rm $directory/$setup_file
    rm $directory/usr/bin/qemu-aarch64-static

    sleep 3

    umount $directory/proc > /dev/null 2>&1
    umount $directory/sys/firmware/efi/efivars > /dev/null 2>&1
    umount $directory/sys > /dev/null 2>&1
    umount $directory/dev/pts > /dev/null 2>&1
    umount $directory/dev/shm > /dev/null 2>&1
    umount $directory/dev > /dev/null 2>&1
    umount $directory/run > /dev/null 2>&1
    umount $directory/tmp > /dev/null 2>&1
    umount $directory/etc/resolv.conf > /dev/null 2>&1
    umount $directory/proc > /dev/null 2>&1

    # Wait for proper umount
    sleep 3

    echo "Setting directory permissions..."
    chown -R 1638400000:1638400000 $directory/bin
    chown -R 1638400000:1638400000 $directory/boot
    chown -R 1638400000:1638400000 $directory/etc
    chown 1638400000:1638400000 $directory/home
    chown -R 1638400000:1638400000 $directory/lib
    chown -R 1638400000:1638400000 $directory/lost+found
    chown 1638400000:1638400000 $directory/mnt
    chown 1638400000:1638400000 $directory/opt
    chown -R 1638400000:1638400000 $directory/root
    chown -R 1638400000:1638400000 $directory/run
    chown -R 1638400000:1638400000 $directory/sbin
    chown -R 1638400000:1638400000 $directory/share
    chown -R 1638400000:1638400000 $directory/srv
    chown -R 1638400000:1638400000 $directory/sys
    chown -R 1638400000:1638400000 $directory/usr
    chown -R 1638400000:1638400000 $directory/var
    chown -R 1638400000:1638400000 $directory/proc

    echo "Copying LinuxOnDex dependencies..."
    cp -av Template/usr $directory/
    cp -av Template/devro $directory/
    cp -av Template/share $directory/
    cp -av Template/ext_sd $directory/
    cp -av Template/home/dextop $directory/home/
    cp -av Template/tmp $directory/
    rm -rf $directory/dev
    cp -av Template/dev $directory/
    cp -av Template/proc $directory/
    cp -av Template/media $directory/

    chmod u+s $directory/usr/bin/sudo

    echo "Copyng final configurations..."
    mv $directory/etc/resolv.conf $directory/etc/resolv.conf.systemd
    cp -av Template/etc $directory/
}

make_archlinux
