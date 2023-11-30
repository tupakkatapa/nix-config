{
  lib,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    displayManager = {
      defaultSession = "plasma-bigscreen-wayland";
      autoLogin = {
        enable = true;
        user = "kari";
      };
      sddm.enable = true;
      sddm.wayland.enable = true;
      sddm.autoLogin.relogin = true;
    };

    desktopManager.plasma5 = {
      # mobile.enable = true;
      # kdeglobals = {
      #   KDE = {
      #     LookAndFeelPackage = lib.mkDefault "org.kde.plasma.mycroft.bigscreen";
      #   };
      # };
      kwinrc = {
        Windows = {
          BorderlessMaximizedWindows = true;
        };
      };
      # kwinrc = {
      #   "Wayland" = {
      #     "InputMethod[$e]" = "/run/current-system/sw/share/applications/com.github.maliit.keyboard.desktop";
      #     "VirtualKeyboardEnabled" = "true";
      #   };
      #   "org.kde.kdecoration2" = {
      #     # No decorations (title bar)
      #     NoPlugin = lib.mkDefault "true";
      #   };
      # };
      bigscreen.enable = true;
      useQtScaling = true;
    };
  };
  programs.kdeconnect.enable = true;

  environment.systemPackages = with pkgs; [
    plexamp
    plex-media-player
    librewolf
    libsForQt5.kweather
    libsForQt5.plasmatube
  ];
}
