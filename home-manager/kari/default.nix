# https://github.com/hyper-dot/Arch-Hyprland
{
  pkgs,
  inputs,
  lib,
  ...
}:
with lib; {
  # User config, setting password manually
  users.users.kari = {
    isNormalUser = true;
    group = "kari";
    extraGroups = [
      "audio"
      "input"
      "jackaudio"
      "users"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.kari = {};
  environment.shells = [pkgs.fish];

  security.pam.services = {swaylock = {};};
  programs.fish.enable = true;
  # https://github.com/nix-community/home-manager/issues/3113
  programs.dconf.enable = true;

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  # Creating some directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/kari/.ssh 755 kari kari -"
    "d /home/kari/Pictures/Screenshots 755 kari kari -"
    "d /home/kari/Workspace 755 kari kari -"
  ];

  # Home-manager
  home-manager.users.kari = {
    imports = [
      # GUI Apps
      ./config/alacritty.nix
      ./config/librewolf.nix
      ./config/vscode.nix

      # CLI Apps
      ./config/fish.nix
      ./config/neovim.nix

      # WM Apps
      ./config/dunst.nix
      ./config/gtk.nix
      ./config/hyprland
      ./config/swayidle.nix
      ./config/swaylock.nix
      ./config/waybar.nix
      ./config/wofi.nix
    ];

    # Qjackctl presets
    home.file = {
      "focusrite_guitarix_v2.xml".source = ./config/qjackctl/focusrite_guitarix_v2.xml;
    };

    home.packages = with pkgs; [
      # GUI Apps
      discord
      ferdium
      nsxiv
      openrgb
      plex-media-player
      plexamp
      qemu
      rpi-imager
      solaar
      ventoy
      xfce.thunar
      xfce.thunar-archive-plugin

      # Music stuff
      ardour
      guitarix
      qjackctl

      # High quality games
      osu-lazer
      runelite

      # CLI Apps
      exa
      gnupg
      htop
      iputils
      kexec-tools
      lshw
      neofetch
      nix
      nix-tree
      ripgrep
      rsync
      ssh-to-age
      sshfs
      tmux
      vim
      wget
      wireguard-tools
      yt-dlp

      # Wofi / Waybar / Hyrpland deps
      blueberry
      grim
      gummy
      hyprpicker
      inputs.hyprwm-contrib.packages.${system}.hyprprop
      jq
      mpv
      pamixer
      pavucontrol
      playerctl
      pulseaudio
      slurp
      swaybg
      wl-clipboard
    ];

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      signing.key = "773DC99EDAF29D356155DC91269CF32D790D1789";
      signing.signByDefault = true;
      userEmail = "jesse@ponkila.com";
      userName = "tupakkatapa";
      extraConfig.http = {
        # https://stackoverflow.com/questions/22369200/git-pull-push-error-rpc-failed-result-22-http-code-408
        postBuffer = "524288000";
      };
    };

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
