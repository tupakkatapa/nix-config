{ pkgs, ... }:
{
  # Cursor theme for cage kiosk
  home.pointerCursor = {
    name = "Capitaine Cursors (Gruvbox)";
    package = pkgs.capitaine-cursors-themed;
    size = 32;
  };
}
