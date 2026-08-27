# Step 03 — Bootstrap Builder VM Toolchain & Desktop Environment

## Objective

Log into the newly installed `xedra-builder` Debian 13 VM, clone the Xedra repository (`~/XedraGoSysInit`), and execute the automated bootstrap script (`scripts/vm/bootstrap-builder.sh`).

This installs:
1. **Developer Desktop UI**: `fluxbox`, `xorg`, `xterm`, `firefox-esr`, `git` (for developer productivity inside the VM).
2. **Distro Engineering Toolchain**: `debootstrap`, `live-build`, `squashfs-tools`, `xorriso`, `grub-pc-bin`, `grub-efi-amd64-bin`, `mtools`, `dosfstools`, `rsync`.

---

## Preconditions

1. **Step 02 Complete**: `xedra-builder` is running Debian 13 "Trixie" on `qemu:///system`.
2. **VM Network Connectivity**: The VM is running with an active IP address.
3. **User Access**: You have credentials for the user account and/or `root` created during the Debian installation.

---

## How to Find Your Builder VM IP Address

### Method 1: From the Host Terminal
Run either of these commands on your host system:
```bash
# HOST
virsh --connect qemu:///system domifaddr xedra-builder
```
Or run the host inspection script:
```bash
# HOST
cd ~/XedraGoSysInit
./scripts/vm/inspect-builder-vm.sh
```

### Method 2: From Inside the VM (via virt-manager console)
Log into the VM console and run:
```bash
# BUILDER VM (Preferred)
hostname -I
```
or:
```bash
# BUILDER VM
ip a
```

---

## Environment

Commands below are executed inside the:

```text
BUILDER VM
```

*(You can access the VM either through the `virt-manager` console or via SSH from the host).*

---

## Commands

### 1. Log into the Builder VM

**Option A: Using virt-manager console (Graphical)**
- In `virt-manager`, double-click `xedra-builder` and log in at the terminal login prompt.

**Option B: Using SSH from Host Terminal**
Replace `<username>` and `<vm-ip>` (obtained above) with your credentials:
```bash
# HOST
ssh <username>@<vm-ip>
```

---

### 2. Ensure sudo & git are Installed (Inside VM)
If logged in as a standard user without `sudo` access, switch to `root` once to enable sudo:
```bash
# BUILDER VM
su -
apt-get update && apt-get install -y git sudo
usermod -aG sudo <your-username>
exit
```

---

### 3. Clone the Xedra Repository (Inside VM)
Log in as your regular VM user and clone the repository:
```bash
# BUILDER VM
cd ~
git clone https://github.com/arthurgray2k/XedraLinux.git ~/XedraGoSysInit
```
*(Or via SSH if you configured GitHub SSH keys: `git clone git@github.com:arthurgray2k/XedraLinux.git ~/XedraGoSysInit`)*

---

### 4. Execute the Toolchain & Desktop Bootstrap
```bash
# BUILDER VM
cd ~/XedraGoSysInit
sudo ./scripts/vm/bootstrap-builder.sh
```

---

### 5. Verify Build Tools Availability
```bash
# BUILDER VM
debootstrap --version
lb --version
xorriso --version
fluxbox -version
which mksquashfs grub-mkstandalone
```

---

### 6. Test the Graphical Desktop (Inside virt-manager console)
Inside the `virt-manager` graphical console of `xedra-builder`:
```bash
# BUILDER VM
startx
```
*Fluxbox will launch with a minimal, responsive desktop interface. Right-click the background to open the applications menu and launch `xterm` or `Firefox`.*

---

## Expected Result

1. `bootstrap-builder.sh` updates Debian package lists and installs packages without errors.
2. The verification section reports `[ PASS ]` for:
   - `debootstrap`
   - `lb` (`live-build`)
   - `mksquashfs`
   - `xorriso`
   - `grub-mkstandalone`
   - `mkfs.vfat`
   - `git`
   - `fluxbox`
   - `xterm`
3. `startx` successfully starts Fluxbox in the `virt-manager` SPICE display.

---

## Failure Handling

- **If `git clone` fails due to network**:
  Test internet reachability inside the VM:
  ```bash
  # BUILDER VM
  ping -c 3 deb.debian.org
  ```
- **If `sudo` is not found**:
  Run `su -` and install it: `apt-get update && apt-get install -y sudo`.
- **If `startx` reports no screens found**:
  Ensure `xorg` package is installed (`sudo apt-get install -y xorg`).

---

## Evidence to Return

Execute the bootstrap inside `xedra-builder` and paste the output of:

1. The final summary from: `sudo ./scripts/vm/bootstrap-builder.sh`
2. Output of: `debootstrap --version && lb --version && xorriso --version`

---

## Completion Criteria

This step is complete when `xedra-builder` has its own cloned working tree at `~/XedraGoSysInit`, all distro build tools (`debootstrap`, `live-build`, `squashfs-tools`, `xorriso`, `grub-efi-amd64-bin`) are verified, and the Fluxbox desktop runs.
