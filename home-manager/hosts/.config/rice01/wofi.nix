{ config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT TERMINAL;
in
{
  programs.wofi = {
    enable = true;
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
        background-color: #282828;
        color: #d9e0ee;
        border: 2px solid #2E2D2C;
        border-radius: 0px;
      }

      #outer-box {
        padding: 20px;
      }

      #input {
        background-color: #2E2D2C;
        border: 0px solid #FFCE8A;
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
        background-color: #FFCE8A;
      }

      #text {
        color: #d9e0ee;
      }

      #text:selected {
        background-color: #FFCE8A;
        color: #282828;
      }

      #entry {
        padding: 6px;
      }

      #entry:selected {
        background-color: #FFCE8A;
        border-radius: 4px;
        color: #282828;
      }
    '';
  };
}
