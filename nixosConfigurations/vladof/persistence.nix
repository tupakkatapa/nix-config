{ lib
, dataDir
, ...
}:
let
  # Persistent directories for each user
  # Data is stored under: dataDir/home/<user>/<category>/<dir>
  users = {
    acme = [{
      name = "appdata";
      dirs = [{ name = "acme"; mode = "700"; what = "/var/lib/acme"; }];
    }];
    vaultwarden = [{
      name = "appdata";
      dirs = [{ name = "vaultwarden"; mode = "700"; what = "/var/lib/vaultwarden"; }];
    }];
    transmission = [{
      name = "appdata";
      dirs = [{ name = "transmission"; mode = "700"; what = "/var/lib/transmission"; }];
    }];
    plex = [{
      name = "appdata";
      dirs = [{ name = "plex"; mode = "700"; what = "/var/lib/plex"; }];
    }];
    kavita = [{
      name = "appdata";
      dirs = [{ name = "kavita"; mode = "700"; what = "/var/lib/kavita"; }];
    }];
    root = [
      {
        # For compiling hosts that contain or are sourced from private inputs
        # Potentially required by the 'nixie' or 'refindGenerate' modules
        # You can remove this when Nixie is someday open-sourced
        name = "secrets";
        dirs = [{ name = "ssh"; mode = "700"; what = "/root/.ssh"; }];
      }
      {
        name = "appdata";
        dirs = [{ name = "nixie"; mode = "755"; what = "/var/www/netboot"; }];
      }
    ];
    kari = [{
      name = "appdata";
      dirs = [{ name = "firefox"; mode = "755"; what = "/home/kari/.mozilla"; }];
    }];
  };

  # Create tmpfiles rules for persistent directories under dataDir/home
  mkUserTmpfiles = user: categories:
    let
      parentRules = lib.concatMap
        (cat:
          [ "d ${dataDir}/home/${user}/${cat.name} 755 ${user} ${user} -" ]
        )
        categories;
      subdirRules = lib.concatMap
        (cat:
          map
            (d:
              "d ${dataDir}/home/${user}/${cat.name}/${d.name} ${d.mode} ${user} ${user} -"
            )
            cat.dirs
        )
        categories;
    in
    parentRules ++ subdirRules;

  # Create bind mount entries from persistent data into /home/<user>
  mkUserFileSystems = user: categories:
    lib.listToAttrs (lib.concatMap
      (cat:
        map
          (d: {
            name = d.what;
            value = {
              device = "${dataDir}/home/${user}/${cat.name}/${d.name}";
              options = [ "bind" "mode=${d.mode}" ];
            };
          })
          cat.dirs
      )
      categories);

  # Create the overall list of tmpfiles rules
  userHomeTmpfiles = lib.map (user: "d ${dataDir}/home/${user} 755 ${user} ${user} -") (lib.attrNames users);
  allUserTmpfiles = lib.concatLists (lib.attrValues (lib.mapAttrs (user: cats: mkUserTmpfiles user cats) users));
  allTmpfiles = userHomeTmpfiles ++ allUserTmpfiles;

  # All bind mounts for user persistent directories
  allFileSystems = lib.foldl' (acc: user: acc // (mkUserFileSystems user users.${user})) { } (lib.attrNames users);
in
{
  # Host SSH keys
  services.openssh.hostKeys = [{
    path = "${dataDir}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Mount persistent drives and user binds
  fileSystems = allFileSystems // {
    "${dataDir}" = {
      device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
      fsType = "btrfs";
      neededForBoot = true;
    };
    "/mnt/boot" = {
      device = "/dev/disk/by-uuid/C994-FCFD";
      fsType = "vfat";
    };
  };

  # Mount '/nix/.rw-store' and '/tmp' to disk
  services.nixRemount = {
    enable = true;
    where = "${dataDir}/store";
    type = "none";
    options = [ "bind" ];
  };

  # Update the rEFInd boot manager
  services.refindGenerate = {
    enable = true;
    where = "/dev/sda1";
    flakeUrl = "github:tupakkatapa/nix-config";
    hosts = [ "vladof" "bandit" ];
    default = "vladof";
    timeout = 1;
  };

  # Create directories
  systemd.tmpfiles.rules = allTmpfiles ++ [
    "d /mnt/boot          755 root root -"
    "d ${dataDir}         755 root root -"
    "d ${dataDir}/backups 700 root root -"
    "d ${dataDir}/home    755 root root -"
    "d ${dataDir}/sftp    755 root root -"
    "d ${dataDir}/ssh     700 root root -"
    "d ${dataDir}/store   755 root root -"
  ];
}
