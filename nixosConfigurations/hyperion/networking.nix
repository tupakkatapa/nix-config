{ config, lib, ... }:
{
  # NOTE: WAN and LAN networking is managed by Nixie

  # Disable systemd-resolved (Unbound handles DNS, resolved uses port 5353 for mDNS)
  services.resolved.enable = false;

  # WAN DHCP privacy
  systemd.network.networks."10-wan".dhcpV4Config = {
    Anonymize = true;
    SendHostname = false;
  };

  # IPv6 privacy
  systemd.network.networks."10-wan".networkConfig = {
    IPv6LinkLocalAddressGenerationMode = "random";
    IPv6PrivacyExtensions = "yes";
  };
  systemd.network.networks."br-lan".networkConfig.IPv6LinkLocalAddressGenerationMode = "random";
  systemd.network.networks."br-wifi".networkConfig.IPv6LinkLocalAddressGenerationMode = "random";

  # WiFi Access Point
  services.hostapd = {
    enable = true;
    radios.wlp0s20f3 = {
      band = "2g"; # Intel CNVi doesn't support 5g
      channel = 6;
      countryCode = "FI";
      wifi4.capabilities = [ "LDPC" "HT40+" "SHORT-GI-20" "SHORT-GI-40" ];
      networks.wlp0s20f3 = {
        ssid = "hyperion-2g";
        authentication = {
          mode = "wpa3-sae"; # no WPA2 fallback
          saePasswords = [{ passwordFile = config.age.secrets.wifi-ap-password.path; }];
        };
      };
    };
  };

  # Secrets
  age.secrets.wifi-ap-password = {
    rekeyFile = ./secrets/wifi-ap-password.age;
    mode = "400";
  };
  age.secrets.cloudflare-dns-token = {
    rekeyFile = ./secrets/cloudflare-dns-token.age;
    mode = "400";
  };

  # Dynamic DNS
  services.cloudflare-dyndns = {
    enable = true;
    domains = [ "coditon.com" ];
    proxied = false;
    ipv4 = true;
    ipv6 = true;
    deleteMissing = true;
    apiTokenFile = config.age.secrets.cloudflare-dns-token.path;
  };
  systemd.services.cloudflare-dyndns = {
    after = [ "unbound.service" ];
    wants = [ "unbound.service" ];
    serviceConfig.DynamicUser = lib.mkForce false;
  };

  # Wait for WiFi bridge before starting network services
  # Intel CNVi can crash/recover at boot, delaying br-wifi creation
  systemd.services.kea-dhcp4-server = {
    after = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    wants = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    serviceConfig.DynamicUser = lib.mkForce false;
  };
  systemd.services.nginx = {
    after = [ "network-online.target" "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    wants = [ "network-online.target" "sys-subsystem-net-devices-br\\x2dwifi.device" ];
  };
}
