{ config, lib, pkgs, ... }:
let
  cfg = config.services.foobar;
in
{
  # Declare the configuration options
  options.services.foobar = {
    enable = lib.mkEnableOption "Whether to enable the foobar service.";

    setting = lib.mkOption {
      type = lib.types.str;
      default = "default-value";
      description = "Some configuration setting for the foobar service.";
    };
  };

  # Define the config implementation
  config = lib.mkIf cfg.enable {
    systemd.services.foobar = {
      description = "foobar Service";
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

