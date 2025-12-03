{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;
in
{
  gtk = {
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    font = {
      name = "${FONT}";
      size = 10;
    };
    cursorTheme = {
      name = "capitaine-cursors";
      package = pkgs.capitaine-cursors;
      size = 16;
    };
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
  };

  home.pointerCursor = {
    name = "capitaine-cursors";
    package = pkgs.capitaine-cursors;
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };
}
