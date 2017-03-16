#!/bin/sh

#  The powerfull tool for building daily Funtoo Live CD
#     by Daniel K. aka *DANiO*

die() {
echo "
ERROR: $1
"
if [ -e "`pwd`/stamps/$2" ]; then
	rm -rf "`pwd`/stamps/$2"
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
i[3-6]86) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-32bit/generic_32/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.i686 ;;
x86_64) export url_of_stage_file=http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz ; export portage_make_dot_conf=/usr/share/portage/make.conf.x86_64 ;;
*) die "Architecture `uname -m` is'nt supported!" ;;
esac

if [ -e '`pwd`/stamps/00' ]; then
	echo
else
	
	touch '`pwd`/stamps/00'
	if [ ! -d rootfs ]; then
	(
		mkdir -p rootfs
		tar -xvf stage.tar.xz -C rootfs
	) || die "Can't extract ${url_of_stage_file} to `pwd`rootfs" '00'
	else
	(
		wget --no-check-cert -c ${url_of_stage_file} -O stage.tar.xz
		mkdir -p rootfs
		tar -xvf stage.tar.xz -C rootfs
	) || die "Can't download ${url_of_stage_file} and extract!" '00'
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

cp `readlink -f /etc/resolv.conf` etc

if [ -e '`pwd`/stamps/01' ]; then
	echo
else
	(
	touch '`pwd`/stamps/01'
	chroot . emerge --sync
	) || die "Can't sync the portage" '01'
fi

if [ -e '`pwd`/stamps/02' ]; then
	echo
else
	(
	touch '`pwd`/stamps/02'
	chroot . epro mix-ins +xfce
	) || die "Can'r setup mix-ins!" '02'
fi

if [ -e '`pwd`/stamps/03' ]; then
	echo
else
	(
	touch '`pwd`/stamps/03'
	chroot . echo "exec startxfce4 --with-ck-launch" > ~/.xinitrc
	) || die "Can't setup xinitrd!" '03'
fi

if [ -e '`pwd`/stamps/04' ]; then
	echo
else
	(
	cp -raf stage/* rootfs
	chroot . rm -rf /etc/portage/make.conf*
	chroot . ln -s ${portage_make_dot_conf} /etc/portage/make.conf
	chroot . ln -s ${portage_make_dot_conf} /etc/portage/make.conf.example
	touch '`pwd`/stamps/04'
	chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --autounmask-write --ask n
	#	Now we must repeat above command for some reasons to 'autounmask' masked packages :)
	chroot . emerge boot-update wicd squashfs-tools opera-developer geany porthole xorg-x11 dialog cdrtools lightdm genkernel xfce4-meta --ask n
	) || die "Can't emerge default packages!" '04'
fi

if [ -e '`pwd`/stamps/05' ]; then
	echo
else
	(
	touch '`pwd`/stamps/05'
	chroot . rc-update add consolekit default
	chroot . rc-update add dhcpcd default
	chroot . echo "DISPLAYMANAGER='lightdm'" touch /etc/conf.d/xdm
	chroot . rc-update add xdm default
	chroot . rc-update add dbus default
	) || die "Can't setup rc-update!" '05'
fi

if [ -e '`pwd`/stamps/06' ]; then
	echo
else
	(
	touch '`pwd`/stamps/06'
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
	if [ -d /lib/modules/`uname -r` ]; then
		cp -raf /lib/modules/`uname -r` rootfs/lib/modules/`uname -r`
		if [ -d /lib64/modules/`uname -r` ]; then
			if [ `uname -m` = "x86_64" ]; then
				echo -e "\nWARN: Your host machine is multilib, it's good, but I suggest to use a `uname -m` host machine without multilib!\n\n"
				sleep 2
				ask_to_copy_a_multilib() {
					unset question
					clear
					echo -e "\nQUESTION: Would you like to copy multilib modules from /lib64/modules/`uname -r` to `pwd`/rootfs/lib64/modules/`uname -r` ?\n[Y]es or [N]o?\n\n"
					read question
					case ${question} in
						y|Y|Yes|yes) cp -raf /lib64/modules/`uname -r` rootfs/lib64/modules/`uname -r` ;;
						n|N|No|no) echo ;;
						*) echo -e "\nWARN: Unkown answer '${question}'!" ; sleep 2 ; ask_to_copy_a_multilib ;;
					esac
				}
				ask_to_copy_a_multilib
			fi
		fi
	else
		die "Can't find kernel modules for release `uname -r`!"
	fi
	cd rootfs
	) || die "Can't setup directories!" '06'
fi

if [ -e '`pwd`/stamps/07' ]; then
	echo
else
	(
	touch '`pwd`/stamps/07'
	echo "
Please provide a 'root' password:
	"
	chroot . passwd root
	) || die "Can't setup password for root!" '07'
fi

if chroot . /tmp/linx-live/build; then
	umount -f dev proc sys
	cd ..
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
build)	build_ && exit ;;
clean)	rm -rf rootfs out stage.tar.xz stamps && exit ;;
*)	clear && echo -e "\nOnly use:\n$0 <build|cleantouch!\n\n" && exit ;;
esac

exit
