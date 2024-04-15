{ pkgs
, ...
}@args:
let
  helpers = import ../helpers.nix args;
in
{
  # Set as default
  home.sessionVariables = {
    FILEMANAGER = "thunar";
  };
  xdg.mime.enable = true;
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = helpers.createMimes {
    directory = [ "thunar.desktop" ];
  };
  xdg.configFile."mimeapps.list".force = true;

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
  ];
}
