{ pkgs
, config
, customLib
, ...
}:
let
  inherit (config.home.sessionVariables) THEME;
  colors = customLib.colors.${THEME};
in
{
  imports = [
    ./hyprland.nix
    ./thunar.nix
    ./mpv.nix
    ./imv.nix
    ./zathura.nix
  ];

  # Screen locker + idle daemon
  programs.hyprlock.enable = true;
  services.hypridle =
    let
      lockCountdown = "${pkgs.wm-helpers}/bin/lock-countdown";
      idleSec = 300;
      warnSec = 10;
    in
    {
      enable = true;
      settings = {
        general = {
          lock_cmd = "if ! pgrep hyprlock; then hyprlock; fi";
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
        };
        listener = [
          {
            timeout = idleSec - warnSec;
            on-timeout = "${lockCountdown} ${toString warnSec} nolock";
            on-resume = "${lockCountdown} cancel";
          }
          # +2s buffer so countdown vanishes before lock screen appears
          { timeout = idleSec + 2; on-timeout = "loginctl lock-session"; }
          { timeout = idleSec + 60; on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }
        ];
      };
    };

  # Default app associations
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = customLib.xdg.createMimes {
    archive = [ "thunar-archive-open.desktop" ];
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

  # Open files in nvim via terminal
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

  home.packages = with pkgs; [
    libnotify
    wf-recorder
    wl-clipboard
    wlsunset

    # TUI managers
    voltui
    blutui
    nettui
    mustui
    kaltui
    caltui
  ];

  home.sessionVariables = {
    FILEMANAGER = "thunar";
  };

  gtk.enable = true;

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      markup = true;
      icons = true;
      max-icon-size = 64;
      padding = "8,8";
      height = 1000;
      anchor = "top-right";
      sort = "+time";
      group-by = "app-name";

      # Lock countdown
      "app-name=lock-countdown" = {
        anchor = "center";
        width = 600;
        height = 240;
        padding = "32";
        border-size = 4;
        font = "monospace bold 30";
        default-timeout = 1100;
      };

      # Critical warnings
      "app-name=warning" = {
        anchor = "center";
        width = 600;
        height = 200;
        padding = "32";
        border-size = 4;
        background-color = "#${colors.base08}";
        font = "monospace bold 28";
        default-timeout = 5000;
      };
    };
  };

  # Memory pressure: poll every 30s, warn on rising edge over 90%
  systemd.user.services.mem-warn = {
    Unit.Description = "Memory-pressure notification check";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.wm-helpers}/bin/mem-warn 90";
    };
  };
  systemd.user.timers.mem-warn = {
    Unit.Description = "Run mem-warn every 30s";
    Timer = {
      OnBootSec = "1min";
      OnUnitActiveSec = "30s";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  programs.waybar.enable = true;
  programs.wofi.enable = true;

  # Automount removable media
  # services.udiskie = {
  #   enable = true;
  #   settings = {
  #     # Workaround for https://github.com/nix-community/home-manager/issues/632
  #     program_options = {
  #       file_manager = "${pkgs.nautilus}/bin/nautilus";
  #     };
  #   };
  # };
}
