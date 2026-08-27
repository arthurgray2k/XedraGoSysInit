# Concept: The Debian Root Filesystem

The **root filesystem** (often abbreviated as `rootfs`) is the top-level directory hierarchy (mounted at `/`) from which an operating system locates all files, directories, programs, configuration files, and device interfaces.

---

## 1. The Filesystem Hierarchy Standard (FHS) in Debian

Debian strictly adheres to the Filesystem Hierarchy Standard (FHS):

| Directory | Purpose | Key Contents in Debian Rootfs |
| :--- | :--- | :--- |
| `/bin` | Essential command binaries | Symlink to `/usr/bin` (UsrMerge) |
| `/boot` | Static bootloader files & kernel images | `vmlinuz-*`, `initrd.img-*`, `grub/` |
| `/dev` | Device nodes (created dynamically by kernel/devtmpfs) | `/dev/null`, `/dev/tty`, `/dev/sda` |
| `/etc` | Host-specific system configuration | `/etc/passwd`, `/etc/os-release`, `/etc/init.d/` |
| `/home` | User personal directories | `/home/user/` |
| `/lib` | Essential shared libraries and kernel modules | Symlink to `/usr/lib` (UsrMerge) |
| `/proc` | Virtual filesystem exposing kernel & process status | `/proc/cpuinfo`, `/proc/meminfo`, `/proc/1/` |
| `/root` | Home directory for the root superuser | Administrative dotfiles (`.bashrc`) |
| `/run` | Ephemeral runtime state since boot | PID files, socket descriptors |
| `/sbin` | Essential system administration binaries | Symlink to `/usr/sbin` (UsrMerge) |
| `/sys` | Virtual filesystem exposing device drivers & hardware | `/sys/class/net/`, `/sys/block/` |
| `/tmp` | Temporary files | Cleared automatically on reboot |
| `/usr` | Secondary hierarchy containing all user programs | `/usr/bin`, `/usr/lib`, `/usr/share` |
| `/var` | Variable data files (logs, caches, package DB) | `/var/log/`, `/var/lib/dpkg/`, `/var/cache/apt/` |

---

## 2. Modern Debian "UsrMerge"

In modern Debian releases (including Debian 13 Trixie), `/bin`, `/sbin`, `/lib`, and `/lib64` are not distinct directories. They are symbolic links pointing directly into `/usr`:

```text
/bin   -> usr/bin
/sbin  -> usr/sbin
/lib    -> usr/lib
/lib64 -> usr/lib64
```

This guarantees that all executable binaries and libraries live under a unified `/usr` tree, preventing split-binary issues across partitions.

---

## 3. The Package Registry: `/var/lib/dpkg/`

A Debian root filesystem is distinguished from an arbitrary collection of files by the presence of its **DPKG database**:
- `/var/lib/dpkg/status`: Plain-text file recording every package installed, its version, architecture, and dependency declarations.
- `/var/lib/dpkg/info/<package>.list`: Text file recording every file and directory on disk that belongs to that package.

When you run `dpkg -S /path/to/file`, DPKG scans these `.list` files to identify package ownership.
