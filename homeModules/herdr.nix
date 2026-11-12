# herdr, terminal workspace manager for AI coding agents
{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.programs.herdr;
  toml = pkgs.formats.toml { };
in
{
  options.programs.herdr = {
    enable = lib.mkEnableOption "herdr";

    package = lib.mkPackageOption pkgs "herdr" { };

    settings = lib.mkOption {
      inherit (toml) type;
      default = { };
      description = "Written to {file}`$XDG_CONFIG_HOME/herdr/config.toml`.";
    };

    server.enable = lib.mkEnableOption "the herdr server as a user service from boot, for saved machines elsewhere to attach to";

    machines = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "vladof" ];
      description = "SSH targets listed as saved machines beside the local workspaces.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ];
      xdg.configFile."herdr/config.toml".source = toml.generate "herdr-config.toml" cfg.settings;
    }

    # Reports the session to herdr for resume; `herdr integration install claude` cannot write the read-only settings
    (lib.mkIf config.programs.claude-code.enable {
      programs.claude-code.settings.hooks.SessionStart = [{
        matcher = "^(startup|resume|clear|compact|fork)$";
        hooks = [{
          type = "command";
          command = "PATH=${pkgs.python3}/bin:$PATH ${pkgs.bash}/bin/bash ${cfg.package.src}/src/integration/assets/claude/herdr-agent-state.sh session";
          timeout = 10;
        }];
      }];
    })

    # A saved machine attaches to a running server but does not start one
    (lib.mkIf cfg.server.enable {
      systemd.user.services.herdr = {
        Unit = {
          Description = "herdr server";
          # A rebuild would otherwise restart it and kill every running claude
          X-SwitchMethod = "keep-old";
        };
        Service = {
          ExecStart = "${lib.getExe cfg.package} server";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };
    })

    (lib.mkIf (cfg.machines != [ ]) {
      # herdr wants a 32-hex id
      xdg.stateFile."herdr/client/endpoints.json".text = builtins.toJSON {
        version = 1;
        ssh = map
          (target: {
            id = builtins.hashString "md5" target;
            label = target;
            inherit target;
            session = "default";
            enabled = true;
          })
          cfg.machines;
      };
    })
  ]);
}
