{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.foobar;
in
{
  # Declare the configuration options
  options = {
    services.foobar = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Foobar service.";
      };

      setting = mkOption {
        type = types.str;
        default = "default-value";
        description = "Some configuration setting for the Foobar service.";
      };
    };
  };

  # Define the config implementation
  config = mkIf cfg.enable {
    systemd.services.foobar = {
      description = "Foobar Service";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.foobar}/bin/foobar ${cfg.setting}";
        Restart = "always";
      };
      install = {
        wantedBy = [ "multi-user.target" ];
      };
    };
  };
}

