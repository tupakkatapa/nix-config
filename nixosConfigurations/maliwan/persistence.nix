{ pkgs, ... }:
let
  # On-demand mounts from vladof (YubiKey-resident key, requires touch)
  sshfs = device: {
    inherit device;
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
in
{
  fileSystems = {
    "/mnt/sftp" = sshfs "sftp@10.42.0.8:/";
    # As kari, at vladof's own path
    "/home/kari/Workspace" = sshfs "kari@10.42.0.8:/home/kari/Workspace";
    "/home/kari/.BitwigStudio" = sshfs "kari@10.42.0.8:/home/kari/.BitwigStudio";
  };

  # SSHFS support
  system.fsPackages = [ pkgs.sshfs ];
  programs.fuse.userAllowOther = true;

  # Mountpoints; home parents owned by kari, else nested tmpfiles and agenix paths create them as root
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                755 root root -"
    "d /home/kari/Workspace     755 kari kari -"
    "d /home/kari/.BitwigStudio 755 kari kari -"
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"
  ];
}
