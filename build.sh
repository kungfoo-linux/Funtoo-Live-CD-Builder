#!/bin/sh

#  The powerfull tool for building daily Funtoo Live CD
#     by Daniel K. aka *DANiO*

die() {
echo "
ERROR: $1
"
if [ -e "stamps/$2" ]; then
	rm -rf "stamps/$2"
else
	# DO NOTHING, JUST `echo`!
	echo
fi
umount -f ./dev
umount -f ./sys
umount -f ./proc
exit 1
}

build_() {
case `uname -m` in
i[3-6]86) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ;;
x86_64) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ;;
*) echo "ERROR: Architecture `uname -m` is'nt supported!" ; exit ;;
esac

mkdir -p rootfs
if [ -e rootfs/* ]; then
	echo
else
	if tar -xvf stage.tar.xz -C rootfs; then
		echo
	else
		wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz
		tar -xvf stage.tar.xz -C rootfs
	fi
fi
mkdir -p out
mkdir -p stamps
cd rootfs
mkdir -p dev sys proc
if mount --bind /dev dev; then
	echo
else
	die "Can't bind /dev to `pwd`/dev!"
fi
if mount --bind /sys sys; then
	echo
else
	die "Can't bind /sys to `pwd`/sys!"
fi
if mount --bind /proc proc; then
	echo
else
	die "Can't bind /proc to `pwd`/proc!"
fi

cp /etc/resolv.conf etc

if [ -e stamps/01 ]; then
	echo
else
	(
	touch stamps/01
	chroot . emerge --sync
	) || die "Can't sync the portage" 01
fi

if [ -e stamps/02 ]; then
	echo
else
	(
	touch stamps/02
	chroot . epro mix-ins +xfce
	) || die "Can'r setup mix-ins!" 02
fi

if [ -e stamps/03 ]; then
	echo
else
	(
	touch stamps/03
	chroot . echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc
	) || die "Can't setup xinitrd!" 03
fi

if [ -e stamps/04 ]; then
	echo
else
	(
	touch stamps/04
	chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --autounmask --ask n
	#	Now we must repeat above command for some reasons to 'autounmask' masked packages :)
	chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --ask n
	) || die "Can't emerge default packages!" 04
fi

if [ -e stamps/05 ]; then
	echo
else
	touch stamps/05
	(
	chroot . rc-update add consolekit default
	chroot . rc-update add dhcpcd default
	chroot . echo "DISPLAYMANAGER='lightdm'" > /etc/conf.d/xdm
	chroot . rc-update add xdm default
	chroot . rc-update add dbus default
	) || die "Can't setup rc-update!" 05
fi

if [ -e stamps/06 ]; then
	echo
else
	touch stamps/06
	(
	chroot . rm -rf /usr/src/*
	chroot . rm -rf /boot
	chroot . mkdir -p /usr/src/linux
	chroot . rm -rf /etc/motd
	chroot . mkdir -p /boot
	chroot . rm -rf /lib/modules/*
	chroot . rm -rf /lib64/modules/*
	cd ..
	cp -raf /usr/src/linux/* rootfs/usr/src/linux
	cp -raf `readlink -f /vmlinuz` rootfs/boot/vmlinuz
	cp -raf /lib/modules/`uname -r` rootfs/lib/modules/`uname -r`
	cp -raf stage/* rootfs
	cd rootfs
	) || die "Can't setup directories!" 06
fi

if [ -e stamps/06 ]; then
	echo
else
	touch stamps/06
	(
	echo "
Please provide a 'root' password:
	"
	chroot . passwd root
	) || die "Can't setup password for root!" 06
fi

if chroot . /tmp/linx-live/build; then
	umount -f dev proc sys
	cd ..
	mv -f rootfs/*.iso rootfs/*.zip out
	clear
	echo "
ALL GOOD FIND IMAGES IN `pwd`/out DIR :)
	"
	ls out | sort
else
	die "Can't create final images!"
fi

}

case $1 in
build)	build_ && exit ;;
clean)	rm -rf rootfs out stage.tar.xz && exit ;;
*)		clear && echo "
Only use $0 <build|clean>!
" && exit ;;
esac

exit
