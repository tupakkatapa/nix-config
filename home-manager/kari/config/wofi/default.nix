{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.wofi];

  home.file = {
    ".config/wofi/colors".source = ./colors;
    ".config/wofi/config_drun".source = ./config_drun;
    ".config/wofi/config_dmenu".source = ./config_dmenu;
    ".config/wofi/style.css".source = ./style.css;
    # Scripts
    ".config/wofi/fullmenu.sh".source = ./scripts/fullmenu.sh;
    ".config/wofi/pipewire-out-switcher.sh".source = ./scripts/pipewire-out-switcher.sh;
    ".config/wofi/radio.sh".source = ./scripts/radio.sh;
  };
}
