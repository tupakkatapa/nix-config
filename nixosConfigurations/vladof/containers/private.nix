{
  pkgs,
  lib,
  config,
  domain,
  serviceDataDir,
  gateway,
  helpers,
  ...
}: let
  address = "10.11.10.2";
in {
  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${serviceDataDir}/transmission   700  70  70 -"
    "d ${serviceDataDir}/radarr         700 275 275 -"
    "d ${serviceDataDir}/jackett        700 276 276 -"
    "d ${serviceDataDir}/vaultwarden    700 993 993 -"
  ];

  # Bind services without dir option
  fileSystems."/var/lib/bitwarden_rs" = {
    device = "${serviceDataDir}/vaultwarden";
    options = ["bind"];
  };

  # Reverse proxy
  services.caddy = {
    enable = true;
    virtualHosts = {
      "torrent.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${address}:9091
        '';
      };
      "radarr.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${address}:7878
        '';
      };
      "jackett.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${address}:9117
        '';
      };
      "vault.${domain}" = {
        useACMEHost = config.networking.fqdn;
        extraConfig = ''
          reverse_proxy http://${address}:8177
        '';
      };
    };
  };

  # Main config
  containers.private = {
    autoStart = true;
    privateNetwork = true;
    #enableTun = true;
    hostAddress = gateway;
    localAddress = address;

    # Binds
    bindMounts = helpers.bindMounts [
      # Appdata
      "${serviceDataDir}/jackett"
      "${serviceDataDir}/radarr"
      "${serviceDataDir}/transmission"
      "${serviceDataDir}/vaultwarden"
      # Media
      "/mnt/wd-red/sftp/dnld"
      "/mnt/wd-red/sftp/media/movies"
      # Other
      "/mnt/wd-red/secrets"
    ];
    forwardPorts = helpers.bindPorts {
      tcp = [7878 9091 9117 8177];
      udp = [51820];
    };

    config = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # Radarr
      services.radarr = {
        enable = true;
        dataDir = "${serviceDataDir}/radarr";
        openFirewall = true;
      };
      users.users.radarr.extraGroups = ["transmission"];

      # Jackett
      services.jackett = {
        enable = true;
        dataDir = "${serviceDataDir}/jackett";
        openFirewall = true;
      };
      users.users.jackett.extraGroups = ["transmission"];

      # Torrent
      services.transmission = {
        enable = true;
        openFirewall = true;
        downloadDirPermissions = "0777";
        openRPCPort = true;
        home = "${serviceDataDir}/transmission";
        settings = {
          download-dir = "/mnt/wd-red/sftp/dnld";
          incomplete-dir = "/mnt/wd-red/sftp/dnld/.incomplete";
          download-queue-enabled = false;
          rpc-authentication-required = false;
          rpc-bind-address = "0.0.0.0";
          rpc-port = 9091;
          rpc-host-whitelist-enabled = false;
          rpc-whitelist-enabled = false;
          # rpc-whitelist = lib.concatStringsSep "," [
          #   "127.0.0.1"
          #   "192.168.1.*"
          #   "10.11.10.*"
          #   "172.16.16.*"
          # ];
        };
      };
      # Workaround for https://github.com/NixOS/nixpkgs/issues/258793
      systemd.services.transmission = {
        serviceConfig = {
          RootDirectoryStartOnly = lib.mkForce false;
          RootDirectory = lib.mkForce "";
        };
      };

      # Vaultwarden
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

      # # VPN
      # # https://alberand.com/nixos-wireguard-vpn.html
      # # https://discourse.nixos.org/t/route-all-traffic-through-wireguard-interface/1480/18
      # networking.wireguard.interfaces.wg0 = let
      #   mullvadAddr = "193.32.127.69";
      #   splitTunnels = [
      #     "172.16.16.2" # phone
      #   ];
      # in {
      #   ips = ["10.66.219.228/32"];
      #   listenPort = 51820;
      #   privateKeyFile = "/mnt/wd-red/secrets/mullvad-vpn.key";
      #   peers = [
      #     {
      #       publicKey = "C3jAgPirUZG6sNYe4VuAgDEYunENUyG34X42y+SBngQ=";
      #       allowedIPs = ["0.0.0.0/0"];
      #       endpoint = "${mullvadAddr}:51820";
      #       persistentKeepalive = 25;
      #     }
      #   ];
      #
      #   postSetup = ''
      #     # Split tunneling
      #     ${lib.concatStringsSep "\n" (map (splitTunnel: ''
      #         ${pkgs.iptables}/bin/iptables -A INPUT -s ${splitTunnel} -d ${address} \
      #           -m state --state NEW,ESTABLISHED -j ACCEPT
      #         ${pkgs.iptables}/bin/iptables -I OUTPUT -s ${address} -d ${splitTunnel} \
      #           -m state --state NEW,ESTABLISHED -j ACCEPT
      #         ${pkgs.iproute2}/bin/ip route add ${splitTunnel} via ${gateway}
      #       '')
      #       splitTunnels)}
      #
      #     # https://discourse.nixos.org/t/route-all-traffic-through-wireguard-interface/1480/18
      #     ${pkgs.iproute2}/bin/ip route add ${mullvadAddr} via ${gateway}
      #
      #     # Mark packets on the wg0 interface
      #     wg set wg0 fwmark 51820
      #
      #     # Forbid anything else which doesn't go through wireguard VPN on ipV4 and ipV6
      #     ${pkgs.iptables}/bin/iptables -A OUTPUT \
      #       ! -d 192.168.0.0/16 \
      #       ! -o wg0 \
      #       -m mark ! --mark $(wg show wg0 fwmark) \
      #       -m addrtype ! --dst-type LOCAL \
      #       -j REJECT
      #     ${pkgs.iptables}/bin/ip6tables -A OUTPUT \
      #       ! -o wg0 \
      #       -m mark ! --mark $(wg show wg0 fwmark) \
      #       -m addrtype ! --dst-type LOCAL \
      #       -j REJECT
      #   '';
      #   postShutdown = ''
      #     ${lib.concatStringsSep "\n" (map (splitTunnel: ''
      #         ${pkgs.iproute2}/bin/ip route del ${splitTunnel} via ${gateway}
      #       '')
      #       splitTunnels)}
      #
      #     ${pkgs.iproute2}/bin/ip route del ${mullvadAddr} via ${gateway}
      #
      #     ${pkgs.iptables}/bin/iptables -D OUTPUT \
      #       ! -o wg0 \
      #       -m mark ! --mark $(wg show wg0 fwmark) \
      #       -m addrtype ! --dst-type LOCAL \
      #       -j REJECT
      #     ${pkgs.iptables}/bin/ip6tables -D OUTPUT \
      #       ! -o wg0 -m mark \
      #       ! --mark $(wg show wg0 fwmark) \
      #       -m addrtype ! --dst-type LOCAL \
      #       -j REJECT
      #   '';
      # };

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
