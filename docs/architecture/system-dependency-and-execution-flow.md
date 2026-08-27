# Xedra Linux - System Dependency Hierarchy & Execution Flowcharts

This document provides visual architectural diagrams, dependency hierarchies, and end-to-end execution flowcharts for Xedra Linux 0.4.3.

---

## 1. Subsystem & Package Dependency Hierarchy

```mermaid
graph TD
    subgraph Base_Hardware ["1. Hardware & Kernel Subsystem"]
        K1["linux-image-amd64 (Kernel 6.12)"]
        K2["udev & kmod (Hardware Probing)"]
        K3["live-boot & live-config (Live Environment)"]
    end

    subgraph Init_Subsystem ["2. Init & Session Subsystem (SysVinit)"]
        I1["sysvinit-core (PID 1 /sbin/init)"]
        I2["initscripts & insserv (Runlevels 0-6 & S)"]
        I3["elogind & libpam-elogind (Seat & Session Management)"]
        I4["systemd-sysv- (Explicitly Excluded)"]
    end

    subgraph Services_Subsystem ["3. Networking & Remote Services (Configurable)"]
        S1["openssh-server (Port 22 SSH Daemon - Default: ON)"]
        S2["telnetd & openbsd-inetd (Port 23 Telnet - Default: OFF)"]
        S3["Networking (iproute2, dhcpcd-base, net-tools, ping)"]
    end

    subgraph Userland_Tools ["4. Languages, Toolchains & Editors"]
        T1["Python 3 (python3, pip, venv)"]
        T2["Golang (golang-go compiler)"]
        T3["Editors (micro, nano, vim-tiny)"]
    end

    subgraph Disk_Installer ["5. Native System Installer Subsystem"]
        D1["dialog (CLI / TUI Dialogs)"]
        D2["parted (GPT Partitioning)"]
        D3["dosfstools (FAT32 mkfs.fat)"]
        D4["e2fsprogs (ext4 mkfs.ext4)"]
        D5["rsync (Filesystem Synchronization)"]
        D6["grub-efi-amd64 (UEFI Bootloader with --removable fallback)"]
        D7["grub-pc-bin (BIOS MBR Modules)"]
        D8["grub2-common (grub-install & update-grub)"]
    end

    subgraph GUI_Desktop ["6. Display & Desktop Subsystem (GUI Only)"]
        G1["xserver-xorg-core & xserver-xorg-legacy"]
        G2["xserver-xorg-video-qxl & video-all"]
        G3["xserver-xorg-input-libinput"]
        G4["fluxbox (Window Manager)"]
        G5["xterm (Terminal Emulator)"]
        G6["spice-vdagent (KVM Integration)"]
        G7["xinit & x11-xserver-utils (xrandr, xsetroot)"]
    end

    Base_Hardware --> Init_Subsystem
    Init_Subsystem --> Services_Subsystem
    Init_Subsystem --> Userland_Tools
    Init_Subsystem --> Disk_Installer
    Init_Subsystem --> GUI_Desktop
```

---

## 2. Live ISO Compilation Pipeline (`scripts/build-iso.sh`)

```mermaid
flowchart TD
    Start(["Start: sudo ./scripts/build-iso.sh"]) --> ParseConfig["Parse config/xedra-build.json (Profile: dev / release / minimal)"]
    ParseConfig --> WorkspaceClean{"Clean Strategy?"}

    WorkspaceClean -->|dev profile| StageClean["lb clean --stage --binary (Preserve .deb & bootstrap cache)"]
    WorkspaceClean -->|release profile| PurgeClean["lb clean --purge (Fresh pristine download)"]

    StageClean --> LBConfig["lb config (Set gzip/xz compression, grub-efi, cache flags)"]
    PurgeClean --> LBConfig

    LBConfig --> GenPackages["Generate package-lists/xedra.list.chroot (Kernel, Python, Go, Micro, SSH/Telnet, Installer, Fluxbox)"]
    GenPackages --> GenHooks["Install 0100-sysvinit-transition.hook.chroot (SSH keygen, users: live:live & root:root)"]
    GenHooks --> GenOverlays["Deploy Overlays: inittab, xinitrc, menu, xedra-installer, Xwrapper"]

    GenOverlays --> LBBuild["Execute 'lb build'"]

    subgraph LiveBuild_Stages ["Internal live-build Engine"]
        LBBuild --> Bootstrap["1. lb bootstrap: Restore cache/stages_bootstrap (Base Debian 13)"]
        Bootstrap --> ChrootInstall["2. lb chroot: Install cached .deb archives via dpkg"]
        ChrootInstall --> ChrootHook["3. lb hooks: Execute SysVinit transition, enable SSH/services"]
        ChrootHook --> ChrootIncludes["4. lb includes: Copy filesystem configuration overlays"]
        ChrootIncludes --> SquashFS["5. lb binary_rootfs: mksquashfs (gzip -1 compression ~15s)"]
        SquashFS --> BinaryISO["6. lb binary_iso: xorriso & GRUB EFI hybrid mastering"]
    end

    BinaryISO --> PackageArtifacts["Move to output/xedra-0.4.3-amd64-gosysvinit.iso & generate .sha256"]
    PackageArtifacts --> Done(["ISO Ready for Testing in xedra-lab VM"])
```

