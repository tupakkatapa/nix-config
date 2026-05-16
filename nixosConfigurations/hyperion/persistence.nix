{ dataDir, lib, ... }:
let
  device = "/dev/disk/by-uuid/2422225e-29a0-480f-9be0-ebabe7ea7e5e";
  # Auxiliary subvols: nofail (boot continues if missing)
  aux = lib.mapAttrs (_: subvol: {
    inherit device;
    fsType = "btrfs";
    options = [ "compress=zstd:2" "noatime" "nofail" "subvol=${subvol}" ];
  });
  # Boot-critical subvols: mounted in initrd, override kexec-tree defaults
  boot = lib.mapAttrs (_: subvol: lib.mkForce {
    inherit device;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "compress=zstd:2" "noatime" "subvol=${subvol}" ];
  });
in
{
  fileSystems = aux
    {
      "/var/log/journal" = "@var-log-journal";

      # Service state — modules without stateDir option get own subvol at default path
      "/var/lib/kea" = "@kea";
      "/var/lib/vnstat" = "@vnstat";
      "/var/lib/cloudflare-dyndns" = "@cloudflare-dyndns";
      "/var/log/kea" = "@kea-logs";
      "/var/log/rsyslog" = "@rsyslog";
    } // boot {
    # dataDir: agenix reads SSH host key from here in stage-2
    "${dataDir}" = "@main";
    # Persistent nix rw-store (overrides kexec-tree.nix tmpfs).
    # Subvol must contain `store/` and `work/` subdirs (create on disk).
    "/nix/.rw-store" = "@nix-rw-store";
  } // {
    "/mnt/boot" = {
      device = "/dev/disk/by-uuid/2A10-2D31";
      fsType = "vfat";
    };
  };

  # SSH host key on disk
  services.openssh.hostKeys = [{
    path = "${dataDir}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Audit log on disk
  security.auditd.settings.log_file = "${dataDir}/home/root/logs/audit/audit.log";

  # rEFInd boot manager
  services.refindGenerate = {
    enable = true;
    dataDir = "${dataDir}/home/root/appdata/refind";
    prune = true;
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

  # Persistent dir tree
  systemd.tmpfiles.rules = [
    "d /mnt/boot                                 755 root root                                     -"
    "d ${dataDir}/ssh                            700 root root                                     -"
    "d ${dataDir}/home                           755 root root                                     -"
    "d ${dataDir}/home/root                      755 root root                                     -"
    "d ${dataDir}/home/root/appdata              755 root root                                     -"
    "d ${dataDir}/home/root/appdata/refind       755 root root                                     -"
    "d ${dataDir}/home/root/logs                 755 root root                                     -"
    "d ${dataDir}/home/root/logs/audit           750 root root                                     -"
    "d ${dataDir}/home/unbound                   755 unbound unbound                               -"
    "d ${dataDir}/home/unbound/appdata           755 unbound unbound                               -"
    "Z ${dataDir}/home/unbound/appdata/unbound   755 unbound unbound                               -"
    "d ${dataDir}/home/chrony                    755 chrony chrony                                 -"
    "d ${dataDir}/home/chrony/appdata            755 chrony chrony                                 -"
    "Z ${dataDir}/home/chrony/appdata/chrony     755 chrony chrony                                 -"
  ];
}
