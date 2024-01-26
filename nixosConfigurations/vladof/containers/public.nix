{
  inputs,
  pkgs,
  lib,
  config,
  domain,
  appData,
  helpers,
  ...
}: let
  hostAddress = "192.168.200.1";
  localAddress = "192.168.200.2";
in {
  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /mnt/wd-red/sftp/share   755 239 239 -"
    "d ${appData}/plex   700 193 193 -"
  ];

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
      "plex.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:32400
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
        # reverse_proxy http://${localAddress}:80
      };
      "blog.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${localAddress}:8080
        '';
      };
    };
  };

  # Main config
  containers.public = {
    inherit hostAddress localAddress;
    autoStart = true;
    privateNetwork = true;

    # Binds
    bindMounts = helpers.bindMounts [
      # Appdata
      "${appData}/plex"
      # Media
      "/mnt/wd-red/sftp/media/movies"
      "/mnt/wd-red/sftp/media/music"
      "/mnt/wd-red/sftp/media/series"
      # Other
      "/mnt/wd-red/sftp/share"
    ];
    forwardPorts = helpers.bindPorts {
      tcp = [32400 3005 8324 32469 8080 80];
      udp = [1900 5353 32410 32412 32413 32414];
    };

    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      imports = [inputs.coditon-blog.nixosModules.default];

      # My personal website
      services.coditon-blog = {
        enable = true;
        openFirewall = true;
        port = 8080;
      };

      # Plex
      services.plex = {
        enable = true;
        dataDir = "${appData}/plex";
        openFirewall = true;
      };

      # Other
      networking = {
        firewall.enable = false;
        # Use systemd-resolved inside the container
        # Workaround for bug https://github.com/NixOS/nixpkgs/issues/162686
        useHostResolvConf = lib.mkForce false;
      };
      services.resolved.enable = true;
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "23.11";
    };
  };
}
