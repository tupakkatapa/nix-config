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

  # Timezone and system version
  hostName = "jakobs";
  time.timeZone = "Europe/Helsinki";
  system.stateVersion = "23.11";
  console.keyMap = "fi";

  # Connectivity
  networking.firewall.enable = false;
  hardware.bluetooth.enable = true;

  services.openssh = {
    enable = true;
    allowSFTP = false;
    extraConfig = ''
      AllowTcpForwarding yes
      X11Forwarding no
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AuthenticationMethods publickey
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
