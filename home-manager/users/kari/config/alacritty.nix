{
  pkgs,
  lib,
  ...
}: {
  home.sessionVariables = {
    TERMINAL = lib.mkDefault "alacritty";
  };

  programs.alacritty = let
    disableKeys = keysList:
      map (keyName: {
        key = keyName;
        action = "None";
      })
      keysList;
  in {
    enable = true;
    settings = {
      key_bindings = disableKeys ["Up" "Down" "Right" "Left"];
      window.padding = {
        x = 20;
        y = 20;
      };
      font = {
        normal = {
          family = "JetBrains Mono";
          style = "Bold";
        };
        bold = {
          family = "JetBrains Mono";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono";
          style = "MediumItalic";
        };
        bold_italic = {
          family = "JetBrains Mono";
          style = "BoldItalic";
        };
        size = 10;
      };
      draw_bold_text_with_bright_colors = true;
      selection.save_to_clioboard = false;
      shell.program = "${pkgs.fish}/bin/fish";

      colors = {
        primary = {
          background = "0x282828";
          foreground = "0xebdbb2";
        };

        normal = {
          black = "0x282828";
          red = "0xcc241d";
          green = "0x98971a";
          yellow = "0xd79921";
          blue = "0x458588";
          magenta = "0xb16286";
          cyan = "0x689d6a";
          white = "0xa89984";
        };

        bright = {
          black = "0x928374";
          red = "0xfb4934";
          green = "0xb8bb26";
          yellow = "0xfabd2f";
          blue = "0x83a598";
          magenta = "0xd3869b";
          cyan = "0x8ec07c";
          white = "0xebdbb2";
        };
      };
    };
  };
}
