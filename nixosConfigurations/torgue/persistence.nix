{ lib, ... }:

let
  dataDir = "/mnt/860";

  # Persistent directories for each user.
  # Data is stored under: dataDir/home/<user>/<category>/<dir>
  users = {
    kari = [
      {
        name = "appdata";
        dirs = [
          { name = "firefox"; mode = "755"; mountPoint = ".mozilla"; }
          { name = "plexamp"; mode = "755"; mountPoint = ".config/Plexamp"; }
          { name = "guitarix"; mode = "755"; mountPoint = ".config/guitarix"; }
          { name = "sublime-merge"; mode = "755"; mountPoint = ".config/sublime-merge"; }
          { name = "openrgb"; mode = "755"; mountPoint = ".config/OpenRGB"; }
          { name = "discord"; mode = "755"; mountPoint = ".config/discord"; }
        ];
      }
      {
        name = "games";
        dirs = [
          { name = "steam"; mode = "755"; mountPoint = ".steam"; }
          { name = "steam/install"; mode = "755"; mountPoint = ".local/share/Steam"; }
          { name = "bottles"; mode = "755"; mountPoint = ".local/share/bottles"; }
          { name = "games"; mode = "755"; mountPoint = "Games"; }
          { name = "anime-game-launcher"; mode = "755"; mountPoint = ".local/share/anime-game-launcher"; }
          { name = "osu-lazer"; mode = "755"; mountPoint = ".local/share/osu"; }
          { name = "runelite"; mode = "755"; mountPoint = ".runelite"; }
        ];
      }
      {
        name = "secrets";
        dirs = [
          { name = "gnupg"; mode = "700"; mountPoint = "gnupg"; }
          { name = "yubico"; mode = "755"; mountPoint = ".config/Yubico"; }
          { name = "ssh"; mode = "700"; mountPoint = ".ssh"; }
        ];
      }
      {
        name = "other";
        dirs = [
          { name = "nix-config"; mode = "755"; mountPoint = "nix-config"; }
        ];
      }
    ];
  };

  # Create tmpfiles rules for persistent directories under dataDir/home.
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

  # Create bind mount entries from persistent data into /home/<user>.
  mkUserFileSystems = user: categories:
    lib.listToAttrs (lib.concatMap
      (cat:
        map
          (d: {
            name = "/home/${user}/${d.mountPoint}";
            value = {
              device = "${dataDir}/home/${user}/${cat.name}/${d.name}";
              options = [ "bind" "mode=${d.mode}" ];
            };
          })
          cat.dirs
      )
      categories);

  # Create the overall list of tmpfiles rules.
  userHomeTmpfiles = lib.map (user: "d ${dataDir}/home/${user} 755 ${user} ${user} -") (lib.attrNames users);
  allUserTmpfiles = lib.concatLists (lib.attrValues (lib.mapAttrs (user: cats: mkUserTmpfiles user cats) users));
  allTmpfiles = [ "d ${dataDir}/home 755 root root -" ] ++ userHomeTmpfiles ++ allUserTmpfiles;

  # All bind mounts for user persistent directories.
  allFileSystems = lib.foldl' (acc: user: acc // (mkUserFileSystems user users.${user})) { } (lib.attrNames users);

  # Ephemeral directories to be created under /home/<user>.
  userEphemeralTmpfiles = lib.concatMap
    (user: [
      "d /home/${user}/.config 755 ${user} ${user} -"
      "d /home/${user}/.local 755 ${user} ${user} -"
      "d /home/${user}/.local/share 755 ${user} ${user} -"
      "d /home/${user}/.ssh 700 ${user} ${user} -"
    ])
    (lib.attrNames users);
in
{
  # Host SSH key (stored under dataDir/ssh) and other host-specific items.
  services.openssh.hostKeys = [{
    path = "${dataDir}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  fileSystems = allFileSystems // {
    "${dataDir}" = {
      device = "/dev/disk/by-uuid/20cfc618-e1e9-476e-984e-55326b3b5ca7";
      fsType = "ext4";
      neededForBoot = true;
    };
    "/mnt/boot" = {
      device = "/dev/disk/by-uuid/CA7C-5C77";
      fsType = "auto";
    };
  };

  # Set a flake directory variable if needed.
  environment.variables.FLAKE_DIR = "${dataDir}/nix-config";

  systemd.tmpfiles.rules = allTmpfiles ++ userEphemeralTmpfiles ++ [
    "d /mnt/boot          755 root root -"
    "d /mnt/sftp          755 root root -"
    "d ${dataDir}         755 root root -"
    "d ${dataDir}/home    755 root root -"
    "d ${dataDir}/ssh     700 root root -"
  ];
}
