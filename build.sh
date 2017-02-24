#!/bin/sh

#  The powerfull tool for building daily Funtoo Live CD
#     by Daniel K. aka *DANiO*

build_() {
case `uname -m` in
i?86) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ;;
x86_64) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ;;
esac

wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz || exit
mkdir -p rootfs
mkdir -p out
if [ -e rootfs/* ]; then
tar -xf stage.tar.xz -C rootfs || exit
fi
cd rootfs
mkdir -p dev sys proc
mount --bind /dev dev || {umount -f dev proc sys; exit}
mount --bind /sys sys || {umount -f dev proc sys; exit}
mount --bind /proc proc || {umount -f dev proc sys; exit}
cp /etc/resolv.conf etc || {umount -f dev proc sys; exit}
chroot . emerge --sync || exit
chroot . epro mix-ins +xfce || {umount -f dev proc sys; exit}
chroot . echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc || {umount -f dev proc sys; exit}
chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta || {umount -f dev proc sys; exit}
chroot . rc-update add consolekit default || {umount -f dev proc sys; exit}
chroot . rc-update add dhcpcd default || {umount -f dev proc sys; exit}
chroot . echo "DISPLAYMANAGER='lightdm'" > /etc/conf.d/xdm || {umount -f dev proc sys; exit}
chroot . rc-update add xdm default || {umount -f dev proc sys; exit}
chroot . rc-update add dbus default || {umount -f dev proc sys; exit}
chroot . rm -rf /usr/src/* || {umount -f dev proc sys; exit}
chroot . rm -rf /boot || {umount -f dev proc sys; exit}
chroot . mkdir -p /usr/src/linux || {umount -f dev proc sys; exit}
chroot . mkdir -p /boot || {umount -f dev proc sys; exit}
chroot . rm -rf /lib/modules/* || {umount -f dev proc sys; exit}
chroot . rm -rf /lib64/modules/* || {umount -f dev proc sys; exit}
echo "
Please provide a 'root' password:
"
chroot . passwd root || {umount -f dev proc sys; exit}
cd ..
cp -raf /usr/src/linux/* rootfs/usr/src/linux || {umount -f dev proc sys; exit}
cp -raf `readlink -f /vmlinuz` rootfs/boot/vmlinuz || {umount -f dev proc sys; exit}
cp -raf /lib/modules/`uname -r` rootfs/lib/modules/`uname -r` || {umount -f dev proc sys; exit}
cp -raf stage/* rootfs || {umount -f dev proc sys; exit}
cd rootfs
chroot . /tmp/linx-live/build || {umount -f dev proc sys; exit}
umount -f dev proc sys || {umount -f dev proc sys; exit}
cd ..
mv -f rootfs/*.iso rootfs/*.zip out || {umount -f dev proc sys; exit}
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
" && {umount -f dev proc sys; exit} ;;
clean)	rm -rf rootfs out stage.tar.xz && exit ;;
*)		clear && echo "
Only use $0 <build|clean>!
" && exit ;;
esac
