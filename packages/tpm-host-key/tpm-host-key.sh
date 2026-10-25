#!/usr/bin/env bash
set -euo pipefail

label="nix-config tpm-host-key v1"
verbose=false

say() {
  local message
  local verbose_only=false
  if [[ $1 == "verbose" ]]; then
    verbose_only=true
    shift
  fi
  message="$*"
  if [[ $verbose_only == true ]] && [[ $verbose == false ]]; then
    return
  fi
  if [[ $verbose == true ]]; then
    echo "[$(date '+%H:%M:%S')] $message" >&2
  else
    echo "$message" >&2
  fi
}

die() {
  say "$@"
  exit 1
}

display_usage() {
  cat <<USAGE
Usage: tpm-host-key [OPTIONS...] OUT

Description:
  Writes an OpenSSH ed25519 host key to OUT (and OUT.pub), derived from this
  machine's TPM: an HMAC by a deterministic endorsement-hierarchy primary.
  Nothing is stored anywhere; the same chip yields the same key every run.

Options:
  -v, --verbose          Enable verbose output.
  -h, --help             Show this help and exit.

Environment:
  TPM2TOOLS_TCTI         TPM connection (default: device:/dev/tpmrm0).
USAGE
}

positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
  -v | --verbose)
    verbose=true
    shift
    ;;
  -h | --help)
    display_usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  -*) die "unknown flag: $1" ;;
  *)
    positional+=("$1")
    shift
    ;;
  esac
done
[[ ${#positional[@]} -eq 1 ]] || die "expected exactly one OUT path"
out="${positional[0]}"

for tool in tpm2_createprimary tpm2_hmac python3 xxd; do
  command -v "$tool" >/dev/null 2>&1 || die "$tool not found in PATH"
done

export TPM2TOOLS_TCTI="${TPM2TOOLS_TCTI:-device:/dev/tpmrm0}"
tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT

printf '%s' "$label" | sha256sum | cut -d' ' -f1 | xxd -r -p >"$tmp/label"

say verbose "TPM: endorsement-hierarchy HMAC primary"
tpm2_createprimary -Q -C e -G hmac -g sha256 \
  -a 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' \
  -u - -c "$tmp/key.ctx" <"$tmp/label"
# Without a resource manager the transient primary keeps its slot until flushed
tpm2_flushcontext -t
printf '%s' "$label" | tpm2_hmac -Q -c "$tmp/key.ctx" -o "$tmp/seed.tpm"
tpm2_flushcontext -t
sha256sum "$tmp/seed.tpm" | cut -d' ' -f1 | xxd -r -p >"$tmp/seed"

python3 - "$tmp/seed" "$out" <<'PY'
import sys
from cryptography.hazmat.primitives import serialization as s
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
key = Ed25519PrivateKey.from_private_bytes(open(sys.argv[1], "rb").read())
with open(sys.argv[2], "wb") as f:
    f.write(key.private_bytes(s.Encoding.PEM, s.PrivateFormat.OpenSSH, s.NoEncryption()))
with open(sys.argv[2] + ".pub", "wb") as f:
    f.write(key.public_key().public_bytes(s.Encoding.OpenSSH, s.PublicFormat.OpenSSH) + b"\n")
PY
say verbose "wrote $out"
