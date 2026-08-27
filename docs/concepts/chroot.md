# Concept: chroot (Change Root)

`chroot` is a core Unix system call (`chroot(2)`) and command-line utility that modifies the apparent root directory (`/`) for the current running process and all of its child processes.

---

## 1. How `chroot` Works

When a program opens a file path like `/etc/passwd` or `/bin/sh`, the Linux kernel resolves the path starting at the process's root directory.

By calling `chroot /workspace/build/rootfs`:
- The kernel reassigns the process's root pointer to `/workspace/build/rootfs`.
- Any subsequent reference to `/etc/passwd` actually opens `/workspace/build/rootfs/etc/passwd`.
- The process cannot see or access files outside of that directory tree through standard pathname resolution.

```text
Before chroot:
/ (Host Root) ───────────> /bin, /etc, /usr, /home/mint/XedraGoSysInit/build/rootfs

After chroot (/workspace/build/rootfs):
/ (Chroot Root) ─────────> /bin, /etc, /usr (inside build/rootfs)
[Host files outside build/rootfs are invisible]
```

---

## 2. What `chroot` DOES vs. What It Does NOT Do

| What `chroot` DOES | What `chroot` Does NOT Do |
| :--- | :--- |
| ✅ Changes the path lookup root (`/`) | ❌ Does NOT boot a Linux kernel |
| ✅ Uses the binaries inside the rootfs | ❌ Does NOT start an init system or PID 1 |
| ✅ Uses the shared libraries (`/lib`) of the rootfs | ❌ Does NOT virtualize hardware or CPU instructions |
| ✅ Allows testing package management inside the rootfs | ❌ Does NOT create an isolated network stack by default |
| ✅ Allows running maintainer scripts in isolation | ❌ Does NOT protect against root-level privilege escapes |

---

## 3. Why `chroot` Is Crucial for Distro Engineering

During distro construction, `chroot` allows the build script to "step inside" the target root filesystem and run commands as if that rootfs were the live machine:

1. **Package Installation**: Running `apt install <pkg>` inside the chroot ensures that all configuration scripts (`postinst`) run directly against the target system files.
2. **User Creation**: Running `useradd` inside the chroot updates `/etc/passwd` and `/etc/shadow` in the target rootfs.
3. **Initramfs Generation**: Running `update-initramfs -u` generates a ramdisk tailored to the target system's installed kernel and modules.
4. **Bootloader Setup**: Generating GRUB configuration files (`grub-mkconfig`) requires querying the target `/boot` directory.

---

## 4. Pseudo-Filesystems: `/proc`, `/sys`, and `/dev`

Many userland utilities (such as `ps`, `free`, `apt`, or `update-initramfs`) query special kernel interfaces:
- `/proc`: Process table and memory statistics.
- `/sys`: Hardware devices, disk block layers, and network interfaces.
- `/dev`: Device nodes (`/dev/null`, `/dev/random`, `/dev/urandom`).

When entering a chroot for advanced configuration, these pseudo-filesystems must be **bind-mounted** from the host/container into the target rootfs:

```bash
mount -t proc proc /workspace/build/rootfs/proc
mount -t sysfs sysfs /workspace/build/rootfs/sys
mount --bind /dev /workspace/build/rootfs/dev
mount -t devpts devpts /workspace/build/rootfs/dev/pts
```

**Crucial Safety Rule**: All bind mounts must be cleanly unmounted before deleting or packaging the rootfs:
```bash
umount /workspace/build/rootfs/dev/pts
umount /workspace/build/rootfs/dev
umount /workspace/build/rootfs/sys
umount /workspace/build/rootfs/proc
```
Our `scripts/enter-rootfs.sh` script automates this cleanup using bash `trap` handlers.
