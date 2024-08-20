{ config
, ...
}:
let
  user = "kari";
in
{
  # This configuration extends the minimal version
  imports = [ ./minimal.nix ];

  # Secrets
  age.secrets = {
    "password".rekeyFile = ./secrets/password.age;
  };

  # Set password
  users.users.${user} = {
    # echo "password" | mkpasswd -s
    hashedPasswordFile = config.age.secrets.password.path;
  };
}
