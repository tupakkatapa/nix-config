{ pkgs, ... }:
let
  # Steven Black hosts converted to unbound format
  # Update with: nix shell nixpkgs#nix-prefetch-github -c nix-prefetch-github StevenBlack hosts
  unboundBlocklist = pkgs.stdenv.mkDerivation {
    name = "unbound-blocklist";
    src = pkgs.fetchFromGitHub {
      owner = "StevenBlack";
      repo = "hosts";
      rev = "88c487e3709e4c45f94264562c770a0ca5e65508";
      hash = "sha256-DkcMg7kgNnn+FL9fxhsTaSa/Q0RkFanvTvcH65DIwa4=";
    };
    phases = [ "installPhase" ];
    installPhase = ''
      ${pkgs.gawk}/bin/awk '/^0\.0\.0\.0/ && $2 !~ /0\.0\.0\.0/ {print "local-zone: \""$2".\" always_null"}' \
        $src/alternates/fakenews-gambling-porn/hosts > $out
    '';
  };
in
{
  services.unbound = {
    enable = true;
    enableRootTrustAnchor = true;

    settings = {
      server = {
        # Bind to specific interfaces only (NOT 0.0.0.0)
        interface = [
          "127.0.0.1"
          "::1"
          "10.42.0.1" # LAN
          "10.42.1.1" # WiFi
          "172.16.16.1" # WireGuard
        ];

        # Access control: default deny
        access-control = [
          "0.0.0.0/0 refuse"
          "::/0 refuse"
          "127.0.0.0/8 allow"
          "::1 allow"
          "10.42.0.0/24 allow" # LAN
          "10.42.1.0/24 allow" # WiFi
          "172.16.16.0/24 allow" # WireGuard
        ];

        port = 53;

        # Security features
        use-caps-for-id = true; # 0x20 randomization
        qname-minimisation = true;

        # DNSSEC (auto-trust-anchor-file set automatically by enableRootTrustAnchor)
        val-permissive-mode = false;
        val-log-level = 1;

        # Broken DNSSEC: cateee.net has stale DS record for non-existent key
        domain-insecure = [ "cateee.net" ];

        # Rate limiting
        ip-ratelimit = 50;
        ratelimit = 1000;

        # Performance
        num-threads = 2;
        msg-cache-slabs = 4;
        rrset-cache-slabs = 4;
        infra-cache-slabs = 4;
        key-cache-slabs = 4;

        rrset-cache-size = "32m";
        msg-cache-size = "16m";
        key-cache-size = "2m";

        edns-buffer-size = 1232;

        # Privacy
        hide-identity = true;
        hide-version = true;
        hide-trustanchor = true;

        # Hardening
        harden-glue = true;
        harden-dnssec-stripped = true;
        harden-below-nxdomain = true;
        harden-referral-path = true;
        harden-algo-downgrade = true;
        harden-large-queries = true;
        harden-short-bufsize = true;

        # Steven Black blocklist
        include = "${unboundBlocklist}";

        unwanted-reply-threshold = 10000;
        do-not-query-localhost = false;
        prefetch = true;
        prefetch-key = true;
        aggressive-nsec = true;

        # Local zone
        local-zone = [ ''"coditon.com." transparent'' ];

        local-data = [
          ''"vladof.coditon.com. IN A 10.42.0.8"''
          # ''"plex.coditon.com. IN A 10.42.0.8"'' # Public service - use public DNS
          ''"vault.coditon.com. IN A 10.42.0.8"''
          ''"lib.coditon.com. IN A 10.42.0.8"''
          ''"torrent.coditon.com. IN A 10.42.0.8"''
          ''"dav.coditon.com. IN A 10.42.0.8"''
          ''"chat.coditon.com. IN A 10.42.0.8"''
          # ''"blog.coditon.com. IN A 10.42.0.8"'' # Public service - use public DNS
          ''"index.coditon.com. IN A 10.42.0.8"''
          ''"eth.coditon.com. IN A 10.42.0.25"''
          ''"kaakkuri.coditon.com. IN A 10.42.0.25"''
          ''"hyperion.coditon.com. IN A 10.42.0.1"''
          ''"router.coditon.com. IN A 10.42.0.1"''
          ''"torgue.coditon.com. IN A 10.42.0.7"''

          # PTR records
          ''"1.0.42.10.in-addr.arpa. IN PTR hyperion.coditon.com."''
          ''"7.0.42.10.in-addr.arpa. IN PTR torgue.coditon.com."''
          ''"8.0.42.10.in-addr.arpa. IN PTR vladof.coditon.com."''
          ''"25.0.42.10.in-addr.arpa. IN PTR kaakkuri.coditon.com."''
        ];
      };

      remote-control = {
        control-enable = true;
        control-interface = "127.0.0.1";
      };
    };
  };

  # Static UID/GID for persistent storage
  users.users.unbound.uid = 994;
  users.groups.unbound.gid = 992;
}
