# Architectural Decision Records (ADR)

This document records the foundational technical decisions for Xedra Linux, explaining the rationale, alternatives considered, and why each choice was made.

---

## 1. Upstream Base: Debian 13 "Trixie" (amd64)

- **Decision**: Build Xedra directly on top of Debian 13 "Trixie" stable repositories without custom package forks.
- **Reason**: Debian provides the largest, most stable collection of pre-compiled packages with transparent packaging standards and robust dependency tracking. Using Debian Stable guarantees reliability and avoids the burden of maintaining thousands of package builds.
- **Alternatives Considered**:
  - *Arch Linux*: Rolling release base; too volatile for a stable educational baseline.
  - *Alpine Linux*: Musl-based; highly minimalist, but incompatible with standard glibc Debian packages and standard SysVinit patterns.
  - *From Scratch (LFS)*: Compiling everything from source; over-engineers the build system and obscures package management concepts.
- **Verdict**: **Debian 13 Trixie** provides the ideal balance of stability, package availability, and transparency.

---

## 2. Init System: SysVinit as PID 1

- **Decision**: Enforce SysVinit (`sysvinit-core`) as PID 1. Strictly exclude `systemd-sysv`.
- **Reason**: Educational clarity. SysVinit operates via clear shell scripts in `/etc/init.d/` and predictable runlevel symlinks in `/etc/rc*.d/`. Every service start and shutdown can be inspected, traced, and understood line-by-line without binary loggers or opaque service managers.
- **Alternatives Considered**:
  - *systemd*: Default Debian init system; powerful but introduces high complexity, tight subsystem coupling, binary journals, and opaque state management.
  - *OpenRC / Runit*: Excellent lightweight init systems, but SysVinit is the classic Unix init standard natively supported in Debian repositories via `sysvinit-core`.
- **Verdict**: **SysVinit** maximizes transparency and learning value.

---

## 3. Display Server: X11 with XLibre-Compatible Design

- **Decision**: Use the X11 display stack for initial graphical output, structured to permit a future migration to XLibre.
- **Reason**: X11 is mature, well-documented, runs on minimal resources without requiring Wayland compositor abstractions, and integrates directly with lightweight window managers like Fluxbox.
- **Alternatives Considered**:
  - *Wayland*: Modern display protocol, but requires a complex compositor (e.g. Sway, Wayfire) with heavier dependency footprints and less transparent low-level debugging.
- **Verdict**: **X11** is simple, modular, and compatible with our minimal UI target.

---

## 4. Window Manager & Terminal: Fluxbox + xterm

- **Decision**: Select Fluxbox as the window manager and `xterm` as the terminal emulator for Xedra.
- **Reason**: Fluxbox requires negligible RAM (~15-30 MB), has no background daemon dependencies, stores all configurations in clean plain text (`~/.fluxbox/menu`, `~/.fluxbox/init`), and provides a complete windowing environment without desktop portals or policy agents.
- **Alternatives Considered**:
  - *Full Desktop Environments (GNOME, KDE, Cinnamon, XFCE)*: Pull hundreds of background services, D-Bus daemons, display managers, and megabytes of dependencies.
  - *i3 / bspwm*: Tiling window managers; excellent, but Fluxbox provides traditional floating windows that are immediately intuitive.
- **Verdict**: **Fluxbox + xterm** delivers the smallest reasonably useful graphical desktop.

---

## 5. Build Environment Architecture: Dedicated Debian 13 VM (`xedra-builder`)

- **Decision**: Use a dedicated Debian 13 (Trixie) virtual machine (`xedra-builder`) running on KVM/libvirt as the authoritative build environment for all Xedra distro engineering.
- **Reason**: Distribution engineering tools (`debootstrap`, `live-build`, `losetup`, `mksquashfs`, `xorriso`, `grub-mkstandalone`) require uncompromised Linux kernel privileges (creating real device nodes, loopback devices, and mounting pseudo-filesystems). A dedicated builder VM provides full kernel capabilities safely without granting dangerous `--privileged` root access to containers on the physical host system.
- **Alternatives Considered**:
  - *Rootless Podman Container*: Evaluated in Stage 2; hit kernel user-namespace limits (`mknod`, nested `mount`).
  - *Privileged Container on Host*: Weakens host security by disabling container isolation mechanisms.
  - *Direct Build on Host*: Pollutes host `/etc/apt/` and package database with cross-distro packages.
