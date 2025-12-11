_:
{
  # Chrony NTP server - critical for PXE boot
  services.chrony = {
    enable = true;

    # NTP servers to sync from
    servers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    # Allow LAN clients to sync time from this server
    extraConfig = ''
      # Allow time queries from LAN
      allow 192.168.1.0/24

      # Allow time queries from WireGuard
      allow 172.16.16.0/24

      # Serve time even if not synced (for initial PXE boot)
      local stratum 10
    '';
  };
}
