# Step 04 — Bootstrap Pure Debian 13 Root Filesystem Inside Builder VM

## Objective

Bootstrap a clean, minimal Debian 13 "Trixie" (`amd64`) base root filesystem into `~/XedraGoSysInit/build/rootfs` using native `debootstrap` inside the `xedra-builder` VM.

This step allows us to observe how Debian creates the root filesystem from scratch:
- Downloading upstream binary `.deb` archives from `deb.debian.org`.
- Extracting the standard Filesystem Hierarchy Standard (FHS) directory structure (`/bin`, `/etc`, `/lib`, `/usr`, `/var`).
- Running package maintainer scripts (`*.postinst`) in dependency order.
- Initializing the central DPKG database at `/var/lib/dpkg/status`.

---

## Preconditions

1. **Step 03 Complete**: The `xedra-builder` VM is running, has the `~/XedraGoSysInit` repository cloned, and the distro engineering toolchain (`debootstrap`, `live-build`, `xorriso`, `fluxbox`) has been installed via `bootstrap-builder.sh`.
2. **Network Access**: The VM can reach `https://deb.debian.org/debian`.

---

## Environment

Commands in this runbook are executed exclusively inside the:

```text
BUILDER VM
```

*(Connect to `xedra-builder` via SSH: `ssh <username>@192.168.122.180` or via `virt-manager` console)*

---

## Commands

Execute the following commands sequentially inside the `xedra-builder` VM:

### 1. Ensure Clean Build Directory
```bash
# BUILDER VM
cd ~/XedraGoSysInit
mkdir -p build
```

### 2. Run Native debootstrap
Run `debootstrap` to fetch and configure the Debian 13 base system:
```bash
# BUILDER VM
sudo debootstrap --arch=amd64 trixie ~/XedraGoSysInit/build/rootfs https://deb.debian.org/debian
```

*(Note: Because this runs natively inside the Debian 13 VM with full Linux kernel capabilities, `debootstrap` completes in a single, fast pass without user namespace workarounds).*

---

### 3. Run Non-Destructive Rootfs Inspection Script
```bash
# BUILDER VM
sudo ./scripts/inspect-rootfs.sh
```

---

### 4. Educational chroot Inspection (Optional)
Step into the bootstrapped root filesystem to inspect its contents from the inside:
```bash
# BUILDER VM
sudo ./scripts/enter-rootfs.sh
```

Inside the chroot prompt `[XEDRA-ROOTFS] root@builder:/#`:
```bash
# CHROOT
cat /etc/os-release
dpkg -l | head -n 20
dpkg-query -W -f='${binary:Package} (${Version})\n' | head -n 15
exit
```

---

## Expected Result

1. `debootstrap` outputs retrieval, validation, extraction, and configuration steps, finishing with:
   ```text
   I: Base system installed successfully.
   ```
2. `./scripts/inspect-rootfs.sh` reports:
   - **Total Rootfs Size**: ~300–450 MB
   - **OS Release**: Debian GNU/Linux 13 (trixie)
   - **FHS Directories**: All essential directories (`/bin`, `/etc`, `/lib`, `/usr`, `/var`) present
   - **DPKG Package Count**: ~90–110 essential packages installed in `/var/lib/dpkg/status`

---

## Failure Handling

- **If package download fails (DNS / network issue)**:
  Verify internet connectivity inside the VM:
  ```bash
  # BUILDER VM
  ping -c 3 deb.debian.org
  curl -I https://deb.debian.org/debian/
  ```
- **If target directory is not empty**:
  To perform a clean rebuild, remove the old build directory first:
  ```bash
  # BUILDER VM
  sudo rm -rf ~/XedraGoSysInit/build/rootfs
  ```

---

## Evidence to Return

Execute the commands inside `xedra-builder` and paste the output of:

1. The final lines of: `sudo debootstrap --arch=amd64 trixie ~/XedraGoSysInit/build/rootfs https://deb.debian.org/debian`
2. Output of: `sudo ./scripts/inspect-rootfs.sh`

---

## Completion Criteria

This step is complete when a pure Debian 13 base root filesystem is successfully bootstrapped in `~/XedraGoSysInit/build/rootfs` and verified via `inspect-rootfs.sh`.
