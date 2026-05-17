{ pkgs
, lib
, config
, ...
}:
let
  domain = "coditon.com";
  dataDir = "/mnt/lexar";

  # Inherit global stuff for imports
  extendedArgs = { inherit pkgs lib config domain dataDir; };
in
{
  age.rekey = {
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFXTPhVIrcmsJp9AwrPGfh3bX4Ixq6NmwTve3ExlLp16 root@hyperion";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  # Append access tokens to nix.conf for private flake inputs
  age.secrets.nix-access-tokens.rekeyFile = ../../home-manager/users/kari/secrets/nix-access-tokens.age;
  nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';

  imports = [
    (import ./nixie.nix extendedArgs)
    (import ./persistence.nix extendedArgs)
    (import ./dashboard extendedArgs)
    (import ./dns.nix extendedArgs)
    (import ./ntp.nix extendedArgs)
    ../.config/hw/cpu-intel.nix
    ../.config/motd.nix
    ../.config/hw/yubikey.nix
    ./firewall.nix
    ./hardening.nix
    ./monitoring.nix
    ./networking.nix
    ./wireguard.nix
  ];

  # Disk-aware garbage collection
  sys2x.gc.useDiskAware = true;

  # Networking
  networking = {
    hostName = "hyperion";
    domain = "${domain}";
  };
}

