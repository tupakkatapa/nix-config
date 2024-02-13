{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  user = "core";
in {
  networking.hostName = "bandit";

  # Autologin
  services.getty.autologinUser = user;

  # User config
  users.users."${user}" = {
    isNormalUser = true;
    group = user;
    extraGroups = [
      "audio"
      "users"
      "video"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEdpdbTOz0h9tVvkn13k1e8X7MnctH3zHRFmYWTbz9T kari@torque"
    ];
    shell = pkgs.fish;
  };
  users.groups."${user}" = {};
  environment.shells = [pkgs.fish];
  programs.fish.enable = true;

  # Allow passwordless sudo from wheel group
  security.sudo = {
    enable = true;
    wheelNeedsPassword = lib.mkForce false;
    execWheelOnly = true;
  };
}
