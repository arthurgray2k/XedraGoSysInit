# Xedra Linux - Architectural Overview

## 1. System Topology

Xedra Linux development uses a clean, reproducible architecture separating the development workstation, the authoritative build environment, and the testing hypervisor target:

```text
+-------------------------------------------------------------------------------+
|                            1. LINUX HOST (PHYSICAL)                           |
|  - Physical workstation OS: Linux Host (x86_64)                               |
|  - Manages host hypervisor (libvirt, QEMU/KVM) & Git repository               |
|  - Source tree at ~/XedraGoSysInit (https://github.com/arthurgray2k/XedraLinux)   |
|  - Unmodified: Host bootloader, kernel, and package trees are NEVER altered   |
+-------------------------------------------------------------------------------+
                                         │
                   Hypervisor: qemu:///system (Bridged / NAT)
                                         │
        ┌────────────────────────────────┴────────────────────────────────┐
        │                                                                 │
        ▼                                                                 ▼
+-----------------------------------------------+ +-----------------------------------------------+
|         2. AUTHORITATIVE BUILD ENVIRONMENT    | |            3. DISPOSABLE TEST TARGET          |
|                  (xedra-builder VM)           | |                   (xedra-lab VM)              |
|                                               | |                                               |
|  - OS: Debian 13 "Trixie" (amd64)             | |  - Specifications: 2 vCPU, 2 GB RAM, 8 GB Disk|
|  - Specifications: 2 vCPUs, 4 GB RAM, 35 GB   | |  - Firmware: UEFI                             |
|  - Firmware: UEFI                             | |  - Role: Boots generated Xedra ISO images     |
|  - Desktop UI: Fluxbox, Firefox-ESR, xterm    | |  - Validates: SysVinit PID 1, X11, Fluxbox,  |
|  - Toolchain: debootstrap, live-build,        | |    and xterm in real virtualized hardware     |
|    xorriso, squashfs-tools, grub-efi-bin      | +-----------------------------------------------+
|  - Local Working Tree: ~/XedraGoSysInit           |                         ▲
|  - Artifact Output: ~/XedraGoSysInit/output/      |                         │
|    └── xedra-0.1-amd64.iso ───────────────────┼─────────────────────────┘
+-----------------------------------------------+
```

---

## 2. Distinction Between Environments

| Layer | Environment | Purpose | Modifies Physical Host? |
| :--- | :--- | :--- | :--- |
| **Development Host** | Linux Host (`x86_64`) | Physical workstation, IDE, Git, VM orchestration | **No** |
| **Builder VM (`xedra-builder`)** | Debian 13 Trixie (amd64) | Authoritative OS build environment with full Linux kernel capabilities for `debootstrap` and `live-build` | **No** (Isolated in virtual disk) |
| **Target Xedra 0.1** | Debian 13 Base (amd64) | Minimal distribution under construction (SysVinit, Fluxbox, xterm, X11) | N/A (Emitted as ISO) |
| **Testing VM (`xedra-lab`)** | Virtualized Hardware (UEFI) | Disposable hardware testbed for booting and verifying Xedra ISOs | **No** (Disposable virtual disk) |

---

## 3. Target Operating System Stack (Xedra 0.1 Milestone)

When assembled and booted in the `xedra-lab` VM, Xedra 0.1 consists of the following technical layers:

```text
+-------------------------------------------------------------------------------+
|                                USER INTERFACE                                 |
|  - Window Manager:  Fluxbox                                                   |
|  - Terminal:        xterm                                                     |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼
+-------------------------------------------------------------------------------+
|                                DISPLAY SERVER                                 |
|  - Protocol & Server: X11 (structured for future XLibre compatibility)        |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼
+-------------------------------------------------------------------------------+
|                              INIT SYSTEM (PID 1)                              |
|  - Daemon: SysVinit (/sbin/init from sysvinit-core)                           |
|  - Services: /etc/init.d/ scripts and /etc/rc*.d/ runlevel symlinks           |
|  - Rule: systemd-sysv is explicitly forbidden from running as PID 1           |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼
+-------------------------------------------------------------------------------+
|                             USERLAND / BASE ROOTFS                            |
|  - Distribution: Debian 13 "Trixie" (amd64)                                   |
|  - Package Management: Native apt and dpkg from official Debian repositories  |
|  - Hierarchy: Standard Filesystem Hierarchy Standard (FHS)                    |
+-------------------------------------------------------------------------------+
                                        │
                                        ▼
+-------------------------------------------------------------------------------+
|                             KERNEL & HARDWARE INIT                            |
|  - Linux Kernel: Debian upstream linux-image-amd64                            |
|  - Initramfs: initramfs-tools                                                 |
|  - Bootloader: GRUB with UEFI boot support                                    |
+-------------------------------------------------------------------------------+
```

---

## 4. Directory Layout & Roles

```text
~/XedraGoSysInit/
├── LICENSE          # GPL-3.0-or-later for Xedra tooling
├── README.md        # Distro overview and quickstart
├── config/          # live-build configurations, package lists, and SysVinit scripts
├── container/       # (Historical) Stage 2 Podman container definitions
├── docs/            # Architecture, concept explanations, decisions, and stage logs
├── output/          # Build artifacts and target ISO images
└── scripts/         # Automation scripts
    ├── check-host.sh
    └── vm/          # VM lifecycle scripts (create, start, stop, inspect, destroy, bootstrap)
```
