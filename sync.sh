#!/bin/bash

# The idea of this script is to copy the generated archlinuxarm
# file structure into the official ubuntu image which should be
# mounted with: mount -o loop xenia.img ubuntu. We dont clean
# the entire /etc directory because removing some of its files
# make the image format invalid to Linux on Dex app.

rm -rf ubuntu/usr/*
rm -rf ubuntu/bin
rm -rf ubuntu/lib
rm -rf ubuntu/sbin
rm -rf ubuntu/var/*
rm -rf ubuntu/boot/*

cp -av archlinux/usr ubuntu/
cp -av archlinux/bin ubuntu/
cp -av archlinux/lib ubuntu
cp -av archlinux/sbin ubuntu/
cp -av archlinux/var ubuntu/

chmod u+s ubuntu/usr/bin/sudo

rm -rf archlinux/etc/init.d
rm archlinux/etc/lod_monitor.conf
rm archlinux/etc/LoDVersion
rm archlinux/resolv.conf
rm archlinux/securetty
rm archlinux/etc/subgid
rm archlinux/etc/subuid

cp -av archlinux/etc ubuntu/
