{ inputs, ... }: {
  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:${inputs.self.outPath}";

    modules = [
      {
        name = "gaming";
        path = ../.config/gaming-amd/default.nix;
      }
      {
        name = "podman";
        path = ../.config/virtualization/podman.nix;
      }
      {
        name = "wine";
        path = ../.config/virtualization/wine.nix;
      }
      {
        name = "visual";
        path = ../.config/media-production/visual.nix;
      }
      {
        name = "audio";
        path = ../.config/media-production/audio.nix;
      }
    ];
  };
  # Import kernel-related configurations directly in the base system
  # These configurations contain essential drivers and parameters that need
  # to be available at boot time and cannot be dynamically loaded/unloaded.
  imports = [
    ../.config/gaming-amd/kernel.nix
  ];
}
