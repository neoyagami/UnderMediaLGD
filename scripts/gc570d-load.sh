#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# Load the GC570D kernel module and its dependencies from an installed or local build.

set -eu

die()
{
	echo "gc570d-load: $*" >&2
	exit 1
}

[ "$(id -u)" -eq 0 ] || die "run as root (sudo $0)"

case "${1:-}" in
	"")
		AUTO_HDMI1=1
		;;
	--hdmi2-only)
		AUTO_HDMI1=0
		;;
	*)
		die "usage: $0 [--hdmi2-only]"
		;;
esac

if grep -q '^gc570d ' /proc/modules; then
	echo "gc570d is already loaded; module defaults were not changed"
	exit 0
fi

KERNEL_RELEASE=$(uname -r)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CHECKOUT_MODULE="$SCRIPT_DIR/../gc570d.ko"
PORTABLE_MODULE="/var/lib/gc570d/$KERNEL_RELEASE/gc570d.ko"

for dependency in \
	snd-pcm \
	videodev \
	videobuf2-v4l2 \
	videobuf2-dma-contig \
	led-class-multicolor
do
	modprobe "$dependency" || die "could not load dependency $dependency"
done

if modinfo -k "$KERNEL_RELEASE" gc570d >/dev/null 2>&1; then
	modprobe gc570d auto_hdmi1="$AUTO_HDMI1" || die "modprobe failed; check Secure Boot and dmesg"
elif [ -f "$PORTABLE_MODULE" ]; then
	insmod "$PORTABLE_MODULE" auto_hdmi1="$AUTO_HDMI1" || die "insmod failed; check vermagic, Secure Boot and dmesg"
elif [ -f "$CHECKOUT_MODULE" ]; then
	insmod "$CHECKOUT_MODULE" auto_hdmi1="$AUTO_HDMI1" || die "insmod failed; run make and check dmesg"
else
	die "no module for $KERNEL_RELEASE; run make or install-portable.sh"
fi

sleep 1
grep -q '^gc570d ' /proc/modules || die "module did not remain loaded"
if [ "$AUTO_HDMI1" -eq 1 ]; then
	echo "gc570d loaded; HDMI IN 2 is ready and HDMI IN 1/passthrough will initialize automatically"
else
	echo "gc570d loaded in HDMI IN 2-only mode"
fi
