{ lib, pkgs, config, ... }:
let
  cfg = config.services.sftpClient;

  # Base SSFS options
  sftpFsBaseOptions = [
    "nodev"
    "noatime"
    "idmap=user"
    "ServerAliveInterval=15"
    "_netdev"
    "allow_other"
    "reconnect"
  ];

  # Compile SFTP filesystem
  sftpFileSystems =
    lib.listToAttrs (map
      (m: {
        name = m.where;
        value = {
          device = m.what;
          fsType = "sshfs";
          options =
            (if m.autoMount
            then sftpFsBaseOptions ++ [ "x-systemd.automount" "x-systemd.idle-timeout=600" ]
            else sftpFsBaseOptions ++ [ "noauto" ]
            )
            ++ [ "port=${m.port}" ]
            ++ [ "IdentityFile=${m.identityFile}" ];
        };
      })
      cfg.mounts);

  # Compile systemd deps for binds
  mkBindDependencies = bindMount:
    builtins.concatLists (
      lib.attrsets.mapAttrsToList
        (mountpoint: _sftpAttrs:
          if lib.hasPrefix mountpoint bindMount.what then
            [
              "x-systemd.requires=${lib.escapeShellArg mountpoint}.mount"
              "x-systemd.after=${lib.escapeShellArg mountpoint}.mount"
            ]
          else
            [ ]
        )
        sftpFileSystems
    );

  # Base bind options
  bindBaseOptions = [ "bind" ];

  # Compile bind filesystems
  bindFileSystems =
    lib.listToAttrs (map
      (m: {
        name = m.where;
        value = {
          device = m.what;
          fsType = "none";
          options =
            (if m.autoMount
            then bindBaseOptions ++ [ "x-systemd.automount" "x-systemd.idle-timeout=600" ]
            else bindBaseOptions ++ [ "noauto" ]
            )
            # Systemd ordering
            ++ mkBindDependencies m;
        };
      })
      cfg.binds);
in
{
  options.services.sftpClient = {
    enable = lib.mkEnableOption "Enable SFTP mount.";

    defaults = {
      identityFile = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Default SSH identity file.";
      };

      port = lib.mkOption {
        type = lib.types.str;
        default = "22";
        description = "Default SFTP port.";
      };

      autoMount = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "If true, it is auto-mounted via systemd; otherwise, run `sftp-mount` manually. The script is available in `$PATH`.";
      };
    };

    mounts = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          identityFile = lib.mkOption {
            type = lib.types.str;
            default = cfg.defaults.identityFile;
            description = "SSH identity file for the mount.";
          };
          port = lib.mkOption {
            type = lib.types.str;
            default = cfg.defaults.port;
            description = "Port for SFTP.";
          };
          autoMount = lib.mkOption {
            type = lib.types.bool;
            default = cfg.defaults.autoMount;
            description = "If true, it is auto-mounted via systemd; otherwise, run `sftp-mount` manually. The script is available in `$PATH`.";
          };
          what = lib.mkOption {
            type = lib.types.str;
            description = "SFTP source (e.g., user@host:/remote/path).";
          };
          where = lib.mkOption {
            type = lib.types.str;
            description = "Local mount point.";
          };
        };
      });
      default = [ ];
      description = "List of SFTP mounts.";
    };

    binds = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          what = lib.mkOption {
            type = lib.types.str;
            description = "Local path to bind from.";
          };
          where = lib.mkOption {
            type = lib.types.str;
            description = "Local path to bind to.";
          };
          autoMount = lib.mkOption {
            type = lib.types.bool;
            default = cfg.defaults.autoMount;
            description = "If true, it is auto-mounted via systemd; otherwise, run `sftp-mount` manually. The script is available in `$PATH`.";
          };
        };
      });
      default = [ ];
      description = "Bind mounts with automatic dependency handling on SFTP mounts.";
    };
  };

  config = lib.mkIf cfg.enable {

    # We need SSHFS and 'allow_other' for FUSE
    system.fsPackages = [ pkgs.sshfs ];
    programs.fuse.userAllowOther = true;

    # Merge SFTP + bind definitions into fileSystems
    fileSystems = lib.mkMerge [
      sftpFileSystems
      bindFileSystems
    ];

    # If autoMount = false, generate a script to be able to mount them manually
    environment.systemPackages = lib.optional
      ((cfg.mounts != [ ] || cfg.binds != [ ]) && (!cfg.defaults.autoMount))
      (pkgs.writeShellScriptBin "sftp-mount" ''
        #!/usr/bin/env bash
        set -euo pipefail

        echo "Mounting SFTP filesystems..."

        # For each mount, we pass "where=identityFile" as "WHERE=IDENT"
        for info in ${lib.concatStringsSep " " (map (m:
          "${lib.escapeShellArg m.where}=${lib.escapeShellArg m.identityFile}"
        ) cfg.mounts)}; do

          # Split "WHERE=IDENT"
          path=$(expr "$info" : '\([^=]*\)')
          ident=$(expr "$info" : '[^=]*=\(.*\)')

          # Check identity file if not empty
          if [ -n "$ident" ] && [ ! -f "$ident" ]; then
            echo "WARNING: Identity file '$ident' does not exist."
          fi

          echo " -> Mounting $path"
          mount "$path"
        done

        echo
        echo "Mounting bind filesystems..."

        for bp in ${lib.concatStringsSep " " (map (b: lib.escapeShellArg b.where) cfg.binds)}; do
          echo " -> $bp"
          mount "$bp"
        done

        echo
        echo "All done."
      '');
  };
}
