{ pkgs
, lib
, config
, inputs
, ...
}:
let
  domain = "coditon.com";
  user = "kari";
  dataDir = "/mnt/wd-red";

  # Inherit global stuff for imports
  extendedArgs = { inherit pkgs lib config domain dataDir inputs; };
in
{
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEJktZ00i+OxH4Azi1tLkwoYrJ0qo2RIZ5huzzK+g2w root@vladof";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    (import ./services extendedArgs)
    (import ./persistence.nix extendedArgs)
    ../.config/motd.nix
    ../.config/pipewire.nix
    ../.config/yubikey.nix
    ./nixie.nix
    ./wireguard.nix
  ];

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Autologin for 'kari'
  services.getty.autologinUser = user;

  # Cage-kiosk (firefox)
  services.cage = {
    enable = true;
    inherit user;
    program = lib.concatStringsSep " \\\n\t" [
      "${config.home-manager.users."${user}".programs.firefox.package}/bin/firefox"
      "https://www.youtube.com"
      "http://10.233.1.14:32400" # plex
    ];
    environment = {
      XKB_DEFAULT_LAYOUT = "fi";
      HOME = "/home/${user}";
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

  # Networking
  networking = {
    hostName = "vladof";
    domain = "${domain}";
  };

  # SFTP Server
  services.sftpServer = {
    enable = true;
    dataDir = "${dataDir}/sftp";
    authorizedKeys = [
      # kari@phone (preferably removed, keep until YubiKey NFC for SFTP is possible)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"

      # kari@yubikey
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOdsfK46X5IhxxEy81am6A8YnHo2rcF2qZ75cHOKG7ToAAAACHNzaDprYXJp ssh:kari"
    ];
    extraGroups = [ "transmission" ];
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
