{
  pkgs,
  lib,
  config,
  ...
}: {
  boot.initrd.availableKernelModules = ["xhci_pci" "usbhid" "usb_storage"];
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Use the Raspberry Pi 4 kernel
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

  # Connectivity
  networking.hostName = "jakobs";
  networking.firewall.enable = false;
  hardware.bluetooth.enable = true;

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
