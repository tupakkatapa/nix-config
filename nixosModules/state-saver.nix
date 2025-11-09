{ config, lib, ... }:
let
  cfg = config.services.stateSaver;
in
{
  options.services.stateSaver = {
    enable = lib.mkEnableOption "Whether to enable the state saver";

    dataDir = lib.mkOption {
      type = lib.types.str;
      description = "Base directory for persistent data";
      example = "/mnt/data";
    };

    hostKeyPath = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to SSH host key, relative to the data directory
        Will be stored at: <dataDir>/<hostKeyPath>
      '';
      default = "ssh/ssh_host_ed25519_key";
    };

    persistentDirs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            description = "Category name";
            example = "appdata";
          };
          dirs = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Directory name to be created under the data directory";
                  example = "firefox";
                };
                mode = lib.mkOption {
                  type = lib.types.str;
                  description = "Directory mode";
                  default = "755";
                  example = "700";
                };
                what = lib.mkOption {
                  type = lib.types.str;
                  description = "Target directory path to be persisted";
                  example = "/home/user/.mozilla";
                };
              };
            });
            description = "Directories in this category";
            default = [ ];
          };
        };
      }));
      default = { };
      description = ''
        Persistent directories for each user
        Will be stored at: <dataDir>/home/<user>/<category>/<dir>
      '';
      example = {
        alice = [
          {
            name = "appdata";
            dirs = [
              { name = "firefox"; mode = "755"; what = "/home/alice/.mozilla"; }
            ];
          }
          {
            name = "secrets";
            dirs = [
              { name = "ssh"; mode = "700"; what = "/home/alice/.ssh"; }
            ];
          }
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Host SSH key configuration
    services.openssh.hostKeys = [{
      path = "${cfg.dataDir}/${cfg.hostKeyPath}";
      type = "ed25519";
    }];

    # Create tmpfiles rules for persistent directories
    systemd.tmpfiles.rules =
      let
        # Create directory for SSH host key
        sshKeyDirs = [ "d ${cfg.dataDir}/${builtins.dirOf cfg.hostKeyPath} 700 root root -" ];

        # Rules for user home directories
        userHomeTmpfiles = lib.lists.map
          (user: "d ${cfg.dataDir}/home/${user} 755 ${user} ${user} -")
          (lib.attrNames cfg.persistentDirs);

        # Create tmpfiles rules for persistent directories under dataDir/home
        mkUserTmpfiles = user: categories:
          let
            # Create rules for category directories
            categoryRules = lib.lists.map
              (cat: "d ${cfg.dataDir}/home/${user}/${cat.name} 755 ${user} ${user} -")
              categories;

            # Create rules for subdirectories in each category
            subdirRules = lib.lists.concatMap
              (cat:
                lib.lists.map
                  (dir: "d ${cfg.dataDir}/home/${user}/${cat.name}/${dir.name} ${dir.mode} ${user} ${user} -")
                  cat.dirs
              )
              categories;
          in
          categoryRules ++ subdirRules;

        # Get all user tmpfiles rules
        allUserTmpfiles = lib.lists.concatLists
          (lib.attrsets.attrValues
            (lib.attrsets.mapAttrs
              (user: categories: mkUserTmpfiles user categories)
              cfg.persistentDirs
            )
          );
      in
      # Combine all rules
      [
        "d ${cfg.dataDir}      755 root root -"
        "d ${cfg.dataDir}/home 755 root root -"
      ] ++
      sshKeyDirs ++
      userHomeTmpfiles ++
      allUserTmpfiles;

    # Create bind mount entries from persistent data into appropriate locations
    fileSystems =
      let
        # Create bind mount entries from persistent data
        mkUserFileSystems = user: categories:
          lib.attrsets.listToAttrs (lib.lists.concatMap
            (cat:
              lib.lists.map
                (dir: {
                  name = dir.what;
                  value = {
                    device = "${cfg.dataDir}/home/${user}/${cat.name}/${dir.name}";
                    options = [ "bind" "mode=${dir.mode}" ];
                    depends = [ cfg.dataDir ];
                    neededForBoot = true;
                    noCheck = true;
                  };
                })
                cat.dirs
            )
            categories);

        # All bind mounts for user persistent directories
        allFileSystems = lib.lists.foldl'
          (acc: user: acc // (mkUserFileSystems user cfg.persistentDirs.${user}))
          { }
          (lib.attrNames cfg.persistentDirs);
      in
      allFileSystems;
  };
}
