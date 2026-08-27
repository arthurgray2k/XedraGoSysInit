# Xedra Linux - GRUB Bootloader Architecture & Deployment Model

This document specifies the end-to-end bootloader architecture for Xedra Linux, detailing the packaging, script integration points, parameters, and execution lifecycles for both the **Live Hybrid ISO** and the **Persistent Installed System**.

---

## 1. Dual Boot Topology Overview

Xedra Linux operates across two distinct boot topologies:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        1. LIVE HYBRID ISO BOOT                         │
├────────────────────────────────────────────────────────────────────────┤
│ UEFI / BIOS Firmware                                                  │
│   └── Boot Media (CD-ROM / USB)                                        │
│         └── GRUB EFI / ISOLINUX (boot=live components quiet)           │
│               └── Linux Kernel (6.12.x-amd64) + Live Initramfs         │
│                     └── OverlayFS Rootfs -> SysVinit PID 1 -> Fluxbox  │
└────────────────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────────────────┐
│                     2. INSTALLED SYSTEM DISK BOOT                      │
├────────────────────────────────────────────────────────────────────────┤
│ UEFI Firmware (or Legacy BIOS)                                         │
│   └── Partition 1: 512MB ESP (FAT32) -> /EFI/XedraLinux/grubx64.efi    │
│         └── Partition 2: Root (ext4) -> /boot/grub/grub.cfg            │
│               └── Linux Kernel (6.12.x-amd64) (root=UUID=... ro quiet) │
│                     └── Persistent Native Rootfs -> SysVinit PID 1     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Package Inventory & Technical Justification

To support both Live ISO assembly and native hard disk installation, the following packages are integrated into `config/package-lists/xedra.list.chroot`:

| Package Name | Binary / File Deliverables | Technical Justification |
| :--- | :--- | :--- |
| **`grub2-common`** | `/usr/sbin/grub-install`<br>`/usr/sbin/update-grub`<br>`/usr/sbin/grub-mkconfig`<br>`/etc/grub.d/*` | Core bootloader toolchain. Provides the `grub-install` executable and configuration generators used by `xedra-installer`. |
| **`grub-efi-amd64`** | `/usr/lib/grub/x86_64-efi/*`<br>`grubx64.efi`<br>Pulls `efibootmgr` | 64-bit UEFI target drivers and firmware variable management tools required to install GRUB into the EFI System Partition (ESP). |
| **`grub-pc-bin`** | `/usr/lib/grub/i386-pc/*`<br>`boot.img`<br>`core.img` | Legacy BIOS / MBR stage 1 and stage 2 drivers. Modular package that co-exists cleanly with `grub-efi-amd64` without trigger conflicts. |
| **`dosfstools`** | `/usr/sbin/mkfs.fat`<br>`/usr/sbin/fsck.fat` | Used by `xedra-installer` to format the 512 MB ESP partition (`/dev/vda1`) as FAT32. |
| **`parted`** | `/usr/sbin/parted` | Used by `xedra-installer` to create the standard GPT partition table, 512 MB ESP partition with `esp on` flag, and root `ext4` partition. |
| **`e2fsprogs`** | `/usr/sbin/mkfs.ext4` | Used by `xedra-installer` to format the main root filesystem (`/dev/vda2`). |
| **`util-linux`** | `/usr/bin/lsblk`<br>`/usr/sbin/blkid`<br>`/usr/bin/mount`<br>`/usr/bin/umount` | Storage drive enumeration, UUID extraction for `/etc/fstab`, and chroot mount binding. |

---

## 3. Script Integration Map

### 3.1 Live ISO Assembly (`scripts/configure-live-build.sh`)
* **Function**: `prepare_workspace()`
  * **Parameter**: `lb config --bootloader grub-efi --binary-images iso-hybrid`
  * **Role**: Directs `live-build` to generate a dual-mode hybrid ISO containing both UEFI GRUB (`EFI/BOOT/BOOTX64.EFI`) and BIOS ISOLINUX boot structures.
* **Function**: `configure_xedra_packages()`
  * **Role**: Writes `grub2-common`, `grub-efi-amd64`, and `grub-pc-bin` into `config/package-lists/xedra.list.chroot` so that the live root filesystem contains all bootloader installation tools.

---

### 3.2 Native System Installer (`config/xedra-installer`)

