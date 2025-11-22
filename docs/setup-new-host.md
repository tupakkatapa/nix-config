
# Setting up a new host

Quick shell with needed tools:

```bash
nix-shell -p git gnupg pam_u2f trezor-agent trezor-udev openssh
```

## 1) Init

- Create `./nixosConfigurations/<hostname>`
- Add a flake entry with core modules (user, nixosConfiguration, kexecTree, etc.)
- Skip `persistence.nix` import for the first image; no file systems yet
- Leave `age.rekey.hostPubkey` and `systemd.network.networks.<name>.matchConfig.Name` empty

## 2) Collect info

- Boot any installer image
- Partition/format drives; record UUIDs/labels via `blkid`; wire them in `<hostname>/persistence.nix`
- Record NIC names via `ip a`; add to `systemd.network.networks.<name>.matchConfig.Name`

## 3) Configure + secrets

- Boot into the new image; host SSH key is generated at the path set in `persistence.nix`
- Grab the host public key, set `age.rekey.hostPubkey`, then run `agenix-rekey -a`

YubiKey U2F (PAM):
```bash
nix-shell -p pam_u2f
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
```

Recover Trezor GPG key:
```bash
trezor-gpg init "Tupakkatapa <jesse@ponkila.com>" -v --time=<int>
```

## 4) Final boot

Rebuild with updated config and reboot; the host should come up with correct mounts, networking, and secrets.

## References
- YubiKey PAM U2F: https://nixos.wiki/wiki/Yubikey
- Trezor GPG: https://trezor.io/learn/advanced/standards-proposals/what-is-gpg
- agenix-rekey: https://github.com/oddlama/agenix-rekey
