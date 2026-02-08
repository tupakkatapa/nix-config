{ pkgs, config, ... }:
let
  garageDir = "/mnt/jhvst/garage";
in
{
  services.garage = {
    enable = true;
    package = pkgs.garage;
    logLevel = "info";

    settings = {
      metadata_dir = "${garageDir}/metadata";
      data_dir = "${garageDir}/data";
      db_engine = "sqlite";

      replication_factor = 1;

      rpc_bind_addr = "[::]:3901";
      rpc_public_addr = "127.0.0.1:3901";
      rpc_secret_file = config.age.secrets.garage-rpc-secret.path;

      s3_api = {
        s3_region = "garage";
        api_bind_addr = "[::]:3900";
        root_domain = ".s3.garage.local";
      };

      s3_web = {
        bind_addr = "[::]:3902";
        root_domain = ".web.garage.local";
        index = "index.html";
      };

      k2v_api = {
        api_bind_addr = "[::]:3904";
      };

      admin = {
        api_bind_addr = "[::]:3903";
      };
    };
  };

  # RPC secret managed by agenix
  age.secrets."garage-rpc-secret" = {
    rekeyFile = ../secrets/garage-rpc-secret.age;
    owner = "garage";
    mode = "400";
  };

  # Create garage user and group explicitly
  systemd.services.garage.serviceConfig = {
    DynamicUser = false;
    User = "garage";
    Group = "garage";
  };
  users.users.garage = {
    isSystemUser = true;
    group = "garage";
  };
  users.groups.garage = { };

  # Open firewall for internal access
  networking.firewall.allowedTCPPorts = [
    3900 # S3 API
    3901 # RPC
    3902 # Web
    3903 # Admin API
    3904 # K2V API
  ];

  # Ensure garage directories exist with correct ownership
  systemd.tmpfiles.rules = [
    "d ${garageDir}          0750 garage garage -"
    "d ${garageDir}/metadata 0750 garage garage -"
    "d ${garageDir}/data     0750 garage garage -"
    "Z ${garageDir}          0750 garage garage -"
  ];
}
