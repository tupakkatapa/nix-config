# https://github.com/hyper-dot/Arch-Hyprland
{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
  optionalGroups = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in {
  # User config, setting password manually
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    extraGroups =
      [
        "audio"
        "video"
        "wheel"
      ]
      ++ optionalGroups [
        "input"
        "jackaudio"
        "users"
        "i2c"
        "podman"
        "libvirtd"
      ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  # Home-manager config
  home-manager.users."${user}" = {
    imports =
      [
        # GUI Apps
        ./config/alacritty.nix
        ./config/librewolf.nix
        ./config/vscode.nix

        # CLI Apps
        ./config/fish.nix
        ./config/neovim.nix
        ./config/git.nix
        ./config/direnv.nix
      ]
      # Importing host spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

    # Qjackctl presets
    home.file = {
      "focusrite_guitarix_v2.xml".source = ./config/qjackctl/focusrite_guitarix_v2.xml;
      "focusrite_guitarix_ardour_v2.xml".source = ./config/qjackctl/focusrite_guitarix_ardour_v2.xml;
    };

    home.packages = with pkgs; [
      # GUI Apps
      discord
      ferdium
      plex-media-player
      plexamp
      qemu
      rpi-imager
      solaar
      ventoy

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
    ];

    programs.home-manager.enable = true;
    home.stateVersion = "23.05";
  };
}
