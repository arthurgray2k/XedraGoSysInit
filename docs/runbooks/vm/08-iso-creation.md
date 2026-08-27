# Step 08 — Compile Bootable Xedra 0.1 Live ISO Image

## Objective

Execute the automated ISO build pipeline using Debian `live-build` inside the `xedra-builder` VM to compile the bootable **Xedra 0.1 Live ISO Image** (`output/xedra-0.1-amd64.iso`).

This step executes the full distribution packaging chain:
1. **Rootfs Construction**: Downloads and installs all packages defined in `config/package-lists/xedra.list.chroot` (Kernel, SysVinit, X11, Fluxbox, xterm).
2. **Initramfs Generation**: Builds the live-boot initramfs (`live-boot`) with hardware drivers.
3. **Squashfs Compression**: Uses `mksquashfs` to compress the entire root filesystem into `/live/filesystem.squashfs`.
4. **Bootloader Staging**: Prepares dual UEFI (GRUB) and BIOS (Syslinux/GRUB) bootloader stages.
5. **Hybrid ISO Generation**: Uses `xorriso` to create the hybrid bootable ISO image.
6. **Artifact Packaging**: Outputs `xedra-0.1-amd64.iso` and `xedra-0.1-amd64.iso.sha256` in `~/XedraGoSysInit/output/`.

---

## Preconditions

1. **Step 07 Complete**: `live-build` workspace configured at `~/XedraGoSysInit/build/live-build`.
2. **Build Tools**: `live-build`, `xorriso`, `squashfs-tools`, and `grub-efi-amd64-bin` are present in `xedra-builder`.
3. **Disk Space**: At least 5 GB of free space available in `xedra-builder`.

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

### 2. Execute ISO Compilation
Run the automated ISO build script:
```bash
# BUILDER VM
sudo ./scripts/build-iso.sh
```

*(Note: The build process takes approximately 3 to 7 minutes as packages are retrieved and compressed).*

---

### 3. Verify Output Artifacts
```bash
# BUILDER VM
ls -lh ~/XedraGoSysInit/output/
cat ~/XedraGoSysInit/output/xedra-0.1-amd64.iso.sha256
```

---

## Expected Result

1. `build-iso.sh` finishes with:
   ```text
   ======================================================
     Xedra 0.1 ISO Successfully Built!
   ======================================================
   ```
2. In `~/XedraGoSysInit/output/`:
   - `xedra-0.1-amd64.iso` exists with file size between ~350 MB and ~550 MB.
   - `xedra-0.1-amd64.iso.sha256` contains the verified SHA-256 hash.

---

## Failure Handling

- **If package download fails during build**:
  Ensure the VM has an active internet connection (`ping -c 3 deb.debian.org`).
- **If `lb build` fails due to locked files or interrupted run**:
  Clean the build workspace and retry:
  ```bash
  # BUILDER VM
  cd ~/XedraGoSysInit/build/live-build
  sudo lb clean --purge
  cd ~/XedraGoSysInit
  ./scripts/configure-live-build.sh
  sudo ./scripts/build-iso.sh
  ```

---

## Evidence to Return

Execute the build inside `xedra-builder` and paste the output of:

1. The final summary section from: `sudo ./scripts/build-iso.sh`
2. Output of: `ls -lh ~/XedraGoSysInit/output/`

---

## Completion Criteria

This step is complete when `~/XedraGoSysInit/output/xedra-0.1-amd64.iso` is compiled, verified, and ready for test booting in the `xedra-lab` VM.
