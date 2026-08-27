# Xedra Linux - Repository Script Audit

## 1. Overview & Purpose

This document audits all automation and lifecycle scripts in the Xedra Linux repository (`~/XedraGoSysInit`). As the project transitions from the Stage 2 containerized build experiment to the authoritative Stage 3 Debian Builder Virtual Machine (`xedra-builder`), this audit catalogs each script's purpose, current status, technical learnings, and lifecycle recommendation.

In accordance with project policy, **no scripts are deleted or moved during this audit**. Historical scripts are preserved for architectural traceability and learning value.

---

## 2. Classification Schema

- **`ACTIVE`**: Currently used in the active workflow (Stage 1 host checks, Stage 3 VM lifecycle scripts).
- **`HISTORICAL`**: Completed educational exercises (Stage 2 Podman build environment) preserved for reference.
- **`EXPERIMENTAL`**: Experimental or exploratory scripts under ongoing evaluation.
- **`SUPERSEDED`**: Replaced by an updated or higher-level mechanism, but retained for documentation.
- **`OBSOLETE`**: No longer applicable to any active or historical stage.
- **`UNKNOWN`**: Unclassified or unverified scripts.

---

## 3. Comprehensive Script Audit

### A. Host & Virtualization Inspection Scripts

#### 1. `scripts/check-host.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Non-destructive validation of the physical host system for KVM virtualization support, CPU virtualization flags (`vmx`/`svm`), `/dev/kvm` permissions, QEMU, libvirt, and `virt-manager`.
- **Referenced By**: `docs/stages/stage-01-host.md`, `README.md`, `docs/runbooks/vm/01-host-vm-stack.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Demonstrates hardware virtualization detection in sysfs and unprivileged group permissions for `/dev/kvm` and `libvirt`.
- **Recommended Action**: Keep as the primary Stage 1 host validation tool.

---

### B. Container Build Environment Experiment (Stage 2 Historical)

#### 2. `scripts/check-container-runtime.sh`
- **Classification**: `HISTORICAL`
- **Purpose**: Detected whether Podman was installed and functioning in rootless mode on the host system.
- **Referenced By**: `docs/stages/stage-02-build-environment.md`.
- **Is Superseded?**: Yes, superseded by VM infrastructure for distro builds.
- **Useful Knowledge**: Demonstrates rootless OCI runtime detection (`podman info`) without requiring background root daemons.
- **Recommended Action**: Retain in repository as a reference artifact of the Stage 2 container experiment.

#### 3. `scripts/build-builder-image.sh`
- **Classification**: `HISTORICAL`
- **Purpose**: Built the isolated Debian 13 "Trixie" build image (`xedra-builder:trixie`) using Podman from `container/Containerfile`.
- **Referenced By**: `docs/stages/stage-02-build-environment.md`.
- **Is Superseded?**: Yes, superseded by the `xedra-builder` virtual machine.
- **Useful Knowledge**: Documents reproducible minimal base image construction (~118 MB) from `debian:trixie-slim`.
- **Recommended Action**: Retain for historical and container comparison reference.

#### 4. `scripts/check-builder.sh`
- **Classification**: `HISTORICAL`
- **Purpose**: Verified that the container image ran Debian 13 Trixie (`amd64`) and confirmed the `/workspace` host mount.
- **Referenced By**: `docs/stages/stage-02-build-environment.md`.
- **Is Superseded?**: Yes, superseded by VM inspection tools.
- **Useful Knowledge**: Validates architecture matching and mount integrity inside OCI containers.
- **Recommended Action**: Retain for historical documentation.

#### 5. `scripts/enter-builder.sh`
- **Classification**: `HISTORICAL`
- **Purpose**: Interactive entry point into the Debian container environment mounting `~/XedraGoSysInit` at `/workspace`.
- **Referenced By**: `docs/stages/stage-02-build-environment.md`, historical Stage 3 notes.
- **Is Superseded?**: Yes, development is transitioning to the `xedra-builder` VM.
- **Useful Knowledge**: Clean wrapper showing volume bind mounting with SELinux/user namespace flags in Podman.
- **Recommended Action**: Retain for historical reference.

---

### C. Early Debootstrap & Chroot Scripts

#### 6. `scripts/bootstrap-rootfs.sh`
- **Classification**: `HISTORICAL` / `EXPERIMENTAL`
- **Purpose**: Executed Stage 3A `debootstrap --foreign` inside the container to test rootless download and archive unpacking.
- **Referenced By**: `docs/stages/stage-02-build-environment.md`, `docs/LEARNING.md`.
- **Is Superseded?**: Will be superseded by native `debootstrap` running directly inside the `xedra-builder` VM (Stage 4).
- **Useful Knowledge**: Documents how `export container=lxc` allows `debootstrap` to bypass user namespace `test-dev-null` `mknod` limitations.
- **Recommended Action**: Retain as educational evidence of container user namespace behavior vs. native VM execution.

#### 7. `scripts/complete-rootfs.sh`
- **Classification**: `HISTORICAL` / `EXPERIMENTAL`
- **Purpose**: Executed Stage 3B in-chroot second-stage package configuration (`/debootstrap/debootstrap --second-stage`) in the container.
- **Referenced By**: `docs/LEARNING.md`.
- **Is Superseded?**: Will be superseded by native in-VM bootstrapping (Stage 4).
- **Useful Knowledge**: Details second-stage maintainer script execution and DPKG status initialization.
- **Recommended Action**: Retain for reference.

#### 8. `scripts/inspect-rootfs.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Inspects any bootstrapped Debian rootfs directory (analyzes `/etc/os-release`, installed DPKG packages, FHS hierarchy, and PID 1 init binaries).
- **Referenced By**: `docs/stages/stage-04-rootfs.md`, rootfs inspection workflows.
- **Is Superseded?**: No. Works universally on any rootfs path whether generated in a container or in a VM.
- **Useful Knowledge**: Non-destructive FHS and DPKG status parser.
- **Recommended Action**: Maintain as an active rootfs diagnostic utility.

