
# Setting up a new host

## Init

- Create a host directory at `./nixosConfiguration/<hostname>`
- Add a flake entry with the necessary modules, including at least `user`, `nixosConfiguration`, and `kexecTree`
- Do not import `persistence.nix`; file systems should not be configured at this stage
- Keep `age.rekey.hostPubkey` and `systemd.network.networks.<name>.matchConfig.Name` empty

## Get info

- Boot the target machine with any suitable image
- Format the drives. Note their UUIDs or labels using `blkid`, then configure the file systems in `persistence.nix`
- Note the interfaces using `ip a`, then add them to the `systemd.network.networks.<name>.matchConfig.Name` array

## Setup

Boot into the newly configured image. The host SSH key is generated to the defined location in `persistence.nix`. Take the public key, set `age.rekey.hostPubkey` to its value, then run `agenix-rekey -a`.

Setup Yubikey's u2f:
```
nix-shell -p pam_u2f
mkdir -p ~/.config/Yubico
pamu2fcfg > ~/.config/Yubico/u2f_keys
```
Reference: https://nixos.wiki/wiki/Yubikey

Recover Trezor's GPG key:
```
trezor-gpg init "Tupakkatapa <jesse@ponkila.com>" -v --time=<int>
```
Reference: https://trezor.io/learn/advanced/standards-proposals/what-is-gpg

## Final boot

The host is now ready for use.



