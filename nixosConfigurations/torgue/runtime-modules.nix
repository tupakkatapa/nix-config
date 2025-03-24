_: {
  services.runtimeModules = {
    enable = true;
    flakeUrl = "path:/home/kari/nix-config";

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
        name = "visual-production";
        path = ../.config/media-production/visual.nix;
      }
      {
        name = "audio-production";
        path = ../.config/media-production/audio/default.nix;
      }
    ];
  };
  # Import kernel-related configurations directly in the base system
  # These configurations contain essential drivers and parameters that need
  # to be available at boot time and cannot be dynamically loaded/unloaded.
  imports = [
    ../.config/gaming-amd/kernel.nix
    ../.config/media-production/audio/kernel.nix
  ];
}