#### 9. `scripts/enter-rootfs.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Educational chroot entry wrapper setting a distinct prompt `[XEDRA-ROOTFS] root@builder:/#`.
- **Referenced By**: `docs/stages/stage-04-rootfs.md`.
- **Is Superseded?**: No. Useful for interactive chroot exploration inside the builder VM.
- **Useful Knowledge**: Demonstrates clean environment isolation when invoking `chroot`.
- **Recommended Action**: Maintain as an active diagnostic tool.

---

### D. Builder Virtual Machine Lifecycle Scripts (`scripts/vm/`)

#### 10. `scripts/vm/check-builder-vm-host.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Validates host system hypervisor readiness, `qemu:///system` connectivity, storage pool capacity, UEFI firmware availability, and optional ISO file accessibility.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`, `docs/runbooks/vm/01-host-vm-stack.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Non-destructive XML parsing of libvirt storage pools and OVMF firmware file location.
- **Recommended Action**: Maintain as the primary Stage 3 pre-creation validation script.

#### 11. `scripts/vm/create-builder-vm.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Instantiates the authoritative `xedra-builder` Debian 13 VM via `virt-install` with 2 vCPUs, 4 GB RAM, 35 GB virtual disk, UEFI firmware, and SPICE graphics.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Fully reproducible, non-destructive `virt-install` recipe targeting standard libvirt system pools.
- **Recommended Action**: Maintain as the official VM creation automation.

#### 12. `scripts/vm/start-builder-vm.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Powers on `xedra-builder` via `virsh` on `qemu:///system`.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Safe state check before invoking `virsh start`.
- **Recommended Action**: Maintain as a standard operational wrapper.

#### 13. `scripts/vm/stop-builder-vm.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Sends a graceful ACPI shutdown signal to `xedra-builder`.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Clean shutdown wrapper avoiding unclean filesystem unmounts.
- **Recommended Action**: Maintain as a standard operational wrapper.

#### 14. `scripts/vm/inspect-builder-vm.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Displays domain summary, virtual disk allocation, virtual network interfaces, and guest IP address.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Non-destructive multi-attribute libvirt inspection.
- **Recommended Action**: Maintain as the primary in-flight VM diagnostic tool.

#### 15. `scripts/vm/destroy-builder-vm.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Safely undefines `xedra-builder` and deletes only its allocated virtual disk volume from the storage pool with strict interactive confirmations.
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Demonstrates safe domain teardown (`--nvram --remove-all-storage`) restricted strictly to the target VM domain.
- **Recommended Action**: Maintain as the safe cleanup tool.

#### 16. `scripts/vm/bootstrap-builder.sh`
- **Classification**: `ACTIVE`
- **Purpose**: Executed **INSIDE** `xedra-builder` after Debian OS installation to install the developer desktop (Fluxbox, Firefox-ESR, xterm, Git) and the distro engineering toolchain (`debootstrap`, `live-build`, `squashfs-tools`, `xorriso`, `grub-efi-amd64-bin`, `mtools`, `dosfstools`).
- **Referenced By**: `docs/stages/stage-03-builder-vm.md`.
- **Is Superseded?**: No.
- **Useful Knowledge**: Complete recipe separating developer productivity tools from target distro components.
- **Recommended Action**: Maintain as the authoritative in-VM bootstrap script.

---

## 4. Summary Matrix

| Script | Classification | Primary Environment | Status |
| :--- | :--- | :--- | :--- |
| `scripts/check-host.sh` | `ACTIVE` | Linux Host | Maintained |
| `archive/container/check-container-runtime.sh` | `HISTORICAL` | Linux Host | Archived in `archive/container/` |
| `archive/container/build-builder-image.sh` | `HISTORICAL` | Linux Host | Archived in `archive/container/` |
| `archive/container/check-builder.sh` | `HISTORICAL` | Container | Archived in `archive/container/` |
| `archive/container/enter-builder.sh` | `HISTORICAL` | Linux Host | Archived in `archive/container/` |
| `archive/container/bootstrap-rootfs.sh` | `HISTORICAL` | Container | Archived in `archive/container/` |
| `archive/container/complete-rootfs.sh` | `HISTORICAL` | Container | Archived in `archive/container/` |
| `scripts/inspect-rootfs.sh` | `ACTIVE` | Builder VM / Host | Maintained |
| `scripts/enter-rootfs.sh` | `ACTIVE` | Builder VM | Maintained |
| `scripts/transition-sysvinit.sh` | `ACTIVE` | Builder VM | Maintained |
| `scripts/configure-desktop.sh` | `ACTIVE` | Builder VM | Maintained |
| `scripts/configure-live-build.sh` | `ACTIVE` | Builder VM | Maintained |
| `scripts/build-iso.sh` | `ACTIVE` | Builder VM | Maintained |
| `scripts/vm/check-builder-vm-host.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/create-builder-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/start-builder-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/stop-builder-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/inspect-builder-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/destroy-builder-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/bootstrap-builder.sh` | `ACTIVE` | Builder VM (`xedra-builder`) | Maintained |
| `scripts/vm/create-lab-vm.sh` | `ACTIVE` | Linux Host | Maintained |
| `scripts/vm/destroy-lab-vm.sh` | `ACTIVE` | Linux Host | Maintained |
