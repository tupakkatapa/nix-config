{ pkgs
, config
, ...
}:
let
  inherit (config.home.sessionVariables) FONT;
in
{
  gtk = {
    enable = true;
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    font = {
      name = "${FONT}";
      size = 10;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 16;
    };
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };
}
