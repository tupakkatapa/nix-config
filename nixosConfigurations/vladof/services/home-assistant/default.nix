{ lib
, dataDir
, haConfig
}:
let
  inherit (haConfig) uid port;

  # Import modular configs
  dashboard = import ./dashboard.nix;
  scripts = import ./scripts.nix;
  automations = import ./automations.nix;
in
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    configWritable = false;

    extraComponents = [
      "zha"
      "default_config"
      "met"
      # "mobile_app"
      "backup"
      "wake_on_lan"
    ];

    lovelaceConfig = dashboard;

    config = {
      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Europe/Helsinki";
        latitude = 65.0;
        longitude = 25.5;
        external_url = "https://home.coditon.com";
        internal_url = "https://home.coditon.com";
      };

      http = {
        server_port = port;
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "10.42.0.0/24"
          "10.42.1.0/24"
          "172.16.16.0/24"
          "169.254.0.0/16"
        ];
      };

      wake_on_lan = { };

      input_boolean = {
        morning_alarm = {
          name = "Enabled";
          icon = "mdi:weather-sunset-up";
        };
      };

      input_datetime = {
        morning_alarm_time = {
          name = "Time";
          has_date = false;
          has_time = true;
          icon = "mdi:clock-outline";
          initial = "09:00";
        };
      };

      light = [
        {
          platform = "group";
          name = "All Lights";
          entities = [
            "light.innr_rb_282_c"
            "light.innr_rb_282_c_2"
            "light.innr_rb_282_c_3"
            "light.innr_rb_282_c_4"
          ];
        }
        {
          platform = "group";
          name = "All Except Bedroom";
          entities = [
            "light.innr_rb_282_c_2"
            "light.innr_rb_282_c_3"
            "light.innr_rb_282_c_4"
          ];
        }
      ];

      switch = [
        {
          platform = "wake_on_lan";
          name = "maliwan";
          mac = "18:3d:2d:d2:de:41";
          broadcast_address = "10.42.0.255";
        }
        {
          platform = "wake_on_lan";
          name = "torgue";
          mac = "d4:5d:64:d1:12:52";
          broadcast_address = "10.42.0.255";
        }
        {
          platform = "wake_on_lan";
          name = "kaakkuri";
          mac = "70:85:c2:b5:be:db";
          broadcast_address = "10.42.0.255";
        }
      ];

      automation = automations;
      script = scripts;
    };
  };

  # Match UID from previous container setup
  users.users.hass = {
    isSystemUser = true;
    group = "hass";
    uid = lib.mkForce uid;
    extraGroups = [ "dialout" ];
  };
  users.groups.hass.gid = lib.mkForce uid;

  # Ensure data directory exists
  systemd.tmpfiles.rules = [
    "d ${dataDir}/home/home-assistant/appdata/hass 755 ${toString uid} ${toString uid} -"
  ];

  # Use custom data directory instead of default StateDirectory
  systemd.services.home-assistant.serviceConfig.StateDirectory = lib.mkForce [ ];
  services.home-assistant.configDir = "${dataDir}/home/home-assistant/appdata/hass";
}
