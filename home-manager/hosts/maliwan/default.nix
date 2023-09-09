{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: {
  # Just a reminder that this file should be imported under 'home-manager.users.<username>'
  imports = [
    ../torque/default.nix
  ];
}
