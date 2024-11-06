_:
let
  user = "kari";
  dataDir = "/mnt/860";
  appData = "${dataDir}/appdata/${user}";
  secretData = "${dataDir}/secrets/${user}";
  gameData = "${dataDir}/games/${user}";
in
{
  # Host SSH keys
  services.openssh.hostKeys = [{
    path = "${dataDir}/secrets/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Mount drives
  fileSystems."${dataDir}" = {
    device = "/dev/disk/by-uuid/20cfc618-e1e9-476e-984e-55326b3b5ca7";
    fsType = "ext4";
    neededForBoot = true;
  };
  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/CA7C-5C77";
    fsType = "auto";
  };

  # Create directories, not necessarily persistent
  systemd.tmpfiles.rules = [
    "d /mnt/boot                 755 root root -"
    "d /mnt/sftp                 755 root root -"

    "d ${dataDir}                755 root root -"
    "d ${dataDir}/appdata        755 root root -"
    "d ${dataDir}/nix-config     777 root root -"
    "d ${dataDir}/secrets        755 root root -"
    "d ${dataDir}/games          755 root root -"

    # Home
    "d /home/${user}/.config       755 ${user} ${user} -"
    "d /home/${user}/.local        755 ${user} ${user} -"
    "d /home/${user}/.local/share  755 ${user} ${user} -"

    # Apps
    "d ${appData}                755 ${user} ${user} -"
    "d ${appData}/firefox        755 ${user} ${user} -"
    "d ${appData}/guitarix       755 ${user} ${user} -"
    "d ${appData}/plexamp        755 ${user} ${user} -"
    "d ${appData}/sublime-merge  755 ${user} ${user} -"
    "d ${appData}/openrgb        755 ${user} ${user} -"

    # Games
    "d ${gameData}                      755 ${user} ${user} -"
    "d ${gameData}/osu-lazer            755 ${user} ${user} -"
    "d ${gameData}/anime-game-launcher  755 ${user} ${user} -"
    "d ${gameData}/runelite             755 ${user} ${user} -"
    "d ${gameData}/steam                755 ${user} ${user} -"
    "d ${gameData}/steam/install        755 ${user} ${user} -"

    # Secrets
    "d ${secretData}             700 ${user} ${user} -"
    "d ${secretData}/gnupg       700 ${user} ${user} -"
    "d ${secretData}/yubico      755 ${user} ${user} -"
  ];

  # Set local flake path to be able to be referenced
  environment.variables.FLAKE_DIR = "${dataDir}/nix-config";

  # Bind to persistent drive to preserve
  fileSystems = {
    "/home/${user}/nix-config" = {
      device = "${dataDir}/nix-config";
      options = [ "bind" "mode=777" ];
    };
    # Apps
    "/home/${user}/.mozilla" = {
      device = "${appData}/firefox";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/Plexamp" = {
      device = "${appData}/plexamp";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/guitarix" = {
      device = "${appData}/guitarix";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.config/sublime-merge" = {
      device = "${appData}/sublime-merge";
      options = [ "bind" "mode=700" ];
    };
    "/home/${user}/.config/OpenRGB" = {
      device = "${appData}/openrgb";
      options = [ "bind" "mode=755" ];
    };
    # Games
    "/home/${user}/.steam" = {
      device = "${gameData}/steam";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.local/share/Steam" = {
      device = "${gameData}/steam/install";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.local/share/anime-game-launcher" = {
      device = "${gameData}/anime-game-launcher";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.local/share/osu" = {
      device = "${gameData}/osu-lazer";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.runelite" = {
      device = "${gameData}/runelite";
      options = [ "bind" "mode=755" ];
    };
    # Secrets
    "/home/${user}/.config/Yubico" = {
      device = "${secretData}/yubico";
      options = [ "bind" "mode=755" ];
    };
    "/home/${user}/.gnupg" = {
      device = "${secretData}/gnupg";
      options = [ "bind" "mode=700" ];
    };
    "/home/${user}/.ssh" = {
      device = "${secretData}/ssh";
      options = [ "bind" "mode=700" ];
    };
  };
}
