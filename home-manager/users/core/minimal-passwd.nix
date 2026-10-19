{ config, ... }:
let
  user = "core";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Set password
  age.secrets."password".rekeyFile = ./secrets/password.age;
  users.users.${user}.hashedPasswordFile = config.age.secrets.password.path;
}
