{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT THEME;
  colors = (import ../../../colors.nix).${THEME};
in
{
  home.packages = [ pkgs.libnotify ];
  services.mako = {
    enable = true;
    backgroundColor = "#${colors.base00}";
    borderColor = "#${colors.base06}";
    borderRadius = 10;
    borderSize = 2;
    defaultTimeout = 5000;
    font = "${FONT} 10";
    markup = true;
    icons = true;
    maxIconSize = 64;
    padding = "8,8";
    height = 1000;
    anchor = "top-right";
    textColor = "#${colors.base05}";
    progressColor = "#${colors.base08}";
    sort = "+time";
    groupBy = "app-name";
    extraConfig = ''
      [urgency=low]
      background-color=#${colors.base00}
      text-color=#${colors.base05}

      [urgency=normal]
      background-color=#${colors.base00}
      text-color=#${colors.base05}

      [urgency=critical]
      background-color=#${colors.base00}
      text-color=#${colors.base08}
    '';
  };
}

