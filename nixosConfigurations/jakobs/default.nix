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
  networking.hostName = "jakobs";
  time.timeZone = "Europe/Helsinki";
  console.keyMap = "fi";

  # Connectivity
  networking.firewall.enable = false;
  hardware.bluetooth.enable = true;

  services.openssh = {
    enable = true;
    allowSFTP = false;
    extraConfig = ''
      AllowAgentForwarding no
      AllowStreamLocalForwarding no
      AllowTcpForwarding yes
      AuthenticationMethods publickey
      X11Forwarding no
    '';
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Firmware blobs
  hardware.enableRedistributableFirmware = true;
}
