# Stage 5 — Xedra Package Selection & SysVinit Transition

## 1. Objective

Transition the base Debian 13 root filesystem (`~/XedraGoSysInit/build/rootfs`) to use **SysVinit (`sysvinit-core`) as PID 1**, purging `systemd-sysv` and installing standard SysVinit boot configurations in accordance with Xedra Architectural Decision #2.

---

## 2. What Was Executed & Verified

Inside `xedra-builder`:
```bash
sudo ./scripts/transition-sysvinit.sh
sudo ./scripts/inspect-rootfs.sh
```

---

## 3. Technical Changes Applied to Rootfs

1. **APT Solver Atomic Replacement**:
   - In Debian 13 (Trixie), `systemd-sysv` is marked as essential. Attempting to install `sysvinit-core` without explicitly removing `systemd-sysv` triggers an APT dependency solver conflict.
   - We resolved this via atomic replacement syntax:
     ```bash
     apt-get install -y sysvinit-core initscripts insserv systemd-sysv- --allow-remove-essential
     ```
   - The trailing `-` on `systemd-sysv-` signals an immediate uninstallation within the same transaction.
2. **PID 1 Binary Switch**:
   - **Before**: `/sbin/init -> ../lib/systemd/systemd` (systemd PID 1).
   - **After**: `/sbin/init` is a 53 KB standalone executable provided directly by `sysvinit-core`.
3. **Inittab & Host Configuration**:
   - `/etc/inittab`: Installed with default runlevel 2, `rc.sysinit`, `/etc/init.d/rc`, and standard gettys on `tty1`–`tty6`.
   - `/etc/hostname`: Set to `xedra`.
   - `/etc/hosts`: Configured with loopback mappings for `localhost` and `xedra`.

---

## 4. Verification Results

```text
--- Init System & PID 1 Assessment ---
  [ STATUS ] 'sysvinit-core' package: Installed
  [ STATUS ] 'systemd-sysv' (PID 1 symlink): Not installed
  [ INFO ] /sbin/init: -rwxr-xr-x 1 root root 53392 (SysVinit binary)
```

---

## 5. Current State

- **Stage 5 Status**: `Complete & Verified`.
- **Next Stage**: Stage 6 — Minimal Graphical Desktop (X11 + Fluxbox + xterm).
