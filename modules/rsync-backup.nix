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

    folders = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          source = lib.mkOption {
            type = lib.types.path;
            description = "Source folder to backup.";
          };
          destination = lib.mkOption {
            type = lib.types.path;
            description = "Destination folder for the backup.";
          };
        };
      });
      default = [];
      description = "List of folder pairs to backup.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.rsyncBackup = {
      description = "Rsync backup service for multiple folders";
      path = [pkgs.rsync];
      script =
        lib.concatMapStringsSep "\n" (folder: ''
          echo "Starting backup from ${folder.source} to ${folder.destination}"
          ${pkgs.rsync}/bin/rsync -a ${folder.source}/ ${folder.destination}
        '')
        cfg.folders;
      serviceConfig.Type = "oneshot";
    };

    systemd.timers.rsyncBackup = {
      description = "Timer for rsync backup service";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "5min"; # run once right after boot
        OnUnitActiveSec = "${toString cfg.backupFrequencyHours}h";
      };
    };
  };
}
