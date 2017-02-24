#!/bin/sh

#  The powerfull tool for building daily Funtoo Live CD
#     by Daniel K. aka *DANiO*

build_() {
case `uname -m` in
i?86) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ;;
x86_64) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ;;
esac

wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz || exit 1
mkdir -p rootfs
mkdir -p out
tar -xf stage.tar.xz -C rootfs || exit 1
cd rootfs
mkdir -p dev sys proc
mount --bind /dev dev || exit 1
mount --bind /sys sys || exit 1
mount --bind /proc proc || exit 1
cp /etc/resolv.conf etc || exit 1
chroot . emerge --sync || exit
chroot . epro mix-ins +xfce || exit 1
chroot . echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc || exit 1
chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog mkisofs lightdm genkernel xfce4-meta || exit 1
chroot . rc-update add consolekit default || exit 1
chroot . rc-update add dhcpcd default || exit 1
chroot . echo "DISPLAYMANAGER='lightdm'" > /etc/conf.d/xdm || exit 1
chroot . rc-update add xdm default || exit 1
chroot . rc-update add dbus default || exit 1
chroot . rm -rf /usr/src/* || exit 1
chroot . rm -rf /boot || exit 1
chroot . mkdir -p /usr/src/linux || exit 1
chroot . mkdir -p /boot || exit 1
echo "
Please provide a 'root' password:
"
chroot . passwd root || exit 1
cd ..
cp -raf /usr/src/linux/* rootfs/usr/src/linux || exit 1
cp -raf `readlink -f /vmlinuz` rootfs/boot/vmlinuz || exit 1
cp -raf /lib/modules/`uname -r` rootfs/lib/modules/`uname -r` || exit 1
cp -raf stage/* rootfs || exit 1
cd rootfs
chroot . /tmp/linx-live/build || exit 1
cd ..
mv -f rootfs/*.iso rootfs/*.zip out || exit 1
clear
echo "
ALL GOOD FIND IMAGES IN `pwd`/out DIR :)
"
ls out | sort
}

case $1 in
build)	build_ || echo "
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
!!!ERROR FOUND!!!
" && exit 1 ;;
clean)	rm -rf rootfs out stage.tar.xz && exit ;;
*)		clear && echo "
Only use $0 <build|clean>!
" && exit ;;
esac
