#!/bin/bash

# This file is to properly setup the archlinuxarm from within the
# arch-chroot.

# to prevent mmap errors due to qemu and proper mount...
sleep 3

# since network isnt't working with plain resolv.conf we add some hosts
cp /etc/hosts /etc/hosts.original
echo "50.116.36.110 mirror.archlinuxarm.org" >> /etc/hosts
echo "216.155.157.40 fl.us.mirror.archlinuxarm.org" >> /etc/hosts

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.original
echo 'Server = http://fl.us.mirror.archlinuxarm.org/$arch/$repo' \
    > /etc/pacman.d/mirrorlist

# Init archlinuxarm packages keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Remove kernel
pacman --noconfirm -Rcs linux-aarch64 linux-firmware

# Update the base system
pacman --noconfirm -Suy

# Install additional packages
pacman --noconfirm -S sudo pulseaudio xorg-server xorg-apps \
    ttf-liberation ttf-opensans ttf-hack \
    tigervnc fluxbox

# Clean downloaded packages
pacman --noconfirm -Scc

# Enable sudo on all user accounts
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# Fix Xtightvnc missing dependency
ln -s /usr/lib/libXfont2.so.2.0.0 /usr/lib/libXfont.so.1

# Remove default user
userdel -f -r alarm

useradd -m dextop

usermod -a -G network,wheel,audio,input,video,storage dextop

echo "Please enter the dextop user password:"
passwd dextop

echo "Please enter the root password:"
passwd root

mv /etc/hosts.original /etc/hosts

mv /etc/pacman.d/mirrorlist.original /etc/pacman.d/mirrorlist

# Enable networking on the container
groupadd -g 53003 inet
usermod -a -G inet dextop
usermod -a -G inet root

exit