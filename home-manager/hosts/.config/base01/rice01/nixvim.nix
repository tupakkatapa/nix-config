# https://github.com/jhvst/nix-config/blob/main/nixosModules/neovim/default.nix
{ config
, lib
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  programs.nixvim = {
    colorschemes.base16 = {
      enable = true;
      colorscheme = lib.mapAttrs (_name: color: "#${color}") colors;
    };
  };
}

