{ pkgs, lib, config, domain, ... }:
let
  extendedArgs = { inherit pkgs lib config domain; };
in
{
  imports = [
    (import ./index.nix extendedArgs)
    ./network-status.nix
  ];
}
