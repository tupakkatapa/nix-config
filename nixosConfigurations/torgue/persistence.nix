{ pkgs, lib, ... }:
let
  dataDir = "/mnt/860";
  device = "/dev/disk/by-uuid/d69f5624-937a-453d-937c-eae63dd94b06";
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
      "/home/kari/.claude-mem" = "@kari-claude-mem";
      "/home/kari/.claude/projects" = "@kari-claude-projects";
      "/home/kari/.config/mozilla" = "@kari-mozilla";
      "/home/kari/.BitwigStudio" = "@kari-bitwig-config";
      "/home/kari/Bitwig Studio" = "@kari-bitwig-projects";
      "/home/kari/.config/Yubico" = "@kari-yubico";
      "/home/kari/.config/gh" = "@kari-gh";
      "/home/kari/.steam" = "@kari-steam-cfg";
      "/home/kari/.local/share/Steam" = "@kari-steam-install";
      "/home/kari/.gnupg" = "@kari-gnupg";
      "/home/kari/Workspace" = "@kari-workspace";
      "/home/kari/Downloads" = "@kari-downloads";
      "/home/kari/.local/share/atuin" = "@kari-atuin";
      "/home/kari/.local/share/zoxide" = "@kari-zoxide";

      # System state
      "/var/lib/ollama" = "@ollama";
      "/var/lib/bluetooth" = "@var-lib-bluetooth";
      "/var/log/journal" = "@var-log-journal";
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
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_yubikey"
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_yubikey_2"
        "IdentityFile=/home/kari/.ssh/id_ed25519_sk_trezor"
      ];
    };
  };

  # SSHFS support for /mnt/sftp
  system.fsPackages = [ pkgs.sshfs ];
  programs.fuse.userAllowOther = true;

  # Service path redirects into @main
  services.openssh.hostKeys = [{
    path = "${dataDir}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Audit log on disk
  security.auditd.settings.log_file = "${dataDir}/home/root/logs/audit/audit.log";

  # Pin ollama UID (not in nixpkgs static ids)
  users.users.ollama = {
    uid = 987;
    group = "ollama";
  };
  users.groups.ollama.gid = 987;

  # Parent dirs for nested subvol mountpoints
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                755 root root -"
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"
    "d /home/kari/.claude       755 kari kari -"
    "d /var/lib/ollama          755 ollama ollama -"
    "d /var/lib/ollama/models   755 ollama ollama -"

    # Enforce ownership on subvol mountpoints
    "Z /home/kari/.claude-mem              - kari kari -"
    "Z /home/kari/.claude/projects         - kari kari -"
    "Z /home/kari/.config/mozilla          - kari kari -"
    "Z /home/kari/.BitwigStudio            - kari kari -"
    "Z /home/kari/Bitwig\\x20Studio         - kari kari -"
    "Z /home/kari/.config/Yubico           - kari kari -"
    "Z /home/kari/.config/gh               0700 kari kari -"
    "Z /home/kari/.steam                   - kari kari -"
    "Z /home/kari/.local/share/Steam       - kari kari -"
    "Z /home/kari/.gnupg                   0700 kari kari -"
    "Z /home/kari/Workspace                - kari kari -"
    "Z /home/kari/Downloads                - kari kari -"
    "Z /home/kari/.local/share/atuin       - kari kari -"
    "Z /home/kari/.local/share/zoxide      - kari kari -"
  ];
}
