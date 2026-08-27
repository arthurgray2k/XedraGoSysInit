# Xedra Linux - Chronological Learning Log

This document tracks technical insights, practical lessons, encountered challenges, and solutions discovered during each stage of building Xedra Linux.

---

## Stage 1 - Host Environment & Virtualization Validation

- **Status**: `Verified`
- **Focus**: Validating the physical Linux host machine for hypervisor readiness without modifying the host OS.

### What Was Learned:
1. **Host Immutability**: The physical machine is strictly the development workstation. Debian is never installed directly on host metal to protect the working environment.
2. **KVM Virtualization Pipeline**:
   - Hardware CPU extensions (`VMX` for Intel, `SVM` for AMD) allow near-native virtualization speeds via hardware acceleration.
   - The Linux kernel module `kvm_intel` exposes the character device node `/dev/kvm`.
   - QEMU (`qemu-system-x86_64`) acts as the userland machine emulator and connects to `/dev/kvm` via ioctl calls.
   - `libvirt` provides a unified daemon API (`libvirtd`) and management CLI (`virsh`) used by `virt-manager`.
3. **Safety Automation**: Using `set -euo pipefail` in inspection scripts ensures that command failures and unset variables halt execution immediately before any side effects occur.

---

## Stage 2 - Isolated Build Environment Experiment (Podman)

- **Status**: `Completed Learning Exercise`
- **Focus**: Evaluating a rootless Debian 13 (Trixie) userland container using Podman to prevent host contamination.

### What Was Learned & Challenges Encountered:
1. **Container Userspace vs. Kernel**:
   - A container shares the host kernel.
   - The container provides an isolated Debian *userspace* via Linux namespaces (mount, PID, network, user).
2. **The `mknod` & Mount Limitation in Rootless Containers**:
   - Standard `debootstrap` executes `check_sane_mount()`, which calls `mknod "$TARGET/test-dev-null" c 1 3`.
   - Inside an unprivileged Linux User Namespace (`CLONE_NEWUSER`), the kernel strictly blocks `mknod` for device nodes and nested loop mounts.
   - The fallback `mount -o bind /dev/null "$TARGET/test-dev-null"` failed with `permission denied`.
   - `debootstrap` emitted a misleading generic error message: `E: Cannot install into target mounted with noexec`.
3. **Why `--privileged` Was Rejected**:
   - Running containers with `--privileged` indiscriminately disables container security namespaces on the host.
   - The educational conclusion: Debian distro building requires real Linux kernel capabilities (`losetup`, `mksquashfs`, loop devices, real `mknod`), which belong in a dedicated virtual machine rather than a compromised host container.

---

## Stage 3 - Debian Builder VM Setup (`xedra-builder`)

- **Status**: `Verified & Complete`
- **Focus**: Setting up a dedicated Debian 13 (Trixie) VM as the authoritative build environment on libvirt/KVM.

### What Was Learned:
1. **Builder VM vs. Target Distro**:
   - The builder VM is developer infrastructure. It can comfortably have a desktop (`fluxbox`), web browser (`firefox-esr`), and full build tools without polluting the target Xedra distribution.
   - Xedra's target package list remains completely minimal and independent of the builder VM.
2. **UEFI Virtual Machine Automation**:
   - Using `virt-install` with `--boot uefi`, `--osinfo debian12`, `--graphics spice`, and `--disk pool=default,size=35,format=qcow2,bus=virtio` creates a fully reproducible, hardware-accelerated Debian development VM.
3. **Git as the Sole Source of Truth**:
   - Both the host system and the `xedra-builder` VM synchronize via `~/XedraGoSysInit` through Git (`https://github.com/arthurgray2k/XedraLinux`).

---

## Stage 4 - First Debian Root Filesystem

- **Status**: `Verified & Complete`
- **Focus**: Natively bootstrapping the pure Debian 13 base rootfs inside the dedicated builder VM.

### What Was Learned:
1. **Hermetic Rootfs Generation**:
   - Bootstrapping directly from pristine upstream repositories ensures zero leakage of local build-machine state, credentials, or caches.
2. **Merged-/usr Layout**:
   - In modern Debian 13 (Trixie), `/bin`, `/sbin`, and `/lib` are symbolic links pointing into `/usr/bin`, `/usr/sbin`, and `/usr/lib`.
3. **Upstream Init Baseline**:
   - Default debootstrap installs 146 base packages with `systemd-sysv` providing `/sbin/init`.

---

## Stage 5 - Xedra Package Selection & SysVinit Transition

- **Status**: `Verified & Complete`
- **Focus**: Replacing `systemd-sysv` with SysVinit (`sysvinit-core`) as PID 1 inside the target rootfs.

### What Was Learned:
1. **APT Atomic Package Replacement (`systemd-sysv-`)**:
   - Appending a minus sign (`pkg-`) instructs APT to remove the conflicting package in the exact same transaction as installing its replacement.
2. **PID 1 Transition**:
   - `/sbin/init` was transitioned from a symlink to systemd into a direct SysVinit executable binary (~53 KB).
3. **Inittab Runlevels**:
   - SysVinit uses `/etc/inittab` to orchestrate system runlevels (default runlevel 2 for multi-user mode, `rcS` for boot scripts, and gettys on `tty1`–`tty6`).

---

## Stage 6 - Minimal Graphical Desktop (X11 + Fluxbox + xterm)

- **Status**: `Verified & Complete`
- **Focus**: Installing and configuring the minimal X11 display server, Fluxbox window manager, and xterm terminal.