#### A. Partitioning & Formatting Parameters
```bash
# Create standard GPT partition table
parted -s "${TARGET_DISK}" mklabel gpt

# Partition 1: 512 MiB EFI System Partition (FAT32)
parted -s "${TARGET_DISK}" mkpart ESP fat32 1MiB 513MiB
parted -s "${TARGET_DISK}" set 1 esp on

# Partition 2: Root Filesystem (ext4, remaining disk space)
parted -s "${TARGET_DISK}" mkpart primary ext4 513MiB 100%

# Format filesystems
mkfs.fat -F32 -n "XEDRA_EFI" "${EFI_PART}"
mkfs.ext4 -F -L "XEDRA_ROOT" "${ROOT_PART}"
```

#### B. Mount & Target Hierarchy
```bash
# Mount target root
mount "${ROOT_PART}" "${TARGET_MOUNT}"

# Mount target ESP
mkdir -p "${TARGET_MOUNT}/boot/efi"
mount "${EFI_PART}" "${TARGET_MOUNT}/boot/efi"

# Synchronize rootfs via rsync
rsync -aAX --exclude=... / "${TARGET_MOUNT}/"
```

#### C. Chroot Virtual Bind Mounts
```bash
# Expose host hardware and kernel structures to chroot
mount --bind /dev "${TARGET_MOUNT}/dev"
mount --bind /proc "${TARGET_MOUNT}/proc"
mount --bind /sys "${TARGET_MOUNT}/sys"
```

#### D. Bootloader Compilation & Registration
```bash
if [[ -d "/sys/firmware/efi" ]]; then
    # UEFI Installation:
    #   --target=x86_64-efi: Generates 64-bit EFI binary
    #   --efi-directory=/boot/efi: Target ESP mount point
    #   --bootloader-id=XedraLinux: Creates \EFI\XedraLinux\grubx64.efi
    #   --recheck: Probes device map
    chroot "${TARGET_MOUNT}" grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id=XedraLinux \
        --recheck
else
    # Legacy BIOS Installation:
    #   --target=i386-pc: Writes MBR stage 1 to target disk head
    chroot "${TARGET_MOUNT}" grub-install \
        --target=i386-pc \
        "${TARGET_DISK}" \
        --recheck
fi

# Generate /boot/grub/grub.cfg with root UUID and kernel detection
chroot "${TARGET_MOUNT}" update-grub
```

#### E. Storage Identifiers (`/etc/fstab`)
```bash
root_uuid="$(blkid -s UUID -o value "${ROOT_PART}")"
efi_uuid="$(blkid -s UUID -o value "${EFI_PART}")"

cat << FSTAB_EOF > "${TARGET_MOUNT}/etc/fstab"
# /etc/fstab: static file system information for Xedra Linux
UUID=${root_uuid}   /               ext4    errors=remount-ro 0       1
UUID=${efi_uuid}   /boot/efi       vfat    umask=0077      0       2
tmpfs                                       /tmp            tmpfs   defaults,nosuid,nodev 0 0
FSTAB_EOF
```

---

## 4. Execution Lifecycle Tracing (Post-Installation First Boot)

1. **Firmware Stage**:
   - Motherboard / QEMU OVMF UEFI executes `\EFI\XedraLinux\grubx64.efi` from `/dev/vda1`.
2. **GRUB Stage**:
   - GRUB reads `/boot/grub/grub.cfg` from `/dev/vda2`.
   - Displays boot menu and loads `/boot/vmlinuz-6.12.*-amd64` and `/boot/initrd.img-6.12.*-amd64`.
   - Kernel command line: `root=UUID=<UUID-of-vda2> ro quiet`.
3. **Initramfs Stage**:
   - Initramfs drivers mount `/dev/vda2` as `/sysroot`.
   - Because `boot=live` is absent, live media hooks are bypassed completely.
   - Performs `switch_root` and hands control to `/sbin/init`.
4. **SysVinit PID 1 Stage**:
   - SysVinit executes `/etc/init.d/rcS` $\rightarrow$ mounts `/boot/efi` (`/dev/vda1`) and `tmpfs`.
   - Executes `/etc/init.d/rc 2` $\rightarrow$ starts D-Bus, elogind, and networking.
   - Auto-logs in user `xedra` on `tty1` and launches Fluxbox desktop session.

---

## 5. Verification Checklist

* [x] `grub2-common`, `grub-efi-amd64`, `grub-pc` present in `config/package-lists/xedra.list.chroot`.
* [x] `dosfstools`, `parted`, `e2fsprogs`, `rsync`, `util-linux` present in `config/package-lists/xedra.list.chroot`.
* [x] `/etc/fstab` uses persistent dynamic UUIDs from `blkid`.
* [x] `chroot` pseudo-filesystems (`/dev`, `/proc`, `/sys`) bound before `grub-install`.
* [x] Unmounts executed in clean reverse hierarchical order in `cleanup()`.
