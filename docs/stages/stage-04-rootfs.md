# Stage 4 — First Debian Root Filesystem

## 1. Objective

Bootstrap and inspect a pure Debian 13 "Trixie" base root filesystem into `~/XedraGoSysInit/build/rootfs` using native `debootstrap` inside the dedicated `xedra-builder` virtual machine.

---

## 2. What Was Executed & Verified

Inside `xedra-builder`:
```bash
sudo debootstrap --arch=amd64 trixie ~/XedraGoSysInit/build/rootfs https://deb.debian.org/debian
sudo ./scripts/inspect-rootfs.sh
```

---

## 3. Inspection & Technical Findings

1. **Filesystem Hierarchy Standard (FHS) & Merged-/usr**:
   - All standard directories (`/etc`, `/usr`, `/var`, `/dev`, `/proc`, `/sys`, `/tmp`, `/root`, `/home`) were created.
   - `/bin`, `/sbin`, and `/lib` are symlinks pointing into `/usr/bin`, `/usr/sbin`, and `/usr/lib`, confirming Debian 13's modern Merged-/usr layout.
2. **DPKG Database Status**:
   - Exactly **146 base packages** were downloaded, unpacked, configured, and recorded in `/var/lib/dpkg/status`.
   - Essential system providers:
     - `/etc/os-release` is provided by `base-files`
     - `/bin/sh` is provided by `dash`
     - `/usr/bin/dpkg` is provided by `dpkg`
3. **Init System Baseline**:
   - Upstream Debian defaults to installing `systemd` and `systemd-sysv` (`/sbin/init -> ../lib/systemd/systemd`).
   - In subsequent stages, we replace `systemd-sysv` with `sysvinit-core` to fulfill Xedra's core architecture.

---

## 4. Current State

- **Stage 4 Status**: `Verified & Complete`.
- **Next Stage**: Stage 5 — Xedra Package Selection, SysVinit Transition, and Customization.
