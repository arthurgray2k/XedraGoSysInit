# XedraGoSysInit Usage Guide

This document details common workflows, CLI commands, configuration options, and typical use cases for **Xedra Linux (with goSysVinit)**.

---

## 1. Init System Architecture: goSysVinit

Xedra Linux uses **`goSysVinit`**, a pure Go implementation of System V Init 3.15, as its PID 1 process supervisor.

### Package & Binary Overlay Model
* **Debian APT Skeleton (`sysvinit-core`)**: Provides package manager dependency resolution, `insserv`, `initscripts`, and the standard `/etc/init.d/*` shell script library.
* **`goSysVinit` Static Suite**: The actual runtime binaries in `/sbin/` (`/sbin/init`, `/sbin/telinit`, `/sbin/halt`, `/sbin/shutdown`, `/sbin/runlevel`, `/sbin/killall5`, `/sbin/sulogin`) and `/bin/` (`/bin/mountpoint`, `/bin/pidof`) are pure static Go binaries.

---

## 2. Common Administrative Commands

### Inspecting Active Init & Runlevel
```bash
# Check PID 1 executable details
ls -l /proc/1/exe

# View active init system version banner
/sbin/init --version

# View current and previous runlevel
runlevel

# View detailed utmp/wtmp records
utmpdump /var/run/utmp
```

### Runlevel Management via `telinit`
```bash
# Switch to Runlevel 2 (Default multi-user desktop)
sudo telinit 2

# Switch to Runlevel 1 / Single-User Maintenance Mode
sudo telinit 1

# Re-read /etc/inittab configuration without rebooting
sudo telinit q

# Force init to reload its binary state
sudo telinit u
```

### System Shutdown & Reboot
```bash
# Clean timed shutdown (broadcast to all users)
sudo shutdown -h +2 "System undergoing maintenance in 2 minutes"

# Immediate reboot
sudo reboot

# Immediate power off
sudo poweroff

# Cancel a pending timed shutdown
sudo shutdown -c
```

---

## 3. Building the Xedra Live ISO

### Prerequisites on Build Host
Ensure required virtualization and build dependencies are installed:
```bash
sudo apt-get install -y live-build debootstrap xorriso squashfs-tools mtools dosfstools
```

### Build Workflows

#### 1. Developer Profile (`dev` — Fast Iteration)
Builds with persistent package cache and fast gzip compression:
```bash
cd /home/mint/XedraGoSysInit
sudo ./scripts/build-iso.sh dev
```
*Output artifact:* `output/xedra-0.4.3-amd64-gosysvinit.iso`

#### 2. Release Profile (`release` — Production)
Clean build with high XZ compression:
```bash
sudo ./scripts/build-iso.sh release
```
*Output artifact:* `output/xedra-0.4.3-amd64-gosysvinit.iso`

#### 3. Minimal Profile (`minimal` — Headless / Rescue)
Builds lightweight text-console edition:
```bash
sudo ./scripts/build-iso.sh minimal
```
*Output artifact:* `output/xedra-0.4.3-minimal-amd64-gosysvinit.iso`

---

## 4. Testing the ISO in Virtual Machine (QEMU / KVM)

To test-boot the generated ISO using QEMU:
```bash
qemu-system-x86_64 \
    -enable-kvm \
    -m 2048 \
    -smp 2 \
    -cdrom output/xedra-0.4.3-amd64-gosysvinit.iso \
    -boot d \
    -vga std
```

### Default Live Credentials
* **Username:** `live`
* **Password:** `live`
* **Root Password:** `root`
* **Sudo:** Passwordless (`sudo -i`)
