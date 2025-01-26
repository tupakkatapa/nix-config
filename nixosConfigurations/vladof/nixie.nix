{ dataDir
, appData
, secretData
, ...
}: {
  # Support for cross compilation
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
  ];

  # For compiling hosts that contain or are sourced from private inputs
  # Potentially required by the 'nixie' or 'refindGenerate' modules
  # You can remove this when Nixie is someday open-sourced
  fileSystems."/root/.ssh" = {
    device = "${secretData}/root/ssh";
    options = [ "bind" "mode=700" ];
  };

  # Create directories, not necessarily persistent
  systemd.tmpfiles.rules = [
    "d /root/.ssh                700 root root -"

    "d ${appData}/nixie          755 root root -"
    "d ${appData}/nixie/netboot  755 root root -"
    "d ${appData}/nixie/logs     755 root root -"
  ];

  # Mount '/nix/.rw-store' and '/tmp' to disk
  services.nixRemount = {
    enable = true;
    where = "${dataDir}/store";
    type = "none";
    options = [ "bind" ];
  };

  # Update the rEFInd boot manager
  services.refindGenerate = {
    enable = true;
    where = "/dev/sda1";
    flakeUrl = "github:tupakkatapa/nix-config";
    hosts = [ "vladof" "bandit" ];
    default = "vladof";
    timeout = 1;
  };

  services.nixie = {
    enable = true;
    dataDir = "${appData}/nixie/netboot";
    logDir = "${appData}/nixie/logs";

    file-server = {
      https = {
        enable = false;
        address = "ipxe.coditon.com";
      };

      menus = [
        {
          name = "kaakkuri-ephemeral-alpha";
          flakeUrl = "github:ponkila/homestaking-infra";
          hosts = [ "kaakkuri-ephemeral-alpha" ];
          timeout = 1;
        }
        {
          name = "torgue";
          flakeUrl = "github:tupakkatapa/nix-config";
          hosts = [ "torgue" "bandit" ];
          default = "torgue";
          timeout = 3;
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

