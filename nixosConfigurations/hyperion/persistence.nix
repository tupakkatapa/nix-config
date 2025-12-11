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
            { name = "fail2ban"; mode = "755"; what = "/var/lib/fail2ban"; }
          ];
        }
        {
          name = "logs";
          dirs = [
            { name = "journal"; mode = "755"; what = "/var/log/journal"; }
            { name = "rsyslog"; mode = "755"; what = "/var/log/rsyslog"; }
          ];
        }
      ];
      unbound = [
        {
          name = "appdata";
          dirs = [
            { name = "unbound"; mode = "755"; what = "/var/lib/unbound"; }
          ];
        }
      ];
      chrony = [
        {
          name = "appdata";
          dirs = [
            { name = "chrony"; mode = "755"; what = "/var/lib/chrony"; }
          ];
        }
      ];
      vnstatd = [
        {
          name = "appdata";
          dirs = [
            { name = "vnstat"; mode = "755"; what = "/var/lib/vnstat"; }
          ];
        }
      ];
    };
  };

  # Mount persistent drives
  fileSystems = {
    "${dataDir}" = {
      device = "/dev/disk/by-uuid/2422225e-29a0-480f-9be0-ebabe7ea7e5e";
      fsType = "btrfs";
      neededForBoot = true;
    };
    "/mnt/boot" = {
      device = "/dev/disk/by-uuid/2A10-2D31";
      fsType = "vfat";
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
    dataDir = "${dataDir}/home/root/appdata/refind";
    rollbacks = {
      enable = true;
      keep = 4;
    };
    where = "/dev/disk/by-uuid/2A10-2D31";
    flakeUrl = "github:tupakkatapa/nix-config";
    hosts = [ "hyperion" "bandit" ];
    default = "hyperion";
    timeout = 1;
  };

  # Create host-specific directories
  systemd.tmpfiles.rules = [
    "d /mnt/boot           755 root root -"
    "d ${dataDir}/store    755 root root -"
  ];
}
