{ pkgs, config, lib, ... }: {
  home.pointerCursor = {
    name = "Capitaine Cursors (Gruvbox)";
    # The package ships eight colour variants; only this one is used
    package = pkgs.runCommand "capitaine-cursors-gruvbox" { } ''
      mkdir -p $out/share/icons
      cp -r "${pkgs.capitaine-cursors-themed}/share/icons/${config.home.pointerCursor.name}" $out/share/icons/
    '';
    size = lib.mkDefault 24;
    gtk.enable = true;
    x11.enable = true;
  };
}
