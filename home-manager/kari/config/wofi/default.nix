{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [ pkgs.wofi ];

  home.file = {
    # Full
    ".config/wofi/full_colors".source = ./full/colors;
    ".config/wofi/full_config".source = ./full/config;
    ".config/wofi/full_style.css".source = ./full/style.css;
    # Menu
    ".config/wofi/colors".source = ./colors;
    ".config/wofi/config".source = ./config;
    ".config/wofi/style.css".source = ./style.css;
    # Scripts 
    ".config/wofi/fullmenu.sh".source = ./scripts/fullmenu.sh;
    ".config/wofi/pipewire-out-switcher.sh".source = ./scripts/pipewire-out-switcher.sh;
    ".config/wofi/radio.sh".source = ./scripts/radio.sh;
  };
}
