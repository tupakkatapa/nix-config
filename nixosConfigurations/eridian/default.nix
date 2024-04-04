{
  config,
  pkgs,
  ...
}: {
  # Set a hostname and domain of your choice
  networking.hostName = "eridian";

  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  nixie = {
    enable = true;
    file-server = {
      # For unreferenced menus
      defaultAddress = "192.168.1.2";
      httpPort = 10951;

      # Each of these objects represents one iPXE menu
      menus = [
        {
          name = "minimal";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = ["bandit"];
        }
        {
          name = "homelab";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = ["vladof" "bandit"];
          default = "vladof";
          timeout = 1;
          buildRequests = true;
        }
        # TODO: These are not yet ephemeral
        # {
        #   name = "pc";
        #   flakeUrl = "github:tupakkatapa/nix-config";
        #   hosts = ["torgue" "bandit"];
        #   default = "torgue";
        #   timeout = 1;
        #   buildRequests = true;
        # }
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
          address = "192.168.1.2";
          interfaces = ["enp3s0"];
          defaultMenu = "minimal";
          clients = [
            {
              menu = "homelab";
              mac = "30:9c:23:3c:b9:01";
              address = "192.168.1.8";
            }
            # TODO: These are not yet ephemeral
            # {
            #   menu = "pc";
            #   mac = "00:0e:9a:01:52:201";
            #   address = "192.168.1.127";
            # }
            # {
            #   menu = "laptop";
            #   mac = "80:ce:62:39:08:30";
            #   address = "192.168.1.130";
            # }
          ];
          poolStart = "192.168.1.3";
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
