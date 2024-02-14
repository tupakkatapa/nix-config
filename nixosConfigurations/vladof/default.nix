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
  user = "kari";

  # Inherit global stuff for containers
  extendedArgs = args // {inherit appData domain interface;};
in {
  imports = [
    (import ./services extendedArgs)
    ../.config/motd.nix
    #../.config/pipewire.nix
    ../.config/tuigreet-hypr.nix
    ../.config/yubikey.nix
  ];
  hardware.pulseaudio.enable = true;

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
  services.getty.autologinUser = user;

  # Cage-kiosk (firefox)
  services.cage = {
    enable = true;
    user = user;
    program = lib.concatStringsSep " \\\n\t" [
      "${config.home-manager.users."${user}".programs.firefox.package}/bin/firefox"
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
  fileSystems."/home/${user}/.mozilla" = {
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

  # Extra SSH/SFTP settings
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
    hostKeys = [
      {
        path = "/mnt/wd-red/secrets/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  # SFTP user/group
  users.users."sftp" = {
    createHome = true;
    isSystemUser = true;
    useDefaultShell = false;
    group = "sftp";
    extraGroups = [
      "sshd"
      "nextcloud"
      "transmission"
    ];
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

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /mnt/wd-red        755 root root -"
    "d /mnt/wd-red/sftp   755 root root -"
    "d ${appData}         770 root root -"
    "d ${appData}/firefox 755 ${user} ${user} -"
  ];

  # Mount drives
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
  services.sshguard.enable = true;
}
