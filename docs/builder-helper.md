# Xedra Linux - Builder Quick Reference & Helper Guide

A consolidated cheat sheet for building, testing, configuring, and troubleshooting Xedra Linux across the 3 core environments.

---

## 1. Fast Iteration Loop (3-Step Cheat Sheet)

```text
 [ xedra-builder VM ]              [ Linux Host ]                     [ xedra-lab VM ]
  (Compiles ISO)                (Transfers Artifact)                  (Boots & Tests)
        │                                │                                   │
  sudo ./build-iso.sh  ──────►  scp builder@192.168.122.180:... ──►  ./create-lab-vm.sh
```

### Step 1: Build the ISO (Inside `xedra-builder` VM)
```bash
# Connect to builder VM
ssh builder@192.168.122.180

# Build Xedra 0.4.3 ISO with dev cache (~2–3 minutes)
cd ~/XedraLinux-GoSysVinit
git pull
sudo ./scripts/build-iso.sh --profile=dev

# Or build the minimal CLI-only edition:
# sudo ./scripts/build-iso.sh --profile=minimal
```

### Step 2: Transfer the ISO (On Linux Host Terminal)
```bash
cd ~/XedraLinux-GoSysVinit
git pull
scp builder@192.168.122.180:~/XedraLinux-GoSysVinit/output/xedra-0.4.3-amd64-gosysvinit.iso* output/

# (Or for minimal edition):
# scp builder@192.168.122.180:~/XedraLinux-GoSysVinit/output/xedra-0.4.3-minimal-amd64-gosysvinit.iso* output/
```

### Step 3: Launch Test VM (On Linux Host Terminal)
```bash
./scripts/vm/create-lab-vm.sh ~/XedraLinux-GoSysVinit/output/xedra-0.4.3-amd64-gosysvinit.iso
virt-manager &
```

---

## 2. Environments & Credentials Reference

| Environment | Hostname / IP | Default User | Default Password | Role |
| :--- | :--- | :--- | :--- | :--- |
| **Development Host** | Physical Host | `mint` / your user | your sudo password | Manages Git, QEMU/KVM hypervisor, and libvirt VMs |
| **Builder VM** | `xedra-builder`<br>`192.168.122.180` | `builder`<br>`root` | `builder`<br>`root` | Compiles Debian rootfs, packages, and UEFI ISOs |
| **Live Test Target** | `xedra-lab`<br>*(Ephemeral)* | `live`<br>`root` | `live`<br>`root` *(passwordless sudo)* | Boots and runs the live Xedra ISO in RAM (SSH: `ssh live@<IP>`) |

---

## 3. Build Profiles Reference (`config/xedra-build.json`)

| Command | Profile | Target Output ISO | Desktop Mode | Compression |
| :--- | :--- | :--- | :--- | :--- |
| `sudo ./scripts/build-iso.sh` | `dev` | `xedra-0.4.3-amd64-gosysvinit.iso` | **Fluxbox GUI (1600x900)** | Gzip Level 1 (Fast) |
| `sudo ./scripts/build-iso.sh --profile=dev` | `dev` | `xedra-0.4.3-amd64-gosysvinit.iso` | **Fluxbox GUI (1600x900)** | Gzip Level 1 (Fast) |
| `sudo ./scripts/build-iso.sh --profile=release` | `release` | `xedra-0.4.3-amd64-gosysvinit.iso` | **Fluxbox GUI (1600x900)** | XZ (Max Compression) |
| `sudo ./scripts/build-iso.sh --profile=minimal` | `minimal` | `xedra-0.4.3-minimal-amd64-gosysvinit.iso` | **CLI Console Only** | Gzip Level 1 (Fast) |

---

## 4. Configuration & Customization Map

