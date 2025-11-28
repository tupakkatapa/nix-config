{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.zathura.options = {
    # Recolor (theme the PDF content)
    recolor = true;
    recolor-lightcolor = "#${colors.base00}"; # Background
    recolor-darkcolor = "#${colors.base05}"; # Foreground text
    recolor-keephue = true;

    # UI colors
    default-bg = "#${colors.base00}";
    default-fg = "#${colors.base05}";

    statusbar-fg = "#${colors.base05}";
    statusbar-bg = "#${colors.base00}";

    inputbar-bg = "#${colors.base00}";
    inputbar-fg = "#${colors.base05}";

    notification-bg = "#${colors.base00}";
    notification-fg = "#${colors.base05}";
    notification-error-bg = "#${colors.base08}";
    notification-error-fg = "#${colors.base00}";
    notification-warning-bg = "#${colors.base09}";
    notification-warning-fg = "#${colors.base00}";

    highlight-color = "#${colors.base0A}";
    highlight-active-color = "#${colors.base0D}";

    completion-bg = "#${colors.base00}";
    completion-fg = "#${colors.base05}";
    completion-highlight-bg = "#${colors.base02}";
    completion-highlight-fg = "#${colors.base05}";

    index-bg = "#${colors.base00}";
    index-fg = "#${colors.base05}";
    index-active-bg = "#${colors.base02}";
    index-active-fg = "#${colors.base05}";
  };
}
