
# Add encrypted backup disk (`/dev/sdX`) and mirror primary Btrfs

Run on the target host (check `hostname`). Replace `<hostname>`, `/dev/sdX`, mount points, and by-id paths as needed. Primary Btrfs is assumed at `/mnt/data`; the new disk is `/dev/sdX`.

Quick shell with needed tools:

```bash
nix-shell -p btrfs-progs cryptsetup parted util-linux systemd
```

## 1) Prep and partition
- Check disks: `sudo lsblk -f` / `sudo blkid`; ensure `/dev/sdX` is the new empty disk.
- Partition full disk: `sudo parted /dev/sdX -- mklabel gpt mkpart primary 1MiB 100%`

## 2) LUKS + FIDO2 (two keys, destructive format)
- Format with temp pass: `sudo cryptsetup -v luksFormat /dev/sdX1` # destructive
- Open once: `sudo cryptsetup open /dev/sdX1 backup_crypt`
- Enroll key #1: `sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=true /dev/sdX1`
- Enroll key #2 and drop pass: `sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=true --wipe-slot=0 /dev/sdX1`
- Optional test: attach/detach with `systemd-cryptsetup attach|detach backup /dev/sdX1`

## 3) Add to Btrfs + convert to RAID1
- Unlock and keep open: `sudo systemd-cryptsetup attach backup /dev/sdX1` (mapper `/dev/mapper/backup`)
- Ensure `/mnt/data` is mounted
- Add + rebalance:\
  `sudo btrfs device add /dev/mapper/backup /mnt/data`\
  `sudo btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/data`
- Watch: `sudo btrfs balance status /mnt/data`; verify: `sudo btrfs filesystem show /mnt/data`

## 4) Boot wiring
- Find stable path: `ls -l /dev/disk/by-id | grep sdX1` → copy `/dev/disk/by-id/...-part1`
- Add to NixOS:\
  ```nix
  boot.initrd.luks.fido2Support = true;
  boot.initrd.luks.devices.backup = {
    device = "/dev/disk/by-id/<drive>-part1";
    crypttabExtraOpts = [ "fido2-device=auto" "fido2-with-client-pin=yes" ];
  };
  ```
- Remove any old separate mount and rebuild, then reboot

## 5) Post-checks
- `sudo btrfs filesystem show /mnt/data`
- `sudo btrfs device stats /mnt/data`
- `systemd-cryptenroll --fido2-device=list /dev/sdX1` to confirm tokens

## 6) Encrypt the original disk and re-mirror
- Verify pool healthy: `sudo btrfs device stats /mnt/data`
- Remove the unencrypted leg (swap your device/partition): `sudo btrfs device remove /dev/sdY2 /mnt/data` (data now only on the other disk)
- LUKS + FIDO2 on that partition :\
  `sudo cryptsetup -v luksFormat /dev/sdY2` # destructive\
  `sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=true /dev/sdY2`\
  `sudo systemd-cryptenroll --fido2-device=auto --fido2-with-client-pin=true --wipe-slot=0 /dev/sdY2`\
  `sudo systemd-cryptsetup attach primary /dev/sdY2` (mapper `/dev/mapper/primary`)
- Add back and rebalance:\
  `sudo btrfs device add /dev/mapper/primary /mnt/data`\
  `sudo btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/data`
- Boot wiring: add `boot.initrd.luks.devices.primary` with the by-id part for `/dev/sdY2`, rebuild, reboot

## Ad-hoc resync (manual backup)

If the backup disk isn't unlocked at boot (LUKS config commented out), use this to occasionally resync:

- Unlock: `sudo systemd-cryptsetup attach backup /dev/disk/by-id/<drive>-part1`
- Scan: `sudo btrfs device scan`
- Verify both devices visible: `sudo btrfs filesystem show /mnt/data`
- Rebalance unmirrored chunks: `sudo btrfs balance start -dprofiles=single /mnt/data`
- Monitor: `sudo btrfs balance status /mnt/data`
- When done, detach: `sudo systemd-cryptsetup detach backup`

If `-dprofiles=single` finds nothing, the array is already fully mirrored.

## References
- Multi-token FIDO2 LUKS: https://juuso.dev/blogPosts/fido2-luks/multi-token-fido2-luks.html
- agenix: https://github.com/ryantm/agenix
- agenix-rekey: https://github.com/oddlama/agenix-rekey
