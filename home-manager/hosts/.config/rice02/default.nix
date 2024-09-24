{ pkgs, ... }: {
  imports = [
    ./sway.nix
    ../rice01/rgb.nix
  ];

  home.packages = with pkgs; [
    blueberry
    mako
    swaybg
    wl-clipboard
  ];
}

