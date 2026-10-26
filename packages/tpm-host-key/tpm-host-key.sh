#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit

# Part of every host's identity: changing it rotates every derived key
readonly label="nix-config tpm-host-key v1"
verbose=false

display_usage() {
  cat <<USAGE
Usage: tpm-host-key [OPTIONS] OUT

Description:
  Write an OpenSSH ed25519 host key to OUT and its public half to OUT.pub,
  derived from this machine's TPM: an HMAC by a deterministic primary in the
  endorsement hierarchy. Nothing is stored; the same TPM yields the same key
  on every run, also after tpm2_clear.

Options:
  -v, --verbose    Enable verbose output
  -h, --help       Show this help

Environment:
  TPM2TOOLS_TCTI   TPM connection (default: device:/dev/tpmrm0)
USAGE
}

# Output function with optional verbose-only mode and timestamps
# Usage:
#   say "message"          - always shown (with timestamp if verbose enabled)
#   say verbose "message"  - only shown when verbose flag is set
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

# Bytes travel as lowercase hex in shell variables and reach other programs
# only through pipes, so the key never touches the disk or an argument list
hex() { xxd -p | tr -d '\n'; }
unhex() { printf '%s' "$1" | xxd -r -p; }
sha256() { unhex "$1" | sha256sum | cut -d' ' -f1; }

# SSH wire string: a 4-byte big-endian length, then the bytes
sshstr() { printf '%08x%s' $((${#1} / 2)) "$1"; }

# 32 bytes only this TPM can produce: an HMAC of the label by a primary key
# that the TPM recreates from its endorsement seed and this exact template
tpm_secret() {
  local ctx="$1" mac

  unhex "$(sha256 "$(printf '%s' "$label" | hex)")" |
    tpm2_createprimary -Q -C e -G hmac -g sha256 \
      -a 'fixedtpm|fixedparent|sensitivedataorigin|userwithauth|sign' \
      -u - -c "$ctx"
  # Raw TPM devices and swtpm keep the transient primary loaded until flushed
  tpm2_flushcontext -t

  mac=$(printf '%s' "$label" | tpm2_hmac -c "$ctx" | hex)
  tpm2_flushcontext -t
  [[ $mac =~ ^[0-9a-f]{64}$ ]] || die "error: unexpected HMAC from the TPM"
  printf '%s' "$mac"
}

# The public key of an ed25519 seed: PKCS#8 for ed25519 is a fixed DER prefix
# and the seed, and the key is the last 32 bytes of its SubjectPublicKeyInfo
ed25519_public() {
  unhex "302e020100300506032b657004220420$1" |
    openssl pkey -inform DER -pubout -outform DER |
    tail -c 32 | hex
}

# The key as SSH encodes it: type name, then the 32 public bytes
ssh_public_blob() {
  sshstr "$(printf '%s' ssh-ed25519 | hex)"
  sshstr "$1"
}

# OpenSSH's private key format (PROTOCOL.key), unencrypted. ssh-keygen would
# write it, but aborts when getpwuid() fails, and activation runs before
# /etc/passwd exists.
openssh_private_key() {
  local seed="$1" pub="$2" blob="$3" none header private pad=1

  none=$(printf '%s' none | hex)
  # Magic, no cipher, no KDF, empty KDF options, one key
  header="$(printf 'openssh-key-v1\0' | hex)$(sshstr "$none")$(sshstr "$none")$(sshstr "")00000001"
  # Two equal check ints, the key, an empty comment, padded to the 8-byte block
  private="0000000000000000$blob$(sshstr "$seed$pub")$(sshstr "")"
  while (((${#private} / 2) % 8)); do
    private+=$(printf '%02x' "$pad")
    pad=$((pad + 1))
  done

  echo "-----BEGIN OPENSSH PRIVATE KEY-----"
  unhex "$header$(sshstr "$blob")$(sshstr "$private")" | base64 -w 70
  echo "-----END OPENSSH PRIVATE KEY-----"
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
    positional+=("$@")
    break
    ;;
  -*) die "error: unknown flag: $1" ;;
  *)
    positional+=("$1")
    shift
    ;;
  esac
done
[[ ${#positional[@]} -eq 1 ]] || {
  display_usage >&2
  exit 1
}
out="${positional[0]}"

for tool in tpm2_createprimary tpm2_hmac tpm2_flushcontext openssl xxd base64 sha256sum; do
  command -v "$tool" >/dev/null 2>&1 || die "error: $tool not found in PATH"
done

export TPM2TOOLS_TCTI="${TPM2TOOLS_TCTI:-device:/dev/tpmrm0}"
tmp=$(mktemp -d) && trap 'rm -rf "$tmp"' EXIT

say verbose "deriving from the TPM ($TPM2TOOLS_TCTI)"
secret=$(tpm_secret "$tmp/primary.ctx")
seed=$(sha256 "$secret")
pub=$(ed25519_public "$seed")
[[ $pub =~ ^[0-9a-f]{64}$ ]] || die "error: could not compute the public key"
blob=$(ssh_public_blob "$pub")

# Both files are built in full before either is written
private_key=$(openssh_private_key "$seed" "$pub" "$blob")
public_key="ssh-ed25519 $(unhex "$blob" | base64 -w 0)"

install -m 600 /dev/null "$out"
printf '%s\n' "$private_key" >"$out"
printf '%s\n' "$public_key" >"$out.pub"
say verbose "wrote $out and $out.pub"
