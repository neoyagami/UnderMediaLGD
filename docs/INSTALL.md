# Build and installation

## Confirm the exact device

This driver binds only to PCI vendor/device `1461:0054` with subsystem
`1461:5700`.

```sh
lspci -nn -d 1461:0054
lspci -nnk -d 1461:0054
```

Stop virtual machines using the card and detach it from `vfio-pci` before
continuing.

## Install build dependencies

Package names vary by distribution. You need the compiler toolchain and the
build tree matching `uname -r`. Typical examples are:

```sh
# Fedora-family
sudo dnf install gcc make kernel-devel-$(uname -r) v4l-utils alsa-utils

# Debian/Ubuntu-family
sudo apt install build-essential linux-headers-$(uname -r) v4l-utils alsa-utils
```

Bazzite and other image-based systems normally require entering a suitable
development environment or layering the matching kernel-devel package. A
successful build requires this directory:

```sh
ls -ld /lib/modules/$(uname -r)/build
```

The project currently needs installation and runtime testing beyond Bazzite
44. If these package instructions work—or need adjustment—on another
distribution, please report the distribution, release, kernel version and the
exact packages or development environment used. The full checklist is in
[`CONTRIBUTING.md`](../CONTRIBUTING.md).

## Build

```sh
make
modinfo ./gc570d.ko
```

Never force-load a module built for another kernel release. If BTF generation
is skipped because `vmlinux` is unavailable, the module can still be usable;
compiler or modpost errors are different and must be fixed.

## Load from the checkout

```sh
sudo ./scripts/gc570d-load.sh
```

The loader resolves kernel dependencies and then uses an installed module or
the `gc570d.ko` beside the repository scripts. It does not unload a running
driver.

## Conventional system installation

On a mutable distribution:

```sh
sudo make install
sudo modprobe gc570d
```

This installs only for the running kernel. Rebuild and reinstall after a
kernel update.

## Portable installation for Bazzite/Fedora Atomic

The root image is immutable, so installing into `/usr/lib/modules` may be
inappropriate. The portable installer copies the built module to
`/var/lib/gc570d/<kernel-release>/`, installs a system-wide WirePlumber policy
and enables a systemd unit that loads the driver on every boot:

```sh
sudo ./scripts/install-portable.sh
sudo reboot
```

HDMI IN 2 is ready when the module loads. HDMI IN 1 and passthrough use the
driver's background state machine, so disconnected or late-powered HDMI
equipment does not block boot. At desktop login, WirePlumber reads the global
policy and publishes both named capture sources automatically.

For immediate use without reboot:

```sh
sudo gc570d-load
gc570d-setup-pipewire
```

The second command only refreshes the already-running desktop audio session;
it is not needed on subsequent logins or boots.

To remove only the files installed by the portable installer, first close OBS
and every V4L2/ALSA client, then run:

```sh
sudo ./scripts/uninstall-portable.sh
```

The installed module is specific to the running kernel. After every kernel
update, boot the new kernel and run `install-portable.sh` again before relying
on automatic loading.

## Secure Boot

An unsigned out-of-tree module is commonly rejected when Secure Boot/module
signature enforcement is active. Sign `gc570d.ko` using the procedure for
your distribution and enroll your own key, or disable Secure Boot. Do not use
`--force-vermagic` or similar force-loading options.

## Automatic HDMI IN 1 initialization

HDMI IN 2 is initialized during module probe. By default, the driver then runs
the recovered HDMI IN 1/HDMI OUT sequence automatically in a background state
machine. It waits and retries while the source or display is absent, and
normally completes about ten seconds after both are available.

Check progress with:

```sh
sudo ./scripts/status.sh
```

For diagnosis, load only HDMI IN 2 by changing the normal default, then start
HDMI IN 1 explicitly later:

```sh
sudo ./scripts/gc570d-load.sh --hdmi2-only
sudo ./scripts/gc570d-init-hdmi1.sh
```

Do not unload the module while passthrough or capture is in use.
