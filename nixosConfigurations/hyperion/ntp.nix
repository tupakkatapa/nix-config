_:
{
  # Chrony NTP server - serves time to LAN clients, critical for PXE boot
  services.chrony = {
    enable = true;
    servers = [ ]; # Using NTS servers in extraConfig

    extraConfig = ''
      # NTS servers (encrypted + authenticated)
      server time.cloudflare.com iburst nts
      server nts.netnod.se iburst nts
      server ptbtime1.ptb.de iburst nts
      server ntppool1.time.nl iburst nts

      # Fallback pool (unencrypted)
      pool nixos.pool.ntp.org iburst maxsources 2

      ntsdumpdir /var/lib/chrony
      minsources 2

      # Allow LAN/WiFi/WireGuard clients
      allow 10.42.0.0/24
      allow 10.42.1.0/24
      allow 172.16.16.0/24

      # Serve time even if not synced (for initial PXE boot)
      local stratum 10

      # Only listen on internal interfaces (not WAN)
      bindaddress 10.42.0.1
      bindaddress 10.42.1.1
      bindaddress 127.0.0.1

      noclientlog
      makestep 1.0 3
    '';
  };

  systemd.services.chronyd.serviceConfig.StateDirectory = "chrony";
}
