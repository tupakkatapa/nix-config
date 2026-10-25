# tpm-host-key: host key derived from the TPM

Ephemeral hosts have no disk to keep an SSH host key on. `services.tpmHostKey` derives one ed25519 key at every boot from the machine's TPM and uses it as the sshd host key, the agenix identity and the remote-builder key. Nothing secret is stored; only the public key is in git.

## How it works

A TPM can recreate a key instead of storing it. Give it the same template (key type, attributes, a label) and it computes the same key from a seed burned into the chip at manufacture. tpm-host-key uses that:

1. `tpm2_createprimary -C e -G hmac`: the TPM recomputes an HMAC key **K** from its endorsement seed and our fixed template. K never leaves the chip.
2. `tpm2_hmac`: the TPM computes **X** = HMAC-SHA256(K, `"nix-config tpm-host-key v1"`). 32 bytes come out, the same every boot.
3. The script hashes X into an ed25519 seed and writes the key to `/run/tpm-host-key/ssh_host_ed25519_key` (tmpfs, 0600), before agenix runs. sshd, agenix and nix-daemon all read that one file.

The endorsement seed survives `tpm2_clear`; on firmware TPMs it is tied to the CPU. The private key exists only in RAM, so whoever can boot code on this board can derive it, same as with any key the machine can unlock by itself.

## Enable on a host

```nix
services.tpmHostKey.enable = true;
```

Learn the public key on the host:

```bash
nix build .#tpm-host-key -o /tmp/bm
sudo /tmp/bm/bin/tpm-host-key /tmp/k && cat /tmp/k.pub
```

Put it in `age.rekey.hostPubkey` and the host's `knownHosts` entry, `agenix rekey -a`, rebuild. Check:

```bash
cat /run/host-key-source                          # derived
sudo ssh-keygen -lf /run/tpm-host-key/ssh_host_ed25519_key.pub
```

Without a working TPM the marker reads `none`, sshd starts without a host key and secrets stay sealed. Nothing is generated in its place.

## Rotation and loss

A new CPU, a changed template or label: new key. Recovery is `agenix rekey -a` from the master identities and new `knownHosts` entries. Nothing to restore.
