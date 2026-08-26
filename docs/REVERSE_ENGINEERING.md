# Reverse-engineering and development method

This document describes the research, implementation and validation process
used to build the Linux driver.

## Research input

The official Windows software distributed for the capture card was lawfully
obtained and used locally to study how the hardware communicates. The research
focused on the functional behavior required for Linux interoperability.

Ghidra provided the static-analysis environment: disassembly, decompilation,
cross-references, call graphs, data references and comparisons between
initialization paths. The resulting observations were organized into hardware
operations, state transitions and testable hypotheses.

## Development process

Development proceeded in small iterations:

1. Locate a relevant routine or data structure in the Windows driver.
2. Trace its callers, state changes, register operations and timing behavior.
3. Express the observed behavior through Linux PCI, V4L2/videobuf2, ALSA or
   LED-class interfaces.
4. Build a bounded test for the specific behavior under investigation.
5. Compare hardware status, logs, DMA or frame evidence and physical output
   with the expected result.
6. Keep, revise or discard the hypothesis before moving to the next part.

This process produced a Linux-native implementation with lifecycle and data
structures designed for the Linux kernel interfaces. Functional device details
needed for interoperability were retained, including identifiers, register
sequences, masks, delays, format and timing values, EDID contents, and a
generated HDR-to-SDR lookup table.

## AI-assisted workflow

AI agents were used throughout the same iterative process to:

- navigate and compare Ghidra exports and cross-references;
- map Windows routines and state transitions to hardware operations;
- develop and review Linux kernel-driver changes;
- prepare one-test-at-a-time hardware scripts;
- analyze logs, register snapshots, DMA/frame evidence and regressions;
- integrate V4L2, ALSA, passthrough and RGB support; and
- draft and check documentation, installation scripts and packaging.

Research priorities and test boundaries were established under human
direction. Hardware experiments were run locally, and their physical video,
audio, passthrough and RGB results were observed directly. Those observations,
together with the recorded technical evidence, guided each subsequent
iteration.

## Validation

A feature is documented as physically validated only after its real output or
capture behavior has been observed on the project hardware. Depending on the
feature, the supporting evidence also includes register state, kernel logs,
frame counts and hashes, DMA progress, timing or audio levels.

Validation was performed on one card and a limited set of sources, displays,
modes and Linux environments. The tested matrix and remaining gaps are listed
in [`STATUS.md`](STATUS.md).

## Repository output

The resulting public tree contains:

- the Linux PCI/V4L2/ALSA/LED driver;
- the constants, tables and register sequences used by the driver;
- build, installation, initialization, status and release-check scripts;
- a WirePlumber policy for the tested PipeWire-Pulse desktop path; and
- documentation of supported operation, validation status and research method.

The repository documents enough of the process and results for further testing
and independent verification. Any additional research should use lawfully
obtained inputs and follow the laws and license terms applicable to it.
