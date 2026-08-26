# SPDX-License-Identifier: GPL-2.0-only
# Kbuild definition and convenience targets for building and installing gc570d.ko.

obj-m += gc570d.o
gc570d-y := \
	src/gc570d-main.o \
	src/gc570d-hw.o \
	src/gc570d-i2c.o \
	src/gc570d-led.o \
	src/gc570d-receiver.o \
	src/gc570d-splitter.o \
	src/gc570d-dma.o \
	src/gc570d-audio.o \
	src/gc570d-video.o

KERNEL_RELEASE ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KERNEL_RELEASE)/build
INSTALL_MOD_DIR ?= extra/gc570d

.PHONY: all clean install uninstall check

all:
	$(MAKE) -C $(KDIR) M=$(CURDIR) modules

clean:
	$(MAKE) -C $(KDIR) M=$(CURDIR) clean

install: all
	install -D -m 0644 gc570d.ko \
		/lib/modules/$(KERNEL_RELEASE)/$(INSTALL_MOD_DIR)/gc570d.ko
	depmod -a $(KERNEL_RELEASE)

uninstall:
	rm -f /lib/modules/$(KERNEL_RELEASE)/$(INSTALL_MOD_DIR)/gc570d.ko
	depmod -a $(KERNEL_RELEASE)

check:
	sh -n scripts/*.sh
	./scripts/check-release.sh
