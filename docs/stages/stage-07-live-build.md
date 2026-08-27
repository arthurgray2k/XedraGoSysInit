# Stage 7 — Debian Live-Build Configuration

## 1. Objective

Configure the Debian `live-build` framework inside `~/XedraGoSysInit/build/live-build` with Xedra's complete package stack, kernel, SysVinit APT pinning, and desktop overlays to prepare for compiling the bootable ISO.

---

## 2. What Was Executed & Verified

Inside `xedra-builder`:
```bash
./scripts/configure-live-build.sh
```

---

## 3. Configuration Breakdown

1. **`lb config` Profile**:
   - Distribution: `trixie` (Debian 13)
   - Architecture: `amd64`
   - Image Format: `iso-hybrid` (bootable on USB and optical media)
   - Bootloader: `grub-efi` (dual BIOS + UEFI boot support)
2. **Package Selection (`config/package-lists/xedra.list.chroot`)**:
   - Kernel: `linux-image-amd64`
   - Live boot infrastructure: `live-boot`, `live-config`, `live-config-sysvinit`
   - Init system: `sysvinit-core`, `initscripts`, `insserv`, `orphan-sysvinit-scripts`
   - Desktop & Terminal: `xserver-xorg-core`, generic drivers, `fluxbox`, `xterm`
   - Essential tools: `coreutils`, `pciutils`, `usbutils`, `iproute2`, `dhcpcd-base`, `nano`, `sudo`
3. **APT Pinning (`config/archives/nosystemd.pref.chroot`)**:
   - Pins `systemd-sysv` to priority `-1` so the dependency solver never pulls `systemd-sysv` into the ISO.
4. **Overlays (`config/includes.chroot/`)**:
   - `/etc/inittab`: SysVinit runlevel 2 configuration
   - `/etc/skel/.xinitrc` & `/etc/skel/.fluxbox/menu`: Default user desktop session
   - `/etc/live/config.conf.d/xedra.conf`: Live user auto-login hook (`user:xedra`)

---

## 4. Current State

- **Stage 7 Status**: `Complete & Verified`.
- **Next Stage**: Stage 8 — ISO Creation (`sudo lb build` $\rightarrow$ `output/xedra-0.1-amd64.iso`).
