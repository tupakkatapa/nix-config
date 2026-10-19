{ dataDir, ... }:
let
  chronyDir = "${dataDir}/home/chrony/appdata/chrony";
in
{
  # Chrony NTP server - serves time to LAN clients, critical for PXE boot
  services.chrony = {
    enable = true;
    servers = [ ]; # Using NTS servers in extraConfig

    # NTS keys + drift on disk
    directory = chronyDir;

    extraConfig = ''
      # NTS servers (encrypted + authenticated)
      server time.cloudflare.com iburst nts
      server nts.netnod.se iburst nts
      server ptbtime1.ptb.de iburst nts
      server ntppool1.time.nl iburst nts

      # Fallback pool (unencrypted)
      pool nixos.pool.ntp.org iburst maxsources 2

      ntsdumpdir ${chronyDir}
      minsources 2

      # Allow LAN/WiFi/WireGuard clients
      allow 10.42.0.0/24
      allow 10.42.1.0/24
      allow 172.16.16.0/24
      allow 172.16.17.0/24
      allow fd42:42:42:1::/64
      allow fd42:42:42:2::/64
      allow fd42:42:42:3::/64

      # Serve time even if not synced (for initial PXE boot)
      local stratum 10

      # No bindaddress: chrony keeps only the last one per family

      noclientlog
      makestep 1.0 3
    '';
  };
}
