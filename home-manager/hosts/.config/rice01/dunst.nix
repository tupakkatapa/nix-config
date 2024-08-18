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
  services.dunst = {
    enable = true;
    iconTheme = {
      # Icons
      name = "Papirus Dark";
      package = pkgs.papirus-icon-theme;
      size = "16x16";
    };
    settings = {
      global = {
        follow = "mouse";
        monitor = 0;
        indicate_hidden = "yes";

        offset = "15x15";

        notification_height = 0;

        separator_height = 2;

        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        frame_width = 2;

        frame_color = "#${colors.base06}";
        separator_color = "frame";

        sort = "yes";
        idle_threshold = 120;
        font = "${FONT} 10";
        line_height = 0;
        markup = "full";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        word_wrap = "yes";
        stack_duplicates = true;
        hide_duplicate_count = false;

        show_indicators = "yes";

        min_icon_size = 32;
        max_icon_size = 64;

        title = "Dunst";
        class = "Dunst";

        corner_radius = 10;
        timeout = 5;
      };
      urgency_low = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
      };
      urgency_normal = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
      };
      urgency_critical = {
        background = "#${colors.base00}";
        foreground = "#${colors.base08}";
      };
    };
  };
}
