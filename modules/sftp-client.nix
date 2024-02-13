{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.sftpClient;
in {
  options.services.sftpClient = {
    enable = mkEnableOption "SFTP Client";

    user = mkOption {
      type = types.str;
      description = "User for the SFTP client.";
      example = "kari";
    };

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

    bindMounts = mkOption {
      type = types.listOf (types.submodule {
        options = {
          what = mkOption {
            type = types.str;
            description = "The source path of the bind mount.";
          };

          where = mkOption {
            type = types.str;
            description = "The target path of the bind mount.";
          };

          user = mkOption {
            type = types.str;
            default = cfg.user;
            description = "User owner of the bind mount.";
          };

          group = mkOption {
            type = types.str;
            default = cfg.user;
            description = "Group owner of the bind mount.";
          };

          mode = mkOption {
            type = types.int;
            default = 700;
            description = "File mode of the bind mount.";
          };
        };
      });
      default = [];
      description = "List of directories to bind mount.";
    };
  };

  config = mkIf cfg.enable {
    # Binds must be within the mount
    assertions =
      map (bindMount: {
        assertion = hasPrefix cfg.where bindMount.what;
        message = "Bind mount source ${bindMount.what} must be inside ${cfg.where}";
      })
      cfg.bindMounts;

    # Enable sshfs package for mounting SSH drives
    # https://nixos.org/manual/nixos/stable/#sec-sshfs-non-interactive
    system.fsPackages = [pkgs.sshfs];

    # Mount drives
    fileSystems."${cfg.where}" = {
      device = cfg.what;
      fsType = "sshfs";
      options = [
        "IdentityFile=${cfg.identifyFile}"
        "ServerAliveInterval=15"
        "_netdev"
        "allow_other"
        "reconnect"
        "x-systemd.automount"
      ];
    };

    # Better network online target
    # https://systemd.io/NETWORK_ONLINE/
    systemd.services.better-network-online = {
      description = "Check for network connectivity";
      wants = ["nss-lookup.target" "network-online.target"];
      after = ["nss-lookup.target" "network-online.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.iputils}/bin/ping -c 1 example.com; do ${pkgs.coreutils}/bin/sleep 1; done'";
      };
    };
    systemd.targets.better-network-online = {
      description = "Better network online target";
      wants = ["better-network-online.service"];
      after = ["better-network-online.service"];
      unitConfig.DefaultDependencies = "no";
    };

    # Trigger after SFTP mount
    systemd.services.sftp-mount-trigger = let
      sftpMountUnitName = replaceStrings ["/"] ["-"] (builtins.substring 1 (builtins.stringLength cfg.where - 1) cfg.where) + ".mount";
    in {
      description = "Trigger for SFTP Mount";
      after = [sftpMountUnitName];
      wants = [sftpMountUnitName];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.coreutils}/bin/sleep 5";
      };
    };

    # Bind directories from the SFTP mount
    systemd.mounts =
      map (bindMount: {
        description = "Bind mount for ${bindMount.where}";
        what = bindMount.what;
        where = bindMount.where;
        wantedBy = ["multi-user.target"];
        #wants = ["better-network-online.target" "sftp-mount-trigger.service"];
        #after = ["better-network-online.target" "sftp-mount-trigger.service"];
        #requires = ["sftp-mount-trigger.service"];
        options = concatStringsSep "," [
          "bind"
          "mode=${toString bindMount.mode}"
          "uid=${toString config.users.users.${bindMount.user}.uid}"
          "gid=${toString config.users.groups.${bindMount.group}.gid}"
        ];
      })
      cfg.bindMounts;
  };
}
