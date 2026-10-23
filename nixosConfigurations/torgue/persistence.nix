{ pkgs, lib, ... }:
let
  dataDir = "/mnt/860";
  device = "/dev/disk/by-uuid/d69f5624-937a-453d-937c-eae63dd94b06";
  # Boot-critical subvols: mounted in initrd, override kexec-tree defaults
  boot = lib.mapAttrs (_: subvol: lib.mkForce {
    inherit device;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "compress=zstd:2" "noatime" "subvol=${subvol}" ];
  });
in
{
  fileSystems = boot
    {
      # dataDir: agenix reads SSH host key from here in stage-2
      "${dataDir}" = "@main";
    } // {
    # On-demand SFTP mount from vladof (YubiKey-resident key, requires touch)
    "/mnt/sftp" = {
      device = "sftp@10.42.0.8:/";
      fsType = "sshfs";
      options = [
        "nodev"
        "noatime"
        "idmap=user"
        "ServerAliveInterval=15"
        "_netdev"
        "allow_other"
        "reconnect"
        "noauto"
        "port=22"
        # Defaults are 1s, so every lookup is a round trip; 20s bounds how
        # stale a container-written file can look
        "attr_timeout=20"
        "entry_timeout=20"
        "auto_cache"
        "ConnectTimeout=10"
        "IdentityAgent=none"
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_yubikey"
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_yubikey_2"
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_trezor"
      ];
    };
  };

  # SSHFS support for /mnt/sftp
  system.fsPackages = [ pkgs.sshfs ];
  programs.fuse.userAllowOther = true;

  # SSH host keys on disk
  services.openssh.hostKeys = [
    {
      path = "${dataDir}/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "${dataDir}/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # SFTP mountpoint; home parents owned by kari, else nested tmpfiles and agenix paths create them as root
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                755 root root -"
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"
  ];
}
