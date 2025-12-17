# Local testing:
#   nix build .#nixosConfigurations.hyperion.config.system.build.toplevel
#   nix-shell -p python3 --run "python3 -m http.server 8080" -C /nix/store/*-dashboard
#   open http://localhost:8080

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
