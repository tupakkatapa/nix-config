{ pkgs
, lib
, config
, ...
}:
let
  domain = "coditon.com";
  # dataDir = "/mnt/storage";

  # Inherit global stuff for imports
  # extendedArgs = { inherit pkgs lib config domain dataDir inputs; };
in
{
  age.rekey = {
    hostPubkey = "";
    agePlugins = [ pkgs.age-plugin-fido2-hmac ];
    localStorageDir = ./secrets/rekeyed;
    storageMode = "local";
  };

  imports = [
    ../.config/yubikey.nix
    ../.config/motd.nix

    # To be added during migration:
    # (import ./persistence.nix extendedArgs)
    # ./networking.nix    # WAN/LAN interface config
    # ./firewall.nix      # nftables NAT/firewall rules
    # ./nixie.nix         # DHCP + PXE server (from vladof)
    # ./wireguard.nix     # VPN server (from vladof)
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

