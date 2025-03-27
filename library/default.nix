{ lib, ... }:

{
  # Import and export all library modules
  hyprland = import ./hyprland.nix { inherit lib; };
  xdg = import ./xdg.nix { inherit lib; };
  colors = import ./colors.nix;

  # Utility functions that can be used across different modules
  utils = {
    max = a: b: if a > b then a else b;
  };
}
