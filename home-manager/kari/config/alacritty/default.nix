{
  pkgs,
  lib,
  config,
  ...
}: {
  home.sessionVariables = {
    TERMINAL = lib.mkDefault "alacritty";
  };

  programs.alacritty = {
    enable = true;
    settings = {
      window.padding = {
        x = 10;
        y = 10;
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
    };
  };
}
