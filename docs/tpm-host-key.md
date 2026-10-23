# SSH host key from the TPM

An ephemeral host needs one secret of its own: the SSH host key, which is also its agenix identity. Sealed to the host's TPM, the key ships inside the boot image as a blob and is unsealed at boot, so no data disk is needed for identity.

```
boot  ->  activation: systemd-creds decrypt blob  ->  /etc/ssh/ssh_host_ed25519_key  ->  agenix, sshd
```

The blob is useless on any other machine, so it lives in the repo. Anyone who can boot their own code on the machine can unseal it, which is the same exposure as a plaintext key on its disk.

## 1) Check the TPM

```bash
ls /dev/tpm*                                    # tpm0 + tpmrm0
systemd-analyze has-tpm2                        # yes, everything +
test ! -e /run/systemd/tpm2-pcr-public-key.pem  # no signed PCR policy (UKI boots only)
```

## 2) Seal

On the host, from the current key:

```bash
sudo systemd-creds encrypt --with-key=tpm2 --name=ssh-host-key /etc/ssh/ssh_host_ed25519_key /tmp/ssh-host-key.cred
sudo chown $USER /tmp/ssh-host-key.cred
cp /tmp/ssh-host-key.cred <repo>/nixosConfigurations/<host>/ssh-host-key.cred
```

- `--with-key=tpm2`, always. The default `host+tpm2` also needs `/var/lib/systemd/credential.secret`, which a tmpfs root regenerates every boot
- No PCRs are bound by default, so kernel and initrd rebuilds don't matter. A TPM clear, a firmware reset or a board swap do
- `--name` is checked at decrypt; keep it the same in 3)

## 3) Declare

`nixosConfigurations/<host>/`:

```nix
{ config, ... }: {
  services.openssh.hostKeys = [{ path = "/etc/ssh/ssh_host_ed25519_key"; type = "ed25519"; }];

  # Before agenix, which reads its identity from hostKeys
  system.activationScripts.hostKeyUnseal = {
    deps = [ "specialfs" ];
    text = ''
      key=/etc/ssh/ssh_host_ed25519_key
      if [ ! -e "$key" ]; then
        install -d -m 755 /etc/ssh
        if (umask 077; ${config.systemd.package}/bin/systemd-creds decrypt --name=ssh-host-key ${./ssh-host-key.cred} "$key.tmp"); then
          mv "$key.tmp" "$key"
          echo tpm > /run/host-key-source
        else
          rm -f "$key.tmp"
          echo "host key: TPM unseal failed" >&2
          echo none > /run/host-key-source
        fi
      fi
    '';
  };
  system.activationScripts.agenixInstall.deps = [ "hostKeyUnseal" ];
}
```

- Activation snippets are one script: no `exit`, skip with `if`, and keep `umask` in a subshell. A leaked `umask 077` makes the user setup write `/etc/passwd` as 0600, which `nscd` can't read, and every user lookup on the host fails
- Explicit modes (`install -d -m 755`, `-m 600`), never the umask
- Skipping an existing key keeps a `nixos-rebuild test` from touching a running system
- sshd generates any `hostKeys` file that is missing, silently giving the host a new identity. While switching over, keep the disk copy as the fallback in the `else` branch (`install -m 600 <disk key> "$key"`, marker `disk`), and drop it after two `tpm` boots
- One ed25519 key only; the fleet's `knownHosts` are ed25519

## 4) Verify

After a reboot from the new image:

```bash
cat /run/host-key-source                 # tpm
ls /run/agenix                           # secrets decrypted
ssh-keyscan -t ed25519 <ip>              # matches services.openssh.knownHosts.<host>
journalctl -b | grep stage-2-init        # unseal errors land here
```

## Reseal

Needed after a TPM clear, firmware reset or board swap. The key is unchanged, so nothing else moves: mount the old `@main` subvolume by hand, repeat 2) from its `ssh/ssh_host_ed25519_key`, rebuild the image.

A lost key is a new host: update `age.rekey.hostPubkey`, `services.openssh.knownHosts`, vladof's `nixremote` keys, then `agenix rekey -a`.