---

## 3. Native Disk Installer Execution Pipeline (`xedra-installer`)

```mermaid
flowchart TD
    RunInstaller(["Launch: sudo /usr/local/bin/xedra-installer"]) --> CheckRoot{"Is Root?"}
    CheckRoot -->|No| ExitRoot["Error: Root required -> Exit 1"]
    CheckRoot -->|Yes| ScanDrives["Scan Storage Drives: lsblk (Exclude loop, zram, live medium)"]

    ScanDrives --> FoundDrives{"Target Drives Found?"}
    FoundDrives -->|0 Disks| DialogNoDisk["dialog --msgbox 'No suitable hard disk found' -> Exit 1"]
    FoundDrives -->|>= 1 Disks| DialogSelect["dialog --menu: Select Target Drive (e.g. /dev/vda)"]

    DialogSelect --> GetUser["dialog: Input Primary Username (validated)"]
    GetUser --> GetUserPass["dialog --passwordbox: User Password & Confirmation"]
    GetUserPass --> GetRootPass["dialog --passwordbox: Root Password & Confirmation"]
    GetRootPass --> GetHost["dialog: Input System Hostname (default: xedra-box)"]

    GetHost --> ConfirmDialog["dialog --yesno: Confirm Permanent Disk Overwrite"]
    ConfirmDialog -->|Cancel| Abort["Installation Cancelled -> Exit 0"]
    ConfirmDialog -->|Confirm| PartitionDisk["Parted GPT: 512MB ESP (/dev/vda1) + ext4 Root (/dev/vda2)"]

    PartitionDisk --> FormatFS["Format: mkfs.fat -F32 (vda1) & mkfs.ext4 -F (vda2)"]
    FormatFS --> MountTarget["Mount: /dev/vda2 on /mnt/xedra-target & /dev/vda1 on .../boot/efi"]

    MountTarget --> RsyncFiles["rsync -aAX (Synchronize Live Rootfs -> /mnt/xedra-target)"]
    RsyncFiles --> GenFstab["Generate /etc/fstab with persistent blkid UUIDs"]

    GenFstab --> ProvisionUser["Chroot Provisioning: useradd, set passwords, set hostname/hosts"]
    ProvisionUser --> PurgeLive["Purge Live User: userdel -r -f live & rm /home/live"]
    PurgeLive --> CleanMenu["Clean Desktop Menus: remove installer & collapse separators"]

    CleanMenu --> BindChroot["Bind Mount: /dev, /proc, /sys into /mnt/xedra-target"]
    BindChroot --> CheckFirmware{"Firmware Mode?"}

    CheckFirmware -->|UEFI Mode| GrubUEFI["chroot: grub-install --removable + copy to BOOTX64.EFI"]
    CheckFirmware -->|BIOS Mode| GrubBIOS["chroot: grub-install --target=i386-pc /dev/vda"]

    GrubUEFI --> UpdateGrub["chroot: update-grub (Detect kernel & generate grub.cfg)"]
    GrubBIOS --> UpdateGrub

    UpdateGrub --> CleanUnmount["Unmount: /dev, /proc, /sys, /boot/efi, /mnt/xedra-target"]
    CleanUnmount --> SuccessMsg(["dialog: Installation Successful -> Eject ISO & virsh reset"])
```

---

## 4. Installed System Boot Lifecycle (First Boot from Hard Drive)

```mermaid
sequenceDiagram
    autonumber
    actor Hardware as UEFI Firmware (OVMF)
    participant ESP as ESP Partition (/dev/vda1)
    participant GRUB as GRUB2 Bootloader
    participant Kernel as Linux Kernel 6.12
    participant Init as SysVinit (PID 1 /sbin/init)
    participant Services as rcS & rc 2 Runlevels (SSH, D-Bus, elogind)
    participant Session as TTY1 / Fluxbox Desktop

    Hardware->>ESP: Locate \\EFI\\BOOT\\BOOTX64.EFI
    ESP->>GRUB: Load GRUB2 Stage 2 & read /boot/grub/grub.cfg
    GRUB->>Kernel: Load vmlinuz-6.12 & initrd (root=UUID=... ro quiet)
    Kernel->>Kernel: Mount /sysroot (/dev/vda2) & switch_root
    Kernel->>Init: Execute /sbin/init as PID 1
    Init->>Services: Execute /etc/init.d/rcS (mount /boot/efi, tmpfs, udev)
    Init->>Services: Execute /etc/init.d/rc 2 (ssh daemon on :22, dbus, elogind)
    Init->>Session: /sbin/getty auto-login user on tty1
    Session->>Session: ~/.profile runs 'startx -- vt1 -keeptty'
    Session->>Session: Launch Fluxbox Window Manager & SPICE Agent (1600x900)
```
