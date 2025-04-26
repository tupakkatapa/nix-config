_:
let
  dataDir = "/mnt/860";
in
{
  services.stateSaver = {
    enable = true;
    inherit dataDir;

    # Path to SSH host key, relative to dataDir
    # Will be stored at: dataDir/ssh/ssh_host_ed25519_key
    hostKeyPath = "ssh/ssh_host_ed25519_key";

    # Persistent directories for each user
    # Will be stored at: dataDir/home/<user>/<category>/<dir>
    persistentDirs = {
      kari = [
        {
          name = "appdata";
          dirs = [
            { name = "firefox"; mode = "755"; what = "/home/kari/.mozilla"; }
            { name = "guitarix"; mode = "755"; what = "/home/kari/.config/guitarix"; }
            { name = "discord"; mode = "755"; what = "/home/kari/.config/discord"; }
          ];
        }
        {
          name = "games";
          dirs = [
            { name = "steam"; mode = "755"; what = "/home/kari/.steam"; }
            { name = "steam/install"; mode = "755"; what = "/home/kari/.local/share/Steam"; }
            { name = "games"; mode = "755"; what = "/home/kari/Games"; }
            { name = "anime-game-launcher"; mode = "755"; what = "/home/kari/.local/share/anime-game-launcher"; }
            { name = "osu-lazer"; mode = "755"; what = "/home/kari/.local/share/osu"; }
            { name = "runelite"; mode = "755"; what = "/home/kari/.runelite"; }
            { name = "bottles"; mode = "755"; what = "/home/kari/.local/share/bottles"; }
            { name = "minecraft"; mode = "755"; what = "/home/kari/.local/share/PrismLauncher"; }
          ];
        }
        {
          name = "secrets";
          dirs = [
            { name = "gnupg"; mode = "700"; what = "/home/kari/.gnupg"; }
            { name = "yubico"; mode = "755"; what = "/home/kari/.config/Yubico"; }
            { name = "ssh"; mode = "700"; what = "/home/kari/.ssh"; }
          ];
        }
        {
          name = "other";
          dirs = [
            { name = "nix-config"; mode = "755"; what = "/home/kari/nix-config"; }
          ];
        }
      ];
    };
  };

  # Mount persistent drives
  fileSystems = {
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

  # Mount '/nix/.rw-store' and '/tmp' to disk
  services.storeRemount = {
    enable = true;
    where = "${dataDir}/store";
    type = "none";
    options = [ "bind" ];
  };

  # Update the rEFInd boot manager
  services.refindGenerate = {
    enable = true;
    where = "/dev/disk/by-uuid/CA7C-5C77";
    flakeUrl = "github:tupakkatapa/nix-config";
    hosts = [ "bandit" ];
    timeout = 1;
  };

  # Create host-specific directories
  systemd.tmpfiles.rules = [
    "d /mnt/boot          755 root root -"
    "d /mnt/sftp          755 root root -"

    # Ephemeral directories for users
    "d /home/kari/.config 755 kari kari -"
    "d /home/kari/.local 755 kari kari -"
    "d /home/kari/.local/share 755 kari kari -"
    "d /home/kari/.ssh 700 kari kari -"
  ];
}
