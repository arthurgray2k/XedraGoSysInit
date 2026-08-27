# Concept: Linux Kernel vs. Root Filesystem

A frequent source of confusion when building a Linux distribution is the distinction between the **Linux Kernel** and the **Root Filesystem**.

---

## 1. The Separation of Concerns

```text
+-------------------------------------------------------------------------------+
|                                  USER SPACE                                   |
|                                                                               |
|  [Applications]           [Init / Services]          [Shell / Utilities]      |
|   Fluxbox, xterm            SysVinit                   bash, ls, cat, sed     |
|                                                                               |
|  ---------------------------------------------------------------------------  |
|  [Standard C Library (glibc)]                                                 |
|   libc.so.6: Translates program requests into Linux system calls              |
+-------------------------------------------------------------------------------+
                                      │
                         System Call Interface (syscall)
                         (open, read, write, fork, execve, socket)
                                      ▼
+-------------------------------------------------------------------------------+
|                                 KERNEL SPACE                                  |
|                                                                               |
|  [Process Scheduler]      [Memory Manager]          [Virtual Filesystem]     |
|   Context switches, PIDs   Paging, Virtual Memory    VFS, ext4, squashfs      |
|                                                                               |
|  [Device Drivers]         [Network Stack]           [Hardware Security]       |
|   GPU, NVMe, USB, KVM      TCP/IP, Ethernet, Wi-Fi   Ring 0 CPU privileges    |
+-------------------------------------------------------------------------------+
                                      │
                                      ▼
+-------------------------------------------------------------------------------+
|                             PHYSICAL HARDWARE                                 |
|  CPU, RAM, Disks, Motherboard Chipset, Display Adapter, Network Interface     |
+-------------------------------------------------------------------------------+
```

---

## 2. What the Linux Kernel Does

The Linux kernel (`vmlinuz`) is a single, monolithic binary file executed by the bootloader at startup.

Its responsibilities include:
1. **Hardware Discovery & Driver Initialization**: Probing the motherboard buses (PCIe, USB, I2C), loading required driver modules, and exposing hardware endpoints in `/dev` and `/sys`.
2. **Memory Management**: Setting up virtual memory tables and page mappings.
3. **Process Scheduling**: Multiplexing CPU cores among hundreds of running threads.
4. **Mounting the Root Filesystem**: Finding the primary storage partition (or ramdisk) and mounting it at `/`.
5. **Spawning PID 1**: Launching the very first userland program (`/sbin/init`).

---

## 3. What the Root Filesystem Does

The root filesystem is static data stored on disk. It contains:
1. **The Shared C Library (`glibc`)**: Provides the standard POSIX API.
2. **Executables & Binaries**: Compiled machine code that the kernel loads into memory via `execve`.
3. **Configuration Data (`/etc/`)**: Plain-text instructions dictating network settings, user logins, and service definitions.
4. **Package Metadata (`/var/lib/dpkg/`)**: Tracking what is installed.

---

## 4. Why a Root Filesystem Alone Cannot Boot

A root filesystem on a disk partition without a kernel and bootloader is just inert data.
- The computer's CPU boots into UEFI firmware.
- The firmware has no knowledge of how to parse Linux directory structures, load dynamically linked libraries, or schedule processes.
- The firmware requires a **Bootloader (GRUB)** to load the **Kernel (`vmlinuz`)** and **Initramfs (`initrd.img`)** into RAM.
- The kernel boots, initializes the hardware, and only then mounts the root filesystem to run `/sbin/init`.

This is why Xedra's build pipeline creates the root filesystem first (Stage 3), configures init (Stage 4), adds the kernel & bootloader (Stage 5), and packages it into a bootable ISO (Stage 6).
