{ config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) FONT TERMINAL THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.wofi = {
    settings = {
      # General
      columns = 5;
      show = "drun";
      layer = "overlay";
      insensitive = true;
      normal_window = true;
      prompt = " Search ... ";
      term = "${TERMINAL}";

      # Geometry
      dynamic_lines = true;
      location = 0;

      # Images
      allow_images = true;
      allow_markup = true;
      image_size = 24;

      # Other
      gtk_dark = true;
      hide_scroll = true;
      no_actions = true;
      sort_order = "default";

      # Search
      parse_search = true;
    };

    style = ''
      * {
        font-family: "${FONT}";
        font-size: 14px;
      }

      #wofi-window {
        background-color: #${colors.base00};
        color: #${colors.base05};
        border: 2px solid #${colors.base01};
        border-radius: 0px;
      }

      #outer-box {
        padding: 20px;
      }

      #input {
        background-color: #${colors.base01};
        border: 0px solid #${colors.base0A};
        padding: 8px 12px;
        border-radius: 4px;
      }

      #scroll {
        margin-top: 20px;
        margin-bottom: 20px;
      }

      #img {
        padding-right: 8px;
      }

      #img:selected {
        background-color: #${colors.base0A};
      }

      #text {
        color: #${colors.base05};
      }

      #text:selected {
        background-color: #${colors.base0A};
        color: #${colors.base00};
      }

      #entry {
        padding: 6px;
      }

      #entry:selected {
        background-color: #${colors.base0A};
        border-radius: 4px;
        color: #${colors.base00};
      }
    '';
  };
}
