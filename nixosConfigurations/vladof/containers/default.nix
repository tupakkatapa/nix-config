{
  inputs,
  pkgs,
  lib,
  config,
  appData,
  domain,
  interface,
  ...
} @ args: let
  # Functions for container configs
  helpers = {
    bindPorts = protocols:
      lib.concatMap (protocol:
        map (port: {
          inherit protocol;
          hostPort = port;
        }) (protocols.${protocol})) (builtins.attrNames protocols);

    bindMounts = paths:
      lib.listToAttrs (map (path: {
          name = path;
          value = {
            hostPath = path;
            isReadOnly = false;
          };
        })
        paths);
  };

  # Inherit global stuff for containers
  extendedArgs = args // {inherit appData domain helpers;};
in {
  imports = [
    (import ./public.nix extendedArgs)
    (import ./private.nix extendedArgs)
  ];

  # ACME
  security.acme = {
    acceptTerms = true;
    defaults.email = "jesse@ponkila.com";
    defaults.webroot = "${appData}/acme";
  };
  # Bind service directories to persistent disk
  fileSystems."/var/lib/acme" = {
    device = "${appData}/acme";
    options = ["bind"];
  };

  # Other
  networking = {
    firewall = {
      allowedTCPPorts =
        [
          80 # HTTP
          443 # HTTPS
          1337 # Blog
          7878 # Radarr
          9091 # Transmission
          9117 # Jackett
          8222 # Vaultwarden
          3000 # Lanraragi
          8888 # Nextcloud
        ]
        # Plex
        ++ [
          32400 # Plex Media Server
          3005 # Plex Companion
          8324 # Roku via Plex Companion
          32469 # Plex DLNA Server
        ];
      allowedUDPPorts =
        [
          51820 # WireGuard
        ]
        # Plex
        ++ [
          1900 # Plex DLNA Server
          5353 # Older Bonjour/Avahi network discovery
          32410 # Current GDM network discovery
          32412
          32413
          32414
        ];
    };
    nat = {
      enable = true;
      internalInterfaces = ["ve-+"];
      externalInterface = interface;
    };
  };
}
