{
  pkgs,
  lib,
  config,
  ...
}: let
  domain = "coditon.com";
  serviceDataDir = "/mnt/wd-red/appdata";
in {
  # imports = [
  #   ./plasma-bigscreen.nix
  # ];

  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Extends 'system/patches/init1-network.nix'
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

  # Localization and basic stuff
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";
  console.keyMap = "fi";

  # Networking
  networking = {
    hostName = "vladof";
    domain = "${domain}";
    useNetworkd = true;
    firewall = {
      allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];
      allowedUDPPorts = [
        #67 # DHCP
        #69 # TFTP
        #514 # Syslog
        51820 # WG
      ];
    };
  };
  systemd.network.enable = true;

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    # Root
    "d /mnt/wd-red        775 kari kari -"
    "d /mnt/wd-red/sftp   775 sftp sftp -"
    "d /mnt/wd-red/share  770 caddy sftp -"
    # AppData
    "d ${serviceDataDir}                770 kari appdata -"
    "d ${serviceDataDir}/vaultwarden    700 vaultwarden vaultwarden -"
  ];

  # Mounts
  fileSystems."/mnt/wd-red" = {
    device = "/dev/disk/by-uuid/779bb7b3-9ce8-49df-9ade-4f50b379bed9";
    fsType = "ext4";
    options = ["noatime"];
    neededForBoot = true;
  };

  # Strict SSH/SFTP settings
  services.openssh = {
    enable = true;
    allowSFTP = true;
    extraConfig = ''
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
      Match User sftp
        AllowTcpForwarding no
        ChrootDirectory %h
        ForceCommand internal-sftp
        PermitTunnel no
        X11Forwarding no
      Match all
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    hostKeys = [
      {
        path = "/mnt/wd-red/secrets/ssh/ssh_host_ed25519_key";
        type = "ed22519";
      }
    ];
  };

  # Secrets
  sops = {
    secrets = {
      "wireguard/mullvad".sopsFile = ../secrets.yaml;
    };
    age.sshKeyPaths = [
      "/mnt/wd-red/secrets/ssh/ssh_host_ed25519_key"
    ];
  };

  # Message of the day
  programs.rust-motd = {
    enable = true;
    enableMotdInSSHD = true;
    settings = {
      banner = {
        color = "yellow";
        command = ''
          ${pkgs.inetutils}/bin/hostname | tr 'a-z' 'A-Z' | ${pkgs.figlet}/bin/figlet -f rectangles
          systemctl --failed --quiet
        '';
      };
      uptime.prefix = "Uptime:";
      last_login = builtins.listToAttrs (map
        (user: {
          name = user;
          value = 2;
        })
        (builtins.attrNames config.home-manager.users));
    };
  };

  # ACME
  fileSystems."/var/lib/acme" = {
    device = "/mnt/wd-red/appdata/acme";
    options = ["bind"];
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "jesse@ponkila.com";
  security.acme.defaults.webroot = "/mnt/wd-red/acme";

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
      # "vladof.${domain}" = {
      #   useACMEHost = config.networking.fqdn;
      #   extraConfig = ''
      #     reverse_proxy http://127.0.0.1:80
      #   '';
      # };
      "plex.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://127.0.0.1:32400
        '';
      };
      "torrent.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://127.0.0.1:9091
        '';
      };
      "radarr.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://127.0.0.1:7878
        '';
      };
      "jackett.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://127.0.0.1:9117
        '';
      };
      "share.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://localhost:4001
          file_server /mnt/wd-red/share
        '';
      };
      "vault.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://127.0.0.1:8177
        '';
      };
    };
  };
  users.users.caddy.extraGroups = ["appdata" "sftp"];

  # Sftp user/group
  users.users."sftp" = {
    createHome = false;
    group = "sftp";
    home = "/mnt/wd-red/sftp";
    isSystemUser = true;
    shell = null;
    openssh.authorizedKeys.keys = [
      # kari@torque
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"

      # kari@android
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKk3kgeXBMsnpL0/uFLMYwBez1SXU92GyvyjAtmFZkSt kari@phone"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCqcpV951HXpC4Fe8KY3VYKTkWIcwJ1KSXA6xub2gOKbsOzerCFf7AaAJluprpi5YuV9n84RZatjF9E7tk+wjCsgDbfqO9AFWtJtCmyFWfs1cMzmhhxRt8A8KkK56FpJLmLjxEbkeMd8EpLS4HmwWLk+hd5c+1Cz/KgLfIA6WeLt72jArBGjpKFFcW4tLTR+U0I/uW7+YyTIyF8UmINlAHXsOdTptcfHmKIiRek+ySYyGLId3GGtZ0k2Dgh1E3/sHpi3x1GSztXmmn1QFUOeSDe62TRW6Wg78jDXiTUl0HwlIFuvtQ26UTdteC83nHvf70GGh5jH14o1uWhWN0WaE046Sm7aZGOIZ1OX5bfVE6m+taPohF+4Pw1NMV76l6zpRz2X6tSbcG3NSL1Zfx7q/v97M05VsAxMger4mI0h25fdaZSFUh+cNKrRXG12tjr+DZHOCUI2UdSuNp1A8JcKh5k9hL/WR17ZcQDY1Siau1ea/pqzqU6GHFMRLM1w+84jcKOVKFLMSAxl7vbb5dP3OU9CDXWf/fkXl9b2oci/DKNHhZ7G2kLTq6+pE8rPs8A0o48yUkQkYeYoeqNRediAKvcBju4xtdbFidzctV7GgqkH1CL56LbakV8GqsxBH12MK0F36U8PV1xeDYkklVVjX/380OQJD3Yq/hrOV70rcYJMQ== kari@android"

      # kari@macbook
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZlujrZ4ng+IMfiFPKxpMEC5CAcuLN+Xo5zahtHYxy/ kari@macbook"

      # kari@maliwan
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/n5+r2xsdwwIqpnfSQwle9k2G1vTr5pKnIW7Gv4dM1 kari@maliwan"
    ];
  };
  users.groups."sftp" = {};
  users.groups."appdata" = {};

  # Plex
  services.plex = {
    enable = true;
    dataDir = "${serviceDataDir}/plex";
    openFirewall = true;
  };
  users.users.plex.extraGroups = ["sftp" "appdata"];

  # Radarr
  services.radarr = {
    enable = true;
    dataDir = "${serviceDataDir}/radarr";
    openFirewall = true;
  };
  users.users.radarr.extraGroups = ["sftp" "appdata"];

  # Jackett
  services.jackett = {
    enable = true;
    dataDir = "${serviceDataDir}/jackett";
    openFirewall = true;
  };
  users.users.jackett.extraGroups = ["appdata"];

  # Torrent
  services.transmission = {
    enable = true;
    openFirewall = true;
    downloadDirPermissions = "0770";
    openRPCPort = true;
    home = "/mnt/wd-red/appdata/vaultwarden";
    settings = rec {
      download-dir = "/mnt/wd-red/sftp/dnld";
      incomplete-dir = "/mnt/wd-red/sftp/dnld/.incomplete";
      download-queue-enabled = false;
      rpc-authentication-required = false;
      rpc-bind-address = "0.0.0.0";
      rpc-port = 9091;
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
    };
  };
  users.users.transmission.extraGroups = ["appdata" "sftp"];

  # Fail2Ban
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

  # Vaultwarden
  fileSystems."/var/lib/bitwarden_rs" = {
    device = "/mnt/wd-red/appdata/vaultwarden";
    options = ["bind"];
  };
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    config = {
      rockerAddress = "127.0.0.1";
      rocketPort = 8177;
      domain = "http://vault.${domain}";

      # ROCKET_ADDRESS = "127.0.0.1";
      # ROCKET_PORT = 8177;
      # DOMAIN = "http://vault.${domain}";
      # SIGNUPS_ALLOWED = false;
      # INVITATIONS_ALLOWED = false;
      # SHOW_PASSWORD_HINT = false;
      # PASSWORD_HINTS_ALLOWED = false;
      # LOGIN_RATELIMIT_SECONDS=30;
      # LOGIN_RATELIMIT_MAX_BURST=3;
      # ADMIN_SESSION_LIFETIME=20;
      # ADMIN_RATELIMIT_MAX_BURST=3;
      # LOG_FILE="/var/lib/bitwarden_rd/extented.log";
      # EXTENDED_LOGGING=true;
    };
  };
  users.users.vaultwarden.extraGroups = ["appdata"];
}
