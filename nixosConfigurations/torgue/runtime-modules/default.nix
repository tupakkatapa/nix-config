_: {
  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:/home/kari/nix-config";

    modules = [
      {
        name = "gaming";
        path = ./gaming.nix;
      }
      {
        name = "virtualization";
        path = ../../.config/virtualization/default.nix;
      }
      {
        name = "media-production";
        path = ./media-production.nix;
      }
      {
        name = "music-production";
        path = ./music-production.nix;
      }
    ];
  };
}
