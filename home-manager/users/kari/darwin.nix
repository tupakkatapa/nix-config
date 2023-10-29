{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  user = "kari";
  optionalPaths = paths: builtins.filter (path: builtins.pathExists path) paths;
in {
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  # Home-manager config
  home-manager.users."${user}" = {
    imports =
      [
        # GUI Apps
        ./config/alacritty.nix

        # CLI Apps
        ./config/direnv.nix
        ./config/fish.nix
        ./config/git.nix
        ./config/neovim.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

    # Default apps
    home.sessionVariables = {
      FONT = "JetBrainsMono Nerd Font";
    };

    home.packages = with pkgs; [
      android-tools
      eza
      gnupg
      htop
      jq
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
      wireguard-go
      wireguard-tools
      yt-dlp
    ];

    home.stateVersion = "23.05";
  };
}
