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

  # Trust vladof's self-signed cert for private services
  security.pki.certificateFiles = [
    ../../../nixosConfigurations/vladof/services/selfsigned-cert.pem
  ];

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/claude
    ];

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

    # oterm
    home.sessionVariables = {
      OLLAMA_URL = "https://chat.coditon.com/";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
    };
    xdg.dataFile."oterm/config.json".text = builtins.toJSON {
      theme = "gruvbox";
      splash-screen = false;
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
      let
        # User-level variable, cannot use $BROWSER as might not be set yet
        browser = config.home-manager.users."${user}".home.sessionVariables.BROWSER;
        browserFlags = profile: if browser == "firefox" then "--new-instance -P ${profile}" else "";
      in
      [
        # Open programs on specific workspaces
        "[workspace 4 silent] ${browser} ${browserFlags "personal"} https://web.whatsapp.com https://web.telegram.org/ https://discord.com/channels/@me https://outlook.live.com/mail/0/"
        "[workspace 5 silent] ${browser} ${browserFlags "work"} https://app.slack.com/client https://mail.google.com/mail https://calendar.google.com/calendar https://drive.google.com/drive/home https://www.notion.so/"
      ]
      ++ (if config.networking.hostName != "maliwan" then [
        # Open terminal with SFTP mount on login
        "foot -e $SHELL -c 'echo \"\\$ sudo sftp-mount\" && sudo sftp-mount && sleep 1 || read -p \"Press enter to continue..\"'"
      ] else [ ]);

    home.packages = (with pkgs; [
      monitor-adjust
      tui-suite

      guitarix
      gxplugins-lv2

      # Networking
      wireguard-go
      wireguard-tools

      oterm
    ]) ++
    (with unstable; [
    ]);
  };
}
