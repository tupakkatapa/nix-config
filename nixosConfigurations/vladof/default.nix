{
  pkgs,
  lib,
  config,
  ...
}: let
  domain = "coditon.com";
  serviceDataDir = "/mnt/wd-red/appdata";
in {
  imports = [
    ./plasma-bigscreen.nix
  ];

  # Bootloader for x86_64-linux / aarch64-linux
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use the latest kernel
  boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.linux_latest);

  # Extends 'system/patches/init1-network-base.nix'
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
    "d /mnt/wd-red            755 root root -"
    "d /mnt/wd-red/sftp       755 root root -"
    "d /mnt/wd-red/sftp/share 755 caddy sftp -"
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
        type = "ed25519";
      }
    ];
  };
  services.sshguard.enable = true;

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
    device = "${serviceDataDir}/acme";
    options = ["bind"];
  };
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "jesse@ponkila.com";
  security.acme.defaults.webroot = "${serviceDataDir}/acme";

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
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
          encode zstd gzip
          root * /mnt/wd-red/sftp/share
          file_server {
            browse
            hide .* _*
          }
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
    createHome = true;
    isSystemUser = true;
    useDefaultShell = false;
    group = "sftp";
    home = "/mnt/wd-red/sftp";
    openssh.authorizedKeys.keys = [
      # kari@torque
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"

      # kari@phone
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFKfmSYqFE+hXp/P1X8oqcpnUG9cx9ILzk4dqQzlEOC kari@phone"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzhUITs3FB3ND6KMOjBwT04FD0jN+fuY8TIpO3U0Imdkhr++NgkHH8C8tXkKS+XJOUx6kHt9/DkLLmRJLe3qTwwarElgR1bVVIlOHx3Z1AY88b5CjcQV0ZruvZgasKKTfMx3TN5Zl3OBgGckHgAGozM8dZqUEMTE/U/hR/jatCaCEADgBCLM3rM2hCIcjTJ+Rk1rPBjOZzTdNogYWr9puyWu8kTaS/1gALI1bcJ235yKCrAr/fmzZDfBrPM9A9Y8B09rtOEE53GmpEXNyYsllOFA6nurSIIBxQNrUnOoKbCIgAjyttcA1aAxGIB+uZ1Sxnj4bZpHS1+GOqANY1ukeKkga02k2UVwtvMvCqLZHPQ9hUsg8H96V9PwvSUI68E3wEfoc7bV34Srh7TuBkDOcMv0kY5X1WmkgfS4n3CnPBIXoStw49RoMMoorhvazt9p2WIDlygmMWhESF0hYexRrpdVmvpRLjPlCR611PAhxIhn1aquvrr/WTKzWficSUbWbql6+ZYpwZUAaLb6qK35ohS//5gqH9MJCFJZTjfyWBSA2hAxA8hUGPxbGLOg53VDy03vxXCa21FnOWJVMv9bosBfGYPYyBhxTqmN9PJQ2msM1kb2u17E+ZHPt6JZbD4uDweOoPXWF0Bq4JNeA9LYdMgeoQ5hZt3hKuKao9MOF6zw== kari@phone"

      # kari@maliwan
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxmP58tAQ7oN1OT4nZ/pZtrb8vGvuh/l33lxiq3ngIU kari@maliwan"
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
    downloadDirPermissions = "0777";
    openRPCPort = true;
    home = "${serviceDataDir}/transmission";
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

  # Vaultwarden
  fileSystems."/var/lib/bitwarden_rs" = {
    device = "${serviceDataDir}/vaultwarden";
    options = ["bind"];
  };
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";
    config = {
      rocketAddress = "127.0.0.1";
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