- **Verdict**: **Dedicated Debian 13 VM (`xedra-builder`)** is the cleanest, most secure, and most standard approach.

---

## 6. Testing Environment: Disposable QEMU/KVM Virtual Machine (`xedra-lab`)

- **Decision**: Test the generated Xedra ISOs in a dedicated libvirt VM (`xedra-lab`) configured with 2 vCPUs, 2 GB RAM, and UEFI firmware.
- **Reason**: Testing on virtualized hardware accurately replicates the physical PC boot lifecycle (UEFI firmware $\rightarrow$ GRUB $\rightarrow$ Linux kernel $\rightarrow$ initramfs $\rightarrow$ SysVinit $\rightarrow$ X11 $\rightarrow$ Fluxbox) without risking physical host disks.
- **Alternatives Considered**:
  - *Host chroot testing*: Cannot test the bootloader, kernel boot, or hardware device initialization.
- **Verdict**: **QEMU/KVM** via `libvirt` provides real hardware virtualization safely.

---

## 7. Licensing & Attribution

- **Decision**: License Xedra's original build tooling and scripts under **GPL-3.0-or-later**, documentation under **CC BY-SA 4.0**, and preserve upstream licenses for all Debian/Linux components.
- **Reason**: Ensures open-source copyleft protection for Xedra tooling while strictly honoring upstream copyright and licensing.

---

## 8. Distribution Delivery & Installation Model

- **Decision**: Package Xedra 0.1 primarily as an ephemeral **Live Hybrid ISO** (squashfs + RAM overlayfs), with permanent disk installer capabilities scheduled for Milestone 0.2+.
- **Reason**: A Live ISO provides immediate, non-destructive testability across virtual and bare-metal environments without disk partitioning risks. The underlying rootfs remains 100% standard and installable to disk via direct UNIX copy or future automated installers (Calamares / `xedra-installer`).
- **Verdict**: **Live ISO First** for Milestone 0.1; **Automated Installers** in Milestones 0.2+.

---

## 9. Declarative Configuration-Driven Build Manifest (Xedra 0.2+ Roadmap)

- **Decision**: Evolve the build pipeline in Milestone 0.2+ to read declarative build manifests (e.g. `config/xedra-build.yaml` or `json`) supporting build profiles (`dev` fast-cache vs `release` full-purge).
- **Reason**: Decouples build parameters (package sets, mirror URLs, cache policies, user credentials, branding) from procedural shell script logic, making builds fully reproducible and configurable without modifying code.
- **Verdict**: **Procedural Scripts** for Milestone 0.1; **Declarative YAML/JSON Manifests** in Milestone 0.2+.

---

## 10. Daemon Runtime Contract Verification vs. Build-Time Syntax Checks

- **Decision**: Mandate complete **Daemon Runtime Contract Verification** for every added or modified system daemon, treating build-time syntax verification (`bash -n`, JSON schema validation) as insufficient on its own.
- **Reason**: Distribution engineering builds frequently succeed cleanly even when underlying service daemons are misconfigured to reject connections or fail silently upon boot. Reviewing only that the build succeeds is useless if the installed daemons are not configured to listen on network sockets and accept logins. Every daemon must be traced across its full 4-stage runtime contract:
  1. **Configuration Loading**: Exactly which config files the daemon parses on boot (e.g. `/etc/ssh/sshd_config.d/*.conf`, `/etc/inetd.conf`).
  2. **Socket Binding**: Which network ports and IP interfaces are actively opened upon boot (e.g. TCP 22, TCP 23).
  3. **Authentication & PAM Handshake**: How user credentials, PAM policies (`/etc/pam.d/`), and shadow permissions are verified.
  4. **Non-Interactive Chroot Safety**: Explicitly verifying that automated `live-build` batch installation does not silently skip config generation (e.g. `inetd.conf`) or inherit disabled upstream authentication defaults (e.g. `PasswordAuthentication no` in OpenSSH 9.6+).
- **Verdict**: **Mandatory Daemon Runtime Contract Verification** enforced across all reviews and pull requests.
