# Contributing

## Driver source layout

The driver is a composite kernel module built from independent objects under
`src/`.  Shared state, register definitions and internal interfaces live in
`src/gc570d.h`.

- `gc570d-main.c`: bridge setup, PCI probe/removal and module registration
- `gc570d-hw.c`: interrupts, register diagnostics and Xilinx access
- `gc570d-i2c.c`: common I2C transactions
- `gc570d-led.c`: enclosure RGB LED support
- `gc570d-receiver.c`: IT6802/IT68051 receiver support
- `gc570d-splitter.c`: splitter initialization and link/event handling
- `gc570d-dma.c`: VIP and raw video DMA handling
- `gc570d-audio.c`: raw audio DMA and ALSA PCM support
- `gc570d-video.c`: V4L2 streaming for both HDMI inputs

Keep new code in the narrowest matching source file.  Add cross-component
interfaces to `gc570d.h` only when they are genuinely shared.

Contributions should be independently written code, tests or documentation
based on lawful interoperability research and scoped to the public Linux
implementation described in `docs/REVERSE_ENGINEERING.md`.

## Distribution testing

Help testing the driver beyond its current Bazzite 44 environment is wanted.
Reports from Fedora, Debian, Ubuntu, Arch, immutable distributions and other
kernel versions are welcome, including reports where the driver does not build
or load.

A useful test report includes:

1. Distribution and version, `uname -r`, and compiler version.
2. The output of `lspci -nnk -d 1461:0054`.
3. Whether Secure Boot is enabled and how the module was installed and signed.
4. HDMI source, display, resolution, refresh rate, SDR/HDR and passthrough use.
5. Which V4L2 and ALSA inputs were tested, including concurrent-stream order.
6. Relevant build output, `modinfo ./gc570d.ko`, and bounded `dmesg` excerpts.
7. Whether the result is direct physical observation or static analysis only.

Do not publish proprietary vendor drivers, firmware, captures containing
private material, or other restricted artifacts with a report.

For code changes:

1. Describe the exact PCI subsystem, kernel and source/display mode.
2. Keep hardware writes bounded and explain their evidence.
3. Preserve the validated HDMI IN 2 path unless the change explicitly targets
   and tests it.
4. For concurrent video, test HDMI IN 2 STREAMON before HDMI IN 1.
5. Run `make`, `make check`, and `git diff --check`.
6. Separate a static-analysis conclusion from a physical hardware result.

AI-assisted contributions are welcome when disclosed. The contributor remains
responsible for reviewing and testing the submitted work.
