{
  inputs,
  outputs,
  config,
  pkgs,
  lib,
  ...
}: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
    });
  };

  home.file = {
    ".config/waybar/config".source = ./config.json;
    ".config/waybar/style.css".source = ./style.css;
  };
}
