# https://github.com/hyper-dot/Arch-Hyprland
{ pkgs
, config
, ...
}@args:
let
  user = "kari";
  helpers = import ../../helpers.nix args;
in
{
  # This configuration extends the minimal-passwd and minimal-gui versions
  imports = [ ./minimal-passwd.nix ./minimal-gui.nix ];

  # Secrets
  age.secrets."openai-api-key" = {
    file = ./secrets/openai-api-key.age;
    mode = "600";
    owner = user;
    group = "users";
  };

  # Home-manager config
  home-manager.users."${user}" = {
    # Default apps
    xdg.mimeApps.enable = true;
    xdg.mimeApps.defaultApplications = helpers.createMimes {
      text = [ "writer.desktop" ];
      spreadsheet = [ "calc.desktop" ];
      presentation = [ "impress.desktop" ];
    };
    xdg.configFile."mimeapps.list".force = true;

    # Configure chatgpt-cli
    home.sessionVariables = {
      OPENAI_API_KEY = "$(cat ${config.age.secrets.openai-api-key.path})";
    };
    home.file.".chatgpt-cli/config.yaml".text = builtins.toJSON {
      "name" = "openai";
      "model" = "gpt-4o-mini ";
      "track_token_usage" = true;
    };

    home.packages = with pkgs; [
      monitor-adjust

      sublime-merge
      plexamp
      chatgpt-cli

      # GUI
      # libreoffice-qt
      # chromium
      nautilus
      # rpi-imager

      # Media creation and editing
      # aseprite
      # gimp
      # kdenlive
      # video-trimmer

      # Music production
      # ardour
      audacity
      guitarix
      # gxplugins-lv2
      # ladspaPlugins
      qjackctl
      # tuxguitar

      # Networking
      wireguard-go
      wireguard-tools
    ];
  };
}
