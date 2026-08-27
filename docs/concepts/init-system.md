# Concept: The Init System & PID 1

The **Init System** is the first user-space program executed by the Linux kernel during system startup. It is assigned **Process ID 1 (PID 1)** and remains active until the machine powers off.

---

## 1. The Critical Roles of PID 1

Under the Unix process model, PID 1 has unique, non-delegable responsibilities:

1. **System Initialization**:
   - Mounts virtual filesystems (`/proc`, `/sys`, `/dev`, `/run`).
   - Sets the system hostname.
   - Activates swap space and checks root disk integrity.
2. **Service Supervision & Daemons**:
   - Starts system services in order (networking, logging, D-Bus, display manager).
3. **Orphan Process Reaping**:
   - In Unix, when a parent process terminates before its child, the child becomes an "orphan."
   - The Linux kernel automatically re-parents orphaned processes to **PID 1**.
   - PID 1 must continually call `wait()` or `waitpid()` to collect their exit statuses; otherwise, terminated processes become "zombies" that permanently consume kernel process table entries.
4. **Shutdown & Poweroff**:
   - Sends termination signals (`SIGTERM`, then `SIGKILL`) to all running processes, unmounts filesystems cleanly, and invokes the `reboot` or `poweroff` syscall.

---

## 2. SysVinit vs. systemd in Debian

Debian supports multiple init systems, with `systemd` being the default since Debian 8 (Jessie), and `SysVinit` fully supported via `sysvinit-core`.

```text
================================================================================
                               SysVinit Architecture
================================================================================
Kernel -> /sbin/init -> /etc/inittab -> /etc/init.d/rc -> /etc/rc*.d/S* scripts
(Simple shell scripts, sequential execution, explicit runlevels 0-6)

================================================================================
                               systemd Architecture
================================================================================
Kernel -> /lib/systemd/systemd -> systemd units (*.service, *.target, *.socket)
(C binary daemon, parallel execution, socket activation, cgroups, binary journal)
```

### Technical Comparison

| Feature | SysVinit (`sysvinit-core`) | systemd (`systemd`) |
| :--- | :--- | :--- |
| **PID 1 Implementation** | Minimal C binary (`/sbin/init`) | Comprehensive system and service manager |
| **Service Definitions** | Plain POSIX Shell scripts in `/etc/init.d/` | Declarative INI-style unit files (`.service`) |
| **Execution Model** | Sequential runlevels (`rc0` through `rc6`) | Parallel event-driven dependency resolution |
| **Logging** | Standard text logs via `syslogd` (`/var/log/messages`) | Binary structured journal (`journald`) |
| **Scope & Complexity** | Does one thing: starts and stops scripts | Manages init, udev, network, DNS, logins, timers |
| **Transparency for Learning** | **Extremely high** (every script is readable bash/sh) | Medium (requires querying `systemctl` / `journalctl`) |

---

## 3. Why Xedra Uses SysVinit

Xedra is an educational operating system built to be understandable by one person.

1. **Inspectability**: In Xedra, when a service starts, you can open `/etc/init.d/<service>` and read the exact `start-stop-daemon` command that runs.
2. **No Black Boxes**: There are no binary log formats, no socket activation magic, and no implicit background behaviors.
3. **Decoupled Architecture**: SysVinit leaves device management, networking, and logging to independent, replaceable tools (`eudev`, `ifupdown`, `rsyslog`).
