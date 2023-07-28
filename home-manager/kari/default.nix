{
  pkgs,
  inputs,
  config,
  lib,
  ...
}:
with lib; {
  users.users.kari = {
    isNormalUser = true;
    group = "kari";
    extraGroups = [
      "wheel"
      "users"
      "video"
      "audio"
      "input"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.kari = {};
  environment.shells = [pkgs.fish];
  security.pam.services = {swaylock = {};};

  # Creating some directories
  systemd.tmpfiles.rules = [
    "d /home/kari/.ssh 755 kari kari -"
    "d /home/kari/Workspace 755 kari kari -"
    "d /home/kari/Pictures/Screenshots 755 kari kari -"
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  # Window manager
  home-manager.sharedModules = [
    inputs.hyprland.homeManagerModules.default
  ];
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
    waybar = {
      enable = true;
      package = pkgs.waybar.overrideAttrs (oa: {
        mesonFlags = (oa.mesonFlags or []) ++ ["-Dexperimental=true"];
      });
    };
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
      loginShellInit = ''
        if test (tty) = "/dev/tty1"
          exec Hyprland &> /dev/null
        end
      '';
    };
  };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";

    BROWSER = "librewolf";
    TERMINAL = "alacritty";
    EDITOR = "nvim";
  };

  # Home-manager
  home-manager.users.kari = {
    imports = [
      # GUI Apps
      ./config/librewolf
      ./config/alacritty

      # CLI Apps
      ./config/fish
      ./config/neovim

      # WM Apps
      ./config/waybar
      ./config/dunst
      ./config/swaylock
      ./config/swayidle
      ./config/wofi
    ];

    # Hyprland
    home.file = {
      ".config/hypr/audio-volume-high-panel.svg".source = ./assets/audio-volume-high-panel.svg;
      ".config/hypr/volume_notify.sh".source = ./config/hyprland/scripts/volume_notify.sh;
      ".config/hypr/hyprprop_notify.sh".source = ./config/hyprland/scripts/hyprprop_notify.sh;
      ".config/hypr/screenshot_notify.sh".source = ./config/hyprland/scripts/screenshot_notify.sh;
      "Pictures/wallpaper.jpg".source = ./assets/wallpaper.jpg;
    };
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.default;
      extraConfig = import ./config/hyprland/extraConfig.nix {inherit config;};
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "oomox-gruvbox-dark";
        package = pkgs.gruvbox-dark-icons-gtk;
      };
      font = {
        name = "JetBrains Mono";
        package = pkgs.jetbrains-mono;
        size = 10;
      };
      cursorTheme = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
      };
      theme = {
        name = "gruvbox-dark";
        package = pkgs.gruvbox-dark-gtk;
      };
    };

    home.packages = with pkgs; [
      # GUI Apps
      discord
      ferdium
      guitarix
      plex-media-player
      plexamp
      qjackctl
      solaar
      ventoy
      rpi-imager
      openrgb
      ardour
      blueberry
      pavucontrol
      mpv
      sxiv

      # High quality games
      osu-lazer
      runelite

      # CLI Apps
      killall
      pamixer
      exa
      gnupg
      htop
      jq
      kexec-tools
      lshw
      nix
      nix-tree
      ripgrep
      rsync
      ssh-to-age
      vim
      wget
      wireguard-tools
      yt-dlp
      playerctl

      # WM Apps
      grim
      swaybg
      swayidle
      wl-clipboard
      hyprpicker
      xfce.thunar
      xfce.thunar-archive-plugin
      slurp
      grim
      inputs.hyprwm-contrib.packages.${system}.hyprprop
    ];

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      signing.key = "773DC99EDAF29D356155DC91269CF32D790D1789";
      signing.signByDefault = true;
      userEmail = "jesse@ponkila.com";
      userName = "Jesse Karjalainen";
      extraConfig = {
        http = {
          # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
          postBuffer = "524288000";
        };
      };
    };

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      extensions = with pkgs.vscode-extensions; [
        bbenoist.nix
      ];
      userSettings = {
        "terminal.integrated.fontFamily" = "JetBrains Mono";
        "editor.tabSize" = 2;
      };
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
