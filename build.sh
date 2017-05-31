#!/bin/sh

#	The powerfull tool for building daily Funtoo Live CD
#		by Daniel K. aka *DANiO*

die() {
echo "
ERROR: $1
"
if [ "./stamps/$2"="./stamps/" ]; then
	shift
else
	rm -rf "./stamps/$2"
fi
umount -f ./rootfs/dev
umount -f ./rootfs/sys
umount -f ./rootfs/proc
exit 1
}

build() {
unset ask_arch
clear
echo "
Please, choose your prefered architecture of cpu:
[1] is 32-bit,
[2] is 64-bit,
---
Which one?

NOTE: On 32-bit host machine you can't use a 64-bit for building.
"
read ask_arch
case ${ask_arch} in
1)	echo "1" > .asked_arch.cfg ;;
2)	echo "2" > .asked_arch.cfg ;;
esac

case `cat .asked_arch.cfg` in
1) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.i686 ;;
2) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.x86_64 ;;
*) die "Architecture is'nt supported or unkown option '`cat .asked_arch.cfg`' !" ;;
esac

mkdir -p out
mkdir -p stamps
mkdir -p rootfs

if [ ! -e './stamps/00' ]; then
	touch './stamps/00'
	if [ ! -d rootfs && -e stage.tar.xz ]; then
	(
		tar -xf stage.tar.xz -C rootfs
	) || die "Can't extract ${url_of_stage_file} to ./rootfs" '00'
	else
	(
		wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz
		tar -xf stage.tar.xz -C rootfs
	) || die "Can't download ${url_of_stage_file} and extract!" '00'
	fi
fi

mkdir -p rootfs/{dev,proc,sys}
if mount --bind /dev rootfs/dev; then
	shift
else
	die "Can't bind /dev to ./rootfs/dev!"
fi
if mount --bind /sys rootfs/sys; then
	shift
else
	die "Can't bind /sys to ./rootfs/sys!"
fi
if mount --bind /proc rootfs/proc; then
	shift
else
	die "Can't bind /proc to ./rootfs/proc!"
fi

cp -raf `readlink -f /etc/resolv.conf` rootfs/etc

if [ ! -e './stamps/01' ]; then
	(
	touch './stamps/01'
	chroot rootfs emerge --sync
	) || die "Can't sync the portage" '01'
fi

if [ ! -e './stamps/02' ]; th
	(
	touch './stamps/02'
	chroot rootfs epro flavor desktop
	chroot rootfs epro mix-ins +xfce
	) || die "Can'r setup mix-ins!" '02'
fi

if [ ! -e './stamps/03' ]; then
	(
	touch './stamps/03'
	chroot rootfs echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc
	) || die "Can't setup xinitrd!" '03'
fi

if [ ! -e './stamps/04' ]; then
	(
	cp -raf stage/* rootfs
	chroot rootfs rm -rf /etc/motd
	chroot rootfs rm -rf /etc/portage/make.conf*
	chroot rootfs ln -sf ${portage_make_dot_conf} /etc/portage/make.conf
	chroot rootfs ln -sf ${portage_make_dot_conf} /etc/portage/make.conf.example
	touch './stamps/04'
	chroot rootfs emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --autounmask --autounmask-write --ask n
	chroot rootfs etc-update <<eot
-3
eot
	#	Now we must repeat above command for some reasons to 'autounmask' masked packages!
	chroot rootfs emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --autounmask --autounmask-write --ask n
	) || die "Can't emerge default packages!" '04'
fi

if [ ! -e './stamps/05' ]; then
	(
	touch './stamps/05'
	chroot rootfs rc-update add consolekit default
	chroot rootfs rc-update add dhcpcd default
	chroot rootfs echo "DISPLAYMANAGER='lightdm'" > /etc/conf.d/xdm
	chroot rootfs rc-update add xdm default
	chroot rootfs rc-update add dbus default
	) || die "Can't setup rc-update!" '05'
fi

if [ ! -e './stamps/06' ]; then
	(
	touch './stamps/06'
	echo "
Please provide a 'root' password:
	"
	while !	chroot rootfs passwd root; do
		:
	done
	) || die "Can't setup password for root!" '06'
fi

if chroot rootfs /tmp/linx-live/build; then
	umount -f rootfs/dev
	umount -f rootfs/proc
	umount -f rootfs/sys
	mv -f rootfs/*.iso rootfs/*.zip out
	clear
	echo "
ALL GOOD!
FIND IMAGES IN `pwd`/out DIR :)
	"
	ls out | sort
else
	die "Can't create final images!"
fi
}

case ${1} in
build)	build && exit ;;
clean)	rm -rf rootfs out stage.tar.xz stamps .asked_arch.cfg && exit ;;
clean-variable)	rm -rf .asked_arch.cfg && exit ;;
*)	clear && echo -e "\nOnly use:\n`basename $0` <build|clean|clean-variable>\n" && exit ;;
esac
