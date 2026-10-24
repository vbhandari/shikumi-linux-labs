#!/bin/bash
# Make a lab CA and a server certificate for localhost,
# 127.0.0.1 and shikumi.test.
set -euo pipefail
openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
  -subj "/CN=Shikumi Lab CA" \
  -keyout ca.key -out ca.crt
openssl req -newkey rsa:2048 -nodes -subj "/CN=localhost" \
  -keyout server.key -out server.csr
SAN=DNS:localhost,IP:127.0.0.1,DNS:shikumi.test
printf '%s\n' "subjectAltName=$SAN" \
  "extendedKeyUsage=serverAuth" > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -days 825 \
  -extfile server.ext -out server.crt
openssl verify -CAfile ca.crt server.crt
