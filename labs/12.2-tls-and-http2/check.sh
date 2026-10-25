#!/bin/bash
# Lab 12.2 check: read-only; exits 0 when the lab is complete.
set -uo pipefail
# shellcheck source=bin/lib.sh
. "$(dirname "$(readlink -f "$0")")/../../bin/lib.sh"

say "Lab 12.2: TLS termination and HTTP/2"
W="$LAB_HOME/12.2"
check "server.crt verifies against ca.crt" openssl verify -CAfile "$W/ca.crt" "$W/server.crt"
check "HTTPS answers 200 over HTTP/2" test "$(curl -s --cacert "$W/ca.crt" -o /dev/null -w '%{http_version} %{http_code}' https://localhost/healthz)" = "2 200"
check "HTTP redirects with 301" test "$(http_status http://127.0.0.1/healthz)" = 301
check "ufw allows 443/tcp" bash -c "sudo ufw status | grep -q '^443/tcp .*ALLOW'"
a="$(curl -s --cacert "$W/ca.crt" -o /dev/null -w '%{http_code}' 'https://localhost/alloc?mb=0')"
check "nginx refuses /alloc over HTTPS ($a)" test "$a" = 404
finish
