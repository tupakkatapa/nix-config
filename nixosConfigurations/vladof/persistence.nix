{ dataDir, lib, pkgs, ... }:
let
  # RAID1 pool: degraded keeps it mountable with one disk missing
  pool = subvol: {
    device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
    fsType = "btrfs";
    options = [ "compress=zstd:2" "noatime" "nofail" "degraded" "subvol=${subvol}" ];
  };

  nvme = subvol: {
    device = "/dev/disk/by-label/nvme";
    fsType = "btrfs";
    options = [ "compress=zstd:2" "noatime" "nofail" "subvol=${subvol}" ];
  };

  # Overrides kexec-tree.nix's tmpfs defaults
  neededForBoot = fs: lib.mkForce (fs // {
    neededForBoot = true;
    options = lib.remove "nofail" fs.options;
  });
in
{
  fileSystems = {
    "/home/kari/.config/gh" = pool "@kari-gh";
    "/home/kari/.local/share/atuin" = pool "@kari-atuin";
    "/home/kari/.local/share/zoxide" = pool "@kari-zoxide";
    "/home/kari/.local/share/Steam" = nvme "@kari-steam";
    "/home/kari/.claude/projects" = nvme "@kari-claude-projects";
    "/home/kari/Workspace" = nvme "@kari-workspace";

    "/var/log/journal" = pool "@var-log-journal";
    "/var/lib/acme" = pool "@acme";
    "/var/lib/prometheus" = pool "@prometheus";
    "/var/lib/loki" = pool "@loki";

    # agenix reads the SSH host key from here in stage 2
    "${dataDir}" = neededForBoot (pool "@main");
    # The subvolume must contain `store/` and `work/`
    "/nix/.rw-store" = neededForBoot (pool "@nix-rw-store");

    # The NVMe's top level, where btrbk keeps its snapshots
    "/mnt/nvme" = {
      device = "/dev/disk/by-label/nvme";
      fsType = "btrfs";
      options = [ "noatime" "nofail" "subvolid=5" ];
    };
  };

  # SSH host keys on disk
  services.openssh.hostKeys = [
    {
      path = "${dataDir}/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
    {
      path = "${dataDir}/ssh/ssh_host_rsa_key";
      type = "rsa";
      bits = 4096;
    }
  ];

  # Audit log on disk
  security.auditd.settings.log_file = "${dataDir}/home/root/logs/audit/audit.log";

  # Pin UIDs (acme not in nixpkgs static ids)
  users.users.acme.uid = 991;
  users.groups.acme.gid = 991;

  # Hourly snapshots of @main for recovery
  services.snapper = {
    snapshotInterval = "hourly";
    cleanupInterval = "1d";
    configs.wd-red = {
      SUBVOLUME = dataDir;
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 14;
      TIMELINE_LIMIT_WEEKLY = 8;
      TIMELINE_LIMIT_MONTHLY = 12;
      TIMELINE_LIMIT_YEARLY = 2;
    };
  };

  systemd.services.btrbk-nvme = {
    unitConfig.RequiresMountsFor = [ "/mnt/nvme" "${dataDir}/.btrbk/nvme" ];
    serviceConfig.ExecStartPre = "+${lib.getExe' pkgs.coreutils "mkdir"} -p /mnt/nvme/.btrbk";
  };
  services.btrbk.instances.nvme = {
    onCalendar = "hourly";
    settings = {
      snapshot_preserve_min = "2d";
      snapshot_preserve = "24h 7d";
      target_preserve_min = "no";
      target_preserve = "7d 4w";
      volume."/mnt/nvme" = {
        snapshot_dir = ".btrbk";
        target = "${dataDir}/.btrbk/nvme";
        subvolume = {
          "@kari-claude-projects" = { };
          "@kari-workspace" = { };
        };
      };
    };
  };

  # systembus-notify must match earlyoom's (both mkDefault)
  services.smartd = {
    enable = true;
    notifications.systembus-notify.enable = true;
  };

  # Repairs bad blocks from the RAID1 mirror
  services.btrfs.autoScrub = {
    enable = true;
    fileSystems = [ dataDir ];
  };

  # Persistent dir tree
  systemd.tmpfiles.rules = [
    "d ${dataDir}/ssh                            700 root root                                     -"
    "d ${dataDir}/sftp                           755 root root                                     -"
    "d ${dataDir}/home                           755 root root                                     -"
    "d ${dataDir}/home/root                      755 root root                                     -"
    "d ${dataDir}/home/root/logs                 755 root root                                     -"
    "d ${dataDir}/home/root/logs/audit           750 root root                                     -"

    "v ${dataDir}/.snapshots                     750 root root                                     -"
    "d ${dataDir}/.btrbk/nvme                    700 root root                                     -"

    # SFTP subdir ownership enforcement (container writes target these paths)
    "Z ${dataDir}/sftp/appdata                   -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/code                      -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/docs                      -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/games                     -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/media                     -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/sys                       -   sftp sftp                                     -"
    "Z ${dataDir}/sftp/tmp                       -   sftp sftp                                     -"

    # Ephemeral directories for users
    "d /home/kari/.config       755 kari kari -"
    "d /home/kari/.local        755 kari kari -"
    "d /home/kari/.local/share  755 kari kari -"
    "d /home/kari/.claude       755 kari kari -"

    # Enforce ownership on subvol mountpoints
    "Z /home/kari/.local/share/atuin    - kari kari -"
    "Z /home/kari/.local/share/zoxide   - kari kari -"
    "Z /home/kari/.config/gh            0700 kari kari -"
    "Z /home/kari/.claude/projects      - kari kari -"
    "d /home/kari/.local/share/Steam    755 kari kari -"
    "d /home/kari/Workspace             755 kari kari -"
  ];
}
