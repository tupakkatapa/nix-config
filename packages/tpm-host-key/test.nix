{ pkgs
, tpm-host-key
}:
pkgs.runCommand "tpm-host-key-test" { nativeBuildInputs = [ tpm-host-key pkgs.swtpm pkgs.openssh pkgs.util-linux pkgs.age ]; } ''
  set -euo pipefail
  cd "$(mktemp -d)"
  # Fixed TPM state pins the derivation: a changed label, hash or template
  # would rotate every host's identity
  install -D -m 640 ${./tpm2-00.permall} state/tpm2-00.permall
  swtpm socket --tpm2 --tpmstate dir=state --server type=unixio,path=tpm.sock --ctrl type=unixio,path=tpm.sock.ctrl --flags startup-clear &
  export TPM2TOOLS_TCTI="swtpm:path=$PWD/tpm.sock"
  for _ in $(seq 50); do [ -S tpm.sock ] && break; sleep 0.1; done

  (umask 077; tpm-host-key a; tpm-host-key b)
  [[ $(cat a.pub) == "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpJM+d6zQmlTiJ+IAWi9ym8xaGGUrzH+uJYaVhVy0z7" ]]
  cmp a.pub b.pub
  ssh-keygen -yf a | cmp - a.pub
  [[ $(echo ok | age -e -R a.pub | age -d -i a) == ok ]]

  (umask 022; touch c; tpm-host-key c)
  [[ $(stat -c %a c) == 600 ]]
  cmp a.pub c.pub

  tpm-host-key -- d
  cmp a.pub d.pub

  # Activation runs before /etc/passwd exists and before nscd
  unshare -rm sh -c 'mount -t tmpfs none /etc && tpm-host-key e'
  cmp a.pub e.pub

  # Without a TPM nothing is written
  if TPM2TOOLS_TCTI=device:/nonexistent tpm-host-key f; then exit 1; fi
  [[ ! -e f && ! -e f.pub ]]
  if tpm-host-key; then exit 1; fi
  if tpm-host-key --bogus g; then exit 1; fi

  touch $out
''
