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

    # Create local mount points
    systemd.tmpfiles.rules = lib.concatLists [
      (map
        (mount:
          "d ${mount.where} 755 root root -"
        )
        cfg.mounts)
      (map
        (bind:
          "d ${bind.where} 755 root root -"
        )
        cfg.binds)
    ];

    # Scripts for mounting and unmounting
    environment.systemPackages = lib.optional
      ((cfg.mounts != [ ] || cfg.binds != [ ]) && (!cfg.defaults.autoMount))
      (pkgs.runCommand "sftp-utils" { }
        ''
              mkdir -p $out/bin

              # sftp-mount script
              cat > $out/bin/sftp-mount <<EOF
          #!/usr/bin/env bash
          set -euo pipefail

          echo "Mounting SFTP filesystems..."

          for info in ${lib.concatStringsSep " " (map (m:
            "${lib.escapeShellArg m.where}=${lib.escapeShellArg m.identityFile}"
          ) cfg.mounts)}; do

            path=\$(expr "\$info" : '\([^=]*\)')
            ident=\$(expr "\$info" : '[^=]*=\(.*\)')

            if [ -n "\$ident" ] && [ ! -f "\$ident" ]; then
              echo "WARNING: Identity file '\$ident' does not exist."
            fi

            echo " -> Mounting \$path"
            mount "\$path"
          done

          echo
          echo "Mounting bind filesystems..."

          for bp in ${lib.concatStringsSep " " (map (b: lib.escapeShellArg b.where) cfg.binds)}; do
            echo " -> \$bp"
            mount "\$bp"
          done

          echo
          echo "All done."
          EOF
              chmod +x $out/bin/sftp-mount

              # sftp-unmount script
              cat > $out/bin/sftp-unmount <<EOF
          #!/usr/bin/env bash
          set -euo pipefail

          echo "Unmounting bind filesystems..."

          for bp in ${lib.concatStringsSep " " (lib.lists.reverseList (map (b: lib.escapeShellArg b.where) cfg.binds))}; do
            echo " -> \$bp"
            umount "\$bp" || echo "WARNING: Failed to unmount \$bp"
          done

          echo
          echo "Unmounting SFTP filesystems..."

          for info in ${lib.concatStringsSep " " (lib.lists.reverseList (map (m: lib.escapeShellArg m.where) cfg.mounts))}; do
            echo " -> \$info"
            umount "\$info" || echo "WARNING: Failed to unmount \$info"
          done

          echo
          echo "All done."
          EOF
              chmod +x $out/bin/sftp-unmount
        '');
  };
}
