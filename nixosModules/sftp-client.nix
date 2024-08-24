{ lib, pkgs, config, ... }:

let
  cfg = config.services.sftpClient;
in
{
  options.services.sftpClient = {
    enable = lib.mkEnableOption "Enable the SFTP client service.";

    defaultIdentityFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Path to the default SSH identity file used by the SFTP client.";
      example = "/home/user/.ssh/id_rsa";
    };

    mounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          identityFile = lib.mkOption {
            type = lib.types.str;
            default = cfg.defaultIdentityFile;
            description = "Path to the SSH identity file for this specific mount.";
            example = "/home/user/.ssh/id_ed25519";
          };
          what = lib.mkOption {
            type = lib.types.str;
            description = "The remote location to mount using SFTP (e.g., user@host:/path).";
            example = "user@192.168.1.100:/";
          };
          where = lib.mkOption {
            type = lib.types.str;
            description = "Local directory where the remote location should be mounted.";
            example = "/mnt/sftp";
          };
        };
      });
      default = [ ];
      description = "A list of SFTP mounts that define what remote locations to mount and where.";
      example = [
        {
          identityFile = "/home/user/.ssh/id_ed25519";
          what = "user@192.168.1.100:/";
          where = "/mnt/sftp";
        }
      ];
    };

    binds = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          what = lib.mkOption {
            type = lib.types.str;
            description = "Local directory to be bind-mounted within the SFTP-mounted directory.";
            example = "/mnt/sftp/documents";
          };
          where = lib.mkOption {
            type = lib.types.str;
            description = "Target directory where the bind mount should be placed.";
            example = "/home/user/Documents";
          };
        };
      });
      default = [ ];
      description = "A list of bind mounts for local directories, typically used within the SFTP mounts.";
      example = [
        {
          what = "/mnt/sftp/docs";
          where = "/home/user/Documents";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sshfs package for mounting SSH drives
    system.fsPackages = [ pkgs.sshfs ];

    # Required to allow 'allow_other' option for fuse
    programs.fuse.userAllowOther = true;

    # Configure SFTP mounts and optional bind mounts
    fileSystems = lib.listToAttrs
      (map
        (mount:
          lib.nameValuePair mount.where {
            device = mount.what;
            fsType = "sshfs";
            options = [
              "IdentityFile=${mount.identityFile}"
              "ServerAliveInterval=15"
              "_netdev"
              "allow_other"
              "reconnect"
              "x-systemd.automount"
            ];
          })
        cfg.mounts
      ) // lib.listToAttrs (map
      (bind:
        lib.nameValuePair bind.where {
          device = bind.what;
          options = [ "bind" ];
        })
      cfg.binds);
  };
}
