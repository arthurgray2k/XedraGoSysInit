# Concept: The Linux Boot Process

This document traces the complete hardware-to-desktop boot process of a modern Linux system, illustrating how Xedra starts from power-on to the Fluxbox window manager.

---

## 1. The Boot Lifecycle Overview

```text
[ Power Button / VM Start ]
             │
             ▼
1. Firmware Phase (UEFI / BIOS)
   - Initializes CPU, RAM, and Motherboard
   - Reads EFI System Partition (ESP) on disk (/EFI/BOOT/BOOTX64.EFI)
             │
             ▼
2. Bootloader Phase (GRUB)
   - Reads /boot/grub/grub.cfg
   - Loads kernel (vmlinuz) and initramfs (initrd.img) into RAM
   - Transfers execution to the Linux Kernel
             │
             ▼
3. Kernel & Early Userspace Phase (Linux Kernel + Initramfs)
   - Kernel unpacks initramfs into temporary rootfs (tmpfs)
   - Loads storage drivers (NVMe, SATA, USB, ISO 9660)
   - Locates real root filesystem (UUID / Label) and mounts it at /sysroot
   - Performs switch_root to pivot root directory into real rootfs
             │
             ▼
4. Init System Phase (SysVinit as PID 1)
   - Kernel executes /sbin/init
   - SysVinit parses /etc/inittab
   - Runs /etc/init.d/rcS (system initialization scripts)
   - Enters default runlevel (Runlevel 2 in Debian)
   - Runs /etc/rc2.d/S* scripts (networking, udev, dbus)
   - Spawns getty terminals or display manager on /dev/tty1
             │
             ▼
5. Display & Desktop Phase (X11 + Fluxbox + xterm)
   - Launches X11 display server (/usr/bin/Xorg)
   - Reads ~/.xinitrc or session configuration
   - Starts Fluxbox Window Manager
   - Opens xterm terminal emulator
```

---

## 2. Deep Dive: The Role of the Initramfs

Modern Linux systems use an **Initial Ramdisk (initramfs)** to bridge the gap between firmware and the root filesystem.

### The Problem:
- The Linux kernel needs to mount the root filesystem partition from a disk.
- But that partition might be on an encrypted volume (LUKS), a RAID array, a logical volume (LVM), or a live ISO overlay (Squashfs).
- The drivers needed to read that storage cannot be compiled into every kernel image without making the kernel massive.

### The Solution:
1. GRUB loads a small, compressed archive (`initrd.img`) into RAM alongside the kernel.
2. The kernel mounts this ramdisk as its temporary root filesystem.
3. A minimal shell script inside the initramfs (`/init`) loads the necessary storage drivers.
4. Once the real root device is ready, `switch_root` swaps the temporary ramdisk with the real disk filesystem and launches `/sbin/init`.

---

## 3. How Xedra Will Boot in `xedra-lab`

In our disposable QEMU/KVM VM:
1. QEMU starts with OVMF UEFI firmware.
2. OVMF loads GRUB from the Xedra ISO.
3. GRUB presents the Xedra boot menu and loads Debian's `vmlinuz-*-amd64` and `initrd.img`.
4. The live initramfs mounts the Squashfs live root filesystem.
5. SysVinit starts up, initializes the system, and boots straight into X11 and Fluxbox.
