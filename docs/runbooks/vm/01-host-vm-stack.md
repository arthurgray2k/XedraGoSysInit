# Step 01 — Host Virtualization Stack & Pre-Creation Verification

## Objective

Verify that the host system's hardware virtualization (KVM), hypervisor daemons (libvirt/QEMU), management tools (`virsh`, `virt-install`, `virt-manager`), storage pools, virtual networks, UEFI/OVMF firmware, and Debian 13 Netinst ISO are fully operational before creating the authoritative `xedra-builder` virtual machine.

This step performs **read-only verification**. It does not create VMs, format disks, partition drives, or modify the host system.

---

## Preconditions

1. You are logged into the physical Linux host system as a regular user with `sudo` privileges.
2. The user is a member of the `libvirt` and `kvm` groups.
3. The Xedra repository is available at `~/XedraGoSysInit`.
4. A Debian 13 "Trixie" `amd64` Netinst ISO has been downloaded to the host system.

---

## Environment

All commands in this runbook are executed exclusively on the:

```text
HOST
```

---

## Commands

Execute the following commands sequentially in a terminal on the host system:

### 1. Verify Hardware Virtualization Support
```bash
# HOST
grep -E --color=auto '(vmx|svm)' /proc/cpuinfo | head -n 1
```

### 2. Verify KVM Character Device Node
```bash
# HOST
ls -la /dev/kvm
```

### 3. Verify Hypervisor Tools Availability
```bash
# HOST
which qemu-system-x86_64 virsh virt-install virt-manager
```

### 4. Test libvirt System Connection
```bash
# HOST
virsh --connect qemu:///system uri
```

### 5. Inspect libvirt Storage Pools & Free Space
```bash
# HOST
virsh --connect qemu:///system pool-list --all
```
```bash
# HOST
virsh --connect qemu:///system pool-info default
```

### 6. Inspect Host Block Devices (Read-Only)
```bash
# HOST
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

### 7. Inspect libvirt Default Virtual Network
```bash
# HOST
virsh --connect qemu:///system net-list --all
```

### 8. Inspect Host UEFI (OVMF) Firmware Files
```bash
# HOST
ls -la /usr/share/OVMF/ /usr/share/ovmf/ 2>/dev/null || true
```

### 9. Locate & Verify Debian 13 Netinst ISO File
Replace `/path/to/debian-13-netinst.iso` with the actual path to your downloaded Debian 13 ISO:
```bash
# HOST
ls -lh /path/to/debian-13-netinst.iso
```

### 10. Run Automated Host Pre-Creation Check Script
```bash
# HOST
cd ~/XedraGoSysInit
./scripts/vm/check-builder-vm-host.sh /path/to/debian-13-netinst.iso
```

---

## Expected Result

1. **Hardware Virtualization**: `grep` highlights `vmx` (Intel) or `svm` (AMD).
2. **KVM Device**: `/dev/kvm` exists with `rw` permissions for group `kvm` (e.g. `crw-rw----+ 1 root kvm`).
3. **Toolchain**: Paths returned for `qemu-system-x86_64`, `virsh`, `virt-install`, and `virt-manager`.
4. **libvirt URI**: Outputs `qemu:///system`.
5. **Storage Pool**: Pool `default` is `active`, state `running`, with at least `35 GiB` available.
6. **Virtual Network**: Network `default` is `active`, autostart `yes`.
7. **Firmware**: OVMF firmware files (such as `OVMF_CODE_4M.fd` or `OVMF_CODE.fd`) are present.
8. **ISO File**: The Debian 13 Netinst ISO exists and is readable (typically ~400–800 MB).
9. **Script Check**: `./scripts/vm/check-builder-vm-host.sh` outputs all `[ PASS ]` checks.

---

## Verification

Run the following consolidated command:
```bash
# HOST
virsh --connect qemu:///system list --all
```
Expected output shows the libvirt domain list (e.g., `minideb-lab` or empty list; `xedra-builder` should not yet be defined).

---

## Failure Handling

- **If `/dev/kvm` is missing or permission denied**:
  Ensure Intel VT-x / AMD-V is enabled in system BIOS/UEFI and your user belongs to the `kvm` group:
  ```bash
  sudo usermod -aG kvm,libvirt $USER
  ```
- **If `virsh --connect qemu:///system uri` fails**:
  Ensure the libvirt daemon is running:
  ```bash
  sudo systemctl status libvirtd
  ```
- **If storage pool `default` has less than 35 GiB available**:
  Do NOT proceed. We will configure an alternate storage pool or identify an additional physical disk in a dedicated step.
- **If network `default` is inactive**:
  Start the virtual network:
  ```bash
  sudo virsh --connect qemu:///system net-start default
  sudo virsh --connect qemu:///system net-autostart default
  ```

---

## Evidence to Return

Execute the commands above on the host system and paste the output of the following items back for review:

1. Output of: `virsh --connect qemu:///system uri`
2. Output of: `virsh --connect qemu:///system pool-info default`
3. Output of: `lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS`
4. Output of: `virsh --connect qemu:///system net-list --all`
5. Output of: `./scripts/vm/check-builder-vm-host.sh /path/to/debian-13-netinst.iso` (with your actual ISO path)

---

## Completion Criteria

This step is complete when all pre-creation checks pass, the Debian 13 ISO path is confirmed on the host, and sufficient disk space in the libvirt storage pool is verified.
