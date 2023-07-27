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
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  programs.fish = {
    enable = true;
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

  # Home-manager
  home-manager.users.kari = {
    imports = [
      ./config/fish
      ./config/waybar
      ./config/neovim
      ./config/dunst
      ./config/swaylock
      ./config/swayidle
      ./config/wofi
      ./config/librewolf
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
      steam
      ardour
      blueberry
      pavucontrol
      mpv
      sxiv

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
      inputs.hyprwm-contrib.packages.${system}.hyprprop

      # Window manager
      gnome.file-roller
      grim
      swaybg
      swayidle
      wl-clipboard
      wl-color-picker
      wl-gammactl
      wl-mirror
      xfce.thunar
      xfce.thunar-archive-plugin
    ];

    programs.alacritty = {
      enable = true;
      settings = {
        window.padding = {
          x = 10;
          y = 10;
        };
        font = {
          normal = {
            family = "JetBrains Mono";
            style = "Bold";
          };
          bold = {
            family = "JetBrains Mono";
            style = "Bold";
          };
          italic = {
            family = "JetBrains Mono";
            style = "MediumItalic";
          };
          bold_italic = {
            family = "JetBrains Mono";
            style = "BoldItalic";
          };
          size = 10;
        };
        draw_bold_text_with_bright_colors = true;
        selection.save_to_clioboard = false;
        shell.program = "${pkgs.fish}/bin/fish";
      };
    };

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
