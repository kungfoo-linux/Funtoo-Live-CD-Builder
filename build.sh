#!/bin/sh

#	The powerfull tool for building daily Funtoo Live CD
#		by Daniel K. aka *DANiO*

die() {
	echo -e "\nERROR: $1\n"
	if [ ! -z "$2" ]; then
		rm -rf stamps/$2
	fi
	if [ "$2" != "avoid_loop" ]; then
		umount_
	fi
	exit 1
}

mount_() {
	mkdir -p rootfs/dev
	mkdir -p rootfs/proc
	mkdir -p rootfs/sys
	if ! mountpoint -q "`pwd`/rootfs/dev"; then
		mount --bind /dev rootfs/dev || die "Can't bind /dev to `pwd`/rootfs/dev!"
	fi
	if ! mountpoint -q "`pwd`/rootfs/sys"; then
		mount --bind /sys rootfs/sys || die "Can't bind /sys to `pwd`/rootfs/sys!"
	fi
	if ! mountpoint -q "`pwd`/rootfs/proc"; then
		mount --bind /proc rootfs/proc || die "Can't bind /proc to `pwd`/rootfs/proc!"
	fi
}

umount_() {
	umount -f rootfs/dev || die "Can't unbind /dev from `pwd`/rootfs/dev!" 'avoid_loop'
	umount -f rootfs/sys || die "Can't unbind /sys from `pwd`/rootfs/sys!" 'avoid_loop'
	umount -f rootfs/proc || die "Can't unbind /proc from `pwd`/rootfs/proc!" 'avoid_loop'
}

compare_() {
	if ! diff `readlink -f /etc/resolv.conf` rootfs/etc/resolv.conf >/dev/null; then
		cp -raf `readlink -f /etc/resolv.conf` rootfs/etc
	fi
}

build() {
while [ ! -e ".asked_arch.cfg" ]; do
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
		*)	echo "Unkown choice '${ask_arch}' !" ; sleep 3 ; : ;;
	esac
done

case `cat .asked_arch.cfg` in
	1) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.i686 ; export genkernel=/usr/src/linux/arch/x86/configs/aufs32_defconfig ; export lnx=linux32 ;;
	2) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.x86_64 ; export genkernel=/usr/src/linux/arch/x86/configs/aufs64_defconfig ; export lnx=linux64 ;;
	*) die "Architecture is'nt supported or unkown option '`cat .asked_arch.cfg`' !" ;;
esac

mkdir -p out
mkdir -p stamps
mkdir -p rootfs

if [ ! -e './stamps/00' ]; then
	touch './stamps/00'
	if [ -e stage.tar.xz ] && [ ! -d rootfs/* ]; then
	(
		tar -xf stage.tar.xz -C rootfs
	) || die "Can't extract ${url_of_stage_file} to `pwd`/rootfs" '00'
	else
	(
		wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz
		tar -xf stage.tar.xz -C rootfs
	) || die "Can't download ${url_of_stage_file} and extract!" '00'
	fi
fi

mount_
compare_

if [ ! -e './stamps/01' ]; then
	if ! (
		touch './stamps/01'
		chroot rootfs ${lnx} emerge --sync
	); then
		die "Can't sync the portage" '01'
	fi
fi

if [ ! -e './stamps/02' ]; then
	if ! (
		touch './stamps/02'
		chroot rootfs ${lnx} epro flavor desktop
		chroot rootfs ${lnx} epro mix-ins +xfce
	); then
		die "Can't setup mix-ins!" '02'
	fi
fi

if [ ! -e './stamps/03' ]; then
	if ! (
		touch './stamps/03'
		echo "exec startxfce4 --with-ck-launch" > rootfs/root/.xinitrc
	); then
		die "Can't setup xinitrc!" '03'
	fi
fi

if [ ! -e './stamps/04' ]; then
	if ! (
		rm -rf rootfs/boot/{kernel-*,initramfs-*,System.map-*} rootfs/lib/modules/* rootfs/usr/src/linux*
		chroot rootfs ${lnx} rm -rf /etc/motd
		chroot rootfs ${lnx} rm -rf /etc/portage/make.conf*
		chroot rootfs ${lnx} ln -s ${portage_make_dot_conf} /etc/portage/make.conf
		chroot rootfs ${lnx} ln -s ${portage_make_dot_conf} /etc/portage/make.conf.example
		chroot rootfs ${lnx} chmod 7777 /tmp
		touch './stamps/04'
		chroot rootfs ${lnx} emerge -uvDN --ask n --with-bdeps=y @world
		chroot rootfs ${lnx} emerge aufs-sources --autounmask-write --verbose --ask n
		cp -raf stage/* .asked_arch.cfg rootfs
		cp -raf stage/usr/src/linux/* rootfs/usr/src/linux
		chroot rootfs ${lnx} genkernel --oldconfig --no-mountboot --no-symlink --install --no-splash --unionfs --kernel-config=${genkernel} kernel
		chroot rootfs ${lnx} make mrproper -C /usr/src/linux
		chroot rootfs ${lnx} emerge boot-update wicd squashfs-tools firefox-bin geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta lightdm-gtk-greeter --autounmask-write --verbose --ask n
		chroot rootfs ${lnx} etc-update <<!
-5
!
		#	Now we must repeat above command for some reasons to 'autounmask' masked packages!
		chroot rootfs ${lnx} emerge boot-update wicd squashfs-tools firefox-bin geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta lightdm-gtk-greeter --autounmask-write --verbose --ask n
	); then
		die "Can't emerge default packages!" '04'
	fi
fi

if [ ! -e './stamps/05' ]; then
	if ! (
		touch './stamps/05'
		chroot rootfs ${lnx} rc-update add consolekit default
		chroot rootfs ${lnx} rc-update add dhcpcd default
		echo "DISPLAYMANAGER='lightdm'" > rootfs/etc/conf.d/xdm
		chroot rootfs ${lnx} rc-update add xdm default
		chroot rootfs ${lnx} rc-update add dbus default
	); then
		die "Can't setup rc-update!" '05'
	fi
fi

if [ ! -e './stamps/06' ]; then
	if ! (
		touch './stamps/06'
#	echo "
#Please provide a 'root' password:
#	"
		chroot rootfs ${lnx} passwd root <<!
toor
toor
!
	#while ! chroot rootfs passwd root; do
	#	:
	#done
		echo "The 'root' password is 'toor', remember it!" > out/password_to_root.txt
	); then
		die "Can't setup password for root!" '06'
	fi
fi

rm -rf rootfs/usr/portage/distfiles/*

if chroot rootfs ${lnx} /tmp/linux-live/build; then
	umount_
	mv -f rootfs/*.iso out
	clear
	echo "
ALL GOOD!
FIND IMAGES IN `pwd`/out DIR :)
---
The 'root' password is 'toor', remember it!
"
	ls out | sort
else
	die "Can't create final images!"
fi
}

case ${1} in
	build)	build ;;
	chroot)	mount_ && compare_ && chroot rootfs ${2} && umount_ ;;
	clean)	rm -rf rootfs out stage.tar.xz stamps .asked_arch.cfg ;;
	clean-variable)	rm -rf .asked_arch.cfg ;;
	*)	clear ; echo -e "\nOnly use:\n`basename $0` <build|clean|chroot|clean-variable>\n" ;;
esac

exit
