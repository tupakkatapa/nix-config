_: {
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  nixie = {
    enable = true;
    file-server = {
      # For unreferenced menus
      defaultAddress = "192.168.1.8";
      httpPort = 10951;

      # Each of these objects represents one iPXE menu
      menus = [
        {
          name = "minimal";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "bandit" ];
        }
        {
          name = "kaakkuri-ephemeral-alpha";
          flakeUrl = "github:ponkila/homestaking-infra\?ref=kaakkuri-ephemeral-alpha";
          hosts = [ "kaakkuri-ephemeral-alpha" ];
          timeout = 1;
          buildRequests = true;
        }
        {
          name = "torgue";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "torgue" "bandit" ];
          default = "torgue";
          timeout = 1;
          buildRequests = true;
        }
        # TODO: These are not yet ephemeral
        # {
        #   name = "laptop";
        #   flakeUrl = "github:tupakkatapa/nix-config";
        #   hosts = ["maliwan" "bandit"];
        #   default = "maliwan";
        #   timeout = 1;
        #   buildRequests = true;
        # }
      ];
    };

    dhcp = {
      enable = true;
      subnets = [
        {
          name = "upstream";
          serve = true;
          address = "192.168.1.8";
          interfaces = [ "enp3s0" ];
          defaultMenu = "minimal";
          clients = [
            {
              menu = "torgue";
              mac = "00:0e:9a:01:52:20";
              address = "192.168.1.7";
            }
            {
              menu = "kaakkuri-ephemeral-alpha";
              mac = "70:85:c2:b5:be:db";
              address = "192.168.1.25";
            }
            # TODO: These are not yet ephemeral
            # {
            #   menu = "laptop";
            #   mac = "80:ce:62:39:08:30";
            #   address = "192.168.1.130";
            # }
          ];
          poolStart = "192.168.1.9";
          poolEnd = "192.168.1.29";
        }
      ];
    };
  };

  # TODO: Binary cache
  # services.nix-serve = {
  #   enable = true;
  #   secretKeyFile = "/var/cache-priv-key.pem";
  #   port = 5000;
  #   openFirewall = true;
  # };
}

