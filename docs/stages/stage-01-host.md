# Stage 1 — Host Environment & Virtualization Validation

## 1. Objective

Validate that the physical development machine (Linux host) satisfies all prerequisite hardware, virtualization, and tooling requirements for Xedra Linux engineering and VM-based testing, without modifying the host operating system.

---

## 2. What Was Built / Validated

- Created a non-destructive inspection tool: `scripts/check-host.sh`.
- Inspected and verified host OS, architecture, kernel version, hardware virtualization, KVM device nodes, QEMU emulator, libvirt daemon, virt-manager, Git, DPKG, RAM, and disk storage.

---

## 3. Host Environment Specifications

- **Operating System**: Linux host (`x86_64`)
- **Host Kernel**: `7.0.0-28-generic`
- **CPU Virtualization**: Intel VT-x (`VMX` hardware extension detected)
- **Virtualization Device**: `/dev/kvm` (accessible with RW permissions)
- **Kernel Module**: `kvm_intel` loaded
- **Hypervisor Stack**: QEMU 8.2.2, libvirt 10.0.0, virt-manager
- **Available Resources**: 15 GB RAM (11+ GB free), ~412 GB free disk on `/`
- **Disposable Test VM**: `xedra-lab` (2 vCPUs, 2 GB RAM, 8 GB virtual disk, UEFI firmware)

---

## 4. Tools Used

- `bash`: Scripting execution with `set -euo pipefail`.
- `virsh`: Management of libvirt domains and hypervisor status.
- `qemu-system-x86_64`: Machine emulation backend.
- `grep`, `awk`, `sed`: Text processing of `/proc/cpuinfo`, `/proc/meminfo`, and `lsmod`.

---

## 5. Exact Commands Executed

```bash
# Verify host environment
cd ~/XedraGoSysInit
./scripts/check-host.sh
```

---

## 6. Important Files

- `scripts/check-host.sh`: Automated, read-only host inspection script.
- `/etc/os-release`: Host OS identifier.
- `/proc/cpuinfo`: CPU hardware flags (`vmx`/`svm`).
- `/dev/kvm`: KVM character device interface.

---

## 7. What Happened Internally

1. `check-host.sh` read `/etc/os-release` to confirm the physical host operating system environment.
2. Verified `uname -m` output is `x86_64`.
3. Checked `/proc/cpuinfo` for Intel `vmx` or AMD `svm` CPU flags.
4. Tested `/dev/kvm` permissions to verify unprivileged user access to hardware virtualization.
5. Queried `virsh uri` to confirm an active connection to `qemu:///system`.
6. Calculated available RAM from `/proc/meminfo` and free disk space from `df`.

---

## 8. What Was Learned

- **Host Protection**: Debian is intentionally not installed directly on the physical host machine. Using the physical host as the development workstation allows us to run standard IDEs, Git, and browsers while isolating distro builds inside virtual machines.
- **Hardware Acceleration**: Access to `/dev/kvm` enables QEMU to execute guest instructions directly on the physical CPU without software emulation slowdowns.

---

## 9. Problems Encountered & Solutions

- **Issue**: KVM kernel module check originally used a brittle regular expression that failed on certain `lsmod` line formats.
- **Solution**: Refactored the check to use column-aware `awk` parsing:
  ```bash
  lsmod 2>/dev/null | awk '$1 ~ /^(kvm_intel|kvm_amd)$/ {print $1}'
  ```

---

## 10. Verification Results

```text
======================================================
  Xedra Linux 0.1 - Host Environment Inspection       
======================================================
Inspecting host system configuration, virtualization, and build prerequisites...

--- Host System & Architecture ---
  [ AVAILABLE        ] Host OS -> Linux host (x86_64)
  [ AVAILABLE        ] Host Architecture -> x86_64 (amd64 compatible)
  [ AVAILABLE        ] Host Kernel -> 7.0.0-28-generic

--- Hardware Virtualization & KVM ---
  [ AVAILABLE        ] CPU Virtualization -> Hardware support detected (VMX)
  [ AVAILABLE        ] /dev/kvm -> Device exists and is accessible with read/write permissions
  [ AVAILABLE        ] KVM Kernel Module -> Loaded (kvm_intel)

--- Virtual Machine Stack (xedra-lab VM) ---
  [ AVAILABLE        ] QEMU (x86_64) -> QEMU emulator version 8.2.2
  [ AVAILABLE        ] virsh -> libvirt CLI available (v10.0.0)
  [ AVAILABLE        ] libvirt daemon -> Active connection to qemu:///system
  [ AVAILABLE        ] virt-manager -> Graphical VM manager found (/usr/bin/virt-manager)

--- Host Core Tools ---
  [ AVAILABLE        ] git -> git version 2.43.0
  [ AVAILABLE        ] apt -> Host APT package manager available
  [ AVAILABLE        ] dpkg -> Host DPKG available (version 1.22.6)

--- Debian Distro Build Utilities ---
  [ NOT REQUIRED YET ] debootstrap -> Will run inside isolated builder VM
  [ NOT REQUIRED YET ] live-build (lb) -> Will run inside isolated builder VM

--- System Resources ---
  [ AVAILABLE        ] Host Memory (RAM) -> Total: 15 GB, Available: 11 GB
  [ AVAILABLE        ] Disk Space -> 412 GB available on /

======================================================
  Summary Results:
    Available:        15
    Missing:          0
    Not Required Yet: 2
======================================================
Status: Host is ready for setting up the isolated Debian build environment.
```

---

## 11. Current State

- Host validation is **Complete and Verified**.

---

## 12. What Stage 1 Deliberately Did NOT Do

- ❌ Did NOT install Debian onto the host disk.
- ❌ Did NOT modify host bootloaders or GRUB.
- ❌ Did NOT install development packages onto the physical host.
- ❌ Did NOT power on or modify the `xedra-lab` VM.
