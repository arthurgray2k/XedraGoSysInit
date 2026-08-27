# Step 06 — Configure Minimal Graphical Desktop (X11 + Fluxbox + xterm)

## Objective

Install and configure the minimal graphical desktop environment inside `~/XedraGoSysInit/build/rootfs` to satisfy Xedra Architectural Decisions #3 and #4:
1. **Display Server**: X11 (`xserver-xorg-core`, `xserver-xorg-video-all`, `xinit`).
2. **Window Manager**: `fluxbox` (ultra-lightweight window manager).
3. **Terminal**: `xterm`.
4. **Session Startup**: Default `/etc/skel/.xinitrc` launching Fluxbox upon `startx`.
5. **Desktop Menu**: Custom Xedra root menu in `/etc/skel/.fluxbox/menu`.

---

## Preconditions

1. **Step 05 Complete**: The root filesystem at `~/XedraGoSysInit/build/rootfs` has been transitioned to SysVinit.
2. **Network Access**: `xedra-builder` can reach `https://deb.debian.org/debian`.

---

## Environment

Commands in this runbook are executed exclusively inside the:

```text
BUILDER VM
```

*(Connect to `xedra-builder` via SSH: `ssh builder@192.168.122.180` or via `virt-manager` console)*

---

## Commands

Execute the following commands sequentially inside the `xedra-builder` VM:

### 1. Update Repository Working Tree
```bash
# BUILDER VM
cd ~/XedraGoSysInit
git pull
```

### 2. Execute Desktop Configuration Script
Run the automated script to install X11, Fluxbox, and xterm into the rootfs:
```bash
# BUILDER VM
sudo ./scripts/configure-desktop.sh
```

---

### 3. Run the Rootfs Inspection Tool
```bash
# BUILDER VM
sudo ./scripts/inspect-rootfs.sh
```

---

### 4. Interactive chroot Verification (Optional)
Step into the rootfs to inspect the installed desktop binaries and configurations:
```bash
# BUILDER VM
sudo ./scripts/enter-rootfs.sh
```

Inside the chroot session `[XEDRA-ROOTFS] root@builder:/#`:
```bash
# CHROOT
which Xorg fluxbox xterm
cat /etc/skel/.xinitrc
cat /etc/skel/.fluxbox/menu
dpkg -l | grep -E '(xserver|fluxbox|xterm)'
exit
```

---

## Expected Result

1. `configure-desktop.sh` reports:
   - Installs minimal X11 packages, Fluxbox, and xterm.
   - Copies `/etc/skel/.xinitrc` and `/etc/skel/.fluxbox/menu`.
   - Verifies binaries: `/usr/bin/Xorg`, `/usr/bin/fluxbox`, `/usr/bin/xterm`.
   - Reports: `X11 + Fluxbox Desktop Successfully Configured!`.
2. Total package count in `inspect-rootfs.sh` increases to ~200–230 packages.

---

## Evidence to Return

Execute the script inside `xedra-builder` and paste the output of:

1. The final summary from: `sudo ./scripts/configure-desktop.sh`
2. Section 3 ("DPKG Package Database Inspection") from: `sudo ./scripts/inspect-rootfs.sh`

---

## Completion Criteria

This step is complete when `~/XedraGoSysInit/build/rootfs` has `xserver-xorg-core`, `fluxbox`, `xterm`, and `.xinitrc` installed and verified.
