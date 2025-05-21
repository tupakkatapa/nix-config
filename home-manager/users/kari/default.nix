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
    wayland.windowManager.hyprland = {
      extraConfig = ''
        exec-once = $TERMINAL -T "SFTP Mount" sh -c "echo '\$ sudo sftp-mount' && sudo sftp-mount && sleep 1 || read"
        windowrulev2 = float, title:SFTP Mount
        windowrulev2 = center, title:SFTP Mount
        windowrulev2 = size 600 450, title:SFTP Mount
      '';
    };

    home.packages = with pkgs; [
      monitor-adjust
      levari

      discord
      # chromium
      # rpi-imager
      # appimage-run

      # Also available via runtime-modules, but using these very often
      guitarix
      gxplugins-lv2
      ladspaPlugins
      qjackctl

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
