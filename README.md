# Xedra Linux (with goSysVinit)

**XedraGoSysInit** is a variation of [**XedraLinux**](https://github.com/arthurgray2k/XedraLinux) that uses [**`goSysVinit`**](https://github.com/arthurgray2k/goSysVinit)—a drop-in replacement init system written in Go—instead of traditional C SysVinit. It runs `goSysVinit` as its true PID 1 init daemon and complete userspace supervision suite.

## Core Environments

```text
Linux Host (Physical Workstation)
     │
     ├── libvirt / QEMU/KVM
     │     │
     ├── xedra-builder (Debian 13 Trixie Builder VM)
     │     │      ├── Development Desktop: Fluxbox, Firefox-ESR, xterm, Git
     │     │      ├── Toolchain: debootstrap, live-build, xorriso, squashfs-tools
     │     │      └── Local Repository: ~/XedraGoSysInit
     │     │
     │     └── xedra-lab (Disposable Test VM)
     │            └── Boots & verifies Xedra with goSysVinit ISO
     │
     └── Source Repository: ~/XedraGoSysInit
```

- **Development Host**: Linux Host (`x86_64`) — Physical workstation; manages Git and hypervisor.
- **Authoritative Builder VM (`xedra-builder`)**: Debian 13 Trixie (`amd64`, UEFI, 4 GB RAM, 35 GB Disk) — Houses the complete build toolchain.
- **Target Xedra 0.4.3 (with goSysVinit)**: Modern lightweight distribution (Debian 13 base, `goSysVinit` PID 1, OpenSSH/Telnet services, Python 3, Golang, Micro editor, modern CLI suite, interactive user installer, Fluxbox GUI or Minimal CLI).
- **Test VM (`xedra-lab`)**: Disposable libvirt VM (2 vCPU, 2 GB RAM, UEFI) — Boots and tests the output ISO.

---

## Core Design (Xedra 0.4.3 Milestone)

- **Base**: Debian 13 ("Trixie", `amd64`)
- **Init System**: `goSysVinit` (PID 1 pure Go implementation of SysVinit 3.15; `systemd-sysv` explicitly excluded, elogind seat manager)
- **Live Session**: `live` user with password `live`, passwordless sudo, and OpenSSH server enabled by default
- **Toolchains & Languages**: Python 3 (`python3`, `pip`, `venv`) and Golang (`golang-go`)
- **Editors**: `micro` modern terminal editor (+ `nano`, `vim-tiny`)
- **Modern CLI Suite**: `bat`, `fd`, `fzf`, `ripgrep`, `eza`, `zoxide`, `btop`, `jq`, `fastfetch`, `where`
- **System Installer**: Native interactive TUI/CLI installer (`/usr/local/bin/xedra-installer`) with GPT/UEFI/BIOS support, custom user account setup, root password configuration, and automatic live-user purging
- **Profiles**:
  - **`dev`**: Ultra-fast build with persistent bootstrap & package caching + fast gzip compression (`xedra-0.4.3-amd64-gosysvinit.iso`)
  - **`release`**: Pristine production build with high XZ compression (`xedra-0.4.3-amd64-gosysvinit.iso`)
  - **`minimal`**: Lightweight CLI-only rescue/server edition with pure text console (`xedra-0.4.3-minimal-amd64-gosysvinit.iso`)
- **Display Server & GUI**: X11 (`xserver-xorg-legacy`, console rights) + Fluxbox + `xterm` + SPICE guest agent (1600x900)
- **Bootloader & Firmware**: Hybrid GRUB with UEFI (`--removable` fallback) + BIOS support

---

## Repository Structure

```text
~/XedraLinux/
├── LICENSE          # GPL-3.0-or-later
├── README.md        # Distro architecture and documentation
├── config/          # live-build configs, package lists, overlay roots
├── docs/            # Architecture, concepts, decisions, and stage logs
├── output/          # Build artifacts and target ISO images
└── scripts/         # Modular automation scripts
    ├── check-host.sh
    └── vm/          # Builder VM lifecycle & bootstrap scripts
```

---

## Guides & Documentation

* 👉 **[Validating goSysVinit in Live System](docs/validate-init.md)** (Live boot proof, dmesg output, and verification commands)
* 👉 **[Usage & Command Reference](USAGE.md)** (Init system workflows, runlevel management, ISO compilation)
* 👉 **[Builder Helper Guide](docs/builder-helper.md)** (All-in-one cheat sheet with commands, VM IPs, credentials, and build profiles)

---

## Quick Start

### 1. Validate Host Virtualization
```bash
./scripts/check-host.sh
```

### 2. Validate Builder VM Host Prerequisites
```bash
./scripts/vm/check-builder-vm-host.sh /path/to/debian-13-netinst.iso
```

### 3. Create the 'xedra-builder' VM
```bash
./scripts/vm/create-builder-vm.sh /path/to/debian-13-netinst.iso
```

### 4. Bootstrap Build Toolchain (Inside 'xedra-builder' VM)
```bash
sudo ~/XedraLinux/scripts/vm/bootstrap-builder.sh
```

---

## License

- Xedra scripts, build tooling, and code: [GPL-3.0-or-later](LICENSE)
- Documentation: [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)
- Upstream packages retain their respective upstream licenses.
