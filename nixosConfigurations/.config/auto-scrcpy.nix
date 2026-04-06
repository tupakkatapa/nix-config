{ ... }: {
  imports = [ ../../nixosModules/auto-scrcpy.nix ];
  services.autoScrcpy.enable = true;
}
