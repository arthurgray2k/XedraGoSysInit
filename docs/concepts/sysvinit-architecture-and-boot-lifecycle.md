# SysVinit Architecture, ISO Image Construction, and Boot Lifecycle

## 1. Executive Summary

**Xedra Linux** is an educational, minimalist distribution built from first principles using pure upstream Debian 13 ("Trixie") packages, but fundamentally distinguished by its init architecture:
- **Traditional SysVinit (`sysvinit-core`) operates as PID 1** instead of `systemd`.
- **Session and seat management is provided by `elogind`** (a standalone, non-systemd logind daemon).
- **The user interface is a lightweight X11 desktop** using Fluxbox and `xterm`.

This document details the architectural principles of SysVinit, how the Xedra ISO build pipeline constructs this environment, and the exact step-by-step lifecycle from UEFI power-on to the graphical desktop.

---

## 2. SysVinit vs. Systemd: Architectural Comparison

```text
+-----------------------------------------------------------------------------------------+
|                                    SYSVINIT ARCHITECTURE                                |
|                                                                                         |
|  [ Linux Kernel ] ──► PID 1: /sbin/init (C binary)                                      |
|                             │                                                           |
|                             ├── Reads /etc/inittab                                      |
|                             ├── Executes POSIX Shell Scripts:                           |
|                             │     ├── /etc/init.d/rcS (Mounts, udev, early hardware)    |
|                             │     └── /etc/init.d/rc 2 (Runlevel multi-user daemons)    |
|                             ├── Spawns & Respawns getty(s) on virtual terminals         |
|                             └── Reaps orphaned child processes (Zombie cleanup)         |
+-----------------------------------------------------------------------------------------+
|  Key Philosophy: Unix Rule of Simplicity. PID 1 is tiny (<100 KB); all startup logic is |
|  transparent, inspectable, and debuggable plain-text shell scripting.                   |
+-----------------------------------------------------------------------------------------+

+-----------------------------------------------------------------------------------------+
|                                     SYSTEMD ARCHITECTURE                                |
|                                                                                         |
|  [ Linux Kernel ] ──► PID 1: /lib/systemd/systemd (Monolithic C daemon)                 |
|                             │                                                           |
|                             ├── Socket activation, D-Bus broker coordination            |
|                             ├── cgroup process tree management                          |
|                             ├── Declarative .service unit parsing                       |
|                             ├── Integrated journald logging, udev, networkd, logind     |
|                             └── Dependency graph solver & parallel execution engine     |
+-----------------------------------------------------------------------------------------+
|  Key Philosophy: Feature-rich platform integration. PID 1 manages services, logging,    |
|  timers, containers, and network state in a unified codebase.                           |
+-----------------------------------------------------------------------------------------+
```

### Detailed Component Comparison:

| Dimension | SysVinit (`sysvinit-core`) | Systemd (`systemd-sysv`) |
| :--- | :--- | :--- |
| **PID 1 Binary** | `/sbin/init` (compact C binary) | `/lib/systemd/systemd` (large C binary) |
| **Configuration Format** | `/etc/inittab` + `/etc/init.d/*` shell scripts | Declarative Unit files (`.service`, `.target`) |
| **Execution Model** | Deterministic, sequential execution by runlevel (`/etc/rc2.d/S*`) | Parallelized execution based on dependency DAG |
| **Logging** | Standard syslog (`/var/log/messages`, `/var/log/syslog`) | Binary Journal (`systemd-journald`, `journalctl`) |
| **Process Tracking** | PID files in `/run/` or `/var/run/` | Linux Control Groups (cgroups v2) |
| **Session Management** | Standalone `elogind` daemon over D-Bus | Built-in `systemd-logind` |
| **Crash Surface** | Minimal; shell scripts fail individually without crashing PID 1 | Higher complexity in PID 1 code path |

---

## 3. How We Build the Xedra SysVinit Live ISO

Building a bootable Debian-based distribution with SysVinit requires overcoming Debian's default assumption that `systemd` is PID 1. We accomplish this inside the dedicated `xedra-builder` VM using a 4-phase build pipeline:

