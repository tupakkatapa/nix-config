{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;
  inherit
    (import ./colors.nix)
    background
    foreground
    accent
    red
    ;
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

        frame_color = "#${accent}";
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
        background = "#${background}";
        foreground = "#${foreground}";
      };
      urgency_normal = {
        background = "#${background}";
        foreground = "#${foreground}";
      };
      urgency_critical = {
        background = "#${background}";
        foreground = "#${red}";
      };
    };
  };
}
