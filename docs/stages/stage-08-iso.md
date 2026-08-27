# Stage 8 — ISO Creation & Packaging

## 1. Objective

Compile, verify, and package the standalone, bootable **Xedra 0.1 Live ISO Image** (`output/xedra-0.1-amd64.iso`) using Debian `live-build` inside the `xedra-builder` virtual machine.

---

## 2. What Was Executed & Verified

Inside `xedra-builder`:
```bash
sudo ./scripts/build-iso.sh
```

---

## 3. Build Results & Verified Artifacts

1. **Compilation Pipeline Stages Completed**:
   - **Bootstrap**: Minimal Debian 13 "Trixie" (`amd64`) base packages downloaded and verified.
   - **Chroot Hook Execution**: `0100-sysvinit-transition.hook.chroot` executed inside chroot, installing `sysvinit-core`, `initscripts`, `insserv`, `live-config-sysvinit`, and purging `systemd-sysv`.
   - **Initramfs Generation**: Debian Linux 6.12 kernel (`linux-image-6.12.101+deb13-amd64`) and `live-boot` initramfs generated.
   - **Squashfs Compression**: `mksquashfs` compressed root filesystem into `/live/filesystem.squashfs`.
   - **Dual Bootloader Staging**: UEFI (`grub-efi`) and BIOS stages embedded into ISO 9660 hybrid image via `xorriso`.
2. **Output Artifacts**:
   - **ISO Image**: `/home/builder/XedraLinux/output/xedra-0.1-amd64.iso` (Size: 948 MB)
   - **SHA256 Checksum**: `07cbea3b76718c76f0bed730f3b8cac2276377adf406f64613c8cd84a474d058`

---

## 4. Current State

- **Stage 8 Status**: `Complete & Verified`.
- **Next Stage**: Stage 9 — Test Booting Xedra 0.1 in the `xedra-lab` Virtual Machine.
