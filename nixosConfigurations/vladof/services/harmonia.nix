{ config, ... }:
{
  # Harmonia: nix binary cache for the LAN
  # URL: http://10.42.0.8:5000
  # Generate signing key (one-time):
  #   nix-store --generate-binary-cache-key vladof.coditon.com-1 priv.pem pub.pem
  #   agenix rekey edit nixosConfigurations/vladof/secrets/harmonia-key.age # paste priv.pem
  #   then update system/nix-settings.nix with the pub.pem contents
  services.harmonia.cache = {
    enable = true;
    signKeyPaths = [ config.age.secrets.harmonia-key.path ];
    settings = {
      bind = "0.0.0.0:5000";
      workers = 4;
      max_connection_rate = 128;
      priority = 30; # lower number = higher priority than nixos.org cache
    };
  };

  # Static user for User=harmonia (module uses DynamicUser, base.nix disables it)
  users.users.harmonia = { isSystemUser = true; group = "harmonia"; };
  users.groups.harmonia = { };

  # No owner: key read via LoadCredential as root
  age.secrets.harmonia-key = {
    rekeyFile = ../secrets/harmonia-key.age;
    mode = "400";
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
