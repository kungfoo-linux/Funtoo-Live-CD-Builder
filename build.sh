#!/bin/sh

#  The powerfull tool for building daily Funtoo Live CD
#     by Daniel K. aka *DANiO*

build_() {
case `uname -m` in
i?86) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ;;
x86_64) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ;;
esac

wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz
mkdir -p rootfs
mkdir -p out
[ -d rootfs/boot ] && true || tar -xvf stage.tar.xz -C rootfs
cd rootfs
mkdir -p dev sys proc
mount --bind /dev dev
mount --bind /sys sys
mount --bind /proc proc
cp /etc/resolv.conf etc
chroot . emerge --sync
chroot . epro mix-ins +xfce
chroot . echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc
chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta
chroot . rc-update add consolekit default
chroot . rc-update add dhcpcd default
chroot . echo "DISPLAYMANAGER='lightdm'" > /etc/conf.d/xdm
chroot . rc-update add xdm default
chroot . rc-update add dbus default
chroot . rm -rf /usr/src/*
chroot . rm -rf /boot
chroot . mkdir -p /usr/src/linux
chroot . mkdir -p /boot
chroot . rm -rf /lib/modules/*
chroot . rm -rf /lib64/modules/*
echo "
Please provide a 'root' password:
"
chroot . passwd root
cd ..
cp -raf /usr/src/linux/* rootfs/usr/src/linux
cp -raf `readlink -f /vmlinuz` rootfs/boot/vmlinuz
cp -raf /lib/modules/`uname -r` rootfs/lib/modules/`uname -r`
cp -raf stage/* rootfs
cd rootfs
chroot . /tmp/linx-live/build
umount -f dev proc sys
cd ..
mv -f rootfs/*.iso rootfs/*.zip out
clear
echo "
ALL GOOD FIND IMAGES IN `pwd`/out DIR :)
"
ls out | sort
}

case $1 in
build)	build_ || clear && echo "!!!ERROR FOUND!!!" && umount -f dev proc sys && exit ;;
clean)	rm -rf rootfs out stage.tar.xz && exit ;;
*)		clear && echo "
Only use $0 <build|clean>!
" && exit ;;
esac
