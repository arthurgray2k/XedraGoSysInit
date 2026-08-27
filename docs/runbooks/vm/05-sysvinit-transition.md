# Step 05 — Transition Root Filesystem to SysVinit (PID 1)

## Objective

Configure the bootstrapped Debian 13 root filesystem (`~/XedraGoSysInit/build/rootfs`) to use **SysVinit (`sysvinit-core`) as PID 1** in accordance with Xedra Architectural Decision #2.

This step performs the following core transformations inside the target rootfs:
1. Configures standard Debian Trixie APT repository mirrors in `/etc/apt/sources.list`.
2. Installs `sysvinit-core`, `initscripts`, and `insserv`.
3. Purges `systemd-sysv` (the package that provides systemd as `/sbin/init`).
4. Installs the Xedra `/etc/inittab` configuration (defining runlevel 2, `rc.sysinit`, and virtual ttys `tty1`–`tty6`).
5. Configures system hostname (`/etc/hostname`) to `xedra` and sets up `/etc/hosts`.

---

## Preconditions

1. **Step 04 Complete**: A pristine Debian 13 base root filesystem exists at `~/XedraGoSysInit/build/rootfs` inside the `xedra-builder` VM.
2. **Network Connectivity**: `xedra-builder` can reach `https://deb.debian.org/debian`.

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

### 2. Execute the SysVinit Transition Script
Run the automated transition script:
```bash
# BUILDER VM
sudo ./scripts/transition-sysvinit.sh
```

---

### 3. Run the Rootfs Inspection Tool
Verify the updated init system status and package database:
```bash
# BUILDER VM
sudo ./scripts/inspect-rootfs.sh
```

---

### 4. Interactive chroot Inspection (Optional)
Step into the rootfs to inspect the newly installed SysVinit files from within:
```bash
# BUILDER VM
sudo ./scripts/enter-rootfs.sh
```

Inside the chroot session `[XEDRA-ROOTFS] root@builder:/#`:
```bash
# CHROOT
ls -l /sbin/init
head -n 25 /etc/inittab
dpkg -l | grep -E '(sysvinit|systemd)'
cat /etc/hostname
exit
```

---

## Expected Result

1. `transition-sysvinit.sh` reports:
   - Mounts `/proc`, `/sys`, `/dev`, `/dev/pts` successfully.
   - Installs `sysvinit-core`, `initscripts`, `insserv`.
   - Purges `systemd-sysv`.
   - Copies `/etc/inittab` and sets hostname to `xedra`.
   - Reports: `SysVinit Transition Successfully Completed!`.
2. In `inspect-rootfs.sh`:
   - **`sysvinit-core` package**: `Installed`
   - **`systemd-sysv` package**: `Not installed`
   - **`/sbin/init`**: points to `/lib/sysvinit/init` (or provided directly by `sysvinit-core`)

---

## Failure Handling

- **If package download fails inside chroot**:
  Verify DNS resolution and repository connectivity inside the VM:
  ```bash
  # BUILDER VM
  curl -I https://deb.debian.org/debian/
  ```
- **If mount errors occur**:
  Manually clean up any lingering mounts before retrying:
  ```bash
  # BUILDER VM
  sudo umount ~/XedraGoSysInit/build/rootfs/dev/pts 2>/dev/null || true
  sudo umount ~/XedraGoSysInit/build/rootfs/dev 2>/dev/null || true
  sudo umount ~/XedraGoSysInit/build/rootfs/sys 2>/dev/null || true
  sudo umount ~/XedraGoSysInit/build/rootfs/proc 2>/dev/null || true
  ```

---

## Evidence to Return

Execute the transition inside `xedra-builder` and paste the output of:

1. The final summary from: `sudo ./scripts/transition-sysvinit.sh`
2. Section 4 ("Init System & PID 1 Assessment") from: `sudo ./scripts/inspect-rootfs.sh`

---

## Completion Criteria

This step is complete when `~/XedraGoSysInit/build/rootfs` has `sysvinit-core` installed, `systemd-sysv` purged, `/sbin/init` configured for SysVinit, and `/etc/inittab` installed.
