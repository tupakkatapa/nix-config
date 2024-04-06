{ pkgs
, ...
}: {
  # Use the Raspberry Pi 4 kernel
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

  # Connectivity
  networking.hostName = "jakobs";
  networking.firewall.enable = false;
  hardware.bluetooth.enable = true;
}
