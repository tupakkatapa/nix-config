#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# CA cert (install on devices)
openssl req -x509 -newkey rsa:4096 -keyout ca-key.pem -out ca-cert.pem \
  -days 3650 -nodes -subj "/CN=Coditon CA" \
  -addext "basicConstraints = critical, CA:TRUE, pathlen:0" \
  -addext "keyUsage = critical, keyCertSign, cRLSign"

# Server cert signed by CA (used by Caddy)
openssl req -newkey rsa:4096 -keyout server-key.pem -out server.csr \
  -nodes -subj "/CN=*.coditon.com"
openssl x509 -req -in server.csr -CA ca-cert.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -days 3650 \
  -extfile <(printf '%s\n' \
    "subjectAltName = DNS:*.coditon.com, DNS:coditon.com" \
    "basicConstraints = CA:FALSE" \
    "keyUsage = digitalSignature, keyEncipherment" \
    "extendedKeyUsage = serverAuth")

# Store server key in agenix
rm -f "$(pwd)/../../secrets/server-key.age"
agenix edit -i "$(pwd)/server-key.pem" "$(pwd)/../../secrets/server-key.age"

# Cleanup
rm -f ca-key.pem server-key.pem server.csr ca-cert.srl
