{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  user = "kari";
in {
  # This configuration extends the minimal version
  imports = [./minimal.nix];

  # Secrets
  sops.secrets.kari-password = {
    sopsFile = ../../secrets.yaml;
    neededForUsers = true;
  };

  # Set password
  users.users.${user} = {
    # echo "password" | mkpasswd -s
    hashedPasswordFile = config.sops.secrets.kari-password.path;
  };
}
