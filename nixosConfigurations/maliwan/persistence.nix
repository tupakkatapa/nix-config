_:
let
  dataDir = "/mnt/lenovo";
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
            { name = "claude-projects"; mode = "755"; what = "/home/kari/.claude/projects"; }
            { name = "firefox"; mode = "755"; what = "/home/kari/.mozilla"; }
            { name = "gh"; mode = "755"; what = "/home/kari/.config/gh"; }
            { name = "gcloud"; mode = "755"; what = "/home/kari/.config/gcloud"; }
            { name = "pulumi"; mode = "755"; what = "/home/kari/.pulumi"; }
            { name = "doppler"; mode = "700"; what = "/home/kari/.doppler"; }
          ];
        }
        {
          name = "secrets";
          dirs = [
            { name = "gnupg"; mode = "700"; what = "/home/kari/.gnupg"; }
            { name = "yubico"; mode = "755"; what = "/home/kari/.config/Yubico"; }
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
      device = "/dev/disk/by-uuid/f0a9f000-da9e-4c5b-b06f-350670fde327";
      fsType = "ext4";
      neededForBoot = true;
    };
    # "/mnt/boot" = {
    #   device = "/dev/disk/by-uuid/<uuid>";
    #   fsType = "auto";
    # };
  };

  # Mount '/nix/.rw-store' and '/tmp' to disk
  services.storeRemount = {
    enable = true;
    where = "${dataDir}/store";
    type = "none";
    options = [ "bind" ];
  };

  # Update the rEFInd boot manager
  # services.refindGenerate = {
  #   enable = true;
  #   where = "/dev/disk/by-uuid/<uuid-2>";
  #   flakeUrl = "github:tupakkatapa/nix-config";
  #   hosts = [ "bandit" ];
  #   timeout = 1;
  # };

  # Create host-specific directories
  systemd.tmpfiles.rules = [
    "d /mnt/boot          755 root root -"
    "d /mnt/sftp          755 root root -"
    "d ${dataDir}/store   755 root root -"

    # Ephemeral directories for users
    "d /home/kari/.config 755 kari kari -"
    "d /home/kari/.local 755 kari kari -"
    "d /home/kari/.local/share 755 kari kari -"
    "d /home/kari/.claude 755 kari kari -"
  ];
}

