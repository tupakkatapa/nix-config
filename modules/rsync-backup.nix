{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.rsyncBackup;
in {
  options.services.rsyncBackup = {
    enable = lib.mkEnableOption "Enable rsync backup service";

    backupFrequencyHours = lib.mkOption {
      type = lib.types.int;
      default = 12;
      description = "How often to run the backup, in hours.";
    };

    paths = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          src = lib.mkOption {
            type = lib.types.str;
            description = "Source path to backup. Follows rsync syntax, can be a remote path.";
          };
          dest = lib.mkOption {
            type = lib.types.str;
            description = "Destination path for the backup. Follows rsync syntax, can be a remote path.";
          };
          extraFlags = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Extra flags to pass to rsync.";
          };
        };
      });
      default = [];
      description = "List of path pairs to backup. Paths can be files or directories.";
      example = [
        {
          src = "/home/user/documents";
          dest = "/backup/documents";
          extraFlags = "--delete";
        }
        {
          src = "/home/user/pictures";
          dest = "user@remote-server:/remote/backup/pictures";
          extraFlags = "--progress";
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.rsync-backup = {
      description = "Rsync backup service for multiple paths";
      path = [pkgs.rsync];
      script =
        lib.concatMapStringsSep "\n" (path: ''
          echo "Starting backup from ${path.src} to ${path.dest}"
          ${pkgs.rsync}/bin/rsync -a ${path.extraFlags} ${path.src} ${path.dest}
        '')
        cfg.paths;
      serviceConfig.Type = "oneshot";
    };

    systemd.timers.rsync-backup = {
      description = "Timer for rsync backup service";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min"; # run once right after boot
        OnUnitActiveSec = "${toString cfg.backupFrequencyHours}h";
      };
    };
  };
}
