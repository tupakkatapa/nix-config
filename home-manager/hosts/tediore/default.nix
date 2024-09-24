{ pkgs
, lib
, ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    ../.config/rice02
  ];

  # Default apps by host
  home.sessionVariables = {
    FONT = lib.mkDefault "Noto Sans Mono";
  };

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    noto-fonts
    blueberry
    wl-clipboard
    mako
    swaybg
  ];
}

