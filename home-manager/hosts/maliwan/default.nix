{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  # This file should be imported under 'home-manager.users.<username>'
  # See 'home-manager/users/kari/minimal.nix' for an example how to do this conditionally

  imports = [../torgue/default.nix];
}
