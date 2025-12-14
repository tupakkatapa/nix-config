{ config, ... }:
{
  # NOTE: WAN and LAN networking is managed by Nixie

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

  # Wait for WiFi bridge before starting network services
  # Intel CNVi can crash/recover at boot, delaying br-wifi creation
  systemd.services.kea-dhcp4-server = {
    after = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    wants = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
  };
  systemd.services.nginx = {
    after = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
    wants = [ "sys-subsystem-net-devices-br\\x2dwifi.device" ];
  };

  # Hardening
  boot.kernel.sysctl = {
    # Anti-spoofing
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;

    # ICMP redirect protection
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;

    # Source routing disabled
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # SYN flood protection
    "net.ipv4.tcp_syncookies" = 1;

    # Martian packet logging
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.default.log_martians" = 1;

    # ICMP protection
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
  };
}
