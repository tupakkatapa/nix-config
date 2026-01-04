{ pkgs, ... }:
let
  # DNSCrypt resolver lists - verify signatures at build time
  # Update: nix shell nixpkgs#nix-prefetch-github -c nix-prefetch-github DNSCrypt dnscrypt-resolvers
  dnscryptMinisignKey = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
  dnscryptListsSrc = pkgs.fetchFromGitHub {
    owner = "DNSCrypt";
    repo = "dnscrypt-resolvers";
    rev = "0975c492be42e03931e907a6173e8906d261ddc8";
    hash = "sha256-Iiiy4Hr1imJrzI0yxsX9XEe6OHwILStMNcBjLJsFhiY=";
  };
  dnscryptLists = pkgs.runCommand "dnscrypt-lists-verified"
    {
      nativeBuildInputs = [ pkgs.minisign ];
    } ''
    mkdir -p $out/v3
    cp ${dnscryptListsSrc}/v3/*.md ${dnscryptListsSrc}/v3/*.minisig $out/v3/
    minisign -Vm $out/v3/public-resolvers.md -P ${dnscryptMinisignKey}
    minisign -Vm $out/v3/relays.md -P ${dnscryptMinisignKey}
  '';

  # Steven Black blocklist
  # Update: nix shell nixpkgs#nix-prefetch-github -c nix-prefetch-github StevenBlack hosts
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

        # Security
        use-caps-for-id = true;
        qname-minimisation = true;
        val-permissive-mode = false;
        val-log-level = 1;
        domain-insecure = [ "cateee.net" ]; # Broken DNSSEC

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
        minimal-responses = true;
        deny-any = true;
        log-queries = false;
        log-replies = false;
        log-local-actions = false;
        private-address = [
          "10.0.0.0/8"
          "172.16.0.0/12"
          "192.168.0.0/16"
          "169.254.0.0/16"
          "fd00::/8"
          "fe80::/10"
        ];

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

        # Blocklist
        include = "${unboundBlocklist}";

        # Local zone
        local-zone = [ ''"coditon.com." transparent'' ];
        local-data = [
          ''"coditon.com. IN A 10.42.0.1"''
          ''"cert.coditon.com. IN A 10.42.0.8"''
          ''"chat.coditon.com. IN A 10.42.0.8"''
          ''"dav.coditon.com. IN A 10.42.0.8"''
          ''"index.coditon.com. IN A 10.42.0.8"''
          ''"lib.coditon.com. IN A 10.42.0.8"''
          ''"search.coditon.com. IN A 10.42.0.8"''
          ''"torrent.coditon.com. IN A 10.42.0.8"''
          ''"vault.coditon.com. IN A 10.42.0.8"''
          ''"kaakkuri.coditon.com. IN A 10.42.0.25"''
          ''"hyperion.coditon.com. IN A 10.42.0.1"''
          ''"router.coditon.com. IN A 10.42.0.1"''
          ''"torgue.coditon.com. IN A 10.42.0.7"''
          ''"vladof.coditon.com. IN A 10.42.0.8"''
          ''"maliwan.coditon.com. IN A 10.42.0.9"''
          ''"1.0.42.10.in-addr.arpa. IN PTR hyperion.coditon.com."''
          ''"7.0.42.10.in-addr.arpa. IN PTR torgue.coditon.com."''
          ''"8.0.42.10.in-addr.arpa. IN PTR vladof.coditon.com."''
          ''"9.0.42.10.in-addr.arpa. IN PTR maliwan.coditon.com."''
          ''"25.0.42.10.in-addr.arpa. IN PTR kaakkuri.coditon.com."''
        ];
      };

      remote-control = {
        control-enable = true;
        control-interface = "127.0.0.1";
      };

      # Forward to dnscrypt-proxy
      forward-zone = [{
        name = ".";
        forward-addr = [ "127.0.0.1@5353" "::1@5353" ];
      }];
    };
  };

  # Ensure unbound starts after dnscrypt-proxy
  systemd.services.unbound = {
    after = [ "dnscrypt-proxy.service" ];
    wants = [ "dnscrypt-proxy.service" ];
  };

  # Static UID/GID for persistent storage
  users.users.unbound.uid = 994;
  users.groups.unbound.gid = 992;

  # dnscrypt-proxy - encrypted DNS with anonymized routing
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:5353" "[::1]:5353" ];
      ipv6_servers = true;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;
      fallback_resolvers = [ "9.9.9.9:53" ];
      ignore_system_dns = true;
      block_unqualified = true;
      block_undelegated = true;
      lb_strategy = "p2";
      cache = false;

      # Anonymized DNS (relay sees IP, resolver sees queries, neither sees both)
      anonymized_dns = {
        routes = [{
          server_name = "*";
          via = [ "anon-cs-finland" "anon-cs-sweden" "anon-cs-de" "anon-cs-nl" "anon-tiarap" "anon-scaleway-fr" ];
        }];
        skip_incompatible = true;
      };

      sources.public-resolvers = {
        urls = [ ];
        cache_file = "${dnscryptLists}/v3/public-resolvers.md";
        minisign_key = dnscryptMinisignKey;
      };

      sources.relays = {
        urls = [ ];
        cache_file = "${dnscryptLists}/v3/relays.md";
        minisign_key = dnscryptMinisignKey;
      };
    };
  };
}
