# Lab 12.1: nginx in front of two instances

**Module M12 · Reverse proxy and TLS** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Put nginx on port 80 in front of `shikumi-api@8001` and `@8002`, open port 80 in ufw, and watch traffic move when one instance stops.

## Before you start

- Lab 11.4 done (and the M11 cleanups run).
- nginx installed and disabled (Lab 4.1); `@8001` and `@8002` running (Lab 5.4).

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/12.1-reverse-proxy/setup.sh
cd ~/labs/12.1
```

### Step 1: Install the site configuration.

```bash
cat ~/shikumi-linux-labs/config/nginx/proxy.conf
sudo install -m 0644 \
  ~/shikumi-linux-labs/config/nginx/proxy.conf \
  /etc/nginx/sites-available/shikumi
sudo ln -sf /etc/nginx/sites-available/shikumi \
  /etc/nginx/sites-enabled/shikumi
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
```

The site proxies **only `/healthz`**; nginx answers 404 for every other path. The app's other endpoints are for labs on 127.0.0.1:800x: `/alloc` holds memory, `/cpu` and `/checksum` burn CPU, `/files` leaks descriptors and `/slow` holds connections. Port 80 may face the internet, so an allowlist is the safe default. Ubuntu reads `sites-enabled/`; the default site would also claim port 80. The site file is always `/etc/nginx/sites-available/shikumi`: Lab 12.2 overwrites it with `tls.conf`.

### Step 2: Enable nginx again and open port 80.

```bash
sudo systemctl enable --now nginx
sudo ufw allow 80/tcp
for i in 1 2 3 4; do curl -s http://127.0.0.1/healthz; echo; done
curl -s -o /dev/null -w '%{http_code}\n' \
  'http://127.0.0.1/alloc?mb=0'
```

The last request prints `404`: nginx refuses it before it reaches the app. The four `/healthz` answers may all come from one instance, because each nginx worker keeps its own round-robin position; step 3's concurrent load spreads them.

**On a public cloud VM**, `ufw allow 80/tcp` opens port 80 to the whole internet unless the provider's firewall stops it. Keep the Lab 0.1 provider firewall in front, and for the host test in step 3 allow 80/tcp there from your own public IP only.

### Step 3: Spread load and count responses per instance.

```bash
python3 ~/shikumi-linux-labs/app/loadgen.py http://127.0.0.1/healthz -c 10 -n 200 --by-pid
```

From the host, `curl http://VM_IP/healthz` works too (`VM_IP` as in Lab 11.1). On a cloud VM, that needs a provider-firewall rule for 80/tcp from your own IP only (step 2).

### Step 4: Stop one instance and watch traffic move.

```bash
sudo systemctl stop shikumi-api@8002
python3 ~/shikumi-linux-labs/app/loadgen.py http://127.0.0.1/healthz -c 10 -n 200 --by-pid
sudo tail -n 3 /var/log/nginx/error.log
sudo systemctl start shikumi-api@8002
sleep 11
```

nginx notices the failed connection, retries the request on 8001 and marks 8002 as down for `fail_timeout` (10 s). Open-source nginx only checks passively, by real requests; it has no active health checks. `sleep 11` waits out that 10 s: until then nginx sends nothing to 8002, even though it is running again, and the check would see only one PID.

### Step 5: See what the app sees.

```bash
sudo journalctl -u shikumi-api@8001 -n 3 --no-pager
```

Every request now comes from 127.0.0.1, which is nginx. The `X-Forwarded-For` header carries the real client address.

> **Fedora / RHEL-family (alternate path, untested)**
>
> ```bash
> sudo install -m 0644 ~/shikumi-linux-labs/config/nginx/proxy.conf /etc/nginx/conf.d/shikumi.conf
> sudo setsebool -P httpd_can_network_connect 1     # let nginx connect to 8001/8002
> sudo firewall-cmd --permanent --add-service=http && sudo firewall-cmd --reload
> ```
>
> Fedora's `nginx.conf` has its own default server on port 80; remove or edit that block. *(to verify)*

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 12.1
```

- nginx is enabled, active and its configuration passes `nginx -t`
- ufw allows 80/tcp
- 200 requests through port 80 are answered by two different PIDs
- Only `/healthz` is proxied: `/alloc` through port 80 returns 404

## Stretch challenge

Add `proxy_next_upstream_tries 1;` and repeat step 4. What does the client see now, and why is the default safer for GET but riskier for POST?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/12.1-reverse-proxy/cleanup.sh
```

Removes `~/labs/12.1` and nothing else: Lab 12.2 builds on this.

## Coreutils used

`cat`, `install`, `ln`, `rm`, `tail`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): nginx 1.28 accepts proxy.conf (nginx -t).

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
