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
  # Inherit global stuff for services
  extendedArgs = args // {inherit appData domain;};
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

  # Create directories, these are persistent
  systemd.tmpfiles.rules = [
    "d ${appData}/acme  700 acme acme -"
  ];

  # Firewall
  networking = {
    firewall = {
      allowedTCPPorts = [
        80 # HTTP
        443 # HTTPS
      ];
      allowedUDPPorts = [
        51820 # WG
      ];
    };
  };
}
