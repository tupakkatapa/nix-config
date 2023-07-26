{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.wofi];

  home.file = {
    # Full
    ".config/wofi/full_colors".source = ./full_colors;
    ".config/wofi/full_config".source = ./full_config;
    ".config/wofi/full_style.css".source = ./full_style.css;
    # Menu
    ".config/wofi/menu_colors".source = ./menu_colors;
    ".config/wofi/menu_config".source = ./menu_config;
    ".config/wofi/menu_style.css".source = ./menu_style.css;
    # Scripts 
    ".config/wofi/dm-fullmenu.sh".source = ./dm-fullmenu.sh;
    ".config/wofi/dm-pipewire-out-switcher.sh".source = ./dm-pipewire-out-switcher.sh;
    ".config/wofi/dm-radio.sh".source = ./dm-radio.sh;
    ".config/wofi/dm-setbg.sh".source = ./dm-setbg.sh;
  };
}
