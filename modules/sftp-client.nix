{ lib
, pkgs
, config
, ...
}:
let
  cfg = config.services.sftpClient;
in
{
  options.services.sftpClient = {
    enable = lib.mkEnableOption "SFTP Client";

    mounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          identifyFile = lib.mkOption {
            type = lib.types.str;
            description = "SSH identity file for the SFTP client.";
          };
          what = lib.mkOption {
            type = lib.types.str;
            description = "The SFTP source.";
          };
          where = lib.mkOption {
            type = lib.types.str;
            description = "Mount point for the SFTP source.";
          };
        };
      });
      default = [ ];
      description = "List of directories to bind mount.";
      example = [
        {
          identifyFile = "/home/user/.ssh/id_ed25519";
          what = "user@192.168.1.100:/path/to/remote/dir";
          where = "/mnt/my_sftp_mount";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sshfs package for mounting SSH drives
    system.fsPackages = [ pkgs.sshfs ];

    # Mount drives
    fileSystems = lib.listToAttrs (map
      (mount:
        lib.nameValuePair mount.where {
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