| Customization Area | File Path | Purpose |
| :--- | :--- | :--- |
| **Build Manifest & Profiles** | [`config/xedra-build.json`](file:///home/mint/XedraGoSysInit/config/xedra-build.json) | Central versioning, profile definitions, mirrors, and user settings |
| **SysVinit / Runlevels** | [`config/inittab`](file:///home/mint/XedraGoSysInit/config/inittab) | PID 1 init configuration, runlevel 2, autologin on `tty1` |
| **Desktop Startup & Resolution** | [`config/xinitrc`](file:///home/mint/XedraGoSysInit/config/xinitrc) | Display resolution (1366x768 / 1280x800), wallpaper, SPICE, Fluxbox |
| **Fluxbox Application Menu** | [`config/fluxbox/menu`](file:///home/mint/XedraGoSysInit/config/fluxbox/menu) | Right-click desktop menu items, shortcuts, and commands |
| **ISO Assembly Script** | [`scripts/build-iso.sh`](file:///home/mint/XedraGoSysInit/scripts/build-iso.sh) | Orchestrates workspace generation, `lb build`, and ISO output |
| **Chroot Transition Hook** | [`scripts/configure-live-build.sh`](file:///home/mint/XedraGoSysInit/scripts/configure-live-build.sh) | In-chroot SysVinit + `elogind` atomic transition and user creation |

---

## 5. VM Lifecycle Operations (Run on Linux Host)

### Builder VM (`xedra-builder`)
```bash
# Check status and IP address
./scripts/vm/inspect-builder-vm.sh

# Start builder VM
./scripts/vm/start-builder-vm.sh

# Graceful shutdown
./scripts/vm/stop-builder-vm.sh
```

### Lab Test VM (`xedra-lab`)
```bash
# Create and launch fresh test VM
./scripts/vm/create-lab-vm.sh ~/XedraGoSysInit/output/xedra-0.4.3-amd64-gosysvinit.iso

# Destroy test VM
./scripts/vm/destroy-lab-vm.sh
```

---

---

## 6. Package & Stage Caching Architecture

To achieve rapid 2–3 minute build iterations, `live-build` uses a multi-tier local caching subsystem located at `~/XedraGoSysInit/build/live-build/cache/`:

```text
~/XedraGoSysInit/build/live-build/cache/
├── packages.bootstrap/    ──► Base Debian .deb archives (downloaded by debootstrap)
├── packages.chroot/       ──► Distro packages (Python, Go, Micro, Kernel, Fluxbox, X11)
├── packages.binary/       ──► Bootloader packages (GRUB, syslinux)
└── stages_bootstrap/      ──► Base rootfs filesystem snapshot (skips debootstrap)
```

### Cold vs. Warm Build Behavior:
* **Cold Build (First Run / Cache Miss)**:
  - Downloads ~450 `.deb` packages from `deb.debian.org`.
  - Runs `debootstrap` and generates the pristine `stages_bootstrap` image.
  - Runtime: **~12–15 minutes** (dependent on internet mirror bandwidth).
* **Warm Build (Subsequent Iterations)**:
  - `debootstrap` is skipped entirely; `stages_bootstrap` is restored locally in **~3 seconds**.
  - All `.deb` packages are installed from `cache/packages.chroot/` with `force-unsafe-io` in **~45 seconds**.
  - SquashFS image is compressed with `gzip -1` in **~15 seconds**.
  - Total Runtime: **~2–3 minutes**.

### Managing & Inspecting Cache (Inside `xedra-builder` VM):
```bash
# Check total disk space consumed by caches
du -sh ~/XedraGoSysInit/build/live-build/cache/*

# Count total cached .deb packages
ls -1 ~/XedraGoSysInit/build/live-build/cache/packages.chroot/*.deb | wc -l

# Force a clean purge and fresh download (Release Mode)
sudo ./scripts/build-iso.sh --profile=release
```

---

## 7. Documentation & Architecture Index

- **SysVinit Deep Dive**: [`docs/concepts/sysvinit-architecture-and-boot-lifecycle.md`](file:///home/mint/XedraGoSysInit/docs/concepts/sysvinit-architecture-and-boot-lifecycle.md)
- **Deployment & Installation Model**: [`docs/concepts/installation-and-deployment-model.md`](file:///home/mint/XedraGoSysInit/docs/concepts/installation-and-deployment-model.md)
- **APT vs DPKG & apt-get Guide**: [`docs/concepts/apt-vs-dpkg.md`](file:///home/mint/XedraGoSysInit/docs/concepts/apt-vs-dpkg.md)
- **Architecture Decisions (ADRs 1–9)**: [`docs/decisions/xedra-architecture.md`](file:///home/mint/XedraGoSysInit/docs/decisions/xedra-architecture.md)
- **Step-by-Step Runbooks**: [`docs/runbooks/vm/`](file:///home/mint/XedraGoSysInit/docs/runbooks/vm/)
