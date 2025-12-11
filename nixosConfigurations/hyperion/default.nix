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

  imports = [
    ../.config/yubikey.nix
    ../.config/motd.nix

    # To be added during migration:
    (import ./persistence.nix extendedArgs)
    # ./networking.nix    # WAN/LAN interface config
    # ./firewall.nix      # nftables NAT/firewall rules
    (import ./nixie.nix extendedArgs) # DHCP + PXE server
    ./wireguard.nix # VPN server
    # ./dns.nix           # CoreDNS
    # ./ntp.nix           # chrony NTP server
    # ./monitoring.nix    # Prometheus + vnStat
  ];

  # Saiko's automatic gc
  sys2x.gc.useDiskAware = true;

  # Networking
  networking = {
    hostName = "hyperion";
    domain = "${domain}";
  };

  # Enable blobs
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

