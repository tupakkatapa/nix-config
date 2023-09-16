{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
in {
  # User config, setting password manually
  users.users.${user} = {
    isNormalUser = true;
    group = "${user}";
    extraGroups = [
      "audio"
      "video"
      "wheel"
      "users"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups.${user} = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    rsync
    nix
    git
    tmux
    vim
    wget
  ];
}
