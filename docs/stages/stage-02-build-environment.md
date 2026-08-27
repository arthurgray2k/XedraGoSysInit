# Stage 2 — Isolated Debian Build Environment

## 1. Objective

Establish an isolated, clean Debian 13 "Trixie" build environment using Podman on the Linux host. This ensures that all Xedra distribution construction tooling operates in pure Debian userland without contaminating the host system.

---

## 2. What Was Built

- `container/Containerfile`: Minimal Debian 13 Trixie container recipe.
- `scripts/check-container-runtime.sh`: Detects Podman on the host.
- `scripts/build-builder-image.sh`: Builds the `xedra-builder:trixie` image.
- `scripts/enter-builder.sh`: Launches an interactive shell inside the container.
- `scripts/check-builder.sh`: Validates the container userland, DPKG, APT, and volume mounts.

---

## 3. Host & Container Architecture

```text
Linux Host (x86_64)
   │
   ├── Podman 4.9.3 (Rootless, daemonless OCI engine)
   │       │
   │       └── Container Image: localhost/xedra-builder:trixie
   │               │
   │               ├── Debian 13 (Trixie) Userspace (amd64)
   │               ├── Minimal Tools: bash, apt, dpkg, git, debootstrap
   │               └── Mount: /workspace <-> ~/XedraGoSysInit
   │
   └── Persistent Storage: ~/XedraGoSysInit
```

---

## 4. What a Container Actually Provides

To understand distro isolation, we must distinguish the components of a Linux container:

| Component | In Container | Handled By |
| :--- | :--- | :--- |
| **Linux Kernel** | Shared directly with host (`7.0.0-28-generic`) | Physical host kernel |
| **System Calls** | Kernel handles `clone`, `unshare`, `mount`, `execve` | Host kernel syscall interface |
| **Userspace Libraries** | Pure Debian 13 glibc (`/lib/x86_64-linux-gnu/libc.so.6`) | Container image filesystem |
| **Package Database** | Pure Debian DPKG database (`/var/lib/dpkg/status`) | Container image filesystem |
| **Filesystem Mounts** | Isolated mount namespace (`/workspace` mapped to `~/XedraGoSysInit`) | Linux Mount Namespaces (`CLONE_NEWNS`) |
| **Processes** | Isolated PID namespace | Linux PID Namespaces (`CLONE_NEWPID`) |

---

## 5. Exact Commands Executed

```bash
# 1. Inspect container runtime on Mint host
./scripts/check-container-runtime.sh

# 2. Build the isolated Debian Trixie container
./scripts/build-builder-image.sh

# 3. Validate toolchain inside the container
./scripts/check-builder.sh
```

---

## 6. Important Files

- `container/Containerfile`: Base container definition using `debian:trixie-slim`.
- `scripts/enter-builder.sh`: Mounts `~/XedraGoSysInit` into `/workspace` and drops to bash.
- `scripts/check-builder.sh`: Verifies Debian 13 release status, `amd64` architecture, and `debootstrap` tool presence.

---

## 7. What Happened Internally

1. Podman pulled `docker.io/library/debian:trixie-slim`.
2. Executed `apt-get update` against `deb.debian.org/debian` for `trixie`.
3. Installed `bash`, `ca-certificates`, `git`, `coreutils`, `util-linux`, `procps`, and `debootstrap` into the container image.
4. Cleaned the APT cache (`/var/lib/apt/lists/*`) to keep image size small (~118 MB).
5. Tagged image as `localhost/xedra-builder:trixie`.

---

## 8. Verification Results

```text
Running check-builder.sh inside container via Podman...
======================================================
  Entering Xedra Isolated Debian Build Environment     
======================================================
Mounted Repository: /home/mint/XedraGoSysInit -> /workspace
Container Image:    xedra-builder:trixie
Type 'exit' to return to host system.

======================================================
  Xedra Linux - Debian Build Environment Validation   
======================================================
Environment: Isolated Debian Container (Debian 13 Trixie)

--- Operating System & Architecture ---
  [ PASS ] Debian Version -> Debian GNU/Linux 13 (trixie) (Codename: trixie)
  [ PASS ] Architecture   -> amd64 (amd64 / x86_64)

--- Required Build Tools ---
  [ PASS ] dpkg           -> Debian 'dpkg' package management program version 1.21.23 (amd64).
  [ PASS ] apt-get        -> apt 2.6.1 (amd64)
  [ PASS ] git            -> git version 2.39.5
  [ PASS ] debootstrap    -> debootstrap 1.0.128+nmu2+deb12u2

--- Workspace Mount Verification ---
  [ PASS ] /workspace Mount -> Successfully mounted Xedra repository

--- Container Resources ---
  [ PASS ] Available Memory -> 12 GB
  [ PASS ] Disk on /workspace -> 412 GB available

======================================================
  Validation Summary:  Pass: 9  |  Fail: 0
======================================================
Status: Isolated Debian Build Environment is healthy and verified.
```

---

## 9. Current State

- Isolated build environment is **Complete and Verified**.

---

## 10. What Stage 2 Deliberately Did NOT Do

- ❌ Did NOT install `live-build` yet.
- ❌ Did NOT configure graphical components (X11, Fluxbox).
- ❌ Did NOT configure SysVinit.
- ❌ Did NOT build an ISO image.
- ❌ Did NOT modify the physical host system.
