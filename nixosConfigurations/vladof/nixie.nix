_: {
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  nixie = {
    enable = true;

    rwStoreMount = {
      enable = true;
      what = "/mnt/wd-red/store";
      type = "none";
      options = [ "bind" ];
    };

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
          flakeUrl = "github:tupakkatapa/nix-config\?ref=ephemeral-torgue";
          hosts = [ "torgue" "bandit" ];
          default = "torgue";
          timeout = 1;
        }
      ];
    };

    dhcp = {
      enable = true;
      subnets = [
        {
          name = "upstream";
          serve = true;
          address = "192.168.1.8";
          interfaces = [ "enp0s31f6" ];
          defaultMenu = "minimal";
          clients = [
            {
              menu = "torgue";
              mac = "d4:5d:64:d1:12:52";
              address = "192.168.1.7";
            }
            {
              menu = "kaakkuri-ephemeral-alpha";
              mac = "70:85:c2:b5:be:db";
              address = "192.168.1.25";
            }
          ];
          poolStart = "192.168.1.30";
          poolEnd = "192.168.1.59";
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

