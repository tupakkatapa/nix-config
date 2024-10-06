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

    defaultIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Default SSH identity file for the SFTP client.";
    };

    mounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          identityFile = lib.mkOption {
            type = lib.types.str;
            default = cfg.defaultIdentityFile;
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
          identityFile = "/home/user/.ssh/id_ed25519";
          what = "user@192.168.1.100:/path/to/remote/dir";
          where = "/mnt/my_sftp_mount";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sshfs package for mounting SSH drives
    system.fsPackages = [ pkgs.sshfs ];

    # “fusermount3: option allow_other only allowed if ‘user_allow_other’ is set in /etc/fuse.conf”
    programs.fuse.userAllowOther = true;

    # Mount drives
    fileSystems = lib.listToAttrs (map
      (mount:
        lib.nameValuePair mount.where {
          device = mount.what;
          fsType = "sshfs";
          options = [
            "nodev"
            "noatime"
            "idmap=user"
            "IdentityFile=${mount.identityFile}"
            "ServerAliveInterval=15"
            "_netdev"
            "allow_other"
            "reconnect"
            "x-systemd.automount"
            "x-systemd.idle-timeout=600"
            "port=22"
          ];
        })
      cfg.mounts);
  };
}
