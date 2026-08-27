# Step 02 — Create 'xedra-builder' Virtual Machine

## Objective

Instantiate the authoritative `xedra-builder` Debian 13 (Trixie) virtual machine on the host hypervisor (`qemu:///system`) using `virt-install` and UEFI firmware.

This step allocates a 35 GB virtual disk image inside the libvirt `default` storage pool (`/var/lib/libvirt/images`) and attaches the Debian 13 Netinst ISO to begin the OS installation.

---

## Preconditions

1. **Step 01 Complete**: Hypervisor, storage pool `default` (with 35+ GB free), and UEFI firmware support have been verified on the host system.
2. **Debian 13 ISO Available**: You have the Debian 13 Netinst ISO file on your host system.
3. **Safety**: No physical host disks or partitions will be formatted, repartitioned, or modified.

---

## Environment

All commands in this runbook are executed exclusively on the:

```text
HOST
```

---

## Virtual Machine Parameters

- **Domain Name**: `xedra-builder`
- **CPU**: 2 vCPUs
- **Memory**: 4096 MB (4 GB)
- **Virtual Disk**: 35 GB (`qcow2` format, `virtio` bus, stored in `default` pool)
- **CD-ROM**: Location specified by `$ISO_PATH`
- **Firmware**: UEFI (`--boot uefi`)
- **Network**: NAT (`network=default,model=virtio`)
- **Display / Video**: SPICE console with QXL video (`--graphics spice,listen=none --video qxl`)

---

## Commands

Execute the following commands sequentially in a terminal on the host system:

### 1. Grant Hypervisor Traverse Permission to Home Directory (Option B)
This allows the `libvirt-qemu` service account to read the ISO directly from your home directory without moving or copying files:
```bash
# HOST
setfacl -m u:libvirt-qemu:rx ~
```

### 2. Set Your ISO Path Variable
Set the `ISO_PATH` environment variable to the absolute path of your downloaded Debian 13 Netinst ISO:
```bash
# HOST (Example: replace with your actual file path)
export ISO_PATH="/path/to/your/debian-13.6.0-amd64-netinst.iso"
```
Verify the variable is set and readable:
```bash
# HOST
ls -lh "$ISO_PATH"
```

### 3. Execute Virtual Machine Creation
```bash
# HOST
cd ~/XedraGoSysInit
./scripts/vm/create-builder-vm.sh "$ISO_PATH"
```

### 4. Verify Domain Creation in libvirt
```bash
# HOST
virsh --connect qemu:///system dominfo xedra-builder
```

### 5. Verify Virtual Disks & Attached CD-ROM
```bash
# HOST
virsh --connect qemu:///system domblklist xedra-builder --details
```

---

## Expected Result

1. `virt-install` reports:
   ```text
   Starting install...
   Domain creation completed.
   ```
2. `virsh dominfo xedra-builder` shows:
   - **Name**: `xedra-builder`
   - **State**: `running`
   - **CPU(s)**: `2`
   - **Max memory**: `4194304 KiB` (4 GB)
3. `virsh domblklist xedra-builder --details` lists:
   - Target `vda`: disk in `/var/lib/libvirt/images/xedra-builder.qcow2`
   - Target `sda` (or `sdb`): cdrom pointing to your Debian ISO

---

## Verification

Run the non-destructive inspection tool:
```bash
# HOST
./scripts/vm/inspect-builder-vm.sh
```

---

## Failure Handling

- **If `virt-install` fails with "Domain 'xedra-builder' already exists"**:
  Check domain state:
  ```bash
  virsh --connect qemu:///system dominfo xedra-builder
  ```
  If you need to start fresh, clean up the existing domain:
  ```bash
  ./scripts/vm/destroy-builder-vm.sh
  ```
- **If permission warnings persist**:
  Ensure the parent directories of the ISO have read/execute permissions:
  ```bash
  chmod a+r "$ISO_PATH"
  ```

---

## Evidence to Return

Execute the commands above on the host system and paste the output of the following items back for review:

1. Output of: `./scripts/vm/create-builder-vm.sh "$ISO_PATH"`
2. Output of: `virsh --connect qemu:///system dominfo xedra-builder`
3. Output of: `virsh --connect qemu:///system domblklist xedra-builder --details`

---

## Completion Criteria

This step is complete when the `xedra-builder` domain is successfully created, defined in `qemu:///system`, in a `running` state, with its 35 GB virtual disk and Debian 13 installer CD-ROM attached.
