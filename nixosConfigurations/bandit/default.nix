{ config, lib, ... }: {
  networking.hostName = "bandit";

  # Podman
  imports = [
    ../.config/podman.nix
  ];

  # Disable firewall
  networking.firewall.enable = false;

  # Enable OpenGL
  hardware.graphics.enable = true;

  # NVIDIA support - shouldn't break if no NVIDIA GPU
  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
    modesetting.enable = lib.mkDefault true;
  };
  services.xserver.videoDrivers = [ "nvidia" "modesetting" ];
  hardware.nvidia-container-toolkit.enable = true;
}
