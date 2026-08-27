# Step 09 — Test Boot Xedra 0.1 Live ISO in xedra-lab Virtual Machine

## Objective

Transfer the compiled **`xedra-0.1-amd64.iso`** from the `xedra-builder` VM to the host system and launch the ephemeral **`xedra-lab`** test virtual machine to verify:
1. **UEFI Boot**: GRUB 2.12 EFI boot menu appearance and kernel hand-off.
2. **Live Filesystem**: Squashfs mounting and overlayfs root initialization.
3. **Init System**: SysVinit executing `/etc/inittab`, `/etc/init.d/rcS`, and runlevel 2 as PID 1.
4. **Desktop Environment**: Automatic user login into X11 and the Fluxbox window manager with `xterm`.

---

## Preconditions

1. **Step 08 Complete**: `xedra-0.1-amd64.iso` has been compiled and verified inside `xedra-builder`.
2. **Host Virtualization**: `qemu-system-x86_64`, `libvirtd`, and `virt-manager` are active on the host (verified in Step 01).

---

## Environment

Commands in this runbook are executed on the:

```text
PHYSICAL HOST SYSTEM
```

*(Open your host terminal where `~/XedraGoSysInit` is located)*

---

## Commands

Execute the following commands on your host system:

### 1. Copy ISO from Builder VM to Host
Transfer the finished ISO image from `xedra-builder` (`192.168.122.180`) to the host repository:
```bash
# HOST SYSTEM
cd ~/XedraGoSysInit
mkdir -p output
scp builder@192.168.122.180:~/XedraGoSysInit/output/xedra-0.1-amd64.iso* ~/XedraGoSysInit/output/
```

Verify that the ISO arrived on the host:
```bash
# HOST SYSTEM
ls -lh ~/XedraGoSysInit/output/
```

---

### 2. Launch the 'xedra-lab' Test VM
Run the automated test VM creation script:
```bash
# HOST SYSTEM
./scripts/vm/create-lab-vm.sh ~/XedraGoSysInit/output/xedra-0.1-amd64.iso
```

---

### 3. Open the Graphical VM Console
Open `virt-manager` to watch the boot process in real-time:
```bash
# HOST SYSTEM
virt-manager &
```
*(In the Virtual Machine Manager window, double-click **`xedra-lab`** to open the display console)*

---

### 4. What to Observe During Boot

1. **UEFI Firmware**: TianoCore logo appears.
2. **GRUB Bootloader**: GRUB boot menu displaying `Live system (amd64)`. Press **Enter**.
3. **Kernel Initialization**: Linux 6.12 kernel initializes hardware devices and mounts `filesystem.squashfs`.
4. **SysVinit Execution**: SysVinit (PID 1) executes boot scripts (`rcS`) and enters Runlevel 2.
5. **Desktop Session**: The system automatically logs in and starts the **Fluxbox desktop** with an open terminal (`xterm`)!

---

### 5. Live Environment Verification Commands
Inside the open terminal (`xterm`) on the `xedra-lab` desktop:
```bash
# XEDRA-LAB TERMINAL
uname -a
cat /etc/os-release
ps -ef | head -n 10
df -h
```

Notice:
- `PID 1` is `/sbin/init` (SysVinit).
- RAM usage is minimal (~60–90 MB total!).
- Right-clicking the desktop opens the custom Xedra system menu.

---

### 6. Clean Up Test VM
When you have finished testing, shut down the VM or run:
```bash
# HOST SYSTEM
./scripts/vm/destroy-lab-vm.sh
```

---

## Evidence to Return

Paste the output from inside the `xedra-lab` desktop terminal:
1. `ps -ef | head -n 10`
2. `cat /etc/os-release`

---

## Completion Criteria

This step is complete when the Xedra 0.1 ISO boots successfully in `xedra-lab`, SysVinit is confirmed running as PID 1, and the Fluxbox desktop is fully interactive.
