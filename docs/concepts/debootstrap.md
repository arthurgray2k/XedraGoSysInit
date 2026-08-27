# Concept: debootstrap

`debootstrap` is the official tool used by Debian and its derivatives to install a minimal Debian base system into an arbitrary directory.

---

## 1. Why `debootstrap` Exists

Normally, installing software on Debian requires `apt` or `dpkg`. However, to run `dpkg`, you must already have a functioning Linux userland with `glibc`, `/etc/passwd`, and an initialized `/var/lib/dpkg/status` database.

This presents a classic "chicken-and-egg" problem:
> **How do you install Debian onto an empty directory without already having a package manager inside that directory?**

`debootstrap` solves this problem. It is a standalone shell script that uses basic Unix tools (`ar`, `tar`, `sed`, `awk`, `wget`) to bootstrap the first packages into an empty directory from scratch.

---

## 2. How `debootstrap` Works Internally

When you execute:
```bash
debootstrap --arch=amd64 trixie /target/path https://deb.debian.org/debian
```

`debootstrap` runs through the following distinct stages:

### Stage 1: Download
1. Downloads the repository metadata: `InRelease` and `Packages.xz` for Debian 13 (Trixie).
2. Parses the package index and resolves dependencies for all packages marked `Priority: required` and `Priority: important`.
3. Downloads the `.deb` archive files for these base packages into `/target/path/var/cache/apt/archives/`.

### Stage 2: Extraction
1. Creates the base filesystem hierarchy in the target directory.
2. Extracts each `.deb` file. Because a `.deb` package is an `ar` archive containing `data.tar.xz`, `debootstrap` extracts the files directly onto the target disk without running any package manager.
3. Bootstraps a minimal working `dpkg` and `libc-bin`.

### Stage 3: Configuration (In-Chroot)
1. Initializes `/var/lib/dpkg/status` in the target directory.
2. Changes root (`chroot`) into the new directory.
3. Executes the maintainer scripts (`*.postinst`) of each extracted package in dependency order.
4. Generates essential system files (e.g. `/etc/passwd`, `/etc/group`, `/etc/nsswitch.conf`, `/etc/shells`).
5. Runs `ldconfig` to build the shared library cache.

---

## 3. What `debootstrap` Creates vs. What It Does NOT Create

| What `debootstrap` Creates | What `debootstrap` Does NOT Create |
| :--- | :--- |
| ✅ Full FHS directory tree | ❌ Linux kernel (`/boot/vmlinuz-*` is not installed by default) |
| ✅ Standard C library (`glibc`) | ❌ Initramfs image (`/boot/initrd.img-*`) |
| ✅ Core utilities (`bash`, `coreutils`, `tar`, `sed`) | ❌ Bootloader configuration (GRUB / UEFI) |
| ✅ Functional `apt` and `dpkg` package managers | ❌ User accounts (only default `root` entry exists) |
| ✅ `/var/lib/dpkg/status` package registry | ❌ Graphical environment (no X11, Wayland, or desktop) |
| ✅ Base network utilities & configuration files | ❌ ISO image or bootable filesystem partition |

---

## 4. How `debootstrap` Differs from the Debian Installer (d-i)

- **Debian Installer (d-i / Calamares)**: An interactive graphical/text installer that partitions physical drives, formats filesystems, asks user questions (timezone, keyboard, user accounts), and then runs `debootstrap` internally as its backend.
- **`debootstrap` Directly**: The raw, non-interactive engine. It produces a pristine directory tree that distribution builders can customize and turn into an ISO or container image.
