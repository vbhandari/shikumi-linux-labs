# Shikumi Labs · Linux for Backend Engineers: hands-on labs

*The Linux a backend developer or test engineer needs, from the shell to containers built by hand.*

This repository holds the lab files and step-by-step instructions for the Shikumi Labs Linux course: 16 modules and 46 hands-on labs, from a first VM to a production-shaped stack you deploy, break and fix. The videos teach the concepts; every lab here is something you run yourself on your own VM.

## What you need (VM prerequisites)

- **One VM per learner:** Ubuntu 26.04 LTS (64-bit, amd64 or arm64). Fedora / RHEL-family and Debian notes are included but untested.
- **Resources:** 2 vCPU, 4 GB RAM, 20 GB disk, outbound HTTPS, a sudo user, SSH access from the host.
- **systemd as PID 1** in a real VM. Not WSL1, not a container: the labs use cgroups, namespaces, AppArmor and eBPF.
- **A host tool to make the VM:** [Multipass](https://canonical.com/multipass) or [Vagrant](https://developer.hashicorp.com/vagrant). Lab 0.1 walks through both.
- **No PyPI packages.** The sample app and every helper use the Python standard library only.

## Get the labs

```bash
git clone https://github.com/vbhandari/shikumi-linux-labs.git
cd shikumi-linux-labs
./vm/multipass.sh            # or: cd vm && vagrant up
```

cloud-init (Multipass) or `provision.sh` (Vagrant) installs the course packages and clones the repo again, from GitHub, to `~/shikumi-linux-labs` inside the VM; the VM does not share the host's copy. Then, inside the VM (`multipass shell shikumi` or `vagrant ssh`):

```bash
~/shikumi-linux-labs/bin/shikumi-check env
```

To get updates later: `git -C ~/shikumi-linux-labs pull`.

## How the labs work

- Each lab has its own folder under [`labs/`](labs/) with a `README.md` (goal, steps, checks, stretch challenge, cleanup) and three scripts:
  - `setup.sh` is step 0 in every lab from 1.1 on (Lab 0.1 runs it once the VM and the repo exist). It copies the lab's files to `~/labs/<lab>` and checks prerequisites. Running it again restores the tested files.
  - `check.sh` verifies the result without changing anything, and exits 0 or 1. Run it as `bin/shikumi-check lab <lab>`, for example `bin/shikumi-check lab 5.1`.
  - `cleanup.sh` undoes the lab. It is safe to run twice, and it keeps what later labs build on; the README says when to run it.
- A few labs have a script that runs from the repo rather than from `~/labs`: `labs/15.1-deploy-the-stack/deploy.sh` and `labs/15.2-incident-drills/break.sh`. Scripts the lab works on, such as `mystery.sh` in Lab 14.1, are in the lab's `files/` folder and `setup.sh` copies them.
- Paste one code block at a time: see *Pasting* in [Lab 0.1](labs/00.1-provision-and-verify/README.md), step 5. Without bracketed paste, a `sudo` line swallows the lines pasted after it.
- Run the labs in order. Steps are for Ubuntu 26.04; grey **Fedora / RHEL-family** boxes and **Debian** notes show where other distributions differ.
- Every resource the labs create is named `shikumi`. Sysctls change for the current boot only, and every cleanup restores them.
- Snapshots have fixed names: `clean` after Lab 0.1, `pre-m06`, `pre-m11` and `pre-m13` before those modules, and `stack` after Lab 15.1. A broken lab is one restore away.
- Sudoers rules name exact commands, and no script matches or answers the sudo prompt.
- Nothing in this repo is a real secret. Lab certificates and keys are generated on your VM.
- The VM setup installs the course tools but not nginx: Lab 4.1 installs it. On Ubuntu 26.04 `/tmp` is a tmpfs in RAM, so lab data lives under `~/labs`.
- `bin/shikumi-reset` removes everything the course installed, at the end.

## Safety on a public cloud VM

**Threat model:** the sample app has endpoints that hold memory, burn CPU and leak descriptors on purpose, and Labs 11.1, 12.1 and 12.2 open ports in ufw, so on a VM with a public address anyone on the internet could reach them and take the VM down.
**Defences:** a provider firewall that allows only SSH from your own IP (set up in Lab 0.1), an nginx site that proxies only `/healthz`, an app that listens on 127.0.0.1 and bounds each lab endpoint (`/alloc` holds at most 512 MB), and units capped at `MemoryMax=256M` and `TasksMax=64`.

## Lab index

| Lab | Module | Title | Time | Tested on Ubuntu 26.04 |
|---|---|---|---|---|
| [0.1](labs/00.1-provision-and-verify/README.md) | M00 | Provision and verify your lab VM | 30 min | Not yet on a VM |
| [1.1](labs/01.1-safe-scripts/README.md) | M01 | Make a deploy script fail loudly | 20 min | Not yet on a VM |
| [1.2](labs/01.2-pipes-and-text/README.md) | M01 | Answer five questions from an access log | 20 min | Not yet on a VM |
| [1.3](labs/01.3-env-and-ssh/README.md) | M01 | Configure the app from the environment and reach it over SSH | 20 min | Not yet on a VM |
| [2.1](labs/02.1-disk-full/README.md) | M02 | Disk full, but nothing is big | 25 min | Not yet on a VM |
| [2.2](labs/02.2-users-and-sudo/README.md) | M02 | Users, groups and an exact-command sudo rule | 20 min | Not yet on a VM |
| [2.3](labs/02.3-permissions-and-capabilities/README.md) | M02 | A shared release directory, and why port 80 is refused | 25 min | Not yet on a VM |
| [3.1](labs/03.1-what-a-process-is/README.md) | M03 | Profile a process through /proc, and watch fork and exec | 20 min | Not yet on a VM |
| [3.2](labs/03.2-signals-and-shutdown/README.md) | M03 | Graceful shutdown, KILL, and a zombie | 20 min | Not yet on a VM |
| [3.3](labs/03.3-file-descriptors-and-limits/README.md) | M03 | Run out of file descriptors | 20 min | Not yet on a VM |
| [4.1](labs/04.1-installing-software/README.md) | M04 | Install nginx and find everything it brought | 20 min | Not yet on a VM |
| [5.1](labs/05.1-first-unit/README.md) | M05 | Install the app as a systemd service | 25 min | Not yet on a VM |
| [5.2](labs/05.2-the-journal/README.md) | M05 | Find the crash in the journal | 15 min | Not yet on a VM |
| [5.3](labs/05.3-sandboxing/README.md) | M05 | Sandbox the service and bind port 80 | 25 min | Not yet on a VM |
| [5.4](labs/05.4-templates-and-timers/README.md) | M05 | Two instances from one template, and a timer | 20 min | Not yet on a VM |
| [6.1](labs/06.1-first-apparmor-profile/README.md) | M06 | Generate an AppArmor profile for the app | 30 min | Not yet on a VM |
| [6.2](labs/06.2-living-with-mac/README.md) | M06 | Complain, refine, enforce: confine both instances | 30 min | Not yet on a VM |
| [7.1](labs/07.1-strace/README.md) | M07 | Watch system calls with strace | 25 min | Not yet on a VM |
| [7.2](labs/07.2-threads-vs-event-loop/README.md) | M07 | How servers wait: an event loop and a thread pool | 25 min | Not yet on a VM |
| [8.1](labs/08.1-virtual-memory/README.md) | M08 | RSS, VSZ and a memory-mapped file | 20 min | Not yet on a VM |
| [8.2](labs/08.2-page-cache/README.md) | M08 | Page cache and dirty pages | 25 min | Not yet on a VM |
| [8.3](labs/08.3-oom-killer/README.md) | M08 | The OOM killer and memory limits | 20 min | Not yet on a VM |
| [8.4](labs/08.4-disk-io/README.md) | M08 | The cost of fsync | 20 min | Not yet on a VM |
| [9.1](labs/09.1-interfaces-and-routes/README.md) | M09 | Map the VM's network | 15 min | Not yet on a VM |
| [9.2](labs/09.2-name-resolution/README.md) | M09 | Override a name and find the resolver | 15 min | Not yet on a VM |
| [9.3](labs/09.3-sockets-and-ports/README.md) | M09 | Capture one request and label every packet | 20 min | Not yet on a VM |
| [10.1](labs/10.1-close-wait/README.md) | M10 | CLOSE_WAIT is an application bug | 20 min | Not yet on a VM |
| [10.2](labs/10.2-accept-queue/README.md) | M10 | Fill the accept queue | 20 min | Not yet on a VM |
| [10.3](labs/10.3-socket-options/README.md) | M10 | SO_REUSEPORT, SO_REUSEADDR and EADDRINUSE | 20 min | Not yet on a VM |
| [10.4](labs/10.4-buffers-and-autotuning/README.md) | M10 | Socket buffers and autotuning | 20 min | Not yet on a VM |
| [11.1](labs/11.1-ufw-and-nftables/README.md) | M11 | ufw, and the nftables underneath | 30 min | Not yet on a VM |
| [11.2](labs/11.2-network-namespaces/README.md) | M11 | Two network namespaces and a veth pair | 20 min | Not yet on a VM |
| [11.3](labs/11.3-routing-and-nat/README.md) | M11 | Route and NAT out of a namespace | 25 min | Not yet on a VM |
| [11.4](labs/11.4-netem-faults/README.md) | M11 | Inject delay and loss with tc netem | 25 min | Not yet on a VM |
| [12.1](labs/12.1-reverse-proxy/README.md) | M12 | nginx in front of two instances | 25 min | Not yet on a VM |
| [12.2](labs/12.2-tls-and-http2/README.md) | M12 | TLS termination and HTTP/2 | 25 min | Not yet on a VM |
| [13.1](labs/13.1-namespaces-and-userns/README.md) | M13 | Namespaces, and who may create them | 30 min | Not yet on a VM |
| [13.2](labs/13.2-cgroups-v2/README.md) | M13 | Throttle a busy loop with cgroups v2 | 20 min | Not yet on a VM |
| [13.3](labs/13.3-mini-container/README.md) | M13 | Build a mini container by hand | 35 min | Not yet on a VM |
| [13.4](labs/13.4-what-container-tools-add/README.md) | M13 | What Podman adds | 20 min | Not yet on a VM |
| [14.1](labs/14.1-first-60-seconds/README.md) | M14 | The first 60 seconds | 25 min | Not yet on a VM |
| [14.2](labs/14.2-hangs-and-deadlocks/README.md) | M14 | Prove a deadlock and fix the lock order | 25 min | Not yet on a VM |
| [14.3](labs/14.3-perf-and-flame-graphs/README.md) | M14 | Find the hot function with perf | 30 min | Not yet on a VM |
| [14.4](labs/14.4-ebpf-tools/README.md) | M14 | eBPF: ready-made tools, then your own | 30 min | Not yet on a VM |
| [15.1](labs/15.1-deploy-the-stack/README.md) | M15 | Deploy the production-shaped stack | 30 min | Not yet on a VM |
| [15.2](labs/15.2-incident-drills/README.md) | M15 | Incident drills | 45 min | Not yet on a VM |

About 18 hours of lab time in total.

## Modules

| Module | Title |
|---|---|
| M00 | Orientation and the lab VM |
| M01 | Shell fluency |
| M02 | Files, filesystems, users and permissions |
| M03 | Processes, signals and file descriptors |
| M04 | Packages: apt first, dnf alongside |
| M05 | systemd and the journal |
| M06 | Mandatory access control: AppArmor (core) · SELinux (alternate) |
| M07 | System calls and the kernel boundary |
| M08 | Memory, page cache and disk I/O |
| M09 | Networking fundamentals |
| M10 | TCP for backend and test engineers |
| M11 | Firewalls, network namespaces and fault injection |
| M12 | Reverse proxy and TLS |
| M13 | Containers from kernel primitives |
| M14 | Observability and troubleshooting |
| M15 | Capstone: run it, break it, fix it |

## What is in this repository

| Path | Contents |
|---|---|
| [`app/`](app/) | `shikumi_api.py`, the asyncio sample service (installed as `/opt/shikumi/bin/shikumi-api`), and small helpers: a load generator, a threaded server, and programs that leak, hang or misbehave on purpose |
| [`units/`](units/) | systemd units: the service, its template, a hardening drop-in, and a prune timer |
| [`config/`](config/) | AppArmor profiles, nginx sites, nftables tables, and ufw, SELinux and firewalld notes |
| [`bpf/`](bpf/) | Reference bpftrace scripts for Lab 14.4 |
| [`bin/`](bin/) | `shikumi-check`, `shikumi-reset` and the shared `lib.sh` |
| [`vm/`](vm/) | Multipass cloud-init, Vagrantfile, `provision.sh` and the package map |
| [`labs/`](labs/) | One folder per lab |
| [`appendix-c/`](appendix-c/) | The C examples from the handout's Appendix C (optional, not labs) |
| [`tests/`](tests/) | Unit tests for the app and the unit-file check that CI runs |

## The sample app

`shikumi-api` is one Python file with no dependencies. It serves `GET` requests, one per connection, and every JSON response includes the serving PID.

| Endpoint | Does | Used in |
|---|---|---|
| `/healthz` | Answers `{"status": "ok"}` | everywhere |
| `/slow?ms=N` | Waits N ms without blocking other requests | 3.2, 7.2, 14.4 |
| `/cpu?ms=N` | Busy-loops for N ms | your own experiments |
| `/checksum?kb=N` | Checksums N KB in pure Python (`SHIKUMI_FAST_CHECKSUM=1` uses zlib) | 14.3 |
| `/alloc?mb=N` | Allocates and keeps N MB | your own experiments |
| `/files?n=N` | Opens and keeps N file descriptors | 3.3 |
| `/data?name=F` | Reads F from the data directory, and caches it when `SHIKUMI_CACHE=1` | 5.1, 5.3, 6.1, 6.2 |

Settings come from flags or the environment: `SHIKUMI_HOST`, `SHIKUMI_PORT`, `SHIKUMI_DATA_DIR` (else systemd's `STATE_DIRECTORY`), `SHIKUMI_CACHE_DIR` (else `CACHE_DIRECTORY`), `SHIKUMI_CACHE`. On SIGTERM it stops accepting and lets in-flight requests finish.

## Checks in CI

Every push runs shellcheck, `py_compile` and the unit tests (Python 3.12 and 3.14), an `apparmor_parser` syntax check, `systemd-analyze verify` on the units, a bpftrace parse check (plus an attach dry run that only warns), a build of Appendix C, and a markdown link check, on GitHub's `ubuntu-26.04` runners. None of this replaces running the labs on a real VM.

## Copyright

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.

This is not open-source software. See [LICENSE](https://github.com/vbhandari/shikumi-linux-labs/blob/main/LICENSE). The repository is public so learners can clone it; no rights to reuse or redistribute are granted.
