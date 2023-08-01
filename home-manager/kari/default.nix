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
      "wheel"
      "users"
      "video"
      "audio"
      "input"
      "jackaudio"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.kari = {};
  environment.shells = [pkgs.fish];

  # Creating some directories, these are persistent
  systemd.tmpfiles.rules = [
    "d /home/kari/.ssh 755 kari kari -"
    "d /home/kari/Workspace 755 kari kari -"
    "d /home/kari/Pictures/Screenshots 755 kari kari -"
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
  ];

  # services.user.mounts = [
  #   {
  #     enable = true;
  #     description = "Backup disk";

  #     what = "/dev/disk/by-id/60c4a67d-166b-48d2-a1c2-e457850a87df";
  #     where = "/mnt/3TB";
  #     type = "ext4";
  #     options = "defaults";
  #     wantedBy = [ "multi-user.target" ];
  #   }
  #   {
  #     enable = true;
  #     description = "SFTP mount";

  #     what = "sftp_user@vladof:/root";
  #     where = "/mnt/SFTP";
  #     type = "fuse.sshfs";
  #     options = "identityfile=/home/kari/.ssh/id_ed25519,allow_other,ssh_command=kari@vladof";
  #     wantedBy = [ "multi-user.target" ];
  #   }
  # ];

  # Hyprland
  home-manager.sharedModules = [
    inputs.hyprland.homeManagerModules.default
  ];
  programs = {
    hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
  };
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  security.pam.services = {swaylock = {};};

  # Fish
  programs.fish.enable = true;

  # Home-manager
  home-manager.users.kari = {
    imports = [
      # GUI Apps
      ./config/librewolf.nix
      ./config/alacritty.nix
      ./config/vscode.nix

      # CLI Apps
      ./config/fish.nix
      ./config/neovim.nix

      # WM Apps
      ./config/hyprland
      ./config/waybar.nix
      ./config/dunst.nix
      ./config/swaylock.nix
      ./config/swayidle.nix
      ./config/wofi
      ./config/gtk.nix
    ];

    # Qjackctl presets
    home.file = {
      "focusrite-guitarix.xml".source = ./config/qjackctl/focusrite-guitarix.xml;
      "focusrite-guitarix-ardour-2tracks.xml".source = ./config/qjackctl/focusrite-guitarix-ardour-2tracks.xml;
    };

    home.packages = with pkgs; [
      # GUI Apps
      discord
      ferdium
      plex-media-player
      plexamp
      solaar
      ventoy
      rpi-imager
      openrgb
      xfce.thunar
      xfce.thunar-archive-plugin
      nsxiv
      qemu

      # Music stuff
      guitarix
      qjackctl
      ardour

      # High quality games
      osu-lazer
      runelite

      # CLI Apps
      exa
      gnupg
      htop
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
      sshfs
      tmux
      iputils
      neofetch

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
