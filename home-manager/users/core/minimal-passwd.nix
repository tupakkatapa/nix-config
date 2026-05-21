{ config
, lib
, ...
}:
let
  user = "core";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Set password
  age.secrets."password".rekeyFile = ./secrets/password.age;
  users.users.${user}.hashedPasswordFile = config.age.secrets.password.path;

  # Override minimal.nix's NOPASSWD rule; sudo now prompts for the user's password
  security.sudo.extraRules = lib.mkForce [ ];
}
