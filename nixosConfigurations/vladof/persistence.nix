{ dataDir, ... }:
{
  services.stateSaver = {
    enable = true;
    inherit dataDir;

    # Path to SSH host key, relative to data directory
    # Will be stored at: <dataDir>/<hostKeyPath>
    hostKeyPath = "ssh/ssh_host_ed25519_key";

    # Persistent directories for each user
    # Will be stored at: <dataDir>/home/<user>/<category>/<dir>
    persistentDirs = {
      acme = [
        {
          name = "appdata";
          dirs = [
            { name = "acme"; mode = "700"; what = "/var/lib/acme"; }
          ];
        }
      ];
      root = [
        {
          name = "secrets";
          dirs = [
            # For compiling hosts that contain or are sourced from private inputs
            # Potentially required by the 'nixie' or 'refindGenerate' modules
            # You can remove this when Nixie is someday open-sourced
            { name = "ssh"; mode = "700"; what = "/root/.ssh"; }
          ];
        }
        {
          name = "appdata";
          dirs = [
            { name = "nixie"; mode = "755"; what = "/var/www/netboot"; }
          ];
        }
      ];
      kari = [
        {
          name = "appdata";
          dirs = [
            { name = "firefox"; mode = "755"; what = "/home/kari/.mozilla"; }
          ];
        }
      ];
    };
  };

  # Mount persistent drives
  fileSystems = {
    "${dataDir}" = {
      device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
      fsType = "btrfs";
      neededForBoot = true;
    };
    "/mnt/boot" = {
      device = "/dev/disk/by-uuid/3C60-8E75";
      fsType = "vfat";
      neededForBoot = false;
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
    rollbacks.enable = true;
    where = "/dev/disk/by-uuid/3C60-8E75";
    flakeUrl = "github:tupakkatapa/nix-config";
    hosts = [ "vladof" "bandit" ];
    default = "vladof";
    timeout = 1;
  };

  # Create host-specific directories
  systemd.tmpfiles.rules = [
    "d /mnt/boot          755 root root -"
    "d ${dataDir}/backups  700 root root -"
    "d ${dataDir}/sftp     755 root root -"
  ];
}
