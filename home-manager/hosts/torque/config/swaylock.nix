# derived from: https://github.com/Misterio77/nix-config/blob/0ed82f3d63a366eafbacb8eee27985afe30b249a/home/misterio/features/desktop/common/wayland-wm/swaylock.nix
{
  pkgs,
  config,
  ...
}: let
  inherit (config.home.sessionVariables) FONT;
in {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      effect-blur = "20x3";
      fade-in = 0.1;

      font = "${FONT}";
      font-size = 15;

      line-uses-inside = true;
      disable-caps-lock-text = true;
      indicator-caps-lock = true;
      indicator-radius = 40;
      indicator-idle-visible = true;
      indicator-y-position = 1000;
    };
  };
}
