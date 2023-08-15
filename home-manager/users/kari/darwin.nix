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
        ./config/vscode.nix

        # CLI Apps
        ./config/fish.nix
        ./config/neovim.nix
        ./config/git.nix
        ./config/direnv.nix
      ]
      # Importing host-spesific home-manager config if it exists
      ++ optionalPaths [../../hosts/${config.networking.hostName}];

    home.packages = with pkgs; [
      android-tools
      jq
      exa
      gnupg
      htop
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
