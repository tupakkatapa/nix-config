# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, customLib
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal-passwd and minimal-gui versions
  imports = [ ./minimal-passwd.nix ./minimal-gui.nix ];

  # Home-manager config
  home-manager.users."${user}" = {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
      text = [ "writer.desktop" ];
      spreadsheet = [ "calc.desktop" ];
      presentation = [ "impress.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    # Auto-start floating terminal with SFTP mount on login
    wayland.windowManager.hyprland.settings.exec-once = [
      "foot -e $SHELL -c 'echo \"\\$ sudo sftp-mount\" && sudo sftp-mount && sleep 1 || read -p \"Press enter to continue..\"'"
    ];

    home.packages = with pkgs; [
      monitor-adjust
      levari
      discord
      guitarix

      # chromium
      # rpi-imager
      # appimage-run

      # Work
      google-chrome
      libreoffice
      claude-code

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
