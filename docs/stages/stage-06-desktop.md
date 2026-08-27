# Stage 6 — Minimal Graphical Desktop Configuration (X11 + Fluxbox + xterm)

## 1. Objective

Install and configure the minimal graphical display stack inside `~/XedraGoSysInit/build/rootfs` using X11, the Fluxbox window manager, and the `xterm` terminal emulator, satisfying Xedra Architectural Decisions #3 and #4.

---

## 2. What Was Executed & Verified

Inside `xedra-builder`:
```bash
sudo ./scripts/configure-desktop.sh
sudo ./scripts/inspect-rootfs.sh
```

---

## 3. Installed Components & Configuration

1. **X11 Display Server Stack**:
   - `xserver-xorg-core`, generic video drivers (`xserver-xorg-video-all`), input drivers (`xserver-xorg-input-all`), `xinit`, `xauth`.
2. **Window Manager & Terminal**:
   - `fluxbox`: Minimal, fast window manager. Automatically registered as the system default `x-window-manager` via Debian alternatives.
   - `xterm`: Standard lightweight terminal emulator.
3. **Session & Menu Configuration**:
   - `/etc/skel/.xinitrc` and `/root/.xinitrc`: Automatically starts Fluxbox on `startx`.
   - `/etc/skel/.fluxbox/menu`: Custom lightweight root menu with terminal, process monitor, disk space, and exit options.

---

## 4. Verification Results

```text
--- Verifying Desktop Binaries in Rootfs ---
  [ PASS ] /usr/bin/Xorg exists
  [ PASS ] /usr/bin/xinit exists
  [ PASS ] /usr/bin/fluxbox exists
  [ PASS ] /usr/bin/xterm exists
```

---

## 5. Current State

- **Stage 6 Status**: `Complete & Verified`.
- **Next Stage**: Stage 7 — Debian Live-Build Configuration (`live-build` recipe & kernel installation).
