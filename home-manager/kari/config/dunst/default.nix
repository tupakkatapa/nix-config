{pkgs, ...}: {
  home.packages = [pkgs.libnotify];
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

        offset = "10x10";

        notification_height = 0;

        separator_height = 2;

        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        frame_width = 2;

        frame_color = "#ffce8a";
        separator_color = "frame";

        sort = "yes";
        idle_threshold = 120;
        font = "JetBrains Mono NL SemiBold 10";
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
        background = "#1e1e1e";
        foreground = "#fffee3";
      };
      urgency_normal = {
        background = "#1e1e1e";
        foreground = "#fffee3";
      };
      urgency_critical = {
        background = "#1E1E2E";
        foreground = "#CDD6F4";
        frame_color = "#FAB387";
      };
    };
  };
}
