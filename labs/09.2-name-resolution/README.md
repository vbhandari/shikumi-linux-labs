# Lab 9.2: Override a name and find the resolver

**Module M09 · Networking fundamentals** · about 15 min · [Lab index](../../README.md#lab-index)

**Goal:** Follow a name lookup from `nsswitch.conf` through `/etc/hosts` and systemd-resolved, override one name, and see why `getent` and `dig` can disagree.

## Before you start

- Lab 9.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/09.2-name-resolution/setup.sh
cd ~/labs/9.2
```

### Step 1: Find the order of lookups and the resolver.

```bash
grep '^hosts:' /etc/nsswitch.conf
ls -l /etc/resolv.conf
grep -v '^#' /etc/resolv.conf
resolvectl status --no-pager | head -n 20
```

`files` means `/etc/hosts`; `dns` means the server in `resolv.conf`, here systemd-resolved's stub at 127.0.0.53.

### Step 2: Override a name for this machine.

```bash
echo "10.200.9.9 api.shikumi.test # shikumi-lab" | sudo tee -a /etc/hosts
getent hosts api.shikumi.test
```

### Step 3: Compare getent and dig.

```bash
dig +short api.shikumi.test
dig +short @1.1.1.1 api.shikumi.test
resolvectl query api.shikumi.test
```

`getent` follows `nsswitch.conf`, as your programs do. `dig` asks a DNS server directly and skips `/etc/hosts`. Here the first `dig` still finds the name, because systemd-resolved serves `/etc/hosts` entries on its stub. Asking 1.1.1.1 directly gets nothing.

### Step 4: Look up a real name both ways.

```bash
getent hosts example.com
dig example.com +noall +answer
dig @1.1.1.1 example.com +noall +answer
resolvectl statistics --no-pager | head -n 12
```

The TTL from the stub counts down between runs: resolved caches answers.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Fedora also uses systemd-resolved, with the same stub.

> **Debian**
>
> Debian cloud images may not run systemd-resolved: `/etc/resolv.conf` then names the DNS server directly, and `dig` without `@` skips `/etc/hosts`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 9.2
```

- `getent hosts api.shikumi.test` returns 10.200.9.9
- `/etc/resolv.conf` points at the systemd-resolved stub (127.0.0.53)

## Stretch challenge

Find out which DNS server the stub forwards to (`resolvectl dns`) and query it directly with `dig @SERVER`, where `SERVER` is the address `resolvectl dns` printed. Is the answer the same as through the stub?

## Cleanup

```bash
~/shikumi-linux-labs/labs/09.2-name-resolution/cleanup.sh
```

Removes the `# shikumi-lab` line from `/etc/hosts`.

## Coreutils used

`ls`, `head`, `tee`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
