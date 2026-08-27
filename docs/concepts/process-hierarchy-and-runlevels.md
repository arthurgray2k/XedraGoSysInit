# Linux Process Hierarchy: PID 1, PID 2, and SysVinit Runlevels

## 1. Overview of the Early Linux Process Tree

When the Linux kernel boots into hardware, it establishes two foundational roots that separate **Userland Applications** from **Kernel Threads**:

```text
                           [ Linux Kernel Boot ]
                                     │
                    ┌────────────────┴────────────────┐
                    │                                 │
                    ▼                                 ▼
         ★ PID 1: /sbin/init ★               ★ PID 2: [kthreadd] ★
      (Userland Master Init Process)        (Kernel Thread Daemon)
                    │                                 │
         ┌──────────┼──────────┐            ┌─────────┼─────────┐
         ▼          ▼          ▼            ▼         ▼         ▼
     /etc/init.d  getty(s)   startx     [kworker]  [ksoftirqd] [rcu_sched]
     (Services)   (ttys)    (Fluxbox)   (I/O Work) (Interrupts) (Locking)
```

---

## 2. Distinction Between PID 1 and PID 2

| Process ID | Name | Execution Domain | Origin | Purpose & Lifecycle |
| :--- | :--- | :--- | :--- | :--- |
| **PID 1** | **`/sbin/init` (SysVinit)** | **Userland** | Binary executable on disk (`/sbin/init` from `sysvinit-core`) | The ancestor of all user-space processes (shells, login prompts, daemons, window managers, GUI tools). It manages service startup, runlevels, and adopts orphaned processes. |
| **PID 2** | **`[kthreadd]`** | **Kernel Space** | Built directly into the **Linux Kernel** (`kernel/kthread.c`) | The ancestor of all internal kernel worker threads. It has no binary file on disk, no userland memory space, and handles asynchronous kernel tasks like disk I/O flushes, memory compaction, and soft interrupts. |

---

## 3. SysVinit Runlevels and `/etc/inittab`

While PID 1 is the process identity, **Runlevels** represent the operational state of the operating system configured in `/etc/inittab`.

### Standard Debian / SysVinit Runlevels:

| Runlevel | Name | Purpose |
| :--- | :--- | :--- |
| **0** | **Halt** | Shuts down the machine and powers off hardware (`/etc/init.d/rc 0`). |
| **1 (or S)** | **Single-User Mode** | Maintenance mode with root shell and no networking (`sulogin`). |
| **2** | **Multi-User Graphical / Text** | **Default Xedra Runlevel** (`id:2:initdefault:`). Starts multi-user mode, networking, and virtual terminals. |
| **3–5** | **Multi-User (Custom)** | Identical to runlevel 2 by default in Debian; customizable by administrator. |
| **6** | **Reboot** | Shuts down services cleanly and reboots the machine (`/etc/init.d/rc 6`). |

---

## 4. How `/etc/inittab` Translates PID 1 into Runlevel 2

In Xedra Linux, `/etc/inittab` directs PID 1 on boot:

```text
# 1. Sets the default operating runlevel to 2
id:2:initdefault:

# 2. Runs early hardware initialization before runlevels
si::sysinit:/etc/init.d/rcS

# 3. Invokes runlevel 2 scripts in /etc/rc2.d/
l2:2:wait:/etc/init.d/rc 2

# 4. Spawns login prompts on virtual consoles (tty1 to tty6)
1:2345:respawn:/sbin/getty 38400 tty1
2:23:respawn:/sbin/getty 38400 tty2
3:23:respawn:/sbin/getty 38400 tty3
```

When `/sbin/init` (PID 1) executes:
1. It reads `/etc/inittab`.
2. Runs the boot-time initialization scripts (`rcS`).
3. Transitions into **Runlevel 2** by executing `/etc/init.d/rc 2`.
4. Spawns `getty` on `tty1` through `tty6` waiting for user login.
