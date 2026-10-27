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
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
    gtk4.theme = config.gtk.theme;
  };

  home.pointerCursor = {
    name = "Capitaine Cursors (Gruvbox)";
    # The package ships eight colour variants; only this one is used
    package = pkgs.runCommand "capitaine-cursors-gruvbox" { } ''
      mkdir -p $out/share/icons
      cp -r "${pkgs.capitaine-cursors-themed}/share/icons/${config.home.pointerCursor.name}" $out/share/icons/
    '';
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # Fixes cursor themes in gnome apps under hyprland
      "gsettings set org.gnome.desktop.interface cursor-theme '${config.home.pointerCursor.name}'"
      "gsettings set org.gnome.desktop.interface cursor-size ${toString config.home.pointerCursor.size}"
    ];
  };
}
