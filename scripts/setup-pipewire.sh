#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-only
# Publish and label both GC570D ALSA inputs through WirePlumber/PipeWire-Pulse.

set -eu

die()
{
	echo "setup-pipewire: $*" >&2
	exit 1
}

[ "$(id -u)" -ne 0 ] || die "run as the logged-in desktop user, not with sudo"
command -v pactl >/dev/null 2>&1 || die "pactl is not installed"
command -v systemctl >/dev/null 2>&1 || die "systemctl is not installed"

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_BASE=${XDG_CONFIG_HOME:-${HOME:?HOME is not set}/.config}
POLICY_TARGET="$CONFIG_BASE/wireplumber/wireplumber.conf.d/51-gc570d.conf"
SYSTEM_POLICY=/etc/wireplumber/wireplumber.conf.d/51-gc570d.conf

if [ -f "$SCRIPT_DIR/../config/wireplumber/51-gc570d.conf" ]; then
	POLICY_SOURCE="$SCRIPT_DIR/../config/wireplumber/51-gc570d.conf"
elif [ -f /usr/local/share/gc570d/51-gc570d.conf ]; then
	POLICY_SOURCE=/usr/local/share/gc570d/51-gc570d.conf
elif [ -f "$SYSTEM_POLICY" ]; then
	POLICY_SOURCE="$SYSTEM_POLICY"
else
	die "could not find 51-gc570d.conf"
fi

# Keep a current user-level copy even when a system-wide policy exists.  The
# checkout may contain fixes newer than the last root installation, and the
# user configuration has the required precedence without modifying /etc.
install -D -m 0644 "$POLICY_SOURCE" "$POLICY_TARGET"
echo "Installed WirePlumber policy: $POLICY_TARGET"
if [ -f "$SYSTEM_POLICY" ]; then
	echo "The user policy overrides the installed system copy: $SYSTEM_POLICY"
fi

systemctl --user restart pipewire.service
systemctl --user restart pipewire-pulse.service
systemctl --user restart wireplumber.service

CARD_NAME=
attempt=1
while [ "$attempt" -le 20 ]; do
	CARD_NAME=$(pactl list cards 2>/dev/null | awk '
		/^Card #[0-9]+/ { name = "" }
		/^[[:space:]]*Name:/ { name = $2 }
		/alsa.driver_name = "gc570d"/ { if (name != "") { print name; exit } }
	')
	[ -n "$CARD_NAME" ] && break
	attempt=$((attempt + 1))
	sleep 1
done

[ -n "$CARD_NAME" ] || die "gc570d PipeWire card was not found; check arecord -l and systemctl --user status wireplumber"
pactl set-card-profile "$CARD_NAME" pro-audio || die "could not activate pro-audio on $CARD_NAME"

echo "Activated pro-audio on $CARD_NAME"
echo "Available capture sources:"
pactl list sources short | grep -E 'gc570d|AVerMedia|pro-input' || pactl list sources short
echo "OBS sources: HDMI 2 (Capture Only) and HDMI 1 (Passthrough)"
echo "If OBS was open, reselect both capture sources"
