{ pkgs
, tpm-host-key
}:
pkgs.runCommand "tpm-host-key-test" { nativeBuildInputs = [ tpm-host-key pkgs.swtpm pkgs.openssh ]; } ''
  set -euo pipefail
  cd "$(mktemp -d)"
  mkdir state
  swtpm socket --tpm2 --tpmstate dir=state --server type=unixio,path=tpm.sock --ctrl type=unixio,path=tpm.sock.ctrl --flags startup-clear &
  export TPM2TOOLS_TCTI="swtpm:path=$PWD/tpm.sock"
  for _ in $(seq 50); do [ -S tpm.sock ] && break; sleep 0.1; done

  (umask 077; tpm-host-key a; tpm-host-key b)
  cmp a.pub b.pub
  ssh-keygen -yf a | cmp - a.pub
  [[ $(cut -d' ' -f1 a.pub) == ssh-ed25519 ]]

  touch $out
''
