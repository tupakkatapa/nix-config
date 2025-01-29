{ pkgs
, lib
, config
, ...
}:
let
  domain = "coditon.com";

  user = "kari";
  dataDir = "/mnt/wd-red";
  appData = "${dataDir}/appdata";
  secretData = "${dataDir}/secrets";

  # Inherit global stuff for imports
  extendedArgs = { inherit pkgs lib config domain dataDir appData secretData; };
in
{
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    (import ./nixie.nix extendedArgs)
    (import ./services extendedArgs)
    ../.config/motd.nix
    ../.config/pipewire.nix
  ];

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Host SSH keys
  services.openssh.hostKeys = [{
    path = "${secretData}/ssh/ssh_host_ed25519_key";
    type = "ed25519";
  }];

  # Autologin for 'kari'
  services.getty.autologinUser = user;

  # Cage-kiosk (firefox)
  services.cage = {
    enable = true;
    inherit user;
    program = lib.concatStringsSep " \\\n\t" [
      "${config.home-manager.users."${user}".programs.firefox.package}/bin/firefox"
      "https://www.youtube.com"
      "http://127.0.0.1:32400" # plex
    ];
    environment = {
      XKB_DEFAULT_LAYOUT = "fi";
    };
  };
  systemd.services.cage-tty1 = {
    serviceConfig = {
      Restart = "always";
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  # Enable blobs
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Bind firefox directory to preserve cookies and such
  fileSystems."/home/${user}/.mozilla" = {
    device = "${appData}/firefox";
    options = [ "bind" "mode=755" ];
  };

  # Networking
  networking = {
    hostName = "vladof";
    domain = "${domain}";
  };

  # Extra SSH/SFTP settings (in addition to openssh.nix)
  services.openssh = {
    allowSFTP = lib.mkForce true;
    extraConfig = ''
      Match User sftp
        AllowTcpForwarding no
        ChrootDirectory %h
        ForceCommand internal-sftp
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
  };

  # SFTP user/group
  users.users."sftp" = {
    createHome = true;
    isSystemUser = true;
    useDefaultShell = false;
    group = "sftp";
    extraGroups = [
      "sshd"
      "transmission"
    ];
    home = "${dataDir}/sftp";
    homeMode = "770";
    openssh.authorizedKeys.keys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SFTP is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
    ];
  };
  users.groups."sftp" = { };

  # Create directories, not necessarily persistent
  systemd.tmpfiles.rules = [
    "d /mnt/boot          755 root root -"
    "d ${dataDir}         755 root root -"
    "d ${dataDir}/sftp    755 root root -"
    "d ${dataDir}/store   755 root root -"

    "d ${appData}         777 root root -"
    "d ${appData}/firefox 755 ${user} ${user} -"
  ];

  # Mount drives
  fileSystems."${dataDir}" = {
    device = "/dev/disk/by-uuid/a11f36c2-e601-4e6c-b8c2-136c4b07203e";
    fsType = "btrfs";
    # options = ["subvolid=420"];
    neededForBoot = true;
  };
  fileSystems."/mnt/boot" = {
    device = "/dev/disk/by-uuid/C994-FCFD";
    fsType = "vfat";
  };

  # Security
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      # Whitelisting some subnets:
      "10.0.0.0/8"
      "172.16.0.0/12"
      "192.168.0.0/16"
    ];
    bantime = "24h";
    bantime-increment = {
      enable = true; # Enable increment of bantime after each violation
      multipliers = "1 2 4 8 16 32 64";
      maxtime = "168h"; # Do not ban for more than 1 week
      overalljails = true; # Calculate the bantime based on all the violations
    };
    jails = {
      apache-nohome-iptables = ''
        # Block an IP address if it accesses a non-existent
        # home directory more than 5 times in 10 minutes,
        # since that indicates that it's scanning.
        filter = apache-nohome
        action = iptables-multiport[name=HTTP, port="http,https"]
        logpath = /var/log/httpd/error_log*
        backend = auto
        findtime = 600
        bantime  = 600
        maxretry = 5
      '';
    };
  };
  services.sshguard.enable = true;
}
