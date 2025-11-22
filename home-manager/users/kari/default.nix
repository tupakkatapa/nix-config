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

    # Environment variables
    home.sessionVariables = {
      OLLAMA_URL = "https://chat.coditon.com/";
    };

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

    # Use spesific startup
    wayland.windowManager.hyprland.settings.exec-once =
      [
        # Open programs on specific workspaces
        "[workspace 4 silent] $BROWSER web.whatsapp.com web.telegram.org discord.com/channels/@me outlook.live.com"
        "[workspace 5 silent] $BROWSER app.slack.com/client mail.google.com calendar.google.com drive.google.com www.notion.so"
      ]
      ++ (if config.networking.hostName != "maliwan" then [
        # Open terminal with SFTP mount on login
        "foot -e $SHELL -c 'echo \"\\$ sudo sftp-mount\" && sudo sftp-mount && sleep 1 || read -p \"Press enter to continue..\"'"
      ] else [ ]);

    home.packages = (with pkgs; [
      monitor-adjust
      guitarix
      gxplugins-lv2

      # chromium
      # rpi-imager
      # appimage-run

      # Work
      # libreoffice

      # Networking
      wireguard-go
      wireguard-tools

      oterm
      codex
    ]) ++
    (with unstable; [
      claude-code
      gemini-cli
    ]);
  };
}
