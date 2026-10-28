# Add a Bluetooth device

Pairing keys live in agenix, not on disk. Each device is one secret that agenix decrypts straight into bluetoothd's state dir at boot, so pairings survive the ephemeral root.

```
/var/lib/bluetooth/<adapter MAC>/<device MAC>/info  <-  age.secrets.bt-<device>
```

Only `info` matters, it holds the link key. Adapter `settings` and `cache/` get rebuilt.

## 1) Pair

On the host, as usual:

```bash
bluetoothctl
[bluetooth]# agent on
[bluetooth]# default-agent
[bluetooth]# pairable on
[bluetooth]# scan on
[bluetooth]# pair <device MAC>
[bluetooth]# trust <device MAC>
```

Stay inside the interactive session. A one-shot `bluetoothctl -- pair` has no agent and the adapter is not pairable, so a device that asks for confirmation (Xbox controllers do) fails with `AuthenticationFailed`, or ends up `Paired: yes` but `Bonded: no`, which stores no link key. `bluetoothctl info <MAC>` must show `Bonded: yes` before the export.

## 2) Export

```bash
sudo find /var/lib/bluetooth -name info   # gives adapter + device MAC
sudo cat /var/lib/bluetooth/<adapter MAC>/<device MAC>/info
```

Copy the output, then on a host with the repo on local disk (agenix can't chmod over sshfs):

```bash
agenix edit nixosConfigurations/<host>/secrets/bt-<device>.age   # paste, save
```

## 3) Declare

`nixosConfigurations/<host>/default.nix`:

```nix
age.secrets.bt-<device> = {
  rekeyFile = ./secrets/bt-<device>.age;
  path = "/var/lib/bluetooth/<adapter MAC>/<device MAC>/info";
  symlink = false;
};
```

- `symlink = false`: bluetoothd rewrites `info`, so it gets a real file instead of a link into `/run/agenix`
- Adapter MAC differs per host, so the same device paired on two hosts is two secrets with different keys

## 4) Rekey and deploy

```bash
agenix rekey -a
git add nixosConfigurations/<host>/secrets
```

Rebuild, reboot, then `bluetoothctl devices Paired` lists it and it connects without pairing again.

## Re-pairing

A new pairing means a new link key, and the old secret silently stops working. Repeat 2) over the same `bt-<device>.age`, then 4).
