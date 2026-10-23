{ pkgs, config, ... }:
{
  # On-demand SFTP mount from vladof (YubiKey-resident key, requires touch)
  fileSystems."/mnt/sftp" = {
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

  # SSHFS support for /mnt/sftp
  system.fsPackages = [ pkgs.sshfs ];
  programs.fuse.userAllowOther = true;

  # Unsealed from the TPM before agenix, which reads it as its identity
  services.openssh.hostKeys = [{
    path = "/etc/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];
  system.activationScripts.hostKeyUnseal = {
    deps = [ "specialfs" ];
    text = ''
      # Snippets share one shell, so the umask stays scoped
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

  # SFTP mountpoint; home parents owned by kari, else nested tmpfiles and agenix paths create them as root
  systemd.tmpfiles.rules = [
    "d /mnt/sftp                755 root root -"
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"
  ];
}
