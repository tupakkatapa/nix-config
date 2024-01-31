{
  inputs,
  pkgs,
  lib,
  config,
  ...
} @ args: let
  domain = "coditon.com";
  address = "192.168.1.8";
  gateway = "192.168.1.1";
  interface = "enp0s31f6";

  appData = "/mnt/wd-red/appdata";
  username = "kari";

  # Inherit global stuff for containers
  extendedArgs = args // {inherit appData domain interface;};
in {
  imports = [
    (import ./containers extendedArgs)
    ./config/motd.nix
    ./config/ssh.nix
  ];

  # No bootloader
  boot.loader.grub.enable = false;

  # Enable NIC driver for stage-1
  boot.kernelPatches = [
    {
      name = "kernel nic config (vladof)";
      patch = null;
      extraConfig = ''
        E1000E y
        ETHERNET y
        NET_VENDOR_INTEL y
      '';
    }
  ];

  # Autologin for 'kari'
  services.getty.autologinUser = "kari";

  # Audio settings
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Cage-kiosk (firefox)
  services.cage = {
    enable = true;
    user = username;
    program = lib.concatStringsSep " \\\n\t" [
      "${config.home-manager.users."${username}".programs.firefox.package}/bin/firefox"
      "https://www.youtube.com"
      "https://plex.coditon.com"
      "https://www.twitch.tv"
      "https://kick.com"
    ];
    environment = {
      XKB_DEFAULT_LAYOUT = "fi";
    };
  };
  systemd.services.cage-tty1 = {
    serviceConfig = {
      Restart = "always";
    };
    wants = ["network-online.target"];
    after = ["network-online.target"];
  };
  hardware.opengl.enable = true;

  # Bind firefox directory to preserve cookies and such
  fileSystems."/home/${username}/.mozilla" = {
    device = "${appData}/firefox";
    options = ["bind" "mode=755"];
  };

  # Networking
  networking = {
    hostName = "vladof";
    domain = "${domain}";
    useNetworkd = true;

    interfaces.${interface}.ipv4.addresses = [
      {
        address = address; # static IP
        prefixLength = 24;
      }
    ];
    defaultGateway = {
      address = gateway;
      interface = interface;
    };
    nameservers = [gateway];
    firewall.enable = true;
  };
  systemd.network.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /mnt/wd-red        755 root root -"
    "d /mnt/wd-red/sftp   755 root root -"
    "d ${appData}         770 root root -"
    "d ${appData}/firefox 755 ${username} ${username} -"
  ];

  # Mounts
  fileSystems."/mnt/wd-red" = {
    device = "/dev/disk/by-uuid/779bb7b3-9ce8-49df-9ade-4f50b379bed9";
    fsType = "ext4";
    options = ["noatime"];
    neededForBoot = true;
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
}
