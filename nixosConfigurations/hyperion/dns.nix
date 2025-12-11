_:
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
          "192.168.1.2" # TESTING: Change to .1 for production
          "172.16.16.1"
        ];

        # Access control: default deny
        access-control = [
          "0.0.0.0/0 refuse"
          "::/0 refuse"
          "127.0.0.0/8 allow"
          "::1 allow"
          "192.168.1.0/24 allow"
          "172.16.16.0/24 allow"
        ];

        port = 53;

        # Security features
        use-caps-for-id = true; # 0x20 randomization
        qname-minimisation = true;

        # DNSSEC (auto-trust-anchor-file set automatically by enableRootTrustAnchor)
        val-permissive-mode = false;
        val-log-level = 1;

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

        unwanted-reply-threshold = 10000;
        do-not-query-localhost = false;
        prefetch = true;
        prefetch-key = true;
        aggressive-nsec = true;

        # Local zone
        local-zone = [ ''"coditon.com." transparent'' ];

        local-data = [
          ''"vladof.coditon.com. IN A 192.168.1.8"''
          # ''"plex.coditon.com. IN A 192.168.1.8"'' # Public service - use public DNS
          ''"vault.coditon.com. IN A 192.168.1.8"''
          ''"lib.coditon.com. IN A 192.168.1.8"''
          ''"torrent.coditon.com. IN A 192.168.1.8"''
          ''"dav.coditon.com. IN A 192.168.1.8"''
          ''"chat.coditon.com. IN A 192.168.1.8"''
          # ''"blog.coditon.com. IN A 192.168.1.8"'' # Public service - use public DNS
          ''"index.coditon.com. IN A 192.168.1.8"''
          ''"eth.coditon.com. IN A 192.168.1.25"''
          ''"kaakkuri.coditon.com. IN A 192.168.1.25"''
          ''"hyperion.coditon.com. IN A 192.168.1.2"'' # TESTING: Change to .1 for production
          ''"router.coditon.com. IN A 192.168.1.2"'' # TESTING: Change to .1 for production
          ''"torgue.coditon.com. IN A 192.168.1.7"''

          # PTR records
          ''"2.1.168.192.in-addr.arpa. IN PTR hyperion.coditon.com."'' # TESTING: Change to 1.1.168.192 for production
          ''"7.1.168.192.in-addr.arpa. IN PTR torgue.coditon.com."''
          ''"8.1.168.192.in-addr.arpa. IN PTR vladof.coditon.com."''
          ''"25.1.168.192.in-addr.arpa. IN PTR kaakkuri.coditon.com."''
        ];
      };

      remote-control = {
        control-enable = true;
        control-interface = "127.0.0.1";
      };
    };
  };
}
