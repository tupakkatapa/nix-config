{ pkgs, lib, ... }:
let
  dataDir = "/mnt/lenovo";
  device = "/dev/disk/by-uuid/9425613c-6e4f-41d2-8f67-7473e523a6bf";
  # Auxiliary subvols: nofail (boot continues if missing)
  aux = lib.mapAttrs (_: subvol: {
    inherit device;
    fsType = "btrfs";
    options = [ "compress=zstd:2" "noatime" "nofail" "subvol=${subvol}" ];
  });
  # Boot-critical subvols: mounted in initrd, override kexec-tree defaults
  boot = lib.mapAttrs (_: subvol: lib.mkForce {
    inherit device;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "compress=zstd:2" "noatime" "subvol=${subvol}" ];
  });
in
{
  fileSystems = aux
    {
      # User data
      "/home/kari/.config/mozilla" = "@kari-mozilla";
      "/home/kari/.config/Yubico" = "@kari-yubico";
      "/home/kari/.local/share/atuin" = "@kari-atuin";
      "/home/kari/.local/share/zoxide" = "@kari-zoxide";

      # System state
      "/var/lib/bluetooth" = "@var-lib-bluetooth";
    } // boot {
    # dataDir: agenix reads SSH host key from here in stage-2
    "${dataDir}" = "@main";
    # Persistent nix rw-store (overrides kexec-tree.nix tmpfs).
    # Subvol must contain `store/` and `work/` subdirs (create on disk).
    "/nix/.rw-store" = "@nix-rw-store";
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

  # Parent dirs for nested subvol mountpoints + ephemeral user dirs
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                755 root root -"
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"

    # Enforce ownership on subvol mountpoints
    "Z /home/kari/.config/mozilla          - kari kari -"
    "Z /home/kari/.config/Yubico           - kari kari -"
    "Z /home/kari/.local/share/atuin       - kari kari -"
    "Z /home/kari/.local/share/zoxide      - kari kari -"
  ];
}
