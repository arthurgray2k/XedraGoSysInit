# Stage 3 — Debian Builder VM Setup (`xedra-builder`)

## 1. Objective

Create a dedicated, reproducible Debian 13 "Trixie" virtual machine (`xedra-builder`) on the Linux host via libvirt/QEMU/KVM. This VM serves as the authoritative, uncompromised distribution engineering environment with full Linux kernel capabilities for `debootstrap`, `live-build`, loop mounts, and ISO assembly.

---

## 2. Rationale: Why Transition from Container to VM?

In **Stage 2**, we evaluated a rootless Podman container as the build environment. That experiment revealed:
1. **User Namespace Restrictions**: Linux user namespaces (`CLONE_NEWUSER`) intentionally block unprivileged creation of block/character device nodes (`mknod`) and nested loop mounts.
2. **Distro Tool Requirements**: Standard Debian tooling (`debootstrap`, `live-build`, `losetup`, `mksquashfs`) is designed to operate on a full Linux kernel with device node and loopback filesystem mounting capabilities.
3. **Purity Without `--privileged`**: Rather than weakening container security on the host by passing `--privileged`, creating a dedicated Debian 13 VM provides 100% native kernel features in complete isolation from the physical host system.

---

## 3. Builder VM Specifications

- **Name**: `xedra-builder`
- **OS**: Debian 13 (Trixie) `amd64`
- **vCPUs**: 2
- **RAM**: 4096 MB (4 GB)
- **Virtual Disk**: 35 GB (`qcow2`, `virtio` bus, stored in libvirt storage pool `default`)
- **Firmware**: UEFI (OVMF)
- **Network**: NAT (`network=default`, `virtio`)
- **Display / Graphics**: SPICE with QXL video device (`--graphics spice,listen=none --video qxl`)
- **Hypervisor Instance**: `qemu:///system`

---

## 4. Installed Software Inside `xedra-builder`

We clearly separate **Builder VM Software** from **Target Xedra Software**:

| Category | Packages in `xedra-builder` | Purpose | Included in Xedra Target? |
| :--- | :--- | :--- | :--- |
| **Developer Desktop** | `fluxbox`, `xorg`, `xterm`, `firefox-esr` | Comfortable graphical environment inside the VM for coding and browsing documentation | **No** (Fluxbox/xterm exist in Xedra, but Firefox is NOT in Xedra) |
| **Version Control** | `git` | Clones and manages `~/XedraGoSysInit` | **No** |
| **Distro Engineering** | `debootstrap`, `live-build`, `squashfs-tools`, `xorriso`, `grub-pc-bin`, `grub-efi-amd64-bin`, `mtools`, `dosfstools`, `rsync` | Required to assemble Debian rootfs, compress squashfs, and build UEFI ISOs | **No** (Build tools only) |

---

## 5. Host Automation Scripts

Located under `~/XedraGoSysInit/scripts/vm/`:

| Script | Purpose |
| :--- | :--- |
| `scripts/vm/check-builder-vm-host.sh` | Validates libvirt connection, storage pool capacity, UEFI firmware, and ISO readability. |
| `scripts/vm/create-builder-vm.sh` | Invokes `virt-install` with exact specifications to create `xedra-builder`. |
| `scripts/vm/start-builder-vm.sh` | Powers on the `xedra-builder` VM. |
| `scripts/vm/stop-builder-vm.sh` | Gracefully sends ACPI shutdown signal to `xedra-builder`. |
| `scripts/vm/inspect-builder-vm.sh` | Displays domain info, disks, network interfaces, and IP address. |
| `scripts/vm/destroy-builder-vm.sh` | Safely removes domain and deletes only its virtual disk volume after confirmation. |
| `scripts/vm/bootstrap-builder.sh` | **Runs inside the VM** to install Fluxbox, Firefox, and the distro build toolchain. |

---

## 6. Exact Step-by-Step Installation Procedure

### Step 1: Validate Host Hypervisor (HOST)
```bash
cd ~/XedraGoSysInit
./scripts/vm/check-builder-vm-host.sh /path/to/debian-13-netinst.iso
```

### Step 2: Create the Virtual Machine (HOST)
```bash
./scripts/vm/create-builder-vm.sh /path/to/debian-13-netinst.iso
```

### Step 3: Complete Debian Installer Interactively (VIRT-MANAGER)
Open Virtual Machine Manager:
```bash
virt-manager
```
Inside the Debian Netinst installer:
- **Language/Location**: English / your local timezone and keyboard.
- **Hostname**: `xedra-builder`
- **Domain**: (leave empty or local)
- **Root Password**: Set administrative root password.
- **User Account**: Create user `mint` or `builder` with sudo access.
- **Partitioning**: Guided - use entire disk (35 GB virtual disk), all files in one partition.
- **Package Selection (Software Selection)**:
  - ❌ Uncheck all desktop environments (GNOME, XFCE, KDE, etc.)
  - ✅ Check "SSH server" (optional)
  - ✅ Check "standard system utilities"
- **GRUB Bootloader**: Install to primary drive (UEFI EFI System Partition).

### Step 4: First Boot & Toolchain Bootstrap (INSIDE BUILDER VM)
Log in as root (or user with sudo) inside `xedra-builder`:
```bash
# Clone the Xedra repository
git clone https://github.com/arthurgray2k/XedraLinux.git ~/XedraGoSysInit

# Run post-install bootstrap
sudo ~/XedraGoSysInit/scripts/vm/bootstrap-builder.sh
```

### Step 5: Start Developer Desktop (INSIDE BUILDER VM)
```bash
startx
```
Fluxbox will launch with `xterm` and `firefox-esr` ready.

---

## 7. Current State

- **Scripts & Documentation**: Implemented and verified on host.
- **VM Creation**: Ready for manual execution with user's Debian ISO.
