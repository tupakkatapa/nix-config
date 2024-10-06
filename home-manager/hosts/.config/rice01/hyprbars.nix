# derived from: https://github.com/Misterio77/nix-config/blob/76e2a0590f34538cda1fbf518bf01612a549477d/home/gabriel/features/desktop/hyprland/hyprbars.nix
{ config
, pkgs
, lib
, ...
}@args:
let
  inherit (config.home.sessionVariables) THEME FONT;
  colors = (import ../../../colors.nix).${THEME};
  helpers = import ../../../helpers.nix args;

  hyprbars =
    (pkgs.hyprbars.override {
      # Make sure it's using the same hyprland package as we are
      hyprland = config.wayland.windowManager.hyprland.package;
    }).overrideAttrs
      (old: {
        # Yeet the initialization notification (I hate it)
        postPatch =
          (old.postPatch or "")
          + ''
            ${lib.getExe pkgs.gnused} -i '/Initialized successfully/d' main.cpp
          '';
      });

  hyprctl = "${pkgs.hyprland}/bin/hyprctl";
in
{
  home.packages = [ pkgs.font-awesome ];
  wayland.windowManager.hyprland = {
    plugins = [ hyprbars ];
    settings = {
      "plugin:hyprbars" = {
        bar_height = 20;
        bar_color = helpers.rgba colors.base00 "ff";
        "col.text" = helpers.rgb colors.base06;
        bar_text_font = FONT;
        bar_title_enabled = true;
        bar_text_size = "8";
        bar_part_of_window = true;
        bar_precedence_over_border = true;
        hyprbars-button = [
          # Red close button
          "${helpers.rgb colors.base08},10,,${hyprctl} dispatch killactive"
          # Green "maximize" (fullscreen) button
          "${helpers.rgb colors.base0B},10,,${hyprctl} dispatch fullscreen 1"
          # Yellow placeholder button
          "${helpers.rgb colors.base0A},10,,"
        ];
      };
    };
  };
}
