# Lab 12.2: TLS termination and HTTP/2

**Module M12 · Reverse proxy and TLS** · about 25 min · [Lab index](../../README.md#lab-index)

**Goal:** Make a lab CA and a server certificate, serve HTTPS with HTTP/2 on port 443, redirect HTTP to HTTPS, and confirm h2 with curl and openssl.

## Before you start

- Lab 12.1 done.

## Files in this folder

- [`setup.sh`](setup.sh), [`check.sh`](check.sh), [`cleanup.sh`](cleanup.sh)
- [`files/make-certs.sh`](files/make-certs.sh)

## Steps

Steps are for Ubuntu 26.04 LTS.

### Step 0: Copy the lab files.

```bash
~/shikumi-linux-labs/labs/12.2-tls-and-http2/setup.sh
cd ~/labs/12.2
```

### Step 1: Make the certificates and read them.

```bash
./make-certs.sh
openssl x509 -in server.crt -noout -subject -issuer -ext subjectAltName
```

Besides the certificate details, `make-certs.sh` prints two `-----` lines, `Certificate request self-signature ok`, `subject=CN=localhost` and `server.crt: OK`. They are normal.

### Step 2: Install the certificate and key where nginx expects them.

```bash
sudo install -d -m 0755 /etc/nginx/shikumi-tls
sudo install -m 0644 server.crt ca.crt /etc/nginx/shikumi-tls/
sudo install -m 0600 server.key /etc/nginx/shikumi-tls/
ls -l /etc/nginx/shikumi-tls
```

nginx reads `server.crt` and `server.key`. `ca.crt` goes alongside so later labs can verify against `/etc/nginx/shikumi-tls/ca.crt`, the same path `deploy.sh` uses in Lab 15.1. `ca.key` stays in `~/labs/12.2`.

### Step 3: Switch the site to TLS.

```bash
nginx -v
cat ~/shikumi-linux-labs/config/nginx/tls.conf
sudo install -m 0644 ~/shikumi-linux-labs/config/nginx/tls.conf /etc/nginx/sites-available/shikumi
sudo nginx -t && sudo systemctl reload nginx
sudo ufw allow 443/tcp
```

`http2 on;` needs nginx 1.25.1 or later. On older nginx use `config/nginx/tls-legacy.conf`, which puts `http2` on the `listen` line. Like `proxy.conf`, both proxy only `/healthz`.

**On a public cloud VM**, `ufw allow 443/tcp` opens 443 to the internet unless the provider's firewall stops it. As in Lab 12.1, keep the provider firewall in front and allow 443/tcp there from your own public IP only, for step 6.

### Step 4: Test the redirect, then HTTPS with HTTP/2.

```bash
curl -sI http://127.0.0.1/healthz | head -n 3
curl -s --cacert ca.crt -o /dev/null -w '%{http_version} %{http_code}\n' https://localhost/healthz
curl -sv --cacert ca.crt --http2 https://localhost/healthz 2>&1 | grep -E 'ALPN|SSL connection|subject:'
```

### Step 5: Look at the handshake with openssl.

```bash
openssl s_client -connect 127.0.0.1:443 -servername localhost -alpn h2 -CAfile ca.crt </dev/null 2>/dev/null \
  | grep -a -E 'ALPN|Verify return|Protocol'
```

`-a` makes grep treat the output as text: once h2 is agreed, the server's binary SETTINGS frame reaches stdout too. ALPN is how client and server agree on h2 during the TLS handshake. `Verify return code: 0 (ok)` means the chain checks out against your CA.

### Step 6: Reach it from the host.

```bash
# on the host: copy ca.crt out of the VM, then connect
scp USER@VM_IP:labs/12.2/ca.crt .
curl --cacert ca.crt --resolve shikumi.test:443:VM_IP \
  https://shikumi.test/healthz
```

`USER@VM_IP` is your VM login, as in Lab 1.3, and `VM_IP` the address from Lab 9.1. With Vagrant, copy the file with `vagrant ssh -c 'cat labs/12.2/ca.crt' > ca.crt` instead. On a cloud VM, that needs a provider-firewall rule for 443/tcp from your own public IP only (step 3); remove it when you're done.

> **Fedora / RHEL-family (alternate path, untested)**
>
> Install to `/etc/nginx/conf.d/shikumi.conf`, open the port with `sudo firewall-cmd --permanent --add-service=https && sudo firewall-cmd --reload`. Files copied into `/etc/nginx` get the right SELinux label from `install`; run `restorecon -Rv /etc/nginx` if you used `mv`.

## Checks (expected output)

```bash
~/shikumi-linux-labs/bin/shikumi-check lab 12.2
```

- `https://localhost/healthz` answers 200 over HTTP/2 when verified against `ca.crt`
- `http://127.0.0.1/healthz` redirects with 301
- ufw allows 443/tcp, and `server.crt` verifies against `ca.crt`
- Only `/healthz` is proxied: `/alloc` over HTTPS returns 404

## Stretch challenge

Add `add_header Strict-Transport-Security "max-age=300" always;` to the 443 server and check the header with `curl -sI`. Why is a short max-age wise in a lab?

## Cleanup

```bash
cd ~
~/shikumi-linux-labs/labs/12.2-tls-and-http2/cleanup.sh
```

Nothing to undo: the TLS site stays in place, and so does `~/labs/12.2`, which holds the lab CA's `ca.key`. Lab 15.1 rebuilds the site from a clean snapshot.

## Coreutils used

`install`, `cat`, `head`, `printf`. On Ubuntu 26.04 these come from uutils; if one behaves differently, run its GNU build as `gnu<cmd>` (for example `gnustat`).

## Tested

Not yet run on an Ubuntu 26.04 VM. Checked in an Ubuntu 26.04 chroot (Python 3.14, uutils coreutils, sudo-rs, no systemd): make-certs.sh works; nginx 1.28 accepts tls.conf and warns on tls-legacy.conf as described.

---

© 2026 Vinay Bhandari and Shikumi Labs. All rights reserved.
