{ pkgs
, unstable
, config
, ...
}:
let
  user = "kari";
  hasOllama = config.services.ollama.enable;
  ollamaUrl = if hasOllama then "http://localhost:11434" else "https://chat.coditon.com/";
in
{
  # This configuration extends the minimal-passwd and minimal-gui versions
  imports = [ ./minimal-passwd.nix ./minimal-gui.nix ];

  # Required for hyprlock via home-manager
  security.pam.services.hyprlock = { };

  # Android development
  programs.adb.enable = true;

  # Trezor hardware wallet
  services.trezord.enable = true;

  # Home-manager config
  home-manager.users."${user}" = {
    imports = [
      ./.config/claude
    ];

    home.sessionVariables = {
      OLLAMA_URL = ollamaUrl;
      SEARXNG_URL = "https://search.coditon.com";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      REQUESTS_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
    };
    # oterm
    xdg.dataFile."oterm/config.json".text = builtins.toJSON {
      mcpServers = {
        searxng = {
          command = "npx";
          args = [ "-y" "mcp-searxng" ];
          env = {
            SEARXNG_URL = "https://search.coditon.com";
            NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-bundle.crt";
          };
        };
        filesystem = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-filesystem" "/home/${user}" ];
        };
        fetch = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-fetch" ];
        };
        git = {
          command = "npx";
          args = [ "-y" "@modelcontextprotocol/server-git" ];
        };
      };
      theme = "gruvbox";
      splash-screen = false;
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

      # Trezor (override: keyring 25.7.0 not yet in nixpkgs)
      (trezorctl.overridePythonAttrs (old: {
        pythonRelaxDeps = (old.pythonRelaxDeps or [ ]) ++ [ "keyring" ];
      }))

    ]) ++
    (with unstable; [
      oterm
    ]);
  };
}
