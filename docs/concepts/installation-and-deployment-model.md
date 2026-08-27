# Xedra Linux - Installation & Deployment Model

## 1. Executive Summary

Xedra Linux uses a progressive deployment model:
- **Milestone 0.1 (Current)**: Packaged and distributed as a **Live Hybrid ISO** running ephemerally in RAM.
- **Milestone 0.2+ (Future)**: Support for permanent disk installations on bare-metal and virtual machine storage drives via manual UNIX installation and automated installers (Calamares / CLI installer).

This document explains how the Live RAM overlay operates, how manual disk installation works from the live session, and the roadmap for automated system installers.

---

## 2. Milestone 0.1: Live Hybrid ISO Architecture

In Xedra 0.1, the operating system is delivered as an ephemeral live environment:

```text
+-------------------------------------------------------------------------------+
|                            XEDRA 0.1 LIVE ENVIRONMENT                         |
|                                                                               |
|  [ Virtual/Physical RAM ]                                                     |
|         │                                                                     |
|         ├── OverlayFS Upper Layer: tmpfs (Read-Write RAM Disk)                |
|         │    ├── User modifications, temporary files, downloaded packages     |
|         │    └── Discarded on power-off / reboot                              |
|         │                                                                     |
|         └── OverlayFS Lower Layer: /live/filesystem.squashfs (Read-Only)      |
|              └── Compressed Debian 13 base rootfs, SysVinit, Xorg, Fluxbox    |
+-------------------------------------------------------------------------------+
```

### Why Live ISO First for Milestone 0.1?
1. **Safety**: Does not modify or repartition physical or virtual host hard drives during testing.
2. **Speed & Reproducibility**: Allows rapid testing cycles in `xedra-lab` without disk re-imaging.
3. **Hardware Independence**: Boots uniformly across diverse UEFI motherboards and virtual machines without hardcoded disk UUID dependencies.

---

## 3. Direct Disk Installation (The UNIX / Arch Way)

Because Xedra's root filesystem is a standard FHS-compliant Debian system with SysVinit, it can be installed directly to any local block device (e.g., `/dev/sda` or `/dev/vda`) from within the live session without needing third-party tools.

### Step-by-Step Manual Installation Procedure:

```bash
# 1. Partition the target disk (GPT with EFI System Partition and root partition)
sudo cfdisk /dev/vda
#   /dev/vda1 -> 512 MB (EFI System Partition)
#   /dev/vda2 -> Remaining space (Linux Filesystem)

# 2. Format the partitions
sudo mkfs.vfat -F32 /dev/vda1
sudo mkfs.ext4 /dev/vda2

# 3. Mount the target filesystem
sudo mkdir -p /mnt/target
sudo mount /dev/vda2 /mnt/target
sudo mkdir -p /mnt/target/boot/efi
sudo mount /dev/vda1 /mnt/target/boot/efi

# 4. Copy the live rootfs to the target disk (preserving all attributes and permissions)
sudo rsync -aAXv \
    --exclude=/run/* \
    --exclude=/proc/* \
    --exclude=/sys/* \
    --exclude=/tmp/* \
    --exclude=/mnt/* \
    --exclude=/live \
    / /mnt/target/

# 5. Generate /etc/fstab with real disk UUIDs
ROOT_UUID=$(blkid -s UUID -o value /dev/vda2)
EFI_UUID=$(blkid -s UUID -o value /dev/vda1)

cat << EOF | sudo tee /mnt/target/etc/fstab
# /etc/fstab: Static file system information
UUID=${ROOT_UUID}   /          ext4   errors=remount-ro,noatime   0   1
UUID=${EFI_UUID}    /boot/efi  vfat   umask=0077                  0   1
tmpfs               /tmp       tmpfs  defaults,nosuid,nodev       0   0
EOF

# 6. Bind pseudo-filesystems and chroot to install the bootloader
sudo mount --bind /dev /mnt/target/dev
sudo mount --bind /proc /mnt/target/proc
sudo mount --bind /sys /mnt/target/sys

sudo chroot /mnt/target /bin/bash << 'CHROOT_EOF'
# Install GRUB EFI bootloader to the disk
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Xedra --recheck
update-grub
exit
CHROOT_EOF

# 7. Unmount and reboot into the installed system
sudo umount -R /mnt/target
sudo reboot
```

---

---

## 4. Post-Installation Reboot & Media Ejection Runbook

When installing from a live environment, the running operating system relies on the live media (CD-ROM/USB) as its backing read storage. Ejecting the storage media while the live OS is actively executing binaries causes memory page faults (`SIGBUS` / `Bus error`).

### Standard Post-Installation Lifecycle:

```text
┌───────────────────────────┐      ┌───────────────────────────┐      ┌───────────────────────────┐
│ 1. Complete Installation  │ ──►  │ 2. Eject Live CD/USB Media│ ──►  │ 3. Reset / Boot from Disk │
│ Files cloned & GRUB ready │      │ Disconnect ISO in KVM     │      │ VM boots /dev/vda (Root)  │
└───────────────────────────┘      └───────────────────────────┘      └───────────────────────────┘
```

### Method A: Host CLI Reset (Recommended for Automated VMs)
Once `xedra-installer` displays the success banner:

```bash
# 1. Disconnect the Live ISO from the virtual CD-ROM drive
# (Depending on the hypervisor/bus type, the CD-ROM target may be 'hda', 'sda', or the ISO path directly):

# Option 1 (IDE / ATAPI target - Default for generic/Q35):
virsh --connect qemu:///system change-media xedra-lab hda --eject --config --live

# OR Option 2 (SATA target):
virsh --connect qemu:///system change-media xedra-lab sda --eject --config --live

# OR Option 3 (Direct ISO Path):
virsh --connect qemu:///system change-media xedra-lab /home/mint/XedraGoSysInit/output/xedra-0.4.3-amd64-gosysvinit.iso --eject --config --live

# Tip: To check your exact CD-ROM device target name, run:
# virsh --connect qemu:///system domblklist xedra-lab

# 2. Reset the VM to boot immediately from the installed /dev/vda disk
virsh --connect qemu:///system reset xedra-lab
```

### Method B: Graphical Interface (`virt-manager`)
1. In `virt-manager`, open the VM details (blue lightbulb / `View` -> `Details`).
2. Select **SATA CDROM 1** in the hardware list and click the **Clear / Disconnect (cross icon)** next to the ISO path.
3. Click **Apply** at the bottom right.
4. From the top menu, select **`Virtual Machine` -> `Shut Down` -> `Force Reset`** (or `Reboot`).

---

## 5. Architectural Summary

- **Xedra Linux** is packaged as a **Live Hybrid ISO** for rapid testing, demonstration, system recovery, and persistent installation.
- Its internal root filesystem is **100% standard and fully installable** to persistent block devices via the integrated `/usr/local/bin/xedra-installer`.
- On installed systems, standard SysVinit PID 1 boots directly from `/dev/vda` using persistent UUIDs in `/etc/fstab`.
