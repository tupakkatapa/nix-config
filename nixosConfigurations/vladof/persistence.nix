{ dataDir, lib, ... }:
let
  device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
  # Auxiliary subvols: nofail (boot continues if missing). degraded allows missing RAID1 disk.
  aux = lib.mapAttrs (_: subvol: {
    inherit device;
    fsType = "btrfs";
    options = [ "compress=zstd:2" "noatime" "nofail" "degraded" "subvol=${subvol}" ];
  });
  # Boot-critical subvols: mounted in initrd, override kexec-tree defaults
  boot = lib.mapAttrs (_: subvol: lib.mkForce {
    inherit device;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "compress=zstd:2" "noatime" "degraded" "subvol=${subvol}" ];
  });
in
{
  fileSystems = aux
    {
      # User data
      "/home/kari/.config/mozilla" = "@kari-mozilla";
      "/home/kari/.config/sunshine" = "@kari-sunshine";
      "/home/kari/.local/share/atuin" = "@kari-atuin";
      "/home/kari/.local/share/zoxide" = "@kari-zoxide";

      # System state
      "/var/log/journal" = "@var-log-journal";
      "/var/lib/acme" = "@acme";
      "/var/lib/prometheus" = "@prometheus";
      "/var/lib/loki" = "@loki";
    } // boot {
    # dataDir: agenix reads SSH host key from here in stage-2
    "${dataDir}" = "@main";
    # Persistent nix rw-store (overrides kexec-tree.nix tmpfs).
    # Subvol must contain `store/` and `work/` subdirs (create on disk).
    "/nix/.rw-store" = "@nix-rw-store";
  } // {
    "/mnt/jhvst" = {
      device = "/dev/disk/by-label/jhvst";
      fsType = "btrfs";
    };
    "/mnt/archive" = {
      device = "/dev/disk/by-uuid/7716e9fc-2f0e-4398-b1ff-df6723a01d2c";
      fsType = "btrfs";
      options = [ "compress=zstd:9" "noatime" "nofail" ];
    };
  };

  # SSH host key on disk
  services.openssh.hostKeys = [{
    path = "${dataDir}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

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

  # Persistent dir tree
  systemd.tmpfiles.rules = [
    "d ${dataDir}/ssh                            700 root root                                     -"
    "d ${dataDir}/sftp                           755 root root                                     -"
    "d ${dataDir}/home                           755 root root                                     -"
    "d ${dataDir}/home/root                      755 root root                                     -"
    "d ${dataDir}/home/root/logs                 755 root root                                     -"
    "d ${dataDir}/home/root/logs/audit           750 root root                                     -"
    "d ${dataDir}/home/grafana                   755 grafana grafana                               -"
    "d ${dataDir}/home/grafana/appdata           755 grafana grafana                               -"
    "Z ${dataDir}/home/grafana/appdata/grafana   755 grafana grafana                               -"

    "v ${dataDir}/.snapshots                     750 root root                                     -"

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

    # Enforce ownership on subvol mountpoints
    "Z /home/kari/.config/mozilla       - kari kari -"
    "Z /home/kari/.config/sunshine      - kari kari -"
    "Z /home/kari/.local/share/atuin    - kari kari -"
    "Z /home/kari/.local/share/zoxide   - kari kari -"
  ];
}
