{
  lib,
  pkgs,
  config,
  ...
}:
with lib; let
  cfg = config.services.sftpClient;
in {
  options.services.sftpClient = {
    enable = mkEnableOption "SFTP Client";

    mounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          identifyFile = mkOption {
            type = types.str;
            default = "/home/${cfg.user}/.ssh/id_ed25519";
            description = "SSH identity file for the SFTP client.";
          };

          what = mkOption {
            type = types.str;
            description = "The SFTP source.";
            example = "sftp@192.168.1.8:/";
          };

          where = mkOption {
            type = types.str;
            default = "/mnt/sftp";
            description = "Mount point for the SFTP source.";
          };
        };
      });
      default = [];
      description = "List of directories to bind mount.";
    };
  };

  config = mkIf cfg.enable {
    # Enable sshfs package for mounting SSH drives
    system.fsPackages = [pkgs.sshfs];

    # Mount drives
    fileSystems = listToAttrs (map (mount:
      nameValuePair mount.where {
        device = mount.what;
        fsType = "sshfs";
        options = [
          "IdentityFile=${mount.identifyFile}"
          "ServerAliveInterval=15"
          "_netdev"
          "allow_other"
          "reconnect"
          "x-systemd.automount"
        ];
      })
    cfg.mounts);
  };
}
