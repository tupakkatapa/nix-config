{ pkgs
, lib
, ...
}:
let
  createMimes = values: option:
    lib.listToAttrs (lib.flatten (lib.mapAttrsToList
      (name: types:
        if lib.hasAttr name option
        then map (type: lib.nameValuePair type option."${name}") types
        else [ ])
      values));
in
{
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [
    # ./config/swayidle.nix
    # ./config/swaylock.nix
    ./config/dunst.nix
    ./config/gtk.nix
    ./config/hyprland.nix
    ./config/waybar.nix
    ./config/wofi.nix
  ];

  # Default apps
  home.sessionVariables = {
    FILEMANAGER = "thunar";
    FONT = "JetBrainsMono Nerd Font";
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = createMimes (import ./mimes.nix) {
    audio = [ "mpv.desktop" ];
    archive = [ "xarchiver.desktop" ];
    directory = [ "thunar.desktop" ];
    image = [ "imv-dir.desktop" ];
    pdf = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];
    text = [ "org.xfce.mousepad.desktop" ];
    video = [ "mpv.desktop" ];
  };
  xdg.configFile."mimeapps.list".force = true;

  # Allow fonts trough home.packages
  fonts.fontconfig.enable = true;

  # NOTE: see https://github.com/NixOS/nixpkgs/issues/248192
  nixpkgs.overlays = [
    (_self: super: {
      xarchiver = super.xarchiver.overrideAttrs (_old: {
        postInstall = ''
          rm -rf $out/libexec
        '';
      });

      xfce = super.xfce.overrideScope (_xself: xsuper: {
        thunar-archive-plugin = xsuper.thunar-archive-plugin.overrideAttrs (_old: {
          postInstall = ''
            cp ${super.xarchiver}/libexec/thunar-archive-plugin/* $out/libexec/thunar-archive-plugin/
          '';
        });
      });
    })
  ];

  home.packages = with pkgs; [
    # Nautilus
    gnome.nautilus
    gnome.file-roller
    gnome.sushi

    # Thunar
    (xfce.thunar.override {
      thunarPlugins = [
        xfce.thunar-archive-plugin
        xfce.thunar-volman
        xfce.thunar-dropbox-plugin
        xfce.thunar-media-tags-plugin
      ];
    })
    xfce.xfconf
    xfce.tumbler

    # GUI tools
    xfce.mousepad
    xarchiver
    zathura
    imv

    # Fonts
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
    font-awesome # for waybar

    # WM Apps
    swaybg
    wl-clipboard
    pavucontrol
    pulseaudio
  ];
}