### What Was Learned:
1. **X11 Graphics Stack Footprint**:
   - While Fluxbox is only ~3 MB, the hardware graphics acceleration stack (Mesa, DRI drivers, and Xorg core) accounts for ~300 MB uncompressed, which compresses down to ~80 MB with `mksquashfs`.
2. **Update-Alternatives Integration**:
   - Debian automatically registered `startfluxbox` as the system's default `x-window-manager`.
3. **Skeleton Configuration**:
   - Placing `.xinitrc` and `.fluxbox/menu` in `/etc/skel/` ensures every new user inherits the minimal Xedra desktop environment.

---

## Stage 7 - Debian Live-Build Configuration

- **Status**: `Verified & Complete`
- **Focus**: Configuring `live-build` with Xedra's package list, APT exclusion, and chroot hooks.

### What Was Learned:
1. **Live-Build Chroot Hooks**:
   - Rather than relying on fragile solver priority pinning that can break virtual package candidates, `live-build` chroot hooks (`config/hooks/normal/*.hook.chroot`) provide a clean mechanism to execute atomic transitions inside the rootfs during build time.

---

## Stage 8 - ISO Creation & Packaging

- **Status**: `Verified & Complete`
- **Focus**: Compiling the standalone `xedra-0.1-amd64.iso` image.

### What Was Learned:
1. **Temporary Staging in Live-Build**:
   - `live-build` temporarily installs bootloader packages (`grub-efi-amd64-signed`, `shim-signed`, `mtools`) to assemble the UEFI partition, then purges them before `mksquashfs` compression to prevent ISO bloat.
2. **Hybrid ISO Generation**:
   - `xorriso` packages the kernel, squashfs, and EFI System Partition into a single hybrid ISO (948 MB) bootable across both legacy BIOS and modern UEFI platforms.

---

## Stage 9 - Service Daemon Engineering & Runtime Contract Verification (Milestone 0.4.2)

- **Status**: `Verified & Complete`
- **Focus**: Adding remote access daemons (OpenSSH on port 22, Telnet/inetd on port 23) and establishing rigorous daemon verification standards.

### What Was Learned & Pitfalls Encountered:
1. **Build-Time Verification vs. Daemon Runtime Contracts**:
   - Syntactical correctness (`bash -n`) and successful package installation during `lb build` do not guarantee that installed daemons accept connections upon boot.
   - Reviewing only that the build succeeds is useless if installed services fail to listen or authenticate.
2. **OpenSSH 9.6+ Upstream Policy Shift**:
   - In Debian 13 "Trixie", OpenSSH defaults `PasswordAuthentication` to disabled (`no`), requiring an explicit `/etc/ssh/sshd_config.d/01-xedra.conf` drop-in override (`PasswordAuthentication yes`) for password-based logins to function.
3. **Super-Server (`openbsd-inetd`) Socket Mechanics in Non-Interactive Chroots**:
   - `telnetd` is not an independent daemon; it relies on `openbsd-inetd` parsing `/etc/inetd.conf`.
   - In automated non-interactive `debootstrap`/`live-build` environments, `telnetd` does not automatically populate `/etc/inetd.conf`. The socket definition (`23 stream tcp nowait root /usr/sbin/telnetd telnetd`) must be explicitly written during build configuration, or `inetd` will start with an empty config and refuse connections on TCP Port 23.
4. **Debian 13 Package Migration (`inetutils-telnetd`)**:
   - In Debian 13 "Trixie", the daemon executable was transitioned from the legacy Netkit path `/usr/sbin/in.telnetd` to GNU Inetutils `/usr/sbin/telnetd`. Pointing `inetd.conf` to non-existent `/usr/sbin/in.telnetd` caused immediate socket closure upon connection.
5. **Mandatory 4-Point Daemon Audit**:
   - Every added daemon must be traced for: (1) config file resolution, (2) TCP/UDP socket binding, (3) PAM authentication handshake, and (4) non-interactive batch installation safety.

---

## Stage 10 - Modern Developer CLI Suite & Productivity Engineering (Milestone 0.4.3)

- **Status**: `Verified & Complete`
- **Focus**: Expanding Xedra into a modern developer terminal powerhouse with `bat`, `fd-find`, `fzf`, `ripgrep`, `eza`, `zoxide`, `btop`, `jq`, `fastfetch`, and `where`.

### What Was Learned & Architectural Solutions:
1. **Debian Upstream Binary Renaming (`batcat` & `fdfind`)**:
   - Debian renames `bat` $\rightarrow$ `batcat` and `fd` $\rightarrow$ `fdfind` to avoid namespace collisions with legacy packages (`bacula-console-qt` and `fd` floppy formatter).
   - Solution: Injected local administrator symlinks `/usr/local/bin/bat` and `/usr/local/bin/fd`. Because `/usr/local/bin` precedes `/usr/bin` in `$PATH`, users can type `bat` and `fd` naturally without modifying package manager metadata or risking `dpkg` file collisions.
2. **Cross-Platform `where` Discovery Helper**:
   - Standard Linux lacks a standalone `where` binary. Injected `/usr/local/bin/where` wrapping `which -a "$@"`, allowing developers familiar with Windows/PowerShell/zsh to discover executable locations seamlessly.
3. **Zero Daemon Overhead**:
   - Audited the entire 10-package suite against Debian 13 "Trixie" dependencies (`main` repo). Zero packages require systemd or background sockets; total static memory footprint is 0 MB until executed.
