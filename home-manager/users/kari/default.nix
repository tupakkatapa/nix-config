# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, customLib
, unstable
, config
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
      archive = [ "file-roller.desktop" ];
      audio = [ "mpv.desktop" ];
      browser = [ "firefox.desktop" ];
      image = [ "imv-dir.desktop" ];
      markdown = [ "nvim.desktop" ];
      office = {
        presentation = [ "impress.desktop" ];
        spreadsheet = [ "calc.desktop" ];
        text = [ "writer.desktop" ];
      };
      pdf = [ "org.pwmt.zathura.desktop" ];
      text = [ "nvim.desktop" ];
      video = [ "mpv.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    # Custom desktop entry for opening files in nvim via terminal
    home.file."nvim.desktop" = {
      target = ".local/share/applications/nvim.desktop";
      text = ''
        [Desktop Entry]
        Type=Application
        Name=nvim (foot)
        Exec=foot nvim %F
        Terminal=false
      '';
    };

    # Auto-start floating terminal with SFTP mount on login
    wayland.windowManager.hyprland.settings.exec-once =
      if config.networking.hostName != "maliwan" then [
        "foot -e $SHELL -c 'echo \"\\$ sudo sftp-mount\" && sudo sftp-mount && sleep 1 || read -p \"Press enter to continue..\"'"
      ] else [ ];

    home.packages = (with pkgs; [
      monitor-adjust
      discord
      guitarix
      gxplugins-lv2

      # chromium
      # rpi-imager
      # appimage-run

      # Work
      google-chrome
      # libreoffice

      # Networking
      wireguard-go
      wireguard-tools

      codex
    ]) ++
    (with unstable; [
      claude-code
      gemini-cli
    ]);
  };
}
