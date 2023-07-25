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

  fonts.fonts = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  programs = {
    fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
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

  home.file = {
    ".config/hypr/volume_notify.sh".source = ./config/hyprland/volume_notify.sh;
    ".config/hypr/hyprprop.sh".source = ./config/hyprland/hyprprop_notify.sh;
    ".config/hypr/screenshot_notify.sh".source = ./config/hyprland/screenshot_notify.sh;
  };
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    extraConfig = import ./config/hyprland/extraConfig.nix { inherit config; };
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
      vscode
      steam
      ardour
      blueberry
      pavucontrol
      mpv
      sxiv

      # CLI Apps
      jq
      vim
      git
      rsync
      kexec-tools
      nix
      ssh-to-age
      wget
      gnupg
      exa

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

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs = {
      git.enable = true;
      home-manager.enable = true;
    };

    home.stateVersion = "23.05";
  };
}
