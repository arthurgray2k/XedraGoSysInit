# Step 07 — Configure Debian Live-Build Environment

## Objective

Initialize and configure the Debian `live-build` framework inside `~/XedraGoSysInit/build/live-build` to prepare for compiling the bootable **Xedra 0.1 Live ISO image**.

This step sets up:
1. **Build Profile (`lb config`)**: Debian 13 "Trixie" (`amd64`), `iso-hybrid` image format, UEFI + BIOS bootloaders (GRUB + Syslinux).
2. **Kernel & Live Boot Packages**: `linux-image-amd64`, `live-boot`, `live-config`, `live-config-sysvinit`.
3. **Init System Enforcement**: `sysvinit-core`, `initscripts`, `insserv` with APT pinning strictly excluding `systemd-sysv`.
4. **Desktop Stack**: `xserver-xorg-core`, video drivers, `fluxbox`, `xterm`.
5. **Filesystem Overlays**: `/etc/inittab`, `/etc/skel/.xinitrc`, `/etc/skel/.fluxbox/menu`, and live auto-login hooks.

---

## Preconditions

1. **Step 06 Complete**: Xedra rootfs packages, SysVinit, and Fluxbox desktop have been verified.
2. **Build Tools Present**: `live-build`, `xorriso`, `squashfs-tools`, and `grub-efi-amd64-bin` are installed inside `xedra-builder`.

---

## Environment

Commands in this runbook are executed exclusively inside the:

```text
BUILDER VM
```

*(Connect to `xedra-builder` via SSH: `ssh builder@192.168.122.180` or via `virt-manager` console)*

---

## Commands

Execute the following commands sequentially inside the `xedra-builder` VM:

### 1. Update Repository Working Tree
```bash
# BUILDER VM
cd ~/XedraGoSysInit
git pull
```

### 2. Run the live-build Configuration Script
```bash
# BUILDER VM
./scripts/configure-live-build.sh
```

---

### 3. Inspect the Generated Configuration Tree
```bash
# BUILDER VM
ls -la ~/XedraGoSysInit/build/live-build/config/
cat ~/XedraGoSysInit/build/live-build/config/package-lists/xedra.list.chroot
cat ~/XedraGoSysInit/build/live-build/config/archives/nosystemd.pref.chroot
```

---

## Expected Result

1. `configure-live-build.sh` reports:
   - Base `lb config` profile initialized.
   - Package list `xedra.list.chroot` generated.
   - APT pinning `nosystemd.pref.chroot` created (Priority: -1 for `systemd-sysv`).
   - Overlays installed for `/etc/inittab`, `.xinitrc`, Fluxbox menu, and live auto-login.
   - Reports: `live-build Workspace Successfully Configured!`.

---

## Evidence to Return

Execute the script inside `xedra-builder` and paste the output of:

1. The complete output from: `./scripts/configure-live-build.sh`

---

## Completion Criteria

This step is complete when `~/XedraGoSysInit/build/live-build/config/` is fully populated and verified ready for building the bootable ISO in Step 08.