```text
[ Developer Tree ~/XedraGoSysInit ]
             │
             ▼
 1. live-build Workspace Generation (configure-live-build.sh)
    ├── lb config: Target Debian 13 (Trixie), amd64, GRUB UEFI, Live ISO
    ├── Package List: Linux Kernel, Xorg, Fluxbox, xterm, spice-vdagent
    └── Chroot Hook: 0100-sysvinit-transition.hook.chroot
             │
             ▼
 2. Base Bootstrap & Debootstrap Phase (lb bootstrap)
    └── Downloads minimal Debian base system into chroot/
             │
             ▼
 3. Atomic SysVinit Transition Hook (lb chroot)
    ├── apt-get install sysvinit-core initscripts insserv elogind systemd-sysv-
    ├── Sets passwords (root:root, xedra:xedra) & passwordless sudoers
    ├── Copies /etc/inittab, /etc/issue, /etc/os-release, /home/xedra/.xinitrc
    └── Enables SysVinit services (udev, dbus, elogind) via update-rc.d
             │
             ▼
 4. Binary Assembly & ISO Output (lb binary -> build-iso.sh)
    ├── Compresses chroot into SquashFS: binary/live/filesystem.squashfs
    ├── Installs GRUB EFI bootloader & Linux kernel: binary/boot/
    ├── Generates hybrid ISO via xorriso
    └── Emits ~/XedraGoSysInit/output/xedra-0.1-amd64.iso + SHA256 checksum
```

### Why the Atomic Transition Hook is Required:
Debian package repositories define `systemd-sysv` as the default `Essential: yes` package. Attempting to install `elogind` while `systemd` is present causes an immediate dependency conflict. 

Our hook resolves this atomically using APT's removal syntax:
```bash
apt-get install -y --no-install-recommends \
    sysvinit-core \
    initscripts \
    insserv \
    orphan-sysvinit-scripts \
    live-config-sysvinit \
    systemd-sysv- \
    elogind \
    libpam-elogind \
    --allow-remove-essential
```
The trailing hyphen on `systemd-sysv-` instructs APT to uninstall `systemd-sysv` in the exact same transaction that installs `sysvinit-core` and `elogind`, preserving full package tree sanity.

---

## 4. The Complete End-to-End Boot & Login Lifecycle

When the compiled `xedra-0.1-amd64.iso` boots inside the `xedra-lab` VM (or on bare-metal hardware), the system executes 10 distinct phases:

```text
+-------------------------------------------------------------------------------+
| PHASE 1: UEFI FIRMWARE & HARDWARE INITIALIZATION                              |
|  - Motherboard UEFI firmware initializes CPU, RAM, and PCIe devices.          |
|  - Scans bootable media for EFI/BOOT/BOOTX64.EFI.                             |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 2: GRUB 2 BOOTLOADER                                                    |
|  - Loads grub.cfg menu: "Xedra Linux 0.1 (amd64)".                            |
|  - Loads Linux Kernel (/live/vmlinuz) and Initramfs (/live/initrd.img) to RAM.|
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 3: LINUX KERNEL INITIALIZATION                                          |
|  - Kernel uncompresses, detects CPU cores, initializes memory management.     |
|  - Mounts RAM-based initramfs root and launches early userspace (/init).     |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 4: INITRAMFS & LIVE-BOOT ROOTFS ASSEMBLY                                |
|  - live-boot scripts scan block devices to locate ISO filesystem.             |
|  - Mounts squashfs image: /live/filesystem.squashfs -> /run/live/rootfs/      |
|  - Creates writable OverlayFS in RAM: lowerdir=squashfs, upperdir=ramdisk.    |
|  - Executes switch_root to transfer root to real userland filesystem.         |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 5: PID 1 LAUNCH (/sbin/init)                                            |
|  - Kernel executes the master init binary: /sbin/init (PID 1).                |
|  - Kernel creates PID 2: [kthreadd] for kernel worker threads.                |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 6: /etc/inittab EXECUTION & SYSTEM INITIALIZATION (rcS)                 |
|  - /sbin/init parses /etc/inittab.                                            |
|  - Identifies default runlevel: id:2:initdefault:                             |
|  - Executes early system initialization: si::sysinit:/etc/init.d/rcS          |
|      ├── Mounts /proc, /sys, /dev/pts, /run pseudo-filesystems                |
|      ├── Starts udev daemon (/etc/init.d/udev) -> creates /dev/input/event*   |
|      └── Activates swap and checks filesystems.                               |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 7: RUNLEVEL 2 MULTI-USER TRANSITION (/etc/init.d/rc 2)                  |
|  - /sbin/init invokes /etc/init.d/rc 2 to start multi-user services.          |
|  - Sequentially runs /etc/rc2.d/S* symlinks:                                  |
|      ├── S01dbus   -> Starts System Message Bus daemon (/etc/init.d/dbus)     |
|      ├── S01elogind-> Starts Login & Seat Management daemon                   |
|      └── S01networking / dhcpcd -> Configures Ethernet interfaces             |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 8: TTY SPAWNING & VIRTUAL CONSOLES                                      |
|  - /sbin/init reads inittab lines for virtual consoles:                       |
|      1:2345:respawn:/sbin/getty --autologin xedra --noclear 38400 tty1        |
|      2:23:respawn:/sbin/getty 38400 tty2                                      |
|  - Displays /etc/issue custom Xedra ASCII banner on consoles.                 |
|  - getty automatically logs in user 'xedra' on tty1 without a password prompt.|
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 9: LOGIN SHELL EXECUTION & AUTO-STARTX                                  |
|  - getty launches /bin/bash for user 'xedra'.                                 |
|  - Bash reads /home/xedra/.profile:                                           |
|      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then exec startx; fi |
|  - startx initializes X11 Server (Xorg) on /dev/tty1.                         |
+-------------------------------------------------------------------------------+
                                         │
                                         ▼
+-------------------------------------------------------------------------------+
| PHASE 10: X11 SESSION INITIALIZATION & FLUXBOX DESKTOP                        |
|  - Xorg reads /home/xedra/.xinitrc:                                           |
|      ├── xsetroot -solid "#1e1e1e" (Sets clean dark wallpaper)                |
|      ├── spice-vdagent &           (Enables seamless SPICE mouse capture)     |
|      ├── xterm &                   (Launches terminal emulator)               |
|      └── exec fluxbox              (Replaces subshell with Window Manager)    |
|  - User arrives at an interactive, fully functional graphical desktop!        |
+-------------------------------------------------------------------------------+
```

