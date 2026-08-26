#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only

# Initialize only the HDMI IN 1 receiver and the HDMI IN 1 -> HDMI OUT
# splitter path. HDMI IN 2 is initialized by probe and is not restarted here.

set -eu

DEBUGFS=/sys/kernel/debug
GC_DEBUGFS=$DEBUGFS/gc570d

die()
{
	echo "gc570d-init-hdmi1: $*" >&2
	exit 1
}

write_stage()
{
	stage=$1
	node="$GC_DEBUGFS/$stage"
	[ -e "$node" ] || die "missing debugfs node: $node"
	echo "  $stage"
	printf '1\n' > "$node" || die "stage failed: $stage (see dmesg)"
}

retry_stage()
{
	stage=$1
	attempts=$2
	delay=$3
	try=1
	while [ "$try" -le "$attempts" ]; do
		node="$GC_DEBUGFS/$stage"
		[ -e "$node" ] || die "missing debugfs node: $node"
		echo "  $stage (attempt $try/$attempts)"
		if printf '1\n' > "$node"; then
			return 0
		fi
		try=$((try + 1))
		[ "$try" -le "$attempts" ] && sleep "$delay"
	done
	die "stage failed after $attempts attempts: $stage (see dmesg)"
}

[ "$(id -u)" -eq 0 ] || die "run as root (sudo $0)"

if ! grep -q '^gc570d ' /proc/modules; then
	if command -v gc570d-load >/dev/null 2>&1; then
		gc570d-load
	else
		SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
		"$SCRIPT_DIR/gc570d-load.sh"
	fi
fi

if ! grep -q "[[:space:]]$DEBUGFS[[:space:]]debugfs[[:space:]]" /proc/mounts; then
	mount -t debugfs debugfs "$DEBUGFS" || die "could not mount debugfs"
fi

[ -d "$GC_DEBUGFS" ] || die "driver debugfs directory is absent"

if [ -r "$GC_DEBUGFS/splitter_pump_status" ] &&
   grep -q '^running=yes ' "$GC_DEBUGFS/splitter_pump_status"; then
	echo "HDMI IN 1 state pump is already running; no hardware was reset"
	exit 0
fi

AUTO_PARAMETER=/sys/module/gc570d/parameters/auto_hdmi1
if [ -r "$AUTO_PARAMETER" ] && grep -Eq '^(Y|1)$' "$AUTO_PARAMETER"; then
	if [ -r "$GC_DEBUGFS/splitter_pump_status" ] &&
	   grep -q ' auto_ready=yes$' "$GC_DEBUGFS/splitter_pump_status"; then
		write_stage splitter_windows_state_pump
		sleep 1
		cat "$GC_DEBUGFS/splitter_pump_status"
		echo "HDMI IN 1 state pump restarted"
		exit 0
	fi
	echo "Automatic HDMI IN 1 initialization is enabled; waiting for its background state machine"
	attempt=1
	while [ "$attempt" -le 30 ]; do
		if [ -r "$GC_DEBUGFS/splitter_pump_status" ] &&
		   grep -q '^running=yes ' "$GC_DEBUGFS/splitter_pump_status"; then
			cat "$GC_DEBUGFS/splitter_pump_status"
			echo "HDMI IN 1/passthrough is ready"
			exit 0
		fi
		attempt=$((attempt + 1))
		sleep 1
	done
	[ -r "$GC_DEBUGFS/splitter_pump_status" ] && cat "$GC_DEBUGFS/splitter_pump_status"
	die "automatic initialization is still waiting; verify that the source and HDMI OUT display are on"
fi

echo "Initializing HDMI IN 1 receiver (source and HDMI OUT display must be on)..."
for stage in \
	it68051_init \
	it68051_calibrate \
	it68051_timing_init \
	it68051_edid \
	it68051_hpd
do
	write_stage "$stage"
done

echo "Initializing the passthrough splitter..."
for stage in \
	splitter_core_preamble \
	splitter_clock_init \
	splitter_route_init \
	splitter_output_preamble \
	splitter_post_reset_init \
	splitter_output_mode_init \
	splitter_output_followup \
	splitter_aux_enable_pulse \
	splitter_aux_ports_init \
	splitter_irq_init
do
	write_stage "$stage"
done

write_stage splitter_source_power_event
write_stage splitter_windows_receiver_hdcp_off
sleep 1
write_stage splitter_main_timer_irq
write_stage splitter_windows_channel2_bridge_connect

# The official driver lets the copied EDID/link settle before consuming the receiver
# snapshot and its deferred timer.
sleep 3
retry_stage splitter_receiver_event 5 1
sleep 3
write_stage splitter_main_timer_irq
write_stage splitter_channel_video_stable_irq
write_stage splitter_stable_worker_probe
retry_stage splitter_stable_workers_windows_order 3 1
write_stage splitter_windows_state_pump

sleep 1
if [ -r "$GC_DEBUGFS/splitter_aux_status" ]; then
	AUX_STATUS=$(cat "$GC_DEBUGFS/splitter_aux_status")
	C1_PORT1=$(printf '%s\n' "$AUX_STATUS" | sed -n 's/^channel=1 .* c1=\([0-9a-fA-F][0-9a-fA-F]\) .*/\1/p')
	C1_PORT2=$(printf '%s\n' "$AUX_STATUS" | sed -n 's/^channel=2 .* c1=\([0-9a-fA-F][0-9a-fA-F]\) .*/\1/p')
	if [ -z "$C1_PORT1" ] || [ -z "$C1_PORT2" ] ||
	   [ $((0x$C1_PORT1 & 1)) -ne 0 ] ||
	   [ $((0x$C1_PORT2 & 1)) -ne 0 ]; then
		echo "$AUX_STATUS" >&2
		die "content path was not released (c1=${C1_PORT1:-??}/${C1_PORT2:-??})"
	fi
	echo "content release verified (c1=$C1_PORT1/$C1_PORT2)"
fi

if [ -r "$GC_DEBUGFS/splitter_pump_status" ]; then
	cat "$GC_DEBUGFS/splitter_pump_status"
fi

echo "HDMI IN 1/passthrough initialized; the in-kernel state pump remains active"