---

## 5. Key SysVinit Files & Configuration Reference

### 1. Master Configuration: `/etc/inittab`
```text
# Default runlevel
id:2:initdefault:

# System initialization before any runlevel
si::sysinit:/etc/init.d/rcS

# What to do in runlevel 2
l2:2:wait:/etc/init.d/rc 2

# Automatic login on virtual console 1
1:2345:respawn:/sbin/getty --autologin xedra --noclear 38400 tty1
2:23:respawn:/sbin/getty 38400 tty2
3:23:respawn:/sbin/getty 38400 tty3
```

### 2. User Profile: `/home/xedra/.profile`
```bash
# ~/.profile: Executed upon login by Bourne-compatible login shells
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
```

### 3. X11 Session Script: `/home/xedra/.xinitrc`
```bash
#!/bin/sh
# ~/.xinitrc: Executed by startx

# 1. Set solid dark background color
xsetroot -solid "#1e1e1e"

# 2. Start SPICE agent for seamless mouse pointer tracking in VMs
spice-vdagent &

# 3. Launch terminal emulator
xterm -geometry 80x24+50+50 &

# 4. Launch Fluxbox window manager as the main session process
exec fluxbox
```

### 4. Custom Branding: `/etc/issue`
```text
       __  __          _             _     _                  
      \ \/ /___  __| |_ __ __ _    | |   (_)_ __  _   ___  __
       \  // _ \/ _` | '__/ _` |   | |   | | '_ \| | | \ \/ /
       /  \  __/ (_| | | | (_| |   | |___| | | | | |_| |>  < 
      /_/\_\___|\__,_|_|  \__,_|   |_____|_|_| |_|\__,_/_/\_\

     Xedra Linux 0.4.3 (amd64) — Genesis
     Kernel \r on an \m (\l)
```

---

## 6. What Was Learned & Distro Engineering Insights

1. **Why `udev` is Vital Under SysVinit**: Unlike systemd where `systemd-udevd` starts automatically, SysVinit relies on `/etc/init.d/udev` in `rcS`. If `udev` does not start, Linux does not create `/dev/input/event*` nodes, causing X11 to lack mouse and keyboard input.
2. **Why `elogind` Enables Non-Root Desktops**: `elogind` gives standard users access to DRM graphics devices and input events via PAM (`pam_elogind.so`) and D-Bus without requiring root privileges.
3. **The Power of Plain-Text Lifecycle Control**: In SysVinit, every single step from kernel handoff to graphical desktop can be inspected, logged, and modified directly through standard shell scripts without needing binary debugging tools.
